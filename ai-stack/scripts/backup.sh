#!/bin/bash

# =================================================================
# AI Stack Backup Script
# Automated backup with encryption and retention management
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

# Configuration
BACKUP_DIR="${BACKUP_LOCATION:-$HOME/Documents/ai-stack-backups}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
ENCRYPT="${BACKUP_ENCRYPT:-true}"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"

echo -e "${BLUE}💾 AI Stack Backup Utility${NC}"
echo "=========================="

# Parse command line arguments
BACKUP_TYPE="full"
SERVICES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --type|-t)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --service|-s)
            SERVICES="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --type, -t      Backup type: full, data, config (default: full)"
            echo "  --service, -s   Specific service: postgres, n8n, ollama, etc."
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Backup types:"
            echo "  full     - Complete backup including data and configuration"
            echo "  data     - Only data volumes and databases"
            echo "  config   - Only configuration files"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  No running containers found. Starting services for backup...${NC}"
    docker compose up -d postgres redis
    sleep 10
fi

echo -e "${BLUE}📦 Starting $BACKUP_TYPE backup...${NC}"
echo "Backup location: $BACKUP_DIR"
echo "Timestamp: $DATE"

# Function to encrypt file
encrypt_file() {
    local file="$1"
    if [ "$ENCRYPT" = "true" ] && [ -n "$ENCRYPTION_KEY" ]; then
        echo -e "${BLUE}🔒 Encrypting $file...${NC}"
        openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -pass pass:"$ENCRYPTION_KEY"
        rm "$file"
        echo "${file}.enc"
    else
        echo "$file"
    fi
}

# Function to backup PostgreSQL
backup_postgres() {
    echo -e "${BLUE}🐘 Backing up PostgreSQL databases...${NC}"
    
    # Main database
    docker exec ai-postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$BACKUP_DIR/postgres_main_${DATE}.sql.gz"
    encrypt_file "$BACKUP_DIR/postgres_main_${DATE}.sql.gz"
    
    # n8n database
    if docker exec ai-postgres psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "n8n_prod"; then
        docker exec ai-postgres pg_dump -U "$POSTGRES_USER" -d "n8n_prod" | gzip > "$BACKUP_DIR/postgres_n8n_${DATE}.sql.gz"
        encrypt_file "$BACKUP_DIR/postgres_n8n_${DATE}.sql.gz"
    fi
    
    # LiteLLM database
    if docker exec ai-postgres psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "litellm_prod"; then
        docker exec ai-postgres pg_dump -U "$POSTGRES_USER" -d "litellm_prod" | gzip > "$BACKUP_DIR/postgres_litellm_${DATE}.sql.gz"
        encrypt_file "$BACKUP_DIR/postgres_litellm_${DATE}.sql.gz"
    fi
    
    echo -e "${GREEN}✅ PostgreSQL backup completed${NC}"
}

# Function to backup Docker volumes
backup_volumes() {
    echo -e "${BLUE}💾 Backing up Docker volumes...${NC}"
    
    volumes=("n8n_data" "ollama_data" "webui_data" "redis_data" "litellm_data" "mcp_data")
    
    for volume in "${volumes[@]}"; do
        if docker volume ls | grep -q "ai-stack_${volume}"; then
            echo -e "${BLUE}  📁 Backing up ${volume}...${NC}"
            docker run --rm \
                -v "ai-stack_${volume}:/data" \
                -v "$BACKUP_DIR":/backup \
                alpine tar czf "/backup/${volume}_${DATE}.tar.gz" -C /data .
            encrypt_file "$BACKUP_DIR/${volume}_${DATE}.tar.gz"
        fi
    done
    
    echo -e "${GREEN}✅ Volume backup completed${NC}"
}

# Function to backup configuration files
backup_configs() {
    echo -e "${BLUE}⚙️  Backing up configuration files...${NC}"
    
    # Create config backup
    tar czf "$BACKUP_DIR/configs_${DATE}.tar.gz" \
        configs/ \
        scripts/ \
        docker-compose.yml \
        .env.example \
        2>/dev/null || true
    
    encrypt_file "$BACKUP_DIR/configs_${DATE}.tar.gz"
    
    echo -e "${GREEN}✅ Configuration backup completed${NC}"
}

