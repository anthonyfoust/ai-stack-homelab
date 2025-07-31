# 🤖 AI Stack - Personal Production Environment

A comprehensive AI automation stack optimized for Mac Mini M4, featuring n8n workflow automation, Ollama for local AI models, Open WebUI for chat interfaces, and MCP (Model Context Protocol) integration.

## 🏗️ Architecture Overview

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Open WebUI    │  │       n8n       │  │    LiteLLM      │
│   Port: 8080    │  │   Port: 5678    │  │   Port: 4000    │
└─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘
          │                    │                    │
          └──────────┬─────────┴──────┬─────────────┘
                     │                │
          ┌─────────────────┐  ┌─────────────────┐
          │     Ollama      │  │   PostgreSQL    │
          │  Port: 11434    │  │   Port: 5432    │
          └─────────────────┘  └─────────────────┘
                     │                │
          ┌─────────────────┐  ┌─────────────────┐
          │   MCP Servers   │  │      Redis      │
          │   Port: 3000    │  │   Port: 6379    │
          └─────────────────┘  └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Mac Mini M4 with macOS 14+ (Sonoma)
- Docker Desktop 4.25+ installed and running
- At least 16GB RAM (32GB recommended)
- 100GB+ free disk space

### 1. Download and Setup

```bash
# Clone or download the AI Stack files
# Extract to your desired location, e.g.:
mkdir -p ~/ai-stack
cd ~/ai-stack

# Make scripts executable
chmod +x scripts/*.sh

# Run initial setup
./scripts/setup.sh
```

### 2. Configure Environment

```bash
# Edit the .env file with your secure passwords and keys
nano .env

# Required changes:
# - All passwords (POSTGRES_PASSWORD, REDIS_PASSWORD, etc.)
# - All encryption keys (N8N_ENCRYPTION_KEY, WEBUI_SECRET_KEY, etc.)
# - All API keys and tokens
```

### 3. Start the Stack

```bash
# Start all services
./scripts/start.sh

# Access your services:
# - n8n Workflows: http://localhost:5678
# - Open WebUI: http://localhost:8080
# - LiteLLM Proxy: http://localhost:4000
```

## 📋 Services Overview

### 🔄 n8n Workflow Automation
- **Port**: 5678
- **Purpose**: Visual workflow automation and integration platform
- **Features**: Database persistence, AI integration, webhook support
- **Default Login**: Create account on first visit

### 🤖 Ollama AI Model Server
- **Port**: 11434
- **Purpose**: Local AI model hosting (Llama 3.2)
- **Models**: llama3.2:1b, llama3.2:3b, nomic-embed-text
- **Memory**: Optimized for Mac Mini M4 (up to 16GB allocation)

### 🌐 Open WebUI
- **Port**: 8080
- **Purpose**: ChatGPT-like interface for local AI models
- **Features**: RAG support, document upload, family-safe mode
- **Default Login**: Create account on first visit

### 🎯 LiteLLM Proxy
- **Port**: 4000
- **Purpose**: Unified API interface for multiple AI providers
- **Features**: Load balancing, rate limiting, cost tracking
- **Authentication**: Master key required

### 🐘 PostgreSQL Database
- **Port**: 5432 (internal)
- **Purpose**: Persistent storage for n8n, LiteLLM
- **Databases**: aistack_production, n8n_prod, litellm_prod
- **Backup**: Automated daily backups

### 🔴 Redis Cache
- **Port**: 6379 (internal)
- **Purpose**: Caching and session storage
- **Features**: Persistence, password protection

### 🔗 MCP Servers
- **n8n-mcp Port**: 3000
- **MCPO Port**: 8000
- **Purpose**: Model Context Protocol integration
- **Features**: Secure communication between AI and automation

## 🛠️ Management Scripts

### Start/Stop Operations
```bash
# Start all services
./scripts/start.sh

# Stop all services gracefully
./scripts/stop.sh

# Force stop (immediate)
./scripts/stop.sh --force

# Stop and remove all data (DANGEROUS!)
./scripts/stop.sh --volumes
```

