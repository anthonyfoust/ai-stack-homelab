#!/bin/bash

# =================================================================
# AI Stack Start Script
# Simple startup with clear progress indicators for novice users
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

echo -e "${BLUE}${BOLD}🚀 Starting AI Stack...${NC}"
echo "========================"
echo ""

# Function to print step progress
print_step() {
    echo -e "${BLUE}$1${NC}"
}

# Function to show success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to show warning
print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Function to show error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to wait for service with timeout
wait_for_service() {
    local service=$1
    local check_command=$2
    local timeout=${3:-60}
    local count=0
    
    echo -n "  Waiting for $service to be ready"
    while [ $count -lt $timeout ]; do
        if eval "$check_command" > /dev/null 2>&1; then
            echo -e "\n${GREEN}  ✅ $service is ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        count=$((count + 2))
    done
    
    echo -e "\n${RED}  ❌ $service failed to start within ${timeout}s${NC}"
    return 1
}

# Check prerequisites
print_step "📋 Checking Prerequisites"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    echo ""
    echo "Please start Docker Desktop and try again"
    exit 1
fi
print_success "Docker is running"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found"
    echo ""
    echo "Please run ./scripts/setup.sh first"
    exit 1
fi
print_success ".env file found"

# Load environment variables
source .env

# Validate critical environment variables
print_step "🔍 Validating Configuration"
required_vars=("POSTGRES_PASSWORD" "REDIS_PASSWORD" "N8N_ENCRYPTION_KEY" "OPEN_WEBUI_SECRET_KEY")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == *"your_"* ]] || [[ "${!var}" == *"_here"* ]]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    print_error "Missing or invalid configuration variables:"
    printf '  %s\n' "${missing_vars[@]}"
    echo ""
    echo "Please update your .env file with secure values"
    exit 1
fi
print_success "Configuration validated"

echo ""

# Start services in dependency order
print_step "🚀 Starting Services"

# 1. Start PostgreSQL
print_step "  🐘 Starting PostgreSQL database..."
docker compose up -d postgres
wait_for_service "PostgreSQL" "docker exec postgres pg_isready -h localhost -U $POSTGRES_USER -d $POSTGRES_DB" 60

# Check for pgvector extension
if ! docker exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" 2>/dev/null | grep -q "1"; then
    print_warning "pgvector extension not found"
    echo "  💡 You can install it later with: ./scripts/install-pgvector.sh"
fi

# 2. Start Redis
print_step "  🔴 Starting Redis cache..."
docker compose up -d redis
wait_for_service "Redis" "docker exec redis redis-cli -a '$REDIS_PASSWORD' ping" 30

# 3. Start Ollama
print_step "  🤖 Starting Ollama AI server..."
docker compose up -d ollama
wait_for_service "Ollama" "curl -f http://localhost:${OLLAMA_PORT:-11434}/api/tags" 90

# Check for AI models
print_step "  🔍 Checking AI models..."
if ! docker exec ollama ollama list | grep -q "llama3.2"; then
    print_warning "No Llama 3.2 models found"
    echo "  📥 Downloading basic model (this may take 5-10 minutes)..."
    docker exec ollama ollama pull llama3.2:1b
    print_success "Basic model downloaded"
fi

# 4. Start n8n
print_step "  🔄 Starting n8n workflow engine..."
docker compose up -d n8n
wait_for_service "n8n" "curl -f http://localhost:${N8N_PORT:-5678}/healthz" 90

# 5. Start LiteLLM
print_step "  🎯 Starting LiteLLM proxy..."
docker compose up -d litellm
wait_for_service "LiteLLM" "curl -f http://localhost:${LITELLM_PORT:-4000}/health/liveliness" 60

# 6. Start Open WebUI
print_step "  🌐 Starting Open WebUI..."
docker compose up -d open-webui
wait_for_service "Open WebUI" "curl -f http://localhost:${OPEN_WEBUI_PORT:-8080}/health" 60

# 7. Start MCP servers
print_step "  🔗 Starting MCP servers..."
docker compose up -d n8n-mcp mcpo
sleep 15  # Give MCP servers time to initialize

# Final health check
print_step "🏥 Final Health Check"
sleep 5

services=("postgres" "redis" "ollama" "n8n" "litellm" "open-webui" "n8n-mcp" "mcpo")
failed_services=()

for service in "${services[@]}"; do
    if ! docker compose ps --services --filter "status=running" | grep -q "^$service$"; then
        failed_services+=("$service")
    fi
done

echo ""

if [ ${#failed_services[@]} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 AI Stack Started Successfully!${NC}"
    echo "=================================="
    echo ""
    echo -e "${BOLD}🌟 Your AI services are ready:${NC}"
    echo ""
    echo -e "${BLUE}📊 n8n Workflows:${NC}      http://localhost:${N8N_PORT:-5678}"
    echo -e "${BLUE}🤖 Open WebUI:${NC}         http://localhost:${OPEN_WEBUI_PORT:-8080}"
    echo -e "${BLUE}🎯 LiteLLM Proxy:${NC}      http://localhost:${LITELLM_PORT:-4000}"
    echo -e "${BLUE}🔗 MCP Orchestrator:${NC}   http://localhost:${MCPO_PORT:-8000}"
    echo ""
    echo -e "${BOLD}🏁 First Time Setup:${NC}"
    echo "• Create your account in n8n (first user becomes owner)"
    echo "• Create your account in Open WebUI (first user becomes admin)"
    echo "• Start chatting with AI models!"
    echo ""
    echo -e "${BOLD}💡 Useful Commands:${NC}"
    echo "• View all services:      docker compose ps"
    echo "• View service logs:      docker compose logs -f [service]"
    echo "• Stop all services:      ./scripts/stop.sh"
    echo "• Backup your data:       ./scripts/backup.sh"
    echo ""
    echo -e "${BOLD}🤖 Available AI Models:${NC}"
    echo "• llama3.2:1b (lightweight, fast)"
    echo "• llama3.2:3b (balanced performance)"
    echo "• nomic-embed-text (for embeddings)"
    echo ""
    echo -e "${GREEN}Enjoy your personal AI stack! 🚀${NC}"
    
else
    print_error "Some services failed to start:"
    printf '  %s\n' "${failed_services[@]}"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "• Check logs: docker compose logs [service_name]"
    echo "• Check system resources: docker stats"
    echo "• Restart failed services: docker compose restart [service_name]"
    echo "• Full restart: ./scripts/stop.sh && ./scripts/start.sh"
    echo ""
    exit 1
fi