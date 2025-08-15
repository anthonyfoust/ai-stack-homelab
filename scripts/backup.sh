#!/bin/bash

# =================================================================
# AI Stack Backup Script
# Simple, comprehensive backup for all AI Stack data
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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
ENCRYPT="${BACKUP_ENCRYPT:-true}"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

echo -e "${BLUE}${BOLD}💾 AI Stack Backup Utility${NC}"
echo "============================"
echo ""

# Parse command line arguments
BACKUP_TYPE="full"
SERVICES=""
COMPRESS=true

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
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --type, -t       Backup type: full, data, config (default: full)"
            echo "  --service, -s    Specific service: postgres, n8n, ollama, etc."
            echo "  --no-compress    Skip compression (faster, larger files)"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                       # Full backup"
            echo "  $0 --type data           # Data only backup"
            echo "  $0 --service postgres    # PostgreSQL only"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Function to encrypt file if encryption is enabled
encrypt_file() {
    local file="$1"
    if [ "$ENCRYPT" = "true" ] && [ -n "$ENCRYPTION_KEY" ]; then
        echo -e "${BLUE}🔒 Encrypting $(basename "$file")...${NC}"
        openssl enc -aes-256-cbc -in "$file" -out "${file}.enc" -pass pass:"$ENCRYPTION_KEY"
        rm "$file"
        echo "${file}.enc"
    else
        echo "$file"
    fi
}

# Function to check if services are running
check_services() {
    echo -e "${BLUE}🔍 Checking service status...${NC}"
    
    if ! docker compose ps --services --filter "status=running" | grep -q postgres; then
        echo -e "${YELLOW}⚠️ PostgreSQL is not running. Some backups may be incomplete.${NC}"
    else
        echo -e "${GREEN}✅ PostgreSQL is running${NC}"
    fi
    
    echo ""
}

# Function to create backup directory
setup_backup_dir() {
    echo -e "${BLUE}📁 Setting up backup directory...${NC}"
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}✅ Backup directory: $BACKUP_DIR${NC}"
    echo ""
}

# Function to backup PostgreSQL databases
backup_postgres() {
    echo -e "${BLUE}🐘 Backing up PostgreSQL databases...${NC}"
    
    # Backup main database
    echo "  📊 Backing up main database..."
    if [ "$COMPRESS" = true ]; then
        docker exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_DIR/postgres_main_${DATE}.sql.gz"
        encrypt_file "$BACKUP_DIR/postgres_main_${DATE}.sql.gz"
    else
        docker exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$BACKUP_DIR/postgres_main_${DATE}.sql"
        encrypt_file "$BACKUP_DIR/postgres_main_${DATE}.sql"
    fi
    
    # Backup additional databases
    if [ -n "$POSTGRES_ADDITIONAL_DBS" ]; then
        IFS=',' read -ra DBS <<< "$POSTGRES_ADDITIONAL_DBS"
        for db in "${DBS[@]}"; do
            db=$(echo "$db" | xargs) # trim whitespace
            echo "  📊 Backing up database: $db..."
            if docker exec postgres psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db"; then
                if [ "$COMPRESS" = true ]; then
                    docker exec postgres pg_dump -U "$POSTGRES_USER" "$db" | gzip > "$BACKUP_DIR/postgres_${db}_${DATE}.sql.gz"
                    encrypt_file "$BACKUP_DIR/postgres_${db}_${DATE}.sql.gz"
                else
                    docker exec postgres pg_dump -U "$POSTGRES_USER" "$db" > "$BACKUP_DIR/postgres_${db}_${DATE}.sql"
                    encrypt_file "$BACKUP_DIR/postgres_${db}_${DATE}.sql"
                fi
            else
                echo -e "${YELLOW}    ⚠️ Database $db not found, skipping${NC}"
            fi
        done
    fi
    
    echo -e "${GREEN}✅ PostgreSQL backup completed${NC}"
}

# Function to backup Docker volumes
backup_volumes() {
    echo -e "${BLUE}💾 Backing up Docker volumes...${NC}"
    
    volumes=("n8n_data" "ollama_data" "open-webui_data" "redis_data" "litellm_data" "mcp_data")
    
    for volume in "${volumes[@]}"; do
        echo "  📁 Backing up volume: $volume..."
        if docker volume inspect "ai-stack_$volume" > /dev/null 2>&1; then
            if [ "$COMPRESS" = true ]; then
                docker run --rm \
                    -v "ai-stack_$volume:/data" \
                    -v "$BACKUP_DIR":/backup \
                    alpine tar czf "/backup/${volume}_${DATE}.tar.gz" -C /data .
                encrypt_file "$BACKUP_DIR/${volume}_${DATE}.tar.gz"
            else
                docker run --rm \
                    -v "ai-stack_$volume:/data" \
                    -v "$BACKUP_DIR":/backup \
                    alpine tar cf "/backup/${volume}_${DATE}.tar" -C /data .
                encrypt_file "$BACKUP_DIR/${volume}_${DATE}.tar"
            fi
        else
            echo -e "${YELLOW}    ⚠️ Volume $volume not found, skipping${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Volume backup completed${NC}"
}

