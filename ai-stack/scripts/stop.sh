#!/bin/bash

# =================================================================
# AI Stack Stop Script
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

echo -e "${BLUE}🛑 Stopping AI Stack...${NC}"
echo "======================"

# Parse command line arguments
FORCE_STOP=false
REMOVE_VOLUMES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_STOP=true
            shift
            ;;
        --volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --force, -f     Force stop containers (kill instead of graceful stop)"
            echo "  --volumes, -v   Remove volumes (WARNING: This will delete all data)"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}⚠️  WARNING: You are about to remove all volumes and data!${NC}"
    echo "This action cannot be undone."
    read -p "Are you sure? Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Stop services gracefully or forcefully
if [ "$FORCE_STOP" = true ]; then
    echo -e "${YELLOW}⚡ Force stopping all services...${NC}"
    docker compose kill
else
    echo -e "${BLUE}🔄 Gracefully stopping all services...${NC}"
    
    # Stop services in reverse dependency order
    echo -e "${BLUE}🔗 Stopping MCP services...${NC}"
    docker compose stop mcpo n8n-mcp
    
    echo -e "${BLUE}🌐 Stopping WebUI...${NC}"
    docker compose stop webui
    
    echo -e "${BLUE}🎯 Stopping LiteLLM...${NC}"
    docker compose stop litellm
    
    echo -e "${BLUE}🔄 Stopping n8n...${NC}"
    docker compose stop n8n
    
    echo -e "${BLUE}🤖 Stopping Ollama...${NC}"
    docker compose stop ollama
    
    echo -e "${BLUE}🔴 Stopping Redis...${NC}"
    docker compose stop redis
    
    echo -e "${BLUE}🐘 Stopping PostgreSQL...${NC}"
    docker compose stop postgres
fi

echo -e "${BLUE}🧹 Removing containers...${NC}"
docker compose down

if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}🗑️  Removing volumes...${NC}"
    docker compose down -v
    echo -e "${RED}💀 All data has been removed!${NC}"
fi

# Clean up unused resources
echo -e "${BLUE}🧽 Cleaning up unused Docker resources...${NC}"
docker system prune -f

# Show final status
echo ""
if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${GREEN}🏁 AI Stack stopped and all data removed${NC}"
    echo "To start fresh, run: ./scripts/setup.sh"
else
    echo -e "${GREEN}🏁 AI Stack stopped successfully${NC}"
    echo "Data is preserved. To restart, run: ./scripts/start.sh"
fi

echo ""
echo "Other useful commands:"
echo "  docker compose ps              # Check service status"
echo "  docker compose logs [service]  # View service logs"
echo "  docker system df               # Check Docker disk usage"
