#!/bin/bash

# =================================================================
# AI Stack Restore Script
# Restore from encrypted backups with verification
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
ENCRYPT="${BACKUP_ENCRYPT:-true}"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"

echo -e "${BLUE}🔄 AI Stack Restore Utility${NC}"
echo "==========================="

# Parse command line arguments
RESTORE_DATE=""
RESTORE_TYPE="full"
SERVICES=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --date|-d)
            RESTORE_DATE="$2"
            shift 2
            ;;
        --type|-t)
            RESTORE_TYPE="$2"
            shift 2
            ;;
        --service|-s)
            SERVICES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list|-l)
            echo -e "${BLUE}📋 Available backups:${NC}"
            echo "==================="
            if [ -d "$BACKUP_DIR" ]; then
                find "$BACKUP_DIR" -name "backup_manifest_*.json" | sort -r | while read manifest; do
                    date_part=$(basename "$manifest" | sed 's/backup_manifest_//' | sed 's/.json//')
                    echo -e "${GREEN}📅 $date_part${NC}"
                    if command -v jq > /dev/null 2>&1; then
                        jq -r '. | "   Type: \(.backup_type)\n   Date: \(.backup_date)\n   Files: \(.files | length)"' "$manifest" 2>/dev/null || echo "   (Manifest details unavailable)"
                    fi
                    echo ""
                done
            else
                echo "No backup directory found at: $BACKUP_DIR"
            fi
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --date, -d      Restore from specific backup date (YYYYMMDD_HHMMSS)"
            echo "  --type, -t      Restore type: full, data, config (default: full)"
            echo "  --service, -s   Specific service: postgres, n8n, ollama, etc."
            echo "  --dry-run       Show what would be restored without actually doing it"
            echo "  --list, -l      List available backups"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --list                    # List available backups"
            echo "  $0 --date 20240101_120000    # Restore full backup from specific date"
            echo "  $0 --service postgres        # Restore only PostgreSQL from latest backup"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Find latest backup if no date specified
if [ -z "$RESTORE_DATE" ]; then
    echo -e "${BLUE}🔍 Finding latest backup...${NC}"
    latest_manifest=$(find "$BACKUP_DIR" -name "backup_manifest_*.json" 2>/dev/null | sort -r | head -n1)
    if [ -z "$latest_manifest" ]; then
        echo -e "${RED}❌ No backups found in $BACKUP_DIR${NC}"
        exit 1
    fi
    RESTORE_DATE=$(basename "$latest_manifest" | sed 's/backup_manifest_//' | sed 's/.json//')
    echo -e "${GREEN}📅 Using latest backup: $RESTORE_DATE${NC}"
fi

# Verify backup exists
MANIFEST_FILE="$BACKUP_DIR/backup_manifest_${RESTORE_DATE}.json"
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}❌ Backup manifest not found: $MANIFEST_FILE${NC}"
    echo "Available backups:"
    find "$BACKUP_DIR" -name "backup_manifest_*.json" | sort -r | head -5
    exit 1
fi

echo -e "${BLUE}📋 Backup information:${NC}"
if command -v jq > /dev/null 2>&1; then
    jq -r '. | "Date: \(.backup_date)\nType: \(.backup_type)\nServices: \(.services)\nFiles: \(.files | length)"' "$MANIFEST_FILE"
else
    echo "Manifest: $MANIFEST_FILE"
fi

# Function to decrypt file
decrypt_file() {
    local file="$1"
    if [ -f "${file}.enc" ] && [ "$ENCRYPT" = "true" ] && [ -n "$ENCRYPTION_KEY" ]; then
        echo -e "${BLUE}🔓 Decrypting $(basename "$file")...${NC}"
        openssl enc -aes-256-cbc -d -in "${file}.enc" -out "$file" -pass pass:"$ENCRYPTION_KEY"
        echo "$file"
    elif [ -f "$file" ]; then
        echo "$file"
    else
        echo ""
    fi
}

# Function to restore PostgreSQL
restore_postgres() {
    echo -e "${BLUE}🐘 Restoring PostgreSQL databases...${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would restore PostgreSQL databases"
        return
    fi
    
    # Ensure PostgreSQL is running
    docker compose up -d postgres
    sleep 10
    
    # Restore main database
    main_backup=$(decrypt_file "$BACKUP_DIR/postgres_main_${RESTORE_DATE}.sql.gz")
    if [ -n "$main_backup" ] && [ -f "$main_backup" ]; then
        echo -e "${BLUE}  📊 Restoring main database...${NC}"
        zcat "$main_backup" | docker exec -i ai-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
        rm -f "$main_backup"
    fi
    
    # Restore n8n database
    n8n_backup=$(decrypt_file "$BACKUP_DIR/postgres_n8n_${RESTORE_DATE}.sql.gz")
    if [ -n "$n8n_backup" ] && [ -f "$n8n_backup" ]; then
        echo -e "${BLUE}  🔄 Restoring n8n database...${NC}"
        docker exec ai-postgres createdb -U "$POSTGRES_USER" n8n_prod 2>/dev/null || true
        zcat "$n8n_backup" | docker exec -i ai-postgres psql -U "$POSTGRES_USER" -d "n8n_prod"
        rm -f "$n8n_backup"
    fi
    
    # Restore LiteLLM database
    litellm_backup=$(decrypt_file "$BACKUP_DIR/postgres_litellm_${RESTORE_DATE}.sql.gz")
    if [ -n "$litellm_backup" ] && [ -f "$litellm_backup" ]; then
        echo -e "${BLUE}  🎯 Restoring LiteLLM database...${NC}"
        docker exec ai-postgres createdb -U "$POSTGRES_USER" litellm_prod 2>/dev/null || true
        zcat "$litellm_backup" | docker exec -i ai-postgres psql -U "$POSTGRES_USER" -d "litellm_prod"
        rm -f "$litellm_backup"
    fi
    
    echo -e "${GREEN}✅ PostgreSQL restore completed${NC}"
}

# Function to restore Docker volumes
restore_volumes() {
    echo -e "${BLUE}💾 Restoring Docker volumes...${NC}"
    
    volumes=("n8n_data" "ollama_data" "webui_data" "redis_data" "litellm_data" "mcp_data")
    
    for volume in "${volumes[@]}"; do
        volume_backup=$(decrypt_file "$BACKUP_DIR/${volume}_${RESTORE_DATE}.tar.gz")
        if [ -n "$volume_backup" ] && [ -f "$volume_backup" ]; then
            echo -e "${BLUE}  📁 Restoring ${volume}...${NC}"
            
            if [ "$DRY_RUN" = true ]; then
                echo "    [DRY RUN] Would restore volume: ai-stack_${volume}"
            else
                # Remove existing volume and recreate
                docker volume rm "ai-stack_${volume}" 2>/dev/null || true
                docker volume create "ai-stack_${volume}"
                
                # Restore volume data
                docker run --rm \
                    -v "ai-stack_${volume}:/data" \
                    -v "$BACKUP_DIR":/backup \
                    alpine sh -c "cd /data && tar xzf /backup/$(basename "$volume_backup")"
            fi
            
            rm -f "$volume_backup"
        fi
    done
    
    echo -e "${GREEN}✅ Volume restore completed${NC}"
}

# Function to restore configuration files
restore_configs() {
    echo -e "${BLUE}⚙️  Restoring configuration files...${NC}"
    
    config_backup=$(decrypt_file "$BACKUP_DIR/configs_${RESTORE_DATE}.tar.gz")
    if [ -n "$config_backup" ] && [ -f "$config_backup" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY RUN] Would restore configuration files"
        else
            # Backup current configs
            if [ -d configs ]; then
                mv configs "configs.backup.$(date +%Y%m%d_%H%M%S)"
            fi
            
            # Restore configs
            tar xzf "$config_backup"
        fi
        
        rm -f "$config_backup"
    fi
    
    echo -e "${GREEN}✅ Configuration restore completed${NC}"
}

# Function to restore specific service
restore_service() {
    local service="$1"
    echo -e "${BLUE}🎯 Restoring service: $service${NC}"
    
    case "$service" in
        postgres)
            restore_postgres
            ;;
        n8n|ollama|webui|redis|litellm|mcp)
            volume_backup=$(decrypt_file "$BACKUP_DIR/${service}_data_${RESTORE_DATE}.tar.gz")
            if [ -n "$volume_backup" ] && [ -f "$volume_backup" ]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "  [DRY RUN] Would restore ${service} data"
                else
                    docker volume rm "ai-stack_${service}_data" 2>/dev/null || true
                    docker volume create "ai-stack_${service}_data"
                    docker run --rm \
                        -v "ai-stack_${service}_data:/data" \
                        -v "$BACKUP_DIR":/backup \
                        alpine sh -c "cd /data && tar xzf /backup/$(basename "$volume_backup")"
                fi
                rm -f "$volume_backup"
            else
                echo -e "${YELLOW}⚠️  No backup found for service: $service${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            exit 1
            ;;
    esac
}

# Warning for non-dry-run
if [ "$DRY_RUN" = false ]; then
    echo -e "${RED}⚠️  WARNING: This will overwrite existing data!${NC}"
    echo "Current data will be backed up before restoration."
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
    
    # Stop services before restore
    echo -e "${BLUE}🛑 Stopping AI Stack services...${NC}"
    docker compose down
fi

# Perform restore based on type
echo -e "${BLUE}🔄 Starting $RESTORE_TYPE restore...${NC}"

case "$RESTORE_TYPE" in
    full)
        if [ -n "$SERVICES" ]; then
            restore_service "$SERVICES"
        else
            restore_postgres
            restore_volumes
            restore_configs
        fi
        ;;
    data)
        if [ -n "$SERVICES" ]; then
            restore_service "$SERVICES"
        else
            restore_postgres
            restore_volumes
        fi
        ;;
    config)
        restore_configs
        ;;
    *)
        echo -e "${RED}❌ Unknown restore type: $RESTORE_TYPE${NC}"
        exit 1
        ;;
esac

if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${GREEN}🎉 Restore completed successfully!${NC}"
    echo "=========================="
    echo "📅 Restored from: $RESTORE_DATE"
    echo "🔄 Type: $RESTORE_TYPE"
    echo ""
    echo "To start the AI Stack with restored data:"
    echo "  ./scripts/start.sh"
else
    echo ""
    echo -e "${BLUE}🔍 Dry run completed${NC}"
    echo "No changes were made to the system."
fi
