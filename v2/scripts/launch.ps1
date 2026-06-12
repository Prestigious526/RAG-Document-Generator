param(
    [switch]$Interactive,
    [switch]$ConfigOnly,
    [switch]$ShowConfig,
    [switch]$SkipModelPull,
    [switch]$NoBrowser,
    [string]$EnvName = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

# -------------------------
# Docs / Config Paths
# -------------------------
$DocsFolder = [System.Environment]::GetFolderPath('MyDocuments')
if ([string]::IsNullOrEmpty($DocsFolder)) {
    $DocsFolder = Join-Path $env:USERPROFILE "Documents"
    if (-not (Test-Path $DocsFolder)) {
        $DocsFolder = Join-Path $env:USERPROFILE "OneDrive\Documents"
        if (-not (Test-Path $DocsFolder)) {
            $DocsFolder = $env:USERPROFILE
        }
    }
}

$DocsConfigDir = Join-Path $DocsFolder "RAG-Document-Generator"
if (-not (Test-Path $DocsConfigDir)) {
    New-Item -ItemType Directory -Path $DocsConfigDir -Force | Out-Null
}

$ConfigPath = Join-Path $DocsConfigDir "launcher-config.json"
$DotEnvPath = Join-Path $DocsConfigDir ".env"
$EnvFile = Join-Path $Root "environment.yml"

# -------------------------
# Helpers
# -------------------------
function Write-Colored { param($t,$c="White") Write-Host $t -ForegroundColor $c }
function Step { param($t) Write-Host "> $t" -ForegroundColor White }
function Ok { param($t) Write-Host "OK  $t" -ForegroundColor Green }
function Warn { param($t) Write-Host "!!  $t" -ForegroundColor Yellow }
function Fail { param($t) Write-Host "XX  $t" -ForegroundColor Red }

function Write-Rule {
    param($t="")
    Write-Host ("-" * 76) -ForegroundColor Gray
    if ($t) { Write-Host $t -ForegroundColor Cyan }
}

function Write-Logo {
    Clear-Host
    Write-Host ""
    Write-Host "+--------------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "| Offline RAG Document Generator                                          |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

# -------------------------
# Config
# -------------------------
function Default-Config {
    return [ordered]@{
        user_name = $env:USERNAME
        workspace_name = "RAG Document Generator"
        conda_env_name = "rag_document_generator"
        backend_port = 8000
        frontend_port = 8501
        open_browser = $true
        skip_model_pull = $false
        app_storage_dir = "storage"
        ollama_base_url = "http://localhost:11434"
        postgres_host = "localhost"
        postgres_port = 5432
        postgres_db = "rag_platform"
        postgres_user = "rag"
        postgres_password = "rag_password"
        qdrant_url = "http://localhost:6333"
        redis_url = "redis://localhost:6379/0"
        max_upload_mb = 200
        generation_timeout_seconds = 1800
        worker_concurrency = 2
        models = [ordered]@{
            embedding = "nomic-embed-text"
            planning = "qwen3:14b"
            writing = "qwen3:14b"
            validation = "gemma3:12b"
            editing = "mistral-small"
        }
        env = [ordered]@{
            USE_OLLAMA = "true"
            BACKEND_URL = "http://localhost:8000"
        }
    }
}

function Load-Config {
    $defaults = Default-Config
    if (-not (Test-Path $ConfigPath)) { return $defaults }

    $loaded = Get-Content -Raw $ConfigPath | ConvertFrom-Json
    $loaded = ConvertTo-Hashtable $loaded

    foreach ($k in $defaults.Keys) {
        if (-not $loaded.Contains($k)) {
            $loaded[$k] = $defaults[$k]
        }
    }
    return $loaded
}

function Save-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
}

# FIXED: safer conversion
function ConvertTo-Hashtable($value) {
    if ($null -eq $value) { return $null }

    if ($value -is [array]) {
        return @($value | ForEach-Object { ConvertTo-Hashtable $_ })
    }

    if ($value.PSObject.Properties.Count -gt 0 -and $value -isnot [string]) {
        $h = [ordered]@{}
        foreach ($p in $value.PSObject.Properties) {
            $h[$p.Name] = ConvertTo-Hashtable $p.Value
        }
        return $h
    }

    return $value
}

# -------------------------
# Condu / Env
# -------------------------
function Get-Conda {
    $cmd = Get-Command conda -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $paths = @(
        "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\anaconda3\Scripts\conda.exe"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# FIXED conda detection
function Test-CondaEnv($conda,$name) {
    $envs = & $conda env list 2>$null
    return ($envs | Select-String "^\s*$([regex]::Escape($name))\s")
}

function Ensure-CondaEnv($conda,$name) {
    Step "Checking conda environment"

    if (Test-CondaEnv $conda $name) {
        Ok "Environment exists"
        return
    }

    Warn "Creating conda environment..."
    & $conda env create -n $name -f $EnvFile

    if ($LASTEXITCODE -ne 0) {
        throw "Conda env creation failed"
    }

    Ok "Conda environment created"
}

# -------------------------
# Services
# -------------------------
function Test-Port($port) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $a = $c.ConnectAsync("127.0.0.1",$port)
        return ($a.Wait(500) -and $c.Connected)
    } catch { return $false }
}

function Wait-Port($port,$name) {
    for ($i=0;$i -lt 40;$i++) {
        if (Test-Port $port) {
            Ok "$name running on $port"
            return $true
        }
        Start-Sleep 1
    }
    return $false
}

function Start-ServiceIfNeeded($name,$port,$cmd,$log,$env) {
    Step "Checking $name"

    if (Test-Port $port) {
        Ok "$name already running"
        return
    }

    if (Test-Path $log) { Clear-Content $log }

    $envStr = ($env.GetEnumerator() | ForEach-Object { "`$env:$($_.Key)='$($_.Value)'" }) -join "; "
    $cmdStr = ($cmd -join " ")

    $script = "Set-Location '$Root'; $envStr; $cmdStr *>&1 | Tee-Object '$log'"

    Start-Process powershell.exe -ArgumentList @("-NoExit","-Command",$script)

    if (-not (Wait-Port $port $name)) {
        throw "$name failed"
    }
}

# -------------------------
# Main
# -------------------------
try {
    Write-Logo

    $config = Load-Config

    $firstRun = -not (Test-Path $ConfigPath)

    if ($EnvName) { $config.conda_env_name = $EnvName }
    if ($NoBrowser) { $config.open_browser = $false }
    if ($SkipModelPull) { $config.skip_model_pull = $true }

    if ($Interactive) {
        Warn "Interactive mode not fully included here (keep your wizard if needed)"
        Save-Config $config
    } else {
        Save-Config $config
    }

    Write-Rule "Config loaded"

    $conda = Get-Conda
    if (-not $conda) { throw "Conda not found" }

    Ensure-CondaEnv $conda $config.conda_env_name

    Write-Rule "Starting services"

    $logDir = Join-Path $Root "$($config.app_storage_dir)\logs"
    New-Item -Force -ItemType Directory $logDir | Out-Null

    $backendEnv = $config.env
    $backendEnv.BACKEND_URL = "http://localhost:$($config.backend_port)"

    Start-ServiceIfNeeded `
        "Backend" $config.backend_port `
        @($conda,"run","-n",$config.conda_env_name,"python","-m","uvicorn","backend.main:app","--port",$config.backend_port) `
        (Join-Path $logDir "backend.log") `
        $backendEnv

    $frontendEnv = $backendEnv

    Start-ServiceIfNeeded `
        "Frontend" $config.frontend_port `
        @($conda,"run","-n",$config.conda_env_name,"python","-m","streamlit","run","frontend/streamlit_app/app.py","--server.port",$config.frontend_port) `
        (Join-Path $logDir "frontend.log") `
        $frontendEnv

    Write-Rule "READY"
    Write-Host "Backend : http://localhost:$($config.backend_port)" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:$($config.frontend_port)" -ForegroundColor Green

    if ($config.open_browser) {
        Start-Process "http://localhost:$($config.frontend_port)"
    }

} catch {
    Write-Rule "FAILED"
    Fail $_.Exception.Message
    exit 1
}