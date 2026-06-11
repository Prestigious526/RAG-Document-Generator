param(
    [switch]$Config,
    [switch]$ConfigOnly,
    [switch]$ShowConfig,
    [switch]$SkipModelPull,
    [switch]$NoBrowser,
    [switch]$Test
)

if ($Test) {
    Write-Host "Running all tests..." -ForegroundColor Cyan
    pytest tests/ -v --cov=backend --cov-report=html
    if ($LASTEXITCODE -eq 0) {
        Write-Host "All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "Tests failed!" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Build parameters to pass to scripts/launch.ps1
$scriptArgs = @()

foreach ($arg in $args) {
    switch ($arg) {
        "--config" { $scriptArgs += "-Config" }
        "--config-only" { $scriptArgs += "-ConfigOnly" }
        "--show-config" { $scriptArgs += "-ShowConfig" }
        "--skip-model-pull" { $scriptArgs += "-SkipModelPull" }
        "--no-browser" { $scriptArgs += "-NoBrowser" }
        "--test" { }
        "--no-celery" { }
        "-NoCelery" { }
        default { $scriptArgs += $arg }
    }
}

# Pass script parameters directly
if ($Config) { $scriptArgs += "-Config" }
if ($ConfigOnly) { $scriptArgs += "-ConfigOnly" }
if ($ShowConfig) { $scriptArgs += "-ShowConfig" }
if ($SkipModelPull) { $scriptArgs += "-SkipModelPull" }
if ($NoBrowser) { $scriptArgs += "-NoBrowser" }

# Check if Celery worker should be started in background
$startCelery = $true
if ($args -contains "--no-celery" -or $args -contains "-NoCelery") {
    $startCelery = $false
}

# Start Celery worker in background if requested
if ($startCelery) {
    Write-Host "Starting Celery worker in background..." -ForegroundColor Yellow
    $celeryProcess = Start-Process -PassThru -WindowStyle Hidden -FilePath "powershell" `
        -ArgumentList "-NoExit -Command `"cd '$PSScriptRoot' && celery -A workers.celery_app worker --loglevel=info`""
}

& "$PSScriptRoot\scripts\launch.ps1" @scriptArgs
