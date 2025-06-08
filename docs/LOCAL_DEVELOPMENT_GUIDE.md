# Firecrawl Local Development Guide

This guide provides step-by-step instructions for running Firecrawl services locally without Docker, using DBngin for Redis.

## Prerequisites

### Required Software
- **Node.js** (v18 or higher)
- **pnpm** package manager
- **DBngin** (for Redis database)
- **Git**

### Installation Steps
1. Install Node.js from [nodejs.org](https://nodejs.org/)
2. Install pnpm: `npm install -g pnpm`
3. Install DBngin from [dbngin.com](https://dbngin.com/)
4. Clone the repository: `git clone <repository-url>`

## Environment Configuration

### 1. Create Environment File
Create a `.env` file in `apps/api/.env` with the following configuration:

```bash
# ===== Required ENVS ======
NUM_WORKERS_PER_QUEUE=8
PORT=3002
HOST=localhost
REDIS_URL=redis://localhost:6379
REDIS_RATE_LIMIT_URL=redis://localhost:6379
PLAYWRIGHT_MICROSERVICE_URL=http://localhost:3003/html

# Authentication settings (set to false for local development)
USE_DB_AUTHENTICATION=false

# ===== Optional ENVS ======

# SearchApi configuration
SEARCHAPI_API_KEY=your_searchapi_key_here
SEARCHAPI_ENGINE=google

# Supabase Setup (for authentication when enabled)
SUPABASE_ANON_TOKEN=your_supabase_anon_token
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_REPLICA_URL=https://your-project.supabase.co
SUPABASE_SERVICE_TOKEN=your_supabase_service_token

# Optional services
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
BULL_AUTH_KEY=@
SCRAPING_BEE_API_KEY=
LLAMAPARSE_API_KEY=
SLACK_WEBHOOK_URL=
POSTHOG_API_KEY=
POSTHOG_HOST=

# Logging
LOGGING_LEVEL=INFO
```

### 2. Install Dependencies
```bash
# Install root dependencies
pnpm install

# Install API dependencies
cd apps/api
pnpm install

# Install Playwright service dependencies
cd ../playwright-service-ts
pnpm install
```

## Database Setup

### 1. Start Redis with DBngin
1. Open **DBngin** application
2. Click **"+"** to add a new service
3. Select **Redis**
4. Configure:
   - **Port**: 6379 (default)
   - **Version**: Latest stable
5. Click **"Create"**
6. Start the Redis service (should show green "Running" status)

### 2. Verify Redis Connection
```bash
# Test Redis connection
redis-cli ping
# Should return: PONG
```

## Running Services

### Method 1: Individual Terminal Windows

#### Terminal 1: Playwright Service
```bash
cd apps/playwright-service-ts
pnpm run dev
```
**Expected output:**
```
Playwright service listening on port 3003
```

#### Terminal 2: API Service
```bash
cd apps/api
pnpm run start:dev
```
**Expected output:**
```
Worker [PID] listening on port 3002
Connected to Redis Session Rate Limit Store!
```

#### Terminal 3: Workers
```bash
cd apps/api
pnpm run workers
```
**Expected output:**
```
Liveness endpoint is running on port 3005
Connected to Redis Session Rate Limit Store!
```

### Method 2: PowerShell Script (Windows)

Create `start-services.ps1`:
```powershell
# Start Playwright Service
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location 'apps\playwright-service-ts'; pnpm run dev"

# Wait for Playwright to start
Start-Sleep -Seconds 5

# Start API Service
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location 'apps\api'; pnpm run start:dev"

# Wait for API to start
Start-Sleep -Seconds 5

# Start Workers
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location 'apps\api'; pnpm run workers"

Write-Host "All services started! Check individual terminal windows for status."
```

Run with: `.\start-services.ps1`

## Service Verification

### 1. Check Running Ports
```bash
# Windows
netstat -an | findstr "LISTENING" | findstr ":300"

# Expected output:
# TCP    0.0.0.0:3002    0.0.0.0:0    LISTENING  (API)
# TCP    0.0.0.0:3003    0.0.0.0:0    LISTENING  (Playwright)
# TCP    0.0.0.0:3005    0.0.0.0:0    LISTENING  (Workers)
```

### 2. Test API Endpoints

#### Health Check
```bash
curl http://localhost:3002/test
# Expected: "Hello, world!"
```

#### Scrape Test

**Windows (PowerShell):**
```powershell
$body = @{url="https://example.com"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:3002/v1/scrape" -Method POST -Body $body -ContentType "application/json"
```

**Windows (curl.exe):**
```bash
curl.exe -X POST http://localhost:3002/v1/scrape -H "Content-Type: application/json" -d '{\"url\": \"https://example.com\"}'
```

**macOS/Linux:**
```bash
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

**Expected response:**
```json
{
  "success": true,
  "data": {
    "markdown": "Example Domain\n==============\n\nThis domain is for use in illustrative examples...",
    "metadata": {...}
  }
}
```

## Service Status Summary

When all services are running correctly, you should see:

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| **Playwright** | 3003 | ✅ Running | HTML rendering and conversion |
| **API Server** | 3002 | ✅ Running | Main API endpoints |
| **Workers** | 3005 | ✅ Running | Background job processing |
| **Redis** | 6379 | ✅ Running | Queue and rate limiting |

## Troubleshooting

### Common Issues

#### 1. Redis Connection Failed
**Error:** `Error connecting to Redis`
**Solution:**
- Verify Redis is running in DBngin (green status)
- Check port 6379 is not blocked
- Restart Redis service in DBngin

#### 2. Port Already in Use
**Error:** `EADDRINUSE: address already in use :::3002`
**Solution:**
```bash
# Find process using port
netstat -ano | findstr :3002
# Kill process (replace PID)
taskkill /PID <PID> /F
```

#### 3. Playwright Service Not Found
**Error:** `connect ECONNREFUSED 127.0.0.1:3003`
**Solution:**
- Ensure Playwright service started first
- Check `PLAYWRIGHT_MICROSERVICE_URL` in .env
- Verify port 3003 is listening

#### 4. Environment Variables Not Loaded
**Error:** `Worker listening on port undefined`
**Solution:**
- Verify `.env` file exists in `apps/api/.env`
- Check file permissions
- Restart API service

#### 5. curl Command Issues (Windows)
**Error:** `"Bad request, malformed JSON"` or `"URL rejected: Malformed input"`
**Solution:**
Use proper Windows curl syntax:
```bash
# Correct Windows syntax
curl.exe -X POST http://localhost:3002/v1/scrape -H "Content-Type: application/json" -d '{\"url\": \"https://example.com\"}'

# Or use PowerShell instead
$body = @{url="https://example.com"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:3002/v1/scrape" -Method POST -Body $body -ContentType "application/json"
```

### Logs and Debugging

#### Enable Debug Logging
```bash
# In apps/api/.env
LOGGING_LEVEL=DEBUG
```

#### Check Service Logs
- **API Service**: Look for "Worker [PID] listening on port 3002"
- **Workers**: Look for "Liveness endpoint is running on port 3005"
- **Playwright**: Look for "Playwright service listening on port 3003"
- **Redis**: Look for "Connected to Redis Session Rate Limit Store!"

## Development Workflow

### 1. Daily Startup
1. Start DBngin and ensure Redis is running
2. Run services using preferred method
3. Verify all endpoints are responding

### 2. Making Changes
- API changes: Service auto-restarts with nodemon
- Playwright changes: Service auto-restarts with nodemon
- Environment changes: Restart affected services

### 3. Stopping Services
```bash
# Stop individual services with Ctrl+C in each terminal
# Or kill all Node processes:
taskkill /F /IM node.exe
```

## Production Considerations

When moving to production:

1. **Enable Authentication:**
   ```bash
   USE_DB_AUTHENTICATION=true
   ```

2. **Configure Supabase:**
   - Set up proper Supabase project
   - Add real tokens and URLs

3. **Add API Keys:**
   - SearchAPI for web search
   - OpenAI for AI features
   - Other optional services

4. **Security:**
   - Change `BULL_AUTH_KEY`
   - Use environment-specific configurations
   - Enable proper logging and monitoring

## Support

For issues or questions:
- Check the troubleshooting section above
- Review service logs for error messages
- Ensure all prerequisites are properly installed
- Verify Redis is running in DBngin
