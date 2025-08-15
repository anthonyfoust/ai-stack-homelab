#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 pgvector Installation Script${NC}"
echo "=================================="

# Check if PostgreSQL is running
if ! docker compose ps postgres | grep -q "Up"; then
    echo -e "${RED}❌ PostgreSQL is not running. Please start it first with: ./scripts/start.sh${NC}"
    exit 1
fi

# Check if pgvector is already installed
echo -e "${BLUE}🔍 Checking if pgvector is already installed...${NC}"
if docker exec postgres psql -U aistack_prod -d aistack_production -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" 2>/dev/null | grep -q "1"; then
    echo -e "${GREEN}✅ pgvector extension is already installed and enabled${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️  pgvector extension not found. Installing...${NC}"

# Method 1: Try to install from PostgreSQL repositories
echo -e "${BLUE}📦 Attempting to install pgvector from PostgreSQL repositories...${NC}"
if docker exec postgres bash -c "apt-get update && apt-get install -y postgresql-17-pgvector" 2>/dev/null; then
    echo -e "${GREEN}✅ pgvector installed successfully from repositories${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install from repositories. Trying alternative method...${NC}"
    
    # Method 2: Install build dependencies and compile from source
    echo -e "${BLUE}🔨 Installing build dependencies and compiling pgvector from source...${NC}"
    docker exec postgres bash -c "
        apt-get update &&
        apt-get install -y build-essential git postgresql-server-dev-17 &&
        cd /tmp &&
        git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git &&
        cd pgvector &&
        make &&
        make install &&
        rm -rf /tmp/pgvector
    "
    echo -e "${GREEN}✅ pgvector compiled and installed from source${NC}"
fi

# Restart PostgreSQL to load the new extension
echo -e "${BLUE}🔄 Restarting PostgreSQL to load pgvector...${NC}"
docker compose restart postgres

# Wait for PostgreSQL to be ready
echo -e "${BLUE}⏳ Waiting for PostgreSQL to be ready...${NC}"
until docker exec postgres pg_isready -h localhost -U aistack_prod -d aistack_production > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}✅ PostgreSQL is ready${NC}"

# Create the extension
echo -e "${BLUE}🔧 Creating pgvector extension...${NC}"
docker exec postgres psql -U aistack_prod -d aistack_production -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Verify installation
echo -e "${BLUE}🔍 Verifying installation...${NC}"
if docker exec postgres psql -U aistack_prod -d aistack_production -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" | grep -q "1"; then
    echo -e "${GREEN}✅ pgvector extension installed and enabled successfully!${NC}"
    
    # Test vector operations
    echo -e "${BLUE}🧪 Testing vector operations...${NC}"
    if docker exec postgres psql -U aistack_prod -d aistack_production -c "SELECT '[1,2,3]'::vector;" 2>/dev/null | grep -q "vector"; then
        echo -e "${GREEN}✅ Vector operations working correctly!${NC}"
    else
        echo -e "${YELLOW}⚠️  Vector operations test failed${NC}"
    fi
else
    echo -e "${RED}❌ Failed to install pgvector extension${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 pgvector installation completed successfully!${NC}" 