# 📁 AI Stack Project Structure

This document explains how the AI Stack project is organized and what each file and folder does. Perfect for understanding how everything fits together.

## 🏗️ Main Directory Structure

```
ai-stack/
├── docker-compose.yml              # Main Docker configuration - defines all services
├── .env                           # Your private settings (passwords, ports, etc.)
├── .env.example                   # Template for creating .env file
├── .gitignore                     # Files that Git should ignore
├── README.md                      # Main documentation (what you're reading)
├── ai-stack.code-workspace        # VS Code workspace configuration
│
├── scripts/                       # Management scripts for easy operation
│   ├── setup.sh                  # Initial setup script (run once)
│   ├── start.sh                  # Start all AI services
│   ├── stop.sh                   # Stop all AI services
│   ├── backup.sh                 # Backup all your data
│   ├── restore.sh                # Restore from backups
│   └── install-pgvector.sh       # Install vector database extension
│
├── configs/                       # Configuration files for each service
│   ├── postgres/                 # Database configuration
│   │   ├── init/                 # Database initialization scripts
│   │   │   └── 01-init-databases.sql
│   │   └── postgresql.conf       # PostgreSQL settings
│   ├── redis/                    # Cache configuration
│   │   └── redis.conf
│   ├── n8n/                      # Workflow automation settings
│   ├── ollama/                   # AI model server settings
│   ├── litellm/                  # AI proxy configuration
│   ├── mcp/                      # AI protocol settings
│   │   └── config.json
│   └── nginx/                    # Web server (if used)
│
├── data/                         # Persistent data (created automatically)
│   ├── postgres/                 # Database files
│   ├── n8n/                     # Workflow data
│   ├── ollama/                   # AI models storage
│   ├── open-webui/              # Chat interface data
│   ├── redis/                    # Cache data
│   ├── litellm/                  # AI proxy data
│   └── mcp/                      # Protocol data
│
├── logs/                         # Application logs (created automatically)
│   ├── postgres/                 # Database logs
│   ├── n8n/                     # Workflow logs
│   └── nginx/                    # Web server logs
│
├── backups/                      # Backup storage (created automatically)
│   ├── postgres/                 # Database backups
│   └── volumes/                  # Volume backups
│
└── docs/                         # Documentation
    ├── installation-guide.md     # Step-by-step setup guide
    ├── project-structure.md      # This file
    └── [other guides...]
```

## 📋 Key Files Explained

### Core Configuration Files

**`docker-compose.yml`** - The Heart of the System
- Defines all 8 services (Postgres, Redis, Ollama, n8n, etc.)
- Sets up networking between services
- Configures memory limits and resource allocation
- Maps ports for web access
- **Don't modify this file** - it's production-ready as-is

**`.env`** - Your Private Settings
- Contains all passwords, API keys, and configuration
- **Keep this file secure** - never share it
- Customize resource limits based on your Mac's RAM
- Contains backup settings and security keys

**`.env.example`** - Configuration Template
- Safe template for creating your `.env` file
- Shows what settings are available
- Includes helpful comments and examples

### Management Scripts

**`scripts/setup.sh`** - First-Time Setup
- Checks system requirements
- Helps create secure passwords
- Downloads Docker images and AI models
- Creates necessary directories
- **Run once** when setting up

**`scripts/start.sh`** - Daily Startup
- Starts all services in the correct order
- Waits for each service to be ready
- Checks for common issues
- Shows service URLs when ready
- **Run this when you want to use AI**

**`scripts/stop.sh`** - Safe Shutdown
- Gracefully stops all services
- Can force-stop if needed (`--force`)
- Can remove all data (`--volumes`) - be careful!
- Cleans up Docker resources

**`scripts/backup.sh`** - Data Protection
- Backs up databases and volumes
- Encrypts backups automatically
- Supports full, partial, or service-specific backups
- Manages backup retention (deletes old backups)
- **Run regularly** to protect your data

**`scripts/restore.sh`** - Data Recovery
- Restores from encrypted backups
- Can restore specific dates or services
- Includes dry-run mode for safety
- Lists available backups

### Configuration Directories

**`configs/postgres/`** - Database Settings
- `init/01-init-databases.sql`: Creates additional databases for each service
- `postgresql.conf`: Performance and security settings for PostgreSQL

**`configs/mcp/`** - AI Protocol Settings
- `config.json`: Configuration for Model Context Protocol servers
- Enables advanced AI-to-application communication

**`configs/redis/`** - Cache Settings
- `redis.conf`: Memory limits, persistence, and security settings

## 💾 Data Storage

### Persistent Data (`data/` folder)
This folder contains all your important data:
- **Postgres**: Your databases with AI conversations, workflows, and settings
- **Ollama**: Downloaded AI models (several GB)
- **n8n**: Your workflow definitions and execution history
- **Open WebUI**: Chat history and user accounts
- **Redis**: Cached data for performance