### Backup Operations
```bash
# Full backup (recommended)
./scripts/backup.sh

# Backup specific service
./scripts/backup.sh --service postgres

# Data-only backup
./scripts/backup.sh --type data

# List available backups
./scripts/restore.sh --list
```

### Restore Operations
```bash
# Restore from latest backup
./scripts/restore.sh

# Restore from specific date
./scripts/restore.sh --date 20240101_120000

# Dry run (see what would be restored)
./scripts/restore.sh --dry-run

# Restore specific service
./scripts/restore.sh --service postgres
```

## 📊 Resource Configuration

### Mac Mini M4 Optimized Settings

| Service | Memory Limit | CPU Limit | Purpose |
|---------|-------------|-----------|---------|
| PostgreSQL | 4G | 3.0 | Database operations |
| n8n | 6G | 4.0 | Workflow processing |
| Ollama | 16G | 8.0 | AI model inference |
| Open WebUI | 2G | 2.0 | Web interface |
| LiteLLM | 2G | 2.0 | API proxy |
| Redis | 1G | 1.0 | Caching |
| MCP Servers | 1G | 1.0 | Protocol handling |

**Total Resources**: ~32GB RAM, 21 CPU cores (recommended: 64GB RAM, Mac Mini M4 Pro)

## 🔐 Security Features

### Data Protection
- **Encryption**: All backups encrypted with AES-256
- **Network Segmentation**: Isolated internal networks
- **Read-Only Containers**: Where possible
- **No Privileged Containers**: Security-first approach

### Authentication
- **PostgreSQL**: SCRAM-SHA-256 authentication
- **Redis**: Password protection
- **n8n**: User management enabled
- **WebUI**: Authentication required
- **LiteLLM**: API key protection

### Backup Security
- **Encrypted Backups**: AES-256 encryption
- **Retention Policies**: Configurable retention
- **Secure Storage**: Local encrypted storage

## 📁 Directory Structure

```
ai-stack/
├── docker-compose.yml              # Main compose configuration
├── .env                           # Environment variables (create from .env.example)
├── .env.example                   # Environment template
├── .env.prod                      # Production template
├── .gitignore                     # Git ignore rules
├── README.md                      # This file
│
├── scripts/                       # Management scripts
│   ├── setup.sh                  # Initial setup
│   ├── start.sh                  # Start services
│   ├── stop.sh                   # Stop services
│   ├── backup.sh                 # Backup utility
│   └── restore.sh                # Restore utility
│
├── configs/                       # Configuration files
│   ├── postgres/                 # PostgreSQL configs
│   │   ├── init/                 # Initialization scripts
│   │   └── postgresql.conf       # PostgreSQL settings
│   ├── redis/                    # Redis configuration
│   ├── mcp/                      # MCP server configs
│   │   └── config.json           # MCP configuration
│   └── [other services]/
│
├── data/                         # Persistent data (auto-created)
│   ├── postgres/                 # Database files
│   ├── n8n/                     # n8n data
│   ├── ollama/                   # AI models
│   └── [other services]/
│
├── logs/                         # Application logs (auto-created)
├── backups/                      # Backup storage (auto-created)
└── docs/                         # Additional documentation
```

## 🎛️ Configuration Options

### Environment Variables

Key variables to configure in `.env`:

```bash
# Database
POSTGRES_PASSWORD=your_secure_password
POSTGRES_USER=aistack_prod
POSTGRES_DB=aistack_production

# AI Services  
OLLAMA_MAX_MODELS=2              # Number of models to keep loaded
DEFAULT_MODELS=llama3.2:3b       # Default model for WebUI

# Security
N8N_ENCRYPTION_KEY=your_32_char_key
WEBUI_SECRET_KEY=your_secret_key
BACKUP_ENCRYPTION_KEY=your_backup_key

# Features
ENABLE_SIGNUP=false              # Disable public signup
SAFE_MODE=true                   # Enable family-safe mode
BACKUP_ENABLED=true              # Enable automated backups
```

