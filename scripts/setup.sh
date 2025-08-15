#!/bin/bash

# =================================================================
# AI Stack Setup Script for Mac Mini M4
# Simple, efficient setup for novice users
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}${BOLD}🚀 AI Stack Setup for Mac Mini M4${NC}"
echo "======================================"
echo ""

# Function to print section headers
print_section() {
    echo -e "${BLUE}${BOLD}$1${NC}"
    echo "$(printf '%*s' ${#1} | tr ' ' '=')"
}

# Function to check prerequisites
check_prerequisites() {
    print_section "📋 Checking Prerequisites"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running${NC}"
        echo ""
        echo "Please:"
        echo "1. Open Docker Desktop application"
        echo "2. Wait for it to start completely"
        echo "3. Run this script again"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"

    # Check Docker Compose version
    if ! docker compose version > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose not available${NC}"
        echo "Please update Docker Desktop to the latest version"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker Compose is available${NC}"

    # Check available disk space (at least 10GB)
    available_space=$(df -k . | awk 'NR==2{print $4}')
    if [ "$available_space" -lt 10485760 ]; then
        echo -e "${YELLOW}⚠️  Warning: Less than 10GB free space available${NC}"
        echo "Recommended: At least 50GB for AI models and data"
    else
        echo -e "${GREEN}✅ Sufficient disk space available${NC}"
    fi

    echo ""
}

# Function to create environment file
setup_environment() {
    print_section "⚙️ Setting Up Environment"
    
    if [ ! -f .env ]; then
        echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✅ .env file created${NC}"
        echo ""
        echo -e "${RED}${BOLD}🔑 IMPORTANT: You must update .env file with secure passwords!${NC}"
        echo ""
        echo "Required changes in .env file:"
        echo "• POSTGRES_PASSWORD - Database password"
        echo "• REDIS_PASSWORD - Cache password"
        echo "• N8N_ENCRYPTION_KEY - Workflow encryption (32 characters)"
        echo "• OPEN_WEBUI_SECRET_KEY - Open WebUI security key (32 characters)"
        echo "• All other passwords and API keys"
        echo ""
        echo "💡 Generate secure keys using:"
        echo "   openssl rand -base64 32    # For passwords"
        echo "   openssl rand -hex 16       # For 32-char keys"
        echo ""
        
        # Wait for user confirmation
        while true; do
            read -p "Have you updated the .env file? (y/n): " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) 
                    echo "Please update .env file first, then run this script again"
                    exit 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    else
        echo -e "${GREEN}✅ .env file already exists${NC}"
    fi

    # Validate critical environment variables
    source .env
    critical_vars=("POSTGRES_PASSWORD" "REDIS_PASSWORD" "N8N_ENCRYPTION_KEY" "OPEN_WEBUI_SECRET_KEY")
    missing_vars=()
    
    for var in "${critical_vars[@]}"; do
        if [ -z "${!var}" ] || [[ "${!var}" == *"your_"* ]] || [[ "${!var}" == *"_here"* ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ The following variables need to be set in .env:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        echo ""
        echo "Please update your .env file and run this script again"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Environment variables validated${NC}"
    echo ""
}

# Function to create directory structure
create_directories() {
    print_section "📁 Creating Directory Structure"
    
    # Data directories
    mkdir -p data/{postgres,n8n,ollama,open-webui,redis,litellm,mcp}
    echo -e "${GREEN}✅ Data directories created${NC}"
    
    # Log directories
    mkdir -p logs/{n8n,postgres,nginx}
    echo -e "${GREEN}✅ Log directories created${NC}"
    
    # Backup directories
    mkdir -p backups/{postgres,volumes}
    echo -e "${GREEN}✅ Backup directories created${NC}"
    
    # Config directories
    mkdir -p configs/{postgres/init,redis,n8n,ollama,litellm,mcp,nginx}
    echo -e "${GREEN}✅ Config directories created${NC}"
    
    # Set permissions
    chmod 700 data/postgres
    chmod 755 data/{n8n,ollama,open-webui,redis,litellm,mcp}
    chmod 755 logs/{n8n,postgres}
    chmod 755 backups/{postgres,volumes}
    echo -e "${GREEN}✅ Permissions set${NC}"
    echo ""
}

# Function to create configuration files
create_configs() {
    print_section "🔧 Creating Configuration Files"
    
    # MCP configuration
    cat > configs/mcp/config.json << 'EOF'
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "n8n-mcp",
        "http://n8n-mcp:3000/mcp",
        "--header",
        "Authorization: Bearer ${N8N_MCP_AUTH_TOKEN}",
        "--allow-http"
      ]
    }
  }
}
EOF
    echo -e "${GREEN}✅ MCP configuration created${NC}"

    # PostgreSQL initialization script
    cat > configs/postgres/init/01-init-databases.sql << 'EOF'
