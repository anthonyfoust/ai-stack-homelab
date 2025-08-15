# 🤖 AI Stack - Complete AI Automation Environment

A production-ready AI automation stack for Mac Mini M4, featuring n8n workflows, Ollama local AI models, Open WebUI chat interface, and advanced AI integrations through MCP (Model Context Protocol).

## 🎯 What You Get

**Complete AI Environment**: Local AI models, workflow automation, chat interface, and AI-powered integrations - all running privately on your Mac Mini M4.

**Zero Cloud Dependencies**: Everything runs locally - your data stays private and secure.

**Beginner-Friendly**: Simple setup scripts and clear documentation designed for users new to Docker and AI.

## 🏗️ System Architecture

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Open WebUI    │  │       n8n       │  │    LiteLLM      │
│ (Chat Interface)│  │ (Workflows)     │  │  (AI Proxy)     │
│   Port: 8080    │  │   Port: 5678    │  │   Port: 4000    │
└─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘
          │                    │                    │
          └──────────┬─────────┴──────┬─────────────┘
                     │                │
          ┌─────────────────┐  ┌─────────────────┐
          │     Ollama      │  │   PostgreSQL    │
          │ (Local AI)      │  │ (Database +     │
          │  Port: 11434    │  │  Vectors)       │
          └─────────────────┘  └─────────────────┘
                     │                │
          ┌─────────────────┐  ┌─────────────────┐
          │   MCP Servers   │  │      Redis      │
          │ (AI Protocol)   │  │    (Cache)      │
          └─────────────────┘  └─────────────────┘
```

## 🚀 Quick Start (Complete Beginner)

### Step 1: Install Docker Desktop
1. Download [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. Install and start Docker Desktop
3. In Docker Desktop settings, allocate at least 12GB RAM and 8 CPU cores

### Step 2: Download AI Stack
```bash
# Create project directory
mkdir -p ~/ai-stack
cd ~/ai-stack

# Download project files (copy all files from this repository)
```

### Step 3: Run Setup
```bash
# Make setup script executable and run it
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script will:
- ✅ Check your system is ready
- ✅ Help you create secure passwords
- ✅ Download all required software
- ✅ Download AI models (~4GB)
- ✅ Configure everything automatically

### Step 4: Start Your AI Stack
```bash
./scripts/start.sh
```

### Step 5: Start Using AI
- **Chat with AI**: Visit http://localhost:8080
- **Create Workflows**: Visit http://localhost:5678  
- **API Access**: Visit http://localhost:4000

## 🎮 What Can You Do?

### 💬 Chat with Local AI Models
- **Open WebUI** provides a ChatGPT-like interface
- Multiple AI models available (Llama 3.2 1B, 3B)
- Upload documents for AI analysis
- Generate images (configurable)
- Everything runs locally - complete privacy

### 🔄 Create AI Workflows
- **n8n** provides visual workflow automation
- Connect AI to your apps and services
- Automate repetitive tasks with AI
- Schedule AI-powered workflows
- No coding required - drag and drop interface

### 🔌 Advanced AI Integration
- **MCP Protocol** for advanced AI communication
- **LiteLLM** provides unified API for multiple AI services
- Connect external AI services when needed
- Custom AI tool integration

### 🛡️ Enterprise-Grade Security
- All data encrypted at rest
- Automatic backups
- No data leaves your device
- Industry-standard security practices

## 📋 Requirements

### Hardware (Mac Mini M4)
- **Minimum**: 16GB RAM, 256GB storage
- **Recommended**: 32GB+ RAM, 512GB+ storage
- **Network**: Broadband internet for initial setup

### Software
- **macOS**: 14.0+ (Sonoma or later)
- **Docker Desktop**: 4.25+ (automatically installed)

## 🎛️ Configuration Options

### Memory Settings (16GB Mac Mini)
```bash
# In .env file - optimized for 16GB RAM
POSTGRES_MEMORY_LIMIT=2G
N8N_MEMORY_LIMIT=4G
OLLAMA_MEMORY_LIMIT=8G
OLLAMA_MAX_MODELS=1
DEFAULT_MODELS=llama3.2:1b
```

### Memory Settings (32GB+ Mac Mini)
```bash
# In .env file - optimized for 32GB+ RAM
POSTGRES_MEMORY_LIMIT=4G
N8N_MEMORY_LIMIT=6G
OLLAMA_MEMORY_LIMIT=16G
OLLAMA_MAX_MODELS=2
DEFAULT_MODELS=llama3.2:3b,llama3.2:1b
```

### Security Settings
All passwords and keys are generated during setup:
- Database passwords
- API keys
- Encryption keys
- Backup encryption

## 🔧 Daily Operations

### Starting and Stopping
```bash
# Start everything
./scripts/start.sh

# Stop everything
./scripts/stop.sh

# Stop and remove all data (CAREFUL!)
./scripts/stop.sh --volumes
```

### Backup and Restore
```bash
# Backup all data
./scripts/backup.sh

# Backup specific service
./scripts/backup.sh --service postgres

# Restore from backup
./scripts/restore.sh

# List available backups
./scripts/restore.sh --list
```

### Monitoring
```bash
# View service status
docker compose ps

# View resource usage
docker stats

# View logs for specific service
docker compose logs -f [service_name]

# View all logs
docker compose logs -f
```

## 📊 Service Details

### 🤖 Ollama (AI Models)
- **What**: Local AI model server
- **Models**: Llama 3.2 (1B, 3B), Nomic Embed Text
- **Memory**: 8-16GB (configurable)
- **Access**: http://localhost:11434