## 🔧 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker is running
docker info

# Check logs
docker compose logs [service_name]

# Reset and rebuild
./scripts/stop.sh --force
docker system prune -f
./scripts/start.sh
```

#### Out of Memory Errors
```bash
# Check resource usage
docker stats

# Reduce model size in .env
OLLAMA_MAX_MODELS=1
DEFAULT_MODELS=llama3.2:1b

# Restart with new settings
./scripts/stop.sh && ./scripts/start.sh
```

#### Database Connection Issues
```bash
# Check PostgreSQL logs
docker compose logs postgres

# Reset database
docker volume rm ai-stack_postgres_data
./scripts/start.sh
```

#### Backup/Restore Issues
```bash
# Check backup directory permissions
ls -la ~/Documents/ai-stack-backups/

# Test encryption key
echo "test" | openssl enc -aes-256-cbc -pass pass:"your_key" | openssl enc -aes-256-cbc -d -pass pass:"your_key"
```

### Performance Optimization

#### For 16GB RAM Systems
```bash
# Edit .env for lower resource usage
POSTGRES_MEMORY_LIMIT=2G
N8N_MEMORY_LIMIT=4G
OLLAMA_MEMORY_LIMIT=8G
OLLAMA_MAX_MODELS=1
DEFAULT_MODELS=llama3.2:1b
```

#### For 32GB+ RAM Systems
```bash
# Edit .env for better performance
OLLAMA_MEMORY_LIMIT=20G
OLLAMA_MAX_MODELS=3
DEFAULT_MODELS=llama3.2:3b,llama3.2:1b
```

## 📚 Usage Examples

### Setting Up Your First Workflow in n8n
1. Visit http://localhost:5678
2. Create your account
3. Create a new workflow
4. Add nodes: Webhook → AI Node → Response
5. Configure AI node to use http://ollama:11434

### Using Open WebUI
1. Visit http://localhost:8080
2. Create your account
3. Select llama3.2:3b model
4. Start chatting with your local AI

### Integrating with LiteLLM
```bash
# Test API endpoint
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your_litellm_master_key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama/llama3.2:3b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## 🔄 Maintenance

### Regular Tasks
- **Daily**: Automated backups (configured)
- **Weekly**: Check logs and clean up: `docker system prune`
- **Monthly**: Update models: `docker exec ai-ollama ollama pull llama3.2:latest`
- **Quarterly**: Update images: `docker compose pull && docker compose up -d`

### Health Monitoring
```bash
# Check all services
docker compose ps

# Check resource usage
docker stats

# Check disk usage
docker system df

# View logs
docker compose logs -f [service_name]
```

## 🚨 Important Notes

### Family Safety
- Safe mode is enabled by default in production config
- Image generation disabled by default
- Signup disabled to prevent unauthorized access
- All services password protected

### Data Persistence
- All important data persists across restarts
- Regular automated backups
- Easy restore procedures
- Encrypted backup storage

### Resource Management
- Optimized for Mac Mini M4 hardware
- Configurable resource limits
- Efficient model loading
- Smart caching strategies

## 📞 Support

### Getting Help
1. Check the logs: `docker compose logs [service]`
2. Review this README and troubleshooting section
3. Check Docker Desktop resource allocation
4. Verify .env file configuration

### Useful Commands
```bash
# Complete reset (nuclear option)
./scripts/stop.sh --volumes
docker system prune -a -f
./scripts/setup.sh

# Check service health
docker compose exec postgres pg_isready
docker compose exec redis redis-cli ping
curl -f http://localhost:11434/api/tags

# View real-time logs
docker compose logs -f --tail=100
```

---

**🎉 Enjoy your personal AI automation stack!**

*This configuration is optimized for personal/family use on Mac Mini M4. For production deployment or different hardware, adjust resource limits accordingly.*
