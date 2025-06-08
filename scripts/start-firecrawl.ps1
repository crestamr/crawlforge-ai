# Firecrawl Local Development Startup Script
# This script starts all Firecrawl services in separate terminal windows

param(
    [switch]$CheckOnly,
    [switch]$StopAll,
    [switch]$Help
)

function Show-Help {
    Write-Host @"
Firecrawl Local Development Startup Script

USAGE:
    .\start-firecrawl.ps1 [OPTIONS]

OPTIONS:
    -CheckOnly    Only check if services are running, don't start them
    -StopAll      Stop all running Node.js processes
    -Help         Show this help message

EXAMPLES:
    .\start-firecrawl.ps1           # Start all services
    .\start-firecrawl.ps1 -CheckOnly # Check service status
    .\start-firecrawl.ps1 -StopAll   # Stop all services

SERVICES:
    - Playwright Service (Port 3003)
    - API Service (Port 3002)
    - Workers (Port 3005)
    - Redis (Port 6379) - Must be started manually in DBngin

"@
}

function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Check-Services {
    Write-Host "`n=== Firecrawl Service Status ===" -ForegroundColor Cyan

    $services = @(
        @{Name="Redis"; Port=6379; Required=$true},
        @{Name="Playwright Service"; Port=3003; Required=$true},
        @{Name="API Service"; Port=3002; Required=$true},
        @{Name="Workers"; Port=3005; Required=$true}
    )

    $allRunning = $true

    foreach ($service in $services) {
        $isRunning = Test-Port -Port $service.Port
        $status = if ($isRunning) { "✅ RUNNING" } else { "❌ STOPPED" }
        $color = if ($isRunning) { "Green" } else { "Red" }

        Write-Host "$($service.Name.PadRight(20)) (Port $($service.Port)): " -NoNewline
        Write-Host $status -ForegroundColor $color

        if (-not $isRunning -and $service.Required) {
            $allRunning = $false
        }
    }

    Write-Host ""
    if ($allRunning) {
        Write-Host "🎉 All services are running!" -ForegroundColor Green
        Write-Host "API available at: http://localhost:3002" -ForegroundColor Yellow
        Write-Host "Test endpoint: http://localhost:3002/test" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  Some services are not running." -ForegroundColor Yellow
        if (-not (Test-Port -Port 6379)) {
            Write-Host "💡 Start Redis in DBngin first!" -ForegroundColor Magenta
        }
    }

    return $allRunning
}

function Stop-AllServices {
    Write-Host "🛑 Stopping all Node.js processes..." -ForegroundColor Yellow

    try {
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "✅ All Node.js processes stopped." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error stopping processes: $($_.Exception.Message)" -ForegroundColor Red
    }

    Start-Sleep -Seconds 2
    Check-Services
}

function Start-Services {
    Write-Host "🚀 Starting Firecrawl services..." -ForegroundColor Cyan

    # Check if Redis is running first
    if (-not (Test-Port -Port 6379)) {
        Write-Host "❌ Redis is not running!" -ForegroundColor Red
        Write-Host "💡 Please start Redis in DBngin first, then run this script again." -ForegroundColor Yellow
        return
    }

    # Check if .env file exists
    if (-not (Test-Path "apps\api\.env")) {
        Write-Host "❌ Environment file not found!" -ForegroundColor Red
        Write-Host "💡 Please create apps\api\.env file. See LOCAL_DEVELOPMENT_GUIDE.md for details." -ForegroundColor Yellow
        return
    }

    Write-Host "✅ Redis is running" -ForegroundColor Green
    Write-Host "✅ Environment file found" -ForegroundColor Green
    Write-Host ""

    # Start Playwright Service
    Write-Host "Starting Playwright Service..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location 'apps\playwright-service-ts'; Write-Host '🎭 Starting Playwright Service...' -ForegroundColor Magenta; pnpm run dev"
    )

    # Wait for Playwright to start
    Write-Host "Waiting for Playwright service to start..." -ForegroundColor Gray
    $timeout = 30
    $elapsed = 0
    while (-not (Test-Port -Port 3003) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 1
        $elapsed++
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host ""

    if (Test-Port -Port 3003) {
        Write-Host "✅ Playwright Service started on port 3003" -ForegroundColor Green
    } else {
        Write-Host "❌ Playwright Service failed to start" -ForegroundColor Red
        return
    }

    # Start API Service
    Write-Host "Starting API Service..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location 'apps\api'; Write-Host '🔥 Starting API Service...' -ForegroundColor Cyan; pnpm run start:dev"
    )

    # Wait for API to start
    Write-Host "Waiting for API service to start..." -ForegroundColor Gray
    $elapsed = 0
    while (-not (Test-Port -Port 3002) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 1
        $elapsed++
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host ""

    if (Test-Port -Port 3002) {
        Write-Host "✅ API Service started on port 3002" -ForegroundColor Green
    } else {
        Write-Host "❌ API Service failed to start" -ForegroundColor Red
        return
    }

    # Start Workers
    Write-Host "Starting Workers..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location 'apps\api'; Write-Host '⚙️ Starting Workers...' -ForegroundColor Blue; pnpm run workers"
    )

    # Wait for Workers to start
    Write-Host "Waiting for workers to start..." -ForegroundColor Gray
    $elapsed = 0
    while (-not (Test-Port -Port 3005) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 1
        $elapsed++
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host ""

    if (Test-Port -Port 3005) {
        Write-Host "✅ Workers started on port 3005" -ForegroundColor Green
    } else {
        Write-Host "❌ Workers failed to start" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "🎉 All services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Service URLs:" -ForegroundColor Cyan
    Write-Host "   API:        http://localhost:3002" -ForegroundColor White
    Write-Host "   Test:       http://localhost:3002/test" -ForegroundColor White
    Write-Host "   Playwright: http://localhost:3003" -ForegroundColor White
    Write-Host "   Workers:    http://localhost:3005" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 Test the API:" -ForegroundColor Cyan
    Write-Host '   Invoke-WebRequest -Uri "http://localhost:3002/test"' -ForegroundColor Gray
    Write-Host '   curl.exe -X POST http://localhost:3002/v1/scrape -H "Content-Type: application/json" -d ''{\"url\": \"https://example.com\"}''"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "📖 For more information, see LOCAL_DEVELOPMENT_GUIDE.md" -ForegroundColor Yellow
}

# Main script logic
if ($Help) {
    Show-Help
    exit 0
}

if ($StopAll) {
    Stop-AllServices
    exit 0
}

if ($CheckOnly) {
    Check-Services
    exit 0
}

# Default: Start services
Write-Host @"
🔥 Firecrawl Local Development Startup
=====================================
"@ -ForegroundColor Cyan

# Check current status first
$allRunning = Check-Services

if ($allRunning) {
    Write-Host "All services are already running! Use -StopAll to restart them." -ForegroundColor Yellow
} else {
    Start-Services
}