# Function to backup configuration files
backup_configs() {
    echo -e "${BLUE}⚙️ Backing up configuration files...${NC}"
    
    if [ -d configs ]; then
        echo "  📋 Backing up configs directory..."
        if [ "$COMPRESS" = true ]; then
            tar czf "$BACKUP_DIR/configs_${DATE}.tar.gz" configs/
            encrypt_file "$BACKUP_DIR/configs_${DATE}.tar.gz"
        else
            tar cf "$BACKUP_DIR/configs_${DATE}.tar" configs/
            encrypt_file "$BACKUP_DIR/configs_${DATE}.tar"
        fi
    fi
    
    # Backup important root files (excluding .env for security)
    echo "  📋 Backing up docker-compose.yml..."
    cp docker-compose.yml "$BACKUP_DIR/docker-compose_${DATE}.yml"
    encrypt_file "$BACKUP_DIR/docker-compose_${DATE}.yml"
    
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
        n8n|ollama|open-webui|redis|litellm|mcp)
            echo "  💾 Backing up ${service} data..."
            volume_name="${service}_data"
            if [ "$service" = "open-webui" ]; then
                volume_name="open-webui_data"
            fi
            
            if docker volume inspect "ai-stack_$volume_name" > /dev/null 2>&1; then
                if [ "$COMPRESS" = true ]; then
                    docker run --rm \
                        -v "ai-stack_$volume_name:/data" \
                        -v "$BACKUP_DIR":/backup \
                        alpine tar czf "/backup/${volume_name}_${DATE}.tar.gz" -C /data .
                    encrypt_file "$BACKUP_DIR/${volume_name}_${DATE}.tar.gz"
                else
                    docker run --rm \
                        -v "ai-stack_$volume_name:/data" \
                        -v "$BACKUP_DIR":/backup \
                        alpine tar cf "/backup/${volume_name}_${DATE}.tar" -C /data .
                    encrypt_file "$BACKUP_DIR/${volume_name}_${DATE}.tar"
                fi
                echo -e "${GREEN}✅ $service backup completed${NC}"
            else
                echo -e "${YELLOW}⚠️ Volume for $service not found${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            exit 1
            ;;
    esac
}

# Function to create backup manifest
create_manifest() {
    echo -e "${BLUE}📋 Creating backup manifest...${NC}"
    
    manifest_file="$BACKUP_DIR/backup_manifest_${DATE}.json"
    
    cat > "$manifest_file" << EOF
{
  "backup_date": "$DATE",
  "backup_type": "$BACKUP_TYPE",
  "services": "$SERVICES",
  "compressed": $COMPRESS,
  "encrypted": $ENCRYPT,
  "files": [$(find "$BACKUP_DIR" -name "*_${DATE}.*" -type f | sed 's/.*/"&"/' | paste -sd, -)],
  "ai_stack_version": "1.0",
  "created_by": "ai-stack-backup-script"
}
EOF
    
    echo -e "${GREEN}✅ Backup manifest created${NC}"
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo -e "${BLUE}🧹 Cleaning up old backups...${NC}"
    
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        echo "  🗑️ Removing backups older than $RETENTION_DAYS days..."
        find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -name "*.gz" -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -name "*.tar" -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -name "*.sql" -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -name "*.enc" -delete 2>/dev/null || true
        find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -name "backup_manifest_*.json" -delete 2>/dev/null || true
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    else
        echo "  ℹ️ Cleanup disabled (retention set to 0)"
    fi
}

# Function to show backup summary
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}🎉 Backup Completed Successfully!${NC}"
    echo "=================================="
    echo "📅 Date: $DATE"
    echo "🗂️ Type: $BACKUP_TYPE"
    echo "📍 Location: $BACKUP_DIR"
    echo "🔒 Encrypted: $ENCRYPT"
    echo "📦 Compressed: $COMPRESS"
    
    if [ -n "$SERVICES" ]; then
        echo "🎯 Services: $SERVICES"
    fi
    
    echo ""
    echo "📊 Backup Files:"
    find "$BACKUP_DIR" -name "*_${DATE}.*" -type f | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "  📄 $(basename "$file") ($size)"
    done
    
    echo ""
    echo -e "${BLUE}💡 To restore this backup:${NC}"
    echo "  ./scripts/restore.sh --date $DATE"
    echo ""
}

# Main execution
main() {
    check_services
    setup_backup_dir
    
    echo -e "${BLUE}🔄 Starting $BACKUP_TYPE backup...${NC}"
    echo ""
    
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
            echo "Available types: full, data, config"
            exit 1
            ;;
    esac
    
    create_manifest
    cleanup_old_backups
    show_summary
}

# Check if backup is enabled
if [ "$BACKUP_ENABLED" != "true" ]; then
    echo -e "${YELLOW}⚠️ Backup is disabled in configuration${NC}"
    echo "To enable: Set BACKUP_ENABLED=true in .env file"
    exit 1
fi

# Run main function
main "$@"