# Function to backup specific service
backup_service() {
    local service="$1"
    echo -e "${BLUE}🎯 Backing up service: $service${NC}"
    
    case "$service" in
        postgres)
            backup_postgres
            ;;
        n8n)
            docker run --rm -v "ai-stack_n8n_data:/data" -v "$BACKUP_DIR":/backup alpine tar czf "/backup/n8n_data_${DATE}.tar.gz" -C /data .
            encrypt_file "$BACKUP_DIR/n8n_data_${DATE}.tar.gz"
            ;;
        ollama)
            docker run --rm -v "ai-stack_ollama_data:/data" -v "$BACKUP_DIR":/backup alpine tar czf "/backup/ollama_data_${DATE}.tar.gz" -C /data .
            encrypt_file "$BACKUP_DIR/ollama_data_${DATE}.tar.gz"
            ;;
        webui)
            docker run --rm -v "ai-stack_webui_data:/data" -v "$BACKUP_DIR":/backup alpine tar czf "/backup/webui_data_${DATE}.tar.gz" -C /data .
            encrypt_file "$BACKUP_DIR/webui_data_${DATE}.tar.gz"
            ;;
        redis)
            docker exec ai-redis redis-cli BGSAVE
            sleep 5
            docker run --rm -v "ai-stack_redis_data:/data" -v "$BACKUP_DIR":/backup alpine tar czf "/backup/redis_data_${DATE}.tar.gz" -C /data .
            encrypt_file "$BACKUP_DIR/redis_data_${DATE}.tar.gz"
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            exit 1
            ;;
    esac
}

# Create backup manifest
create_manifest() {
    local manifest_file="$BACKUP_DIR/backup_manifest_${DATE}.json"
    
    cat > "$manifest_file" << EOF
{
  "backup_date": "$(date -Iseconds)",
  "backup_type": "$BACKUP_TYPE",
  "services": $(if [ -n "$SERVICES" ]; then echo "\"$SERVICES\""; else echo "\"all\""; fi),
  "encryption_enabled": $ENCRYPT,
  "ai_stack_version": "1.0.0",
  "files": [
$(find "$BACKUP_DIR" -name "*_${DATE}.*" -type f | sed 's/.*\//    "/' | sed 's/$/"/' | paste -sd ',' -)
  ],
  "retention_days": $RETENTION_DAYS
}
EOF
    
    echo -e "${GREEN}📋 Backup manifest created: $manifest_file${NC}"
}

# Perform backup based on type
case "$BACKUP_TYPE" in
    full)
        if [ -n "$SERVICES" ]; then
            backup_service "$SERVICES"
        else
            backup_postgres
            backup_volumes
            backup_configs
        fi
        ;;
    data)
        if [ -n "$SERVICES" ]; then
            backup_service "$SERVICES"
        else
            backup_postgres
            backup_volumes
        fi
        ;;
    config)
        backup_configs
        ;;
    *)
        echo -e "${RED}❌ Unknown backup type: $BACKUP_TYPE${NC}"
        exit 1
        ;;
esac

# Create manifest
create_manifest

# Cleanup old backups
if [ "$RETENTION_DAYS" -gt 0 ]; then
    echo -e "${BLUE}🧹 Cleaning up backups older than $RETENTION_DAYS days...${NC}"
    find "$BACKUP_DIR" -type f -name "*.tar.gz*" -o -name "*.sql.gz*" -o -name "*.json" | \
        xargs -I {} find {} -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    deleted_count=$(find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" 2>/dev/null | wc -l || echo 0)
    if [ "$deleted_count" -gt 0 ]; then
        echo -e "${GREEN}🗑️  Cleaned up $deleted_count old backup files${NC}"
    fi
fi

# Calculate backup size
backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)

echo ""
echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
echo "=========================="
echo "📍 Location: $BACKUP_DIR"
echo "📊 Total size: $backup_size"
echo "🔒 Encryption: $(if [ "$ENCRYPT" = "true" ]; then echo "Enabled"; else echo "Disabled"; fi)"
echo "⏰ Retention: $RETENTION_DAYS days"
echo ""
echo "To restore from this backup, use: ./scripts/restore.sh --date $DATE"
