# Launch & Setup Script Fixes - Summary

## Overview
Successfully fixed launch script parameter conflicts and created a comprehensive setup.ps1 utility with rich terminal UI styling.

## Issues Resolved

### 1. **Parameter Alias Conflict in launch.ps1**
- **Error Message**: `The parameter 'Config' cannot be specified because it conflicts with the parameter alias of the same name`
- **Root Cause**: The `scripts/launch.ps1` file had `[Alias("config")]` on the `$Config` parameter. When the main `launch.ps1` tried to pass parameters using splatting (`@normalized` and `@scriptArgs`), PowerShell detected a duplicate parameter definition.
- **Files Modified**:
  - `scripts/launch.ps1`: Removed the redundant alias from the parameter definition (line 2)
  - `launch.ps1`: Refactored parameter normalization logic for better clarity

### 2. **Created setup.ps1 Utility**
A new comprehensive setup script with features:
- **System Validation**: Checks for Python, Conda, Ollama, and Docker installations
- **Project Structure Verification**: Validates required directories and files exist
- **Interactive Configuration**: Optional dependency installation and testing
- **Rich Terminal UI**: Consistent ANSI color styling matching launch.ps1
- **Clear Guidance**: Next-step instructions for users

## UI Style Guide
Both scripts use consistent ANSI color codes for professional terminal output:

| Color | Usage | ANSI Code |
|-------|-------|-----------|
| Cyan | Headers, prompts | `\e[36m` |
| Green | Success/OK status | `\e[32m` |
| Yellow | Warnings, optional items | `\e[33m` |
| Red | Errors, failures | `\e[31m` |
| Blue | Step indicators | `\e[34m` |
| Gray | Decorative elements | `\e[90m` |
| Bold | Emphasis | `\e[1m` |
| Dim | Secondary text | `\e[2m` |

## Scripts Overview

### launch.ps1 (Main Entry Point)
- Starts Celery worker in background (optional)
- Delegates to scripts/launch.ps1 for configuration and service startup
- Supports flags:
  - `--config`: Interactive configuration wizard
  - `--config-only`: Configure without launching services
  - `--skip-model-pull`: Skip Ollama model validation
  - `--no-browser`: Don't open browser after launch
  - `--test`: Run test suite

### scripts/launch.ps1 (Service Launcher)
- Manages configuration via `storage/cache/launcher-config.json`
- Checks system requirements (Conda, Ollama, ports)
- Launches FastAPI backend and Streamlit frontend in separate PowerShell windows
- Monitors port availability with retry logic
- Generates `.env` file for backend environment

### setup.ps1 (New Setup Utility)
- Validates Python and Conda installations
- Checks optional tools (Ollama, Docker)
- Verifies project structure integrity
- Optionally installs Python dependencies
- Tests package imports
- Runs pytest suite
- Provides troubleshooting guidance

## Usage

### First Time Setup
```powershell
cd 'path\to\RAG-Document-Generator\v2'
.\setup.ps1
.\launch.ps1 --config
.\launch.ps1
```

### Reconfiguring
```powershell
.\launch.ps1 --config
.\launch.ps1
```

### Configuration Only (No Launch)
```powershell
.\launch.ps1 --config-only
```

### View Active Configuration
```powershell
.\launch.ps1 --show-config
```

## Testing Results
✅ setup.ps1 executes successfully with:
- Python 3.13.13 detected
- Conda installation verified
- Ollama installation detected
- All required project directories and files present
- Comprehensive system status summary displayed
- Interactive prompts for optional features

✅ launch.ps1 parameter conflict resolved:
- Scripts load without parameter alias errors
- Parameters correctly propagate from main script to subscripts
- Configuration wizard initiates properly

## Next Steps for Users
1. Run `.\setup.ps1` to verify system configuration
2. Run `.\launch.ps1 --config` to customize settings
3. Run `.\launch.ps1` to start the application
4. Access frontend at http://localhost:8501 (default)
5. Access backend API at http://localhost:8000 (default)

## Troubleshooting
If issues persist:
1. Check system requirements: `.\setup.ps1`
2. View configuration: `Get-Content 'storage\cache\launcher-config.json'`
3. Check logs: `Get-Content 'storage\cache\logs\backend.log' -Tail 40`
4. Reinstall dependencies: `python -m pip install -r requirements.txt`