### 🔄 n8n (Workflow Automation)
- **What**: Visual workflow automation platform
- **Database**: PostgreSQL with full persistence
- **Memory**: 3-6GB
- **Access**: http://localhost:5678

### 🌐 Open WebUI (Chat Interface)
- **What**: ChatGPT-like web interface
- **Features**: Document upload, RAG, image generation
- **Memory**: 1GB
- **Access**: http://localhost:8080

### 🎯 LiteLLM (AI Proxy)
- **What**: Unified API for multiple AI providers
- **Features**: Load balancing, rate limiting, cost tracking
- **Memory**: 1GB
- **Access**: http://localhost:4000

### 🐘 PostgreSQL (Database)
- **What**: Main database with AI extensions
- **Extensions**: pgvector (embeddings), AI functions
- **Memory**: 2-4GB
- **Databases**: Main, n8n, LiteLLM, Open WebUI

### 🔴 Redis (Cache)
- **What**: High-speed cache for AI operations
- **Memory**: 512MB
- **Persistence**: Automatic saves

### 🔗 MCP Servers (AI Protocol)
- **What**: Model Context Protocol for advanced AI communication
- **Features**: Secure AI-to-app communication
- **Memory**: 512MB total

## 🆘 Troubleshooting

### Services Won't Start
```bash
# Check Docker is running
docker info

# Check logs for errors
docker compose logs [service_name]

# Reset everything
./scripts/stop.sh --force
docker system prune -f
./scripts/start.sh
```

### Out of Memory
```bash
# Check current usage
docker stats

# Reduce memory in .env file:
OLLAMA_MAX_MODELS=1
DEFAULT_MODELS=llama3.2:1b

# Restart
./scripts/stop.sh && ./scripts/start.sh
```

### Database Issues
```bash
# Check PostgreSQL logs
docker compose logs postgres

# Reset database (LOSES DATA!)
docker volume rm ai-stack_postgres_data
./scripts/start.sh
```

### AI Models Not Working
```bash
# Download models manually
docker exec ollama ollama pull llama3.2:1b
docker exec ollama ollama pull llama3.2:3b

# Check available models
docker exec ollama ollama list
```

### Backup/Restore Problems
```bash
# Check backup directory
ls -la ~/Documents/ai-stack-backups/

# Test backup
./scripts/backup.sh --service postgres

# Verify backups
./scripts/restore.sh --list
```

## 🔒 Security & Privacy

### Data Protection
- **Local Processing**: All AI processing happens on your device
- **Encrypted Backups**: AES-256 encryption for all backups
- **Network Isolation**: Services isolated in secure Docker networks
- **No Telemetry**: No data collection or external communication

### Access Control
- **Authentication Required**: All services require login
- **Secure Passwords**: Strong password generation during setup
- **API Key Protection**: All APIs secured with keys
- **Admin Controls**: First user becomes admin

### Backup Security
- **Automatic Encryption**: All backups encrypted by default
- **Local Storage**: Backups stored locally on your device
- **Retention Policies**: Automatic cleanup of old backups
- **Easy Restore**: Simple restore process with verification

## 📈 Performance Guidelines

### For 16GB Mac Mini M4
- **Concurrent Users**: 1-2
- **Model Size**: Use 1B model for best performance
- **Workflows**: Light to medium complexity
- **Expected Response Time**: 2-5 seconds

### For 32GB+ Mac Mini M4
- **Concurrent Users**: 2-5
- **Model Size**: Use 3B model for better quality
- **Workflows**: Complex workflows supported
- **Expected Response Time**: 1-3 seconds

### Optimization Tips
- **Use smaller models** for faster responses
- **Close other applications** when using AI heavily
- **Regular backups** prevent data loss
- **Monitor disk space** - AI models need storage

## 🎓 Learning Resources

### Getting Started with n8n
1. Create your first workflow
2. Connect AI nodes to your workflow
3. Use webhooks for external integration
4. Schedule automated AI tasks

### Using Open WebUI Effectively
1. Chat with different models to find your preference
2. Upload documents for AI analysis
3. Use system prompts for consistent behavior
4. Organize conversations with folders

### API Integration
1. Use LiteLLM for unified AI API access
2. Integrate with external applications
3. Monitor usage and costs
4. Set up rate limiting for safety

## 📞 Support

### Self-Help
1. **Check logs**: `docker compose logs [service]`
2. **Review documentation**: Read this README
3. **Restart services**: `./scripts/stop.sh && ./scripts/start.sh`
4. **Check resources**: `docker stats`

### Common Commands
```bash
# Complete reset (nuclear option)
./scripts/stop.sh --volumes
docker system prune -a -f
./scripts/setup.sh

# Health check
docker compose ps
curl http://localhost:8080/health
curl http://localhost:5678/healthz

# Resource monitoring
docker stats --no-stream
df -h
```

## 🎉 Success!

Once everything is running, you have:

✅ **Private AI chat interface** - like ChatGPT but local  
✅ **Workflow automation** - automate tasks with AI  
✅ **Document analysis** - upload and analyze files with AI  
✅ **API access** - integrate AI into your applications  
✅ **Secure backups** - automatic data protection  
✅ **Zero cloud dependencies** - everything runs locally  

**Your personal AI environment is ready!** 

Start by visiting http://localhost:8080 to chat with your AI, or http://localhost:5678 to create your first automated workflow.

---

*This AI Stack is optimized for Mac Mini M4 and designed for users who want powerful AI capabilities without the complexity. Everything runs locally for maximum privacy and control.*