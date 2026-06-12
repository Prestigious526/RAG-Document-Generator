# Quick Start Guide - Offline RAG Document Generator

Welcome! This guide will help you get the Offline RAG Document Generator running on your machine.

## Prerequisites

You need to have these installed before starting:

1. **Miniconda or Anaconda**
   - Download from: https://docs.conda.io/projects/miniconda/en/latest/
   - During installation, check "Add Miniconda to PATH"

2. **Ollama** (for local LLM support)
   - Download from: https://ollama.com/download
   - After installation, Ollama will run in the background

3. **PostgreSQL** (for document storage)
   - Download from: https://www.postgresql.org/download/
   - Default user/password is fine

4. **Docker & Docker Compose** (optional, for Qdrant and Redis)
   - Or you can run these services separately

## Installation Steps

### Step 1: Clone or Extract the Project
```powershell
cd YourProjectFolder
```

### Step 2: Run the Setup Script
Simply run the launcher - it will automatically:
- Create a Python virtual environment
- Install all dependencies
- Configure everything for you

```powershell
.\launch.ps1
```

On your **first run**, you'll be guided through a setup wizard where you can configure:
- Service ports (Backend: 8000, Frontend: 8501)
- Ollama models for different tasks
- Storage location
- Other preferences

Just press **Enter** to accept the default values if you're not sure.

### Step 3: Services Will Start Automatically
After configuration, the launcher will:
- Start the FastAPI backend
- Start the Streamlit frontend
- Open your web browser automatically

Access the application at: **http://localhost:8501**

## Common Commands

### Just Configure (Don't Launch)
```powershell
.\launch.ps1 -ConfigOnly
```

### Update Configuration
```powershell
.\launch.ps1 -Config
```

### Skip Model Downloading
If you already have Ollama models installed:
```powershell
.\launch.ps1 -SkipModelPull
```

### Don't Open Browser
```powershell
.\launch.ps1 -NoBrowser
```

### Combine Multiple Flags
```powershell
.\launch.ps1 -NoBrowser -SkipModelPull -Config
```

## What Gets Started Automatically?

When you run the launcher, these services start:

| Service | Port | What it does |
|---------|------|------------|
| **Ollama** | 11434 | Runs local LLMs (embedding, planning, writing models) |
| **FastAPI Backend** | 8000 | Processes documents and manages tasks |
| **Streamlit Frontend** | 8501 | Web interface for uploading and generating documents |
| **PostgreSQL** | 5432 | Stores document metadata |
| **Qdrant Vector Store** | 6333 | Stores document embeddings for search |
| **Redis** | 6379 | Task queue for background processing |
| **Celery Worker** | Background | Processes generation tasks |

**Don't worry!** The launcher handles all of this for you - no manual service configuration needed.

## Troubleshooting

### "Conda not found"
- Make sure Miniconda/Anaconda is installed and in your PATH
- Restart your terminal after installing Conda
- Try: `conda env list` in a new PowerShell to verify

### "Ollama server not responding"
- Open the Ollama app manually
- Wait 10 seconds
- Run the launcher again

### Backend/Frontend won't start
- Check if ports 8000 and 8501 are available
- Run: `Get-Content 'storage\cache\logs\backend.log' -Tail 30` to see errors
- Make sure all Python dependencies installed: `pip install -r requirements.txt`

### Models not downloading
- Check your internet connection
- Run: `ollama list` to see what's installed
- Manually pull models: `ollama pull nomic-embed-text`

## Viewing Logs

To see what's happening:

```powershell
# Backend logs
Get-Content 'storage\cache\logs\backend.log' -Tail 50

# Frontend logs
Get-Content 'storage\cache\logs\frontend.log' -Tail 50
```

## Configuration File

Your settings are saved in:
```
storage\cache\launcher-config.json
```

You can edit this manually if needed, but it's recommended to use:
```powershell
.\launch.ps1 -Config
```

## Need Help?

1. Check the logs (see "Viewing Logs" section above)
2. Make sure all prerequisites are installed
3. Try: `.\launch.ps1 -Config` to reconfigure from scratch
4. Restart your machine and try again

---

**That's it!** The launcher handles all the complexity. Just run it and start generating documents!