-- Create additional databases for AI Stack services
SELECT 'CREATE DATABASE n8n_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_db')\gexec
SELECT 'CREATE DATABASE litellm_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm_db')\gexec
SELECT 'CREATE DATABASE open_webui_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'open_webui_db')\gexec

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO aistack_user;
GRANT ALL PRIVILEGES ON DATABASE litellm_db TO aistack_user;
GRANT ALL PRIVILEGES ON DATABASE open_webui_db TO aistack_user;
EOF
    echo -e "${GREEN}✅ PostgreSQL init script created${NC}"

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

# Docker overrides
docker-compose.override.yml

# Backup files
*.backup
*.sql.gz
EOF
    echo -e "${GREEN}✅ .gitignore created${NC}"
    echo ""
}

# Function to pull Docker images
pull_images() {
    print_section "📥 Downloading Docker Images"
    
    echo "This may take several minutes depending on your internet connection..."
    echo ""
    
    if docker compose pull; then
        echo -e "${GREEN}✅ All Docker images downloaded successfully${NC}"
    else
        echo -e "${RED}❌ Failed to download some Docker images${NC}"
        echo "Please check your internet connection and try again"
        exit 1
    fi
    echo ""
}

# Function to download AI models
setup_models() {
    print_section "🤖 Setting Up AI Models"
    
    echo "Downloading Llama 3.2 models (this may take 10-20 minutes)..."
    echo ""
    
    # Start only Ollama for model download
    echo "Starting Ollama temporarily..."
    docker compose up -d ollama
    
    # Wait for Ollama to be ready
    echo "Waiting for Ollama to start..."
    sleep 30
    
    # Download models
    echo -e "${BLUE}📥 Downloading llama3.2:1b (lightweight, ~1.3GB)...${NC}"
    if docker exec ollama ollama pull llama3.2:1b; then
        echo -e "${GREEN}✅ llama3.2:1b downloaded${NC}"
    else
        echo -e "${YELLOW}⚠️ Failed to download llama3.2:1b${NC}"
    fi
    
    echo -e "${BLUE}📥 Downloading llama3.2:3b (balanced, ~2GB)...${NC}"
    if docker exec ollama ollama pull llama3.2:3b; then
        echo -e "${GREEN}✅ llama3.2:3b downloaded${NC}"
    else
        echo -e "${YELLOW}⚠️ Failed to download llama3.2:3b${NC}"
    fi
    
    echo -e "${BLUE}📥 Downloading nomic-embed-text (for embeddings, ~274MB)...${NC}"
    if docker exec ollama ollama pull nomic-embed-text; then
        echo -e "${GREEN}✅ nomic-embed-text downloaded${NC}"
    else
        echo -e "${YELLOW}⚠️ Failed to download nomic-embed-text${NC}"
    fi
    
    # Stop Ollama
    docker compose stop ollama
    echo -e "${GREEN}✅ AI models setup completed${NC}"
    echo ""
}

# Function to make scripts executable
setup_scripts() {
    print_section "📜 Setting Up Management Scripts"
    
    # Make all scripts executable
    chmod +x scripts/*.sh
    echo -e "${GREEN}✅ All scripts are now executable${NC}"
    echo ""
}

# Function to create backup script
create_backup_script() {
    # Enhanced backup script will be created separately
    echo -e "${GREEN}✅ Backup scripts ready${NC}"
}

# Function to display completion message
show_completion() {
    print_section "🎉 Setup Completed Successfully!"
    
    echo -e "${GREEN}Your AI Stack is ready to start!${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "1. Start the AI Stack:    ${BLUE}./scripts/start.sh${NC}"
    echo "2. Wait for all services to start (2-3 minutes)"
    echo "3. Access your services:"
    echo "   • n8n Workflows:       http://localhost:5678"
    echo "   • Open WebUI:          http://localhost:8080"
    echo "   • LiteLLM Proxy:       http://localhost:4000"
    echo "   • MCP Orchestrator:    http://localhost:8000"
    echo ""
    echo -e "${BOLD}First Time Setup:${NC}"
    echo "• Create accounts in n8n and Open WebUI"
    echo "• n8n: First user becomes the owner"
    echo "• Open WebUI: First user becomes admin"
    echo ""
    echo -e "${BOLD}Important Commands:${NC}"
    echo "• Start all services:     ./scripts/start.sh"
    echo "• Stop all services:      ./scripts/stop.sh"
    echo "• Backup data:            ./scripts/backup.sh"
    echo "• View logs:              docker compose logs -f [service]"
    echo ""
    echo -e "${YELLOW}💾 Remember to backup your .env file securely!${NC}"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    setup_environment
    create_directories
    create_configs
    pull_images
    setup_models
    setup_scripts
    create_backup_script
    show_completion
}

# Run main function
main "$@"