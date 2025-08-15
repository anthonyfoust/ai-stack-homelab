#!/bin/bash

# =================================================================
# AI Stack Cleanup Script
# Removes unnecessary files and folders from the project
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

echo -e "${BLUE}${BOLD}🧹 AI Stack Cleanup${NC}"
echo "==================="
echo ""
echo "This script will remove unnecessary files and folders from your AI Stack project."
echo ""
echo -e "${YELLOW}What will be removed:${NC}"
echo "• 5 outdated documentation files"
echo "• 1 redundant environment file (.env.prod)"
echo "• All .DS_Store system files (safe to remove)"
echo "• 3 unused config directories"
echo "• 2 .gitkeep files"
echo "• 1 redundant data directory (data/open-webui)"
echo "• 1 outdated PostgreSQL script"
echo "• Empty directories"
echo "• VS Code workspace file (optional)"
echo ""

# Ask for confirmation
read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Starting cleanup...${NC}"
echo ""

# Function to safely remove file/directory
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [ -e "$path" ]; then
        echo -e "${YELLOW}Removing: $description${NC}"
        rm -rf "$path"
        echo -e "${GREEN}✅ Removed: $path${NC}"
    else
        echo -e "${BLUE}ℹ️  Not found (already clean): $path${NC}"
    fi
}

# 1. Remove outdated documentation files
echo -e "${BLUE}📚 Cleaning up outdated documentation...${NC}"
safe_remove "docs/postgresql-17.5-migration-guide.md" "PostgreSQL 17.5 migration guide"
safe_remove "docs/postgresql-migration-guide.md" "PostgreSQL migration guide"
safe_remove "docs/script-updates-summary.md" "Script updates summary"
safe_remove "docs/service-name-change-summary.md" "Service name change summary"
safe_remove "docs/vector-database-guide.md" "Vector database guide"

# 2. Remove redundant environment file
echo -e "${BLUE}⚙️ Cleaning up environment files...${NC}"
safe_remove ".env.prod" "Redundant production environment file"

# 3. Remove system files
echo -e "${BLUE}🖥️ Cleaning up system files...${NC}"
echo -e "${YELLOW}Removing .DS_Store files...${NC}"
find . -name ".DS_Store" -type f -delete 2>/dev/null || true
echo -e "${GREEN}✅ Removed all .DS_Store files${NC}"

# 4. Remove empty/unused config directories
echo -e "${BLUE}📁 Cleaning up unused config directories...${NC}"
safe_remove "configs/litellm" "Unused LiteLLM config directory"
safe_remove "configs/nginx" "Unused Nginx config directory"
safe_remove "logs/nginx" "Unused Nginx logs directory"

# 5. Remove .gitkeep files
echo -e "${BLUE}🔗 Cleaning up .gitkeep files...${NC}"
safe_remove "configs/n8n/.gitkeep" "n8n .gitkeep file"
safe_remove "configs/ollama/.gitkeep" "Ollama .gitkeep file"

# 6. Remove redundant data directory
echo -e "${BLUE}💾 Cleaning up redundant data directories...${NC}"
safe_remove "data/open-webui" "Redundant open-webui data directory"

# 7. Remove outdated PostgreSQL extension file
echo -e "${BLUE}🐘 Cleaning up outdated PostgreSQL files...${NC}"
safe_remove "configs/postgres/init/00-install-extensions.sql" "Outdated PostgreSQL extension script"

# 8. Optional: Remove VS Code workspace file
echo ""
read -p "Remove VS Code workspace file? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    safe_remove "ai-stack.code-workspace" "VS Code workspace file"
fi

# Clean up empty directories
echo -e "${BLUE}🗂️ Cleaning up empty directories...${NC}"
find . -type d -empty -not -path "./.git/*" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Removed empty directories${NC}"

echo ""
echo -e "${GREEN}${BOLD}🎉 Cleanup completed successfully!${NC}"
echo ""
echo -e "${BOLD}Summary of what was removed:${NC}"
echo "• 5 outdated documentation files"
echo "• 1 redundant environment file"
echo "• All .DS_Store system files"
echo "• 3 unused config directories"
echo "• 2 .gitkeep files"
echo "• 1 redundant data directory"
echo "• 1 outdated PostgreSQL script"
echo "• Empty directories"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "• VS Code workspace file"
fi
echo ""
echo -e "${BLUE}💡 Benefits achieved:${NC}"
echo "• Cleaner project structure"
echo "• Reduced confusion for users"
echo "• Smaller download/clone size"
echo "• Only relevant files remain"
echo "• Production-ready appearance"
echo ""
echo -e "${GREEN}Your AI Stack is now optimized and clean! 🚀${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "• Review the remaining project structure"
echo "• Test that all scripts still work correctly"
echo "• Update any personal documentation if needed"