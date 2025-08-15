# 🖥️ AI Stack Installation Guide - Complete Beginner's Guide

**Welcome!** This guide will help you set up your own private AI environment on your Mac Mini M4. No prior experience with Docker or AI required - we'll walk you through everything step by step.

## 📋 What You'll Have When Done

- 🤖 **Your own ChatGPT-like interface** that runs completely on your computer
- 🔄 **Workflow automation** to connect AI to your apps and automate tasks
- 💾 **Complete privacy** - nothing leaves your device
- 🛡️ **Enterprise-grade security** with automatic backups
- 🚀 **Professional AI tools** used by developers and businesses

## 🧭 Before We Start

### What You Need
- Mac Mini M4 (2024) with macOS 14.0 or later
- At least 16GB RAM (32GB is better)
- At least 256GB free storage (500GB+ recommended)
- Stable internet connection for initial setup
- About 1-2 hours for complete setup

### What We'll Do
1. Install Docker (the software that runs everything)
2. Download the AI Stack files
3. Configure your secure passwords
4. Download AI models
5. Start your AI environment
6. Create your first AI chat!

---

## 🔧 Step 1: Install Docker Desktop

Docker is like a special container that keeps all your AI software organized and secure.

### Download Docker
1. Go to [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Click **"Download for Mac"**
3. Choose **"Mac with Apple Chip"** (for M4)
4. Wait for download (about 500MB)

### Install Docker
1. Open the downloaded file
2. Drag Docker to your Applications folder
3. Open Docker from Applications
4. When prompted, enter your Mac password
5. Follow the setup wizard (keep default settings)
6. Wait for Docker to start (you'll see a whale icon in your menu bar)

### Configure Docker for AI
1. Click the Docker whale icon in your menu bar
2. Select **"Settings"**
3. Go to **"Resources"**
4. Set these values:
   - **CPUs**: 8 (if you have 16GB RAM) or 6 (if you have less)
   - **Memory**: 12GB (if you have 16GB RAM) or 24GB (if you have 32GB+)
   - **Swap**: 2GB
   - **Disk**: 100GB
5. Click **"Apply & Restart"**

**✅ Test**: Open Terminal and type `docker --version`. You should see version information.

---

## 📁 Step 2: Set Up Your AI Stack

### Create Your Project Folder
1. Open **Terminal** (found in Applications > Utilities)
2. Copy and paste this command, then press Enter:
```bash
mkdir -p ~/ai-stack && cd ~/ai-stack
```
3. You should see your prompt change to show you're in the ai-stack folder

### Download AI Stack Files
You'll need to copy the AI Stack files to your new folder. The main files you need are:
- `docker-compose.yml` (the main configuration)
- `.env.example` (password template)
- `scripts/` folder (management tools)
- `configs/` folder (settings)

**Option 1: Download from GitHub** (if this is a GitHub project)
```bash
# Replace with actual repository URL
git clone [repository-url] .
```

**Option 2: Manual Copy**
Copy all the files provided in this conversation to your `~/ai-stack` folder.

---

## 🔐 Step 3: Set Up Your Security

### Create Your Environment File
In Terminal, in your ai-stack folder:
```bash
cp .env.example .env
```

### Generate Secure Passwords
You need several secure passwords. Run these commands one at a time and save the results:

```bash
# For database password
echo "POSTGRES_PASSWORD: $(openssl rand -base64 32)"

# For cache password  
echo "REDIS_PASSWORD: $(openssl rand -base64 32)"

# For workflow encryption (32 characters exactly)
echo "N8N_ENCRYPTION_KEY: $(openssl rand -hex 16)"

# For web interface security (32 characters exactly)
echo "OPEN_WEBUI_SECRET_KEY: $(openssl rand -hex 16)"

# For backup encryption
echo "BACKUP_ENCRYPTION_KEY: $(openssl rand -hex 16)"

# For API keys
echo "N8N_API_KEY: $(openssl rand -base64 24)"
echo "LITELLM_MASTER_KEY: $(openssl rand -base64 24)"
echo "N8N_MCP_AUTH_TOKEN: $(openssl rand -base64 24)"
echo "MCPO_API_KEY: $(openssl rand -base64 24)"
```

**Important**: Save these passwords somewhere safe! You'll need them if you ever need to restore from backup.

### Update Your .env File
1. Open the .env file in a text editor:
```bash
open -e .env
```

2. Replace each password/key with the ones you generated above:
   - Find `POSTGRES_PASSWORD='your_secure_postgres_password_here'`
   - Replace with `POSTGRES_PASSWORD='[your generated password]'`
   - Repeat for all the other passwords and keys

3. Save the file and close the editor

---

## 🚀 Step 4: Run the Setup

### Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### Run the Setup Script
```bash
./scripts/setup.sh
```

The setup script will:
- ✅ Check that Docker is working
- ✅ Verify your passwords are set
- ✅ Create all necessary folders
- ✅ Download AI software (this takes 5-10 minutes)
- ✅ Download AI models (this takes 10-20 minutes)

**Be Patient**: The AI model download is large (about 4GB). Go get a coffee! ☕

---

## 🎬 Step 5: Start Your AI Stack

### Start Everything
```bash
./scripts/start.sh
```

You'll see services starting one by one:
1. 🐘 PostgreSQL (database)
2. 🔴 Redis (cache)
3. 🤖 Ollama (AI models)
4. 🔄 n8n (workflows)
5. 🎯 LiteLLM (AI proxy)
6. 🌐 Open WebUI (chat interface)
7. 🔗 MCP servers (AI protocol)

**Total time**: 2-3 minutes for everything to start

### Success! 🎉
When you see:
```
🎉 AI Stack Started Successfully!
================================

🌟 Your AI services are ready:

📊 n8n Workflows:      http://localhost:5678
🤖 Open WebUI:         http://localhost:8080
🎯 LiteLLM Proxy:      http://localhost:4000
🔗 MCP Orchestrator:   http://localhost:8000
```

Your AI environment is ready!

---

## 💬 Step 6: Your First AI Chat

### Open Your AI Chat Interface
1. Open your web browser
2. Go to: **http://localhost:8080**
3. You'll see a sign-up page

### Create Your Account
1. Click **"Sign up"**
2. Enter your name and email
3. Create a strong password
4. Click **"Create Account"**

**Note**: The first person to sign up becomes the admin!

### Start Chatting
1. You'll see a ChatGPT-like interface
2. Select a model (try **"llama3.2:3b"** for best quality)
3. Type your first message: *"Hello! Can you tell me about yourself?"*
4. Press Enter and watch your local AI respond!

### Try These Commands
- *"What can you help me with?"*
- *"Write a short poem about Mac computers"*
- *"Explain quantum computing in simple terms"*
- *"Create a to-do list for setting up a home office"*

---

## 🔄 Step 7: Create Your First Workflow

### Open n8n Workflow Builder
1. Go to: **http://localhost:5678**
2. Create your account (first user becomes owner)
3. You'll see a visual workflow builder

### Create a Simple AI Workflow
1. Click **"+ Add first step"**
2. Search for **"Manual Trigger"** and select it
3. Click the **"+"** to add another node
4. Search for **"OpenAI"** or **"HTTP Request"** 
5. Configure it to connect to your local AI at `http://ollama:11434`
6. Add a final node to save or send the result
7. Click **"Test workflow"** to try it!

---

## 🛠️ Daily Usage

### Starting and Stopping
```bash
# Start everything (run this when you want to use AI)
./scripts/start.sh

# Stop everything (run this when done for the day)
./scripts/stop.sh

# Check what's running
docker compose ps
```

### Backing Up Your Data
```bash
# Backup everything (run this weekly)
./scripts/backup.sh

# Backups are stored in ~/Documents/ai-stack-backups/
```

### Viewing Logs (if something goes wrong)
```bash
# See all service status
docker compose ps

# View logs for specific service
docker compose logs open-webui
docker compose logs n8n
docker compose logs ollama
```

---

## 🆘 Troubleshooting

### "Docker is not running"
1. Check if Docker Desktop is open (whale icon in menu bar)
2. If not open, start Docker Desktop from Applications
3. Wait for it to fully start before trying again

### "Services won't start" or "Out of memory"
1. Close other applications to free up RAM
2. In Docker Desktop settings, reduce memory allocation
3. Edit your `.env` file to use smaller models:
   ```bash
   OLLAMA_MAX_MODELS=1
   DEFAULT_MODELS=llama3.2:1b
   ```
4. Restart: `./scripts/stop.sh && ./scripts/start.sh`

### "AI models are slow"
- Use **llama3.2:1b** instead of 3b for faster responses
- Close other applications
- Make sure your Mac isn't running on battery power

### "Can't access web interfaces"
1. Make sure services are running: `docker compose ps`
2. Try restarting your browser
3. Check if something else is using those ports

### "Lost my passwords"
If you lose your `.env` file:
1. Stop everything: `./scripts/stop.sh --volumes` (⚠️ This deletes data!)
2. Regenerate passwords and run setup again
3. Or restore from backup: `./scripts/restore.sh --list`

---

## 📈 Performance Tips

### For 16GB Mac Mini
- Use **llama3.2:1b** model (faster)
- Set `OLLAMA_MAX_MODELS=1` in .env
- Close other apps when using AI heavily
- Consider upgrading to 32GB RAM for better performance

### For 32GB+ Mac Mini
- Use **llama3.2:3b** model (better quality)
- Can run multiple models simultaneously
- Can handle more complex workflows
- Better for multiple users

---

## 🎓 What's Next?

### Learn n8n Workflows
- Connect AI to your email, calendar, or other apps
- Automate repetitive tasks with AI
- Schedule AI to run reports or summaries
- Create custom AI assistants for specific tasks

### Explore Open WebUI Features
- Upload documents for AI to analyze
- Create custom AI personas with system prompts
- Organize conversations into folders
- Try different AI models for different tasks

### API Integration
- Use the LiteLLM proxy to connect other applications
- Build custom tools that use your local AI
- Create AI-powered scripts and automations

---

## 🔒 Security Notes

### Your Data is Private
- Everything runs on your Mac - nothing goes to the cloud
- Your conversations and files stay completely private
- No data collection or telemetry

### Keep Backups
- Run backups regularly: `./scripts/backup.sh`
- Store your `.env` file safely (contains your passwords)
- Backups are automatically encrypted

### Updates
- Periodically update your AI models: `docker exec ollama ollama pull llama3.2:3b`
- Update Docker images: `docker compose pull && docker compose up -d`

---

## 🎉 Congratulations!

You now have:
- ✅ Your own private ChatGPT running locally
- ✅ Workflow automation tools
- ✅ Complete data privacy and security
- ✅ Professional-grade AI infrastructure
- ✅ Automatic backups and monitoring

**You're now running the same kind of AI infrastructure that companies pay thousands of dollars per month for - except it's all yours, private, and free to use!**

---

## 📞 Need Help?

### Check These First
1. **Service Status**: `docker compose ps`
2. **Resource Usage**: `docker stats`
3. **Recent Logs**: `docker compose logs --tail=50`
4. **Disk Space**: `df -h`

### Common Commands Cheat Sheet
```bash
# Essential commands
./scripts/start.sh              # Start AI stack
./scripts/stop.sh               # Stop AI stack
./scripts/backup.sh             # Backup data
docker compose ps               # Check status
docker compose logs [service]   # View logs

# Troubleshooting
./scripts/stop.sh --force       # Force stop everything
docker system prune -f          # Clean up Docker
./scripts/setup.sh              # Re-run setup

# Updates
docker compose pull             # Download updates
docker exec ollama ollama pull llama3.2:3b  # Update AI model
```

### When to Ask for Help
- If services consistently fail to start
- If you're getting persistent errors
- If performance is unusably slow
- If you need help with specific workflows

**Remember**: This is a sophisticated system, and it's normal to have questions as you learn. The most important thing is that you now have a powerful, private AI environment that belongs completely to you!

Enjoy exploring the possibilities! 🚀