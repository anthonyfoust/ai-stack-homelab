# 🖥️ AI Stack Installation Guide - Mac Mini M4

Complete step-by-step installation guide for setting up your AI Stack on Mac Mini M4.

## 📋 Pre-Installation Checklist

### Hardware Requirements
- ✅ Mac Mini M4 (2024)
- ✅ Minimum 16GB RAM (32GB+ recommended)
- ✅ 256GB+ SSD (500GB+ recommended)
- ✅ Active internet connection

### Software Requirements
- ✅ macOS 14.0+ (Sonoma or later)
- ✅ Docker Desktop for Mac 4.25+
- ✅ Terminal access
- ✅ Text editor (nano, vim, or VS Code)

## 🔧 Step 1: Install Docker Desktop

### Download and Install
1. Visit [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. Download the Apple Silicon version
3. Install Docker Desktop
4. Start Docker Desktop and complete setup
5. Verify installation:
```bash
docker --version
docker compose --version
```

### Configure Docker Resources
1. Open Docker Desktop
2. Go to Settings → Resources
3. Configure for Mac Mini M4:
   - **CPUs**: 8 (leave 2 for system)
   - **Memory**: 24GB (if you have 32GB) or 12GB (if you have 16GB)
   - **Swap**: 2GB
   - **Disk**: 100GB+

## 📁 Step 2: Create Project Directory

```bash
# Create the AI Stack directory
mkdir -p ~/ai-stack
cd ~/ai-stack

# Verify you're in the right location
pwd
# Should show: /Users/[username]/ai-stack
```

## 📥 Step 3: Download AI Stack Files

### Option A: Direct File Creation
Create each file manually using the configurations provided. Start with creating the directory structure:

```bash
# Create all required directories
mkdir -p {scripts,configs/{postgres/init,redis,n8n,ollama,litellm,mcp,nginx},data,logs,backups,docs}

# Create the main docker-compose.yml file
touch docker-compose.yml
```

### Option B: Using the Artifacts
Copy each configuration file from the artifacts provided in this conversation into the appropriate location.

## ⚙️ Step 4: Configure Environment Files

### Create .env from template
```bash
# Copy the template
cp .env.example .env

# Edit with your preferred editor
nano .env
```

### Required Changes in .env

**🔐 Security Settings (CHANGE THESE!):**
```bash
# Generate strong passwords
POSTGRES_PASSWORD=your_very_secure_postgres_password_here
REDIS_PASSWORD=your_very_secure_redis_password_here

# Generate 32-character keys
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here
WEBUI_SECRET_KEY=your_32_character_webui_secret_key_here
BACKUP_ENCRYPTION_KEY=your_32_character_backup_key_here

# Generate API keys
N8N_API_KEY=your_n8n_api_key_here
LITELLM_MASTER_KEY=your_litellm_master_key_here
N8N_MCP_AUTH_TOKEN=your_n8n_mcp_auth_token_here
MCPO_API_KEY=your_mcpo_api_key_here
```

**💡 Key Generation Helper:**
```bash
# Generate secure passwords and keys
openssl rand -base64 32    # For passwords
openssl rand -hex 16       # For 32-character keys
openssl rand -base64 24    # For API keys
```

**🖥️ Mac Mini M4 Optimized Settings:**

For 16GB RAM Mac Mini:
```bash
POSTGRES_MEMORY_LIMIT=2G
N8N_MEMORY_LIMIT=4G
OLLAMA_MEMORY_LIMIT=8G
OLLAMA_MAX_MODELS=1
DEFAULT_MODELS=llama3.2:1b
```

For 32GB+ RAM Mac Mini:
```bash
POSTGRES_MEMORY_LIMIT=4G
N8N_MEMORY_LIMIT=6G
OLLAMA_MEMORY_LIMIT=16G
OLLAMA_MAX_MODELS=2
DEFAULT_MODELS=llama3.2:3b,llama3.2:1b
```

## 🏗️ Step 5: Set Up Project Structure

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Create required configuration files
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

# PostgreSQL initialization
cat > configs/postgres/init/01-init-databases.sql << 'EOF'
-- Create additional databases
SELECT 'CREATE DATABASE n8n_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_prod')\gexec
SELECT 'CREATE DATABASE litellm_prod' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm_prod')\gexec
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
.env
.env.local
.env.production
data/
logs/
backups/
*.tmp
*.log
.DS_Store
EOF
```

## 🚀 Step 6: Initial Setup and Launch

### Run the Setup Script
```bash
# Run the automated setup
./scripts/setup.sh
```

This script will:
- ✅ Verify Docker is running
- ✅ Create required directories
- ✅ Set proper permissions
- ✅ Pull Docker images
- ✅ Download Llama 3.2 models
- ✅ Configure services

### Start the AI Stack
```bash
# Start all services
./scripts/start.sh
```

The startup process will:
1. 🐘 Start PostgreSQL and wait for readiness
2. 🔴 Start Redis cache
3. 🤖 Start Ollama and verify models
4. 🔄 Start n8n workflows
5. 🎯 Start LiteLLM proxy
6. 🌐 Start Open WebUI
7. 🔗 Start MCP servers

## 🌐 Step 7: First-Time Access

### Service URLs
Once all services are running, access them at:

- **n8n Workflows**: http://localhost:5678
- **Open WebUI**: http://localhost:8080
- **LiteLLM Proxy**: http://localhost:4000
- **MCP Orchestrator**: http://localhost:8000

### Initial Account Setup

**n8n (http://localhost:5678):**
1. Click "Get Started"
2. Create owner account with strong password
3. Complete setup wizard
4. Test connection to AI models

**Open WebUI (http://localhost:8080):**
1. Click "Sign up"
2. Create account (first user becomes admin)
3. Select llama3.2:3b model
4. Start your first chat

## 🔍 Step 8: Verification and Testing

### Health Check
```bash
# Check all services are running
docker compose ps

# Should show all services as "Up" and "healthy"
```

### Test AI Models
```bash
# List available models
curl http://localhost:11434/api/tags

# Test model inference
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Hello, how are you?",
    "stream": false
  }'
```

### Test Workflows
1. Go to n8n (http://localhost:5678)
2. Create a simple workflow:
   - Manual Trigger → AI Node → Set Response
3. Configure AI node to use Ollama
4. Test the workflow

## 📊 Step 9: Performance Monitoring

### Monitor Resource Usage
```bash
# Real-time resource monitoring
docker stats

# Check system resources
top -l 1 | grep -E "^CPU|^PhysMem"
```

### View Logs
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f ollama
docker compose logs -f n8n
```

## 💾 Step 10: Set Up Automated Backups

### Test Backup System
```bash
# Run a test backup
./scripts/backup.sh --type data

# Verify backup was created
ls -la ~/Documents/ai-stack-backups/
```

### Schedule Automated Backups (Optional)
```bash
# Add to crontab for daily 3 AM backups
crontab -e

# Add this line:
0 3 * * * cd ~/ai-stack && ./scripts/backup.sh >/dev/null 2>&1
```

## ✅ Installation Complete!

### Next Steps
1. 🎯 **Explore n8n**: Create your first automation workflows
2. 🤖 **Chat with AI**: Use Open WebUI for conversations
3. 🔧 **Customize**: Adjust settings in .env file as needed
4. 📚 **Learn**: Read the main README.md for usage examples

### Quick Reference Commands
```bash
# Start the stack
./scripts/start.sh

# Stop the stack
./scripts/stop.sh

# Backup data
./scripts/backup.sh

# View logs
docker compose logs -f [service_name]

# Check status
docker compose ps
```

## 🆘 Troubleshooting Installation

### Common Issues

**Docker not starting:**
```bash
# Check Docker Desktop is running
open -a Docker

# Restart Docker service
killall Docker && open -a Docker
```

**Permission errors:**
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix data directory permissions
sudo chown -R $(whoami) data/
```

**Out of disk space:**
```bash
# Clean up Docker
docker system prune -a -f

# Check disk usage
docker system df
df -h
```

**Services failing to start:**
```bash
# Check logs for specific service
docker compose logs [service_name]

# Restart specific service
docker compose restart [service_name]

# Full reset
./scripts/stop.sh --force
docker system prune -f
./scripts/start.sh
```

### Getting Help
1. 📋 Check service logs: `docker compose logs [service]`
2. 🔍 Verify configuration: Review .env file
3. 💻 Check system resources: `docker stats`
4. 🔄 Try restart: `./scripts/stop.sh && ./scripts/start.sh`

---

**🎉 Congratulations! Your AI Stack is now ready for use!**

*Your Mac Mini M4 is now running a complete AI automation environment with local models, workflow automation, and secure backup systems.*
