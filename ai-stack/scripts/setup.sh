#!/bin/bash

# =================================================================
# AI Stack Setup Script for Mac Mini M4
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

echo -e "${BLUE}🚀 AI Stack Setup for Mac Mini M4${NC}"
echo "=================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    cp .env.example .env
    echo -e "${RED}🔑 IMPORTANT: Please edit .env file and set all passwords and keys!${NC}"
    echo "Required changes:"
    echo "  - All passwords (POSTGRES_PASSWORD, REDIS_PASSWORD, etc.)"
    echo "  - All encryption keys (N8N_ENCRYPTION_KEY, WEBUI_SECRET_KEY, etc.)"
    echo "  - All API keys and tokens"
    echo ""
    read -p "Press Enter after updating .env file..."
fi

# Create required directories
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p data/{postgres,n8n,ollama,webui,redis,litellm,mcp}
mkdir -p logs/{n8n,postgres,nginx}
mkdir -p backups/{postgres,volumes}
mkdir -p configs/{postgres/init,redis,n8n,ollama,litellm,mcp,nginx}

# Set proper permissions
echo -e "${BLUE}🔒 Setting permissions...${NC}"
chmod 700 data/postgres
chmod 755 data/{n8n,ollama,webui,redis,litellm,mcp}
chmod 755 logs/{n8n,postgres}
chmod 755 backups/{postgres,volumes}

# Create .gitignore
cat > .gitignore << 'EOF'
# Environment files with secrets
.env
.env.local
.env.production

# Data directories
data/
logs/
backups/

# Temporary files
*.tmp
*.log
.DS_Store

# IDE files
.vscode/
.idea/

# Docker overrides (keep template)
docker-compose.override.yml

# Backup files
*.backup
*.sql.gz
EOF

# Pull all required images
echo -e "${BLUE}📥 Pulling Docker images...${NC}"
docker compose pull

# Download Llama 3.2 models
echo -e "${BLUE}🤖 Setting up Ollama with Llama 3.2 models...${NC}"
echo "This will start Ollama temporarily to download models..."

# Start only Ollama for model download
docker compose up -d ollama
sleep 30

# Download Llama 3.2 models
echo -e "${YELLOW}📥 Downloading Llama 3.2:1b (lightweight)...${NC}"
docker exec ai-ollama ollama pull llama3.2:1b

echo -e "${YELLOW}📥 Downloading Llama 3.2:3b (balanced)...${NC}"
docker exec ai-ollama ollama pull llama3.2:3b

echo -e "${YELLOW}📥 Downloading nomic-embed-text (for RAG)...${NC}"
docker exec ai-ollama ollama pull nomic-embed-text

# Stop Ollama
docker compose stop ollama

echo -e "${GREEN}✅ Models downloaded successfully${NC}"

# Create backup script
cat > scripts/backup.sh << 'EOF'
#!/bin/bash
set -e

source .env

BACKUP_DIR="/Users/$(whoami)/Documents/ai-stack-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "🔄 Starting backup process..."

# Backup PostgreSQL
echo "📊 Backing up PostgreSQL..."
docker exec ai-postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > "$BACKUP_DIR/postgres_${DATE}.sql.gz"

# Backup volumes
echo "💾 Backing up Docker volumes..."
docker run --rm -v ai-stack_n8n_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/n8n_data_${DATE}.tar.gz -C /data .
docker run --rm -v ai-stack_ollama_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/ollama_data_${DATE}.tar.gz -C /data .

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -type f -mtime +30 -delete

echo "✅ Backup completed: $BACKUP_DIR"
EOF

chmod +x scripts/backup.sh

# Make scripts executable
chmod +x scripts/*.sh

echo ""
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Review and update .env file with your secure passwords and keys"
echo "2. Run: ./scripts/start.sh"
echo "3. Access your services:"
echo "   - n8n Workflows: http://localhost:5678"
echo "   - Open WebUI: http://localhost:8080"
echo "   - LiteLLM: http://localhost:4000"
echo ""
echo -e "${YELLOW}⚠️  Remember to backup your .env file securely!${NC}"
