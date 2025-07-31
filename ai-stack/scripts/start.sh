#!/bin/bash

# =================================================================
# AI Stack Start Script
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

echo -e "${BLUE}🚀 Starting AI Stack...${NC}"
echo "======================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Please run ./scripts/setup.sh first.${NC}"
    exit 1
fi

# Load environment variables
source .env

echo -e "${GREEN}✅ Environment loaded${NC}"

# Check for required environment variables
required_vars=("POSTGRES_PASSWORD" "REDIS_PASSWORD" "N8N_ENCRYPTION_KEY" "WEBUI_SECRET_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [ "${!var}" = "CHANGE_THIS_${var}" ] || [[ "${!var}" == *"your_"* ]]; then
        echo -e "${RED}❌ Required environment variable $var is not set or still has default value${NC}"
        echo "Please update your .env file with secure values."
        exit 1
    fi
done

echo -e "${GREEN}✅ Environment variables validated${NC}"

# Start services in dependency order
echo -e "${BLUE}🐘 Starting PostgreSQL...${NC}"
docker compose up -d postgres

echo -e "${BLUE}⏳ Waiting for PostgreSQL to be ready...${NC}"
until docker exec ai-postgres pg_isready -h localhost -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}✅ PostgreSQL is ready${NC}"

echo -e "${BLUE}🔴 Starting Redis...${NC}"
docker compose up -d redis

echo -e "${BLUE}⏳ Waiting for Redis to be ready...${NC}"
until docker exec ai-redis redis-cli ping > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}✅ Redis is ready${NC}"

echo -e "${BLUE}🤖 Starting Ollama...${NC}"
docker compose up -d ollama

echo -e "${BLUE}⏳ Waiting for Ollama to be ready...${NC}"
until curl -f http://localhost:${OLLAMA_PORT:-11434}/api/tags > /dev/null 2>&1; do
    echo -n "."
    sleep 3
done
echo -e "\n${GREEN}✅ Ollama is ready${NC}"

# Check if models are available
echo -e "${BLUE}🔍 Checking Ollama models...${NC}"
if ! docker exec ai-ollama ollama list | grep -q "llama3.2"; then
    echo -e "${YELLOW}⚠️  Llama 3.2 models not found. Downloading...${NC}"
    docker exec ai-ollama ollama pull llama3.2:1b
    docker exec ai-ollama ollama pull llama3.2:3b
    docker exec ai-ollama ollama pull nomic-embed-text
fi
echo -e "${GREEN}✅ Models are ready${NC}"

echo -e "${BLUE}🔄 Starting n8n...${NC}"
docker compose up -d n8n

echo -e "${BLUE}⏳ Waiting for n8n to be ready...${NC}"
until curl -f http://localhost:${N8N_PORT:-5678}/healthz > /dev/null 2>&1; do
    echo -n "."
    sleep 3
done
echo -e "\n${GREEN}✅ n8n is ready${NC}"

echo -e "${BLUE}🎯 Starting LiteLLM...${NC}"
docker compose up -d litellm

echo -e "${BLUE}⏳ Waiting for LiteLLM to be ready...${NC}"
until curl -f http://localhost:${LITELLM_PORT:-4000}/health/liveliness > /dev/null 2>&1; do
    echo -n "."
    sleep 3
done
echo -e "\n${GREEN}✅ LiteLLM is ready${NC}"

echo -e "${BLUE}🌐 Starting Open WebUI...${NC}"
docker compose up -d webui

echo -e "${BLUE}⏳ Waiting for WebUI to be ready...${NC}"
until curl -f http://localhost:${WEBUI_PORT:-8080}/health > /dev/null 2>&1; do
    echo -n "."
    sleep 3
done
echo -e "\n${GREEN}✅ WebUI is ready${NC}"

echo -e "${BLUE}🔗 Starting MCP servers...${NC}"
docker compose up -d n8n-mcp mcpo

echo -e "${BLUE}⏳ Waiting for MCP servers to be ready...${NC}"
sleep 10
echo -e "${GREEN}✅ MCP servers are ready${NC}"

# Final health check
echo -e "${BLUE}🏥 Running final health check...${NC}"
sleep 5

services=("postgres" "redis" "ollama" "n8n" "litellm" "webui" "n8n-mcp" "mcpo")
failed_services=()

for service in "${services[@]}"; do
    if ! docker compose ps --services --filter "status=running" | grep -q "$service"; then
        failed_services+=("$service")
    fi
done

if [ ${#failed_services[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All services are running successfully!${NC}"
    echo ""
    echo "🌟 Your AI Stack is ready!"
    echo "========================="
    echo -e "📊 n8n Workflows:    ${BLUE}http://localhost:${N8N_PORT:-5678}${NC}"
    echo -e "🤖 Open WebUI:       ${BLUE}http://localhost:${WEBUI_PORT:-8080}${NC}"
    echo -e "🎯 LiteLLM Proxy:    ${BLUE}http://localhost:${LITELLM_PORT:-4000}${NC}"
    echo -e "🔗 MCP Orchestrator: ${BLUE}http://localhost:${MCPO_PORT:-8000}${NC}"
    echo ""
    echo "💡 Tips:"
    echo "  - First time? Create accounts in n8n and WebUI"
    echo "  - Models available: llama3.2:1b, llama3.2:3b"
    echo "  - Check logs: docker compose logs -f [service_name]"
    echo "  - Stop all: ./scripts/stop.sh"
    echo ""
else
    echo -e "${RED}❌ Some services failed to start: ${failed_services[*]}${NC}"
    echo "Check logs with: docker compose logs [service_name]"
    exit 1
fi