**Important**: This folder is excluded from Git for security and size reasons.

### Logs (`logs/` folder)
Application logs help troubleshoot issues:
- Check these when services aren't working properly
- Automatically rotated to prevent disk fill-up
- Can be safely deleted if disk space is needed

### Backups (`backups/` folder)
Local backup storage:
- Encrypted backups of all data
- Organized by date and service
- Automatically cleaned up based on retention settings

## 🔧 Service Architecture

### Service Dependencies
```
PostgreSQL (database)
├── Redis (cache) 
│   ├── n8n (workflows)
│   │   ├── n8n-mcp (AI protocol)
│   │   │   └── mcpo (protocol orchestrator)
│   │   └── LiteLLM (AI proxy)
│   └── Ollama (AI models)
│       └── Open WebUI (chat interface)
```

Services start in dependency order to ensure everything works properly.

### Network Architecture
Three separate Docker networks provide security:
- **Frontend Network**: Web-accessible services (Open WebUI, n8n)
- **AI Network**: AI services communication (Ollama, LiteLLM, MCP)
- **Backend Network**: Internal services only (PostgreSQL, Redis)

### Port Mapping
- **5678**: n8n workflow interface
- **8080**: Open WebUI chat interface  
- **4000**: LiteLLM AI proxy API
- **8000**: MCP orchestrator
- **11434**: Ollama AI model server
- **5432**: PostgreSQL (internal only)
- **6379**: Redis (internal only)

## 🔒 Security Design

### File Permissions
- `data/postgres/`: 700 (owner only) - database files are sensitive
- Other data folders: 755 (owner write, others read)
- Scripts: 755 (executable)

### Environment Security
- `.env` file contains sensitive information
- All backups are encrypted by default
- No external network access for backend services
- Security-first Docker configurations

### Backup Security
- AES-256 encryption for all backups
- Local storage only (no cloud uploads)
- Configurable retention policies
- Separate encryption key from main passwords

## 🎯 Customization Points

### Resource Allocation
Edit `.env` file to adjust:
```bash
# For 16GB Mac Mini
POSTGRES_MEMORY_LIMIT=2G
N8N_MEMORY_LIMIT=4G
OLLAMA_MEMORY_LIMIT=8G

# For 32GB Mac Mini  
POSTGRES_MEMORY_LIMIT=4G
N8N_MEMORY_LIMIT=6G
OLLAMA_MEMORY_LIMIT=16G
```

### AI Model Selection
Choose models based on your needs:
```bash
# Fast, lightweight
DEFAULT_MODELS=llama3.2:1b

# Balanced performance
DEFAULT_MODELS=llama3.2:3b

# Multiple models
DEFAULT_MODELS=llama3.2:1b,llama3.2:3b,nomic-embed-text
```

### Backup Configuration
Customize backup behavior:
```bash
BACKUP_RETENTION_DAYS=30    # How long to keep backups
BACKUP_ENCRYPT=true         # Enable encryption
BACKUP_SCHEDULE='0 2 * * *' # Daily at 2 AM (if using cron)
```

## 🚀 Development vs Production

This setup is designed for **production use** but can be adapted:

### Current Setup (Production)
- Single configuration file
- Production-grade security
- Automatic backups
- Resource-optimized
- Novice-friendly

### For Development
If you want a development setup:
1. Create `docker-compose.override.yml` for dev settings
2. Use development images (add `:dev` tags)
3. Enable debug logging
4. Reduce resource limits for faster startup

## 📈 Scaling Considerations

### Single User (Current)
- Optimized for 1-2 concurrent users
- Resource limits set for Mac Mini M4
- Local storage only

### Multiple Users
To support more users:
1. Increase memory limits in `.env`
2. Consider external PostgreSQL database
3. Add load balancing for web interfaces
4. Implement user quotas and rate limiting

### External Access
To access from other devices:
1. Change service bindings from `localhost` to `0.0.0.0`
2. Configure firewall rules
3. Add HTTPS with reverse proxy
4. Implement proper authentication

## 🛠️ Maintenance

### Regular Tasks
- **Daily**: Check service status (`docker compose ps`)
- **Weekly**: Run backup (`./scripts/backup.sh`)
- **Monthly**: Update AI models, clean up logs
- **Quarterly**: Update Docker images

### Monitoring
Key things to watch:
- Disk space usage (`df -h`)
- Memory usage (`docker stats`)
- Service health (`docker compose ps`)
- Log file sizes (`du -sh logs/`)

### Updates
1. **AI Models**: `docker exec ollama ollama pull llama3.2:3b`
2. **Docker Images**: `docker compose pull && docker compose up -d`
3. **Configuration**: Edit `.env` file and restart services

This structure provides a robust, secure, and maintainable AI environment that can grow with your needs while remaining simple enough for beginners to understand and use effectively.