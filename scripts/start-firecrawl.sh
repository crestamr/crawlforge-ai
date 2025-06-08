#!/bin/bash

# Firecrawl Local Development Startup Script
# This script starts all Firecrawl services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    cat << EOF
Firecrawl Local Development Startup Script

USAGE:
    ./start-firecrawl.sh [OPTIONS]

OPTIONS:
    --check-only    Only check if services are running, don't start them
    --stop-all      Stop all running Node.js processes
    --help          Show this help message

EXAMPLES:
    ./start-firecrawl.sh              # Start all services
    ./start-firecrawl.sh --check-only # Check service status
    ./start-firecrawl.sh --stop-all   # Stop all services

SERVICES:
    - Playwright Service (Port 3003)
    - API Service (Port 3002)
    - Workers (Port 3005)
    - Redis (Port 6379) - Must be started manually

EOF
}

# Function to test if a port is open
test_port() {
    local port=$1
    if command -v nc >/dev/null 2>&1; then
        nc -z localhost $port >/dev/null 2>&1
    elif command -v telnet >/dev/null 2>&1; then
        timeout 1 telnet localhost $port >/dev/null 2>&1
    else
        # Fallback using /dev/tcp (bash built-in)
        timeout 1 bash -c "echo >/dev/tcp/localhost/$port" >/dev/null 2>&1
    fi
}

# Function to check service status
check_services() {
    echo -e "\n${CYAN}=== Firecrawl Service Status ===${NC}"

    local services=(
        "Redis:6379:true"
        "Playwright Service:3003:true"
        "API Service:3002:true"
        "Workers:3005:true"
    )

    local all_running=true

    for service_info in "${services[@]}"; do
        IFS=':' read -r name port required <<< "$service_info"

        if test_port $port; then
            printf "%-20s (Port %s): ${GREEN}✅ RUNNING${NC}\n" "$name" "$port"
        else
            printf "%-20s (Port %s): ${RED}❌ STOPPED${NC}\n" "$name" "$port"
            if [ "$required" = "true" ]; then
                all_running=false
            fi
        fi
    done

    echo ""
    if [ "$all_running" = true ]; then
        echo -e "${GREEN}🎉 All services are running!${NC}"
        echo -e "${YELLOW}API available at: http://localhost:3002${NC}"
        echo -e "${YELLOW}Test endpoint: http://localhost:3002/test${NC}"
    else
        echo -e "${YELLOW}⚠️  Some services are not running.${NC}"
        if ! test_port 6379; then
            echo -e "${MAGENTA}💡 Start Redis first! (brew services start redis or use DBngin)${NC}"
        fi
    fi

    return $([ "$all_running" = true ] && echo 0 || echo 1)
}

# Function to stop all services
stop_all_services() {
    echo -e "${YELLOW}🛑 Stopping all Node.js processes...${NC}"

    if pgrep -f "node" > /dev/null; then
        pkill -f "node" || true
        echo -e "${GREEN}✅ All Node.js processes stopped.${NC}"
    else
        echo -e "${YELLOW}No Node.js processes found.${NC}"
    fi

    sleep 2
    check_services
}

# Function to start services
start_services() {
    echo -e "${CYAN}🚀 Starting Firecrawl services...${NC}"

    # Check if Redis is running first
    if ! test_port 6379; then
        echo -e "${RED}❌ Redis is not running!${NC}"
        echo -e "${YELLOW}💡 Please start Redis first:${NC}"
        echo -e "   ${YELLOW}macOS: brew services start redis${NC}"
        echo -e "   ${YELLOW}Linux: sudo systemctl start redis${NC}"
        echo -e "   ${YELLOW}Or use DBngin for a GUI interface${NC}"
        return 1
    fi

    # Check if .env file exists
    if [ ! -f "apps/api/.env" ]; then
        echo -e "${RED}❌ Environment file not found!${NC}"
        echo -e "${YELLOW}💡 Please create apps/api/.env file. See LOCAL_DEVELOPMENT_GUIDE.md for details.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Redis is running${NC}"
    echo -e "${GREEN}✅ Environment file found${NC}"
    echo ""

    # Start Playwright Service
    echo -e "${YELLOW}Starting Playwright Service...${NC}"
    cd apps/playwright-service-ts
    pnpm run dev &
    PLAYWRIGHT_PID=$!
    cd ../..

    # Wait for Playwright to start
    echo -e "${BLUE}Waiting for Playwright service to start...${NC}"
    local timeout=30
    local elapsed=0
    while ! test_port 3003 && [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        echo -n "."
    done
    echo ""

    if test_port 3003; then
        echo -e "${GREEN}✅ Playwright Service started on port 3003${NC}"
    else
        echo -e "${RED}❌ Playwright Service failed to start${NC}"
        kill $PLAYWRIGHT_PID 2>/dev/null || true
        return 1
    fi

    # Start API Service
    echo -e "${YELLOW}Starting API Service...${NC}"
    cd apps/api
    pnpm run start:dev &
    API_PID=$!
    cd ../..

    # Wait for API to start
    echo -e "${BLUE}Waiting for API service to start...${NC}"
    elapsed=0
    while ! test_port 3002 && [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        echo -n "."
    done
    echo ""

    if test_port 3002; then
        echo -e "${GREEN}✅ API Service started on port 3002${NC}"
    else
        echo -e "${RED}❌ API Service failed to start${NC}"
        kill $PLAYWRIGHT_PID $API_PID 2>/dev/null || true
        return 1
    fi

    # Start Workers
    echo -e "${YELLOW}Starting Workers...${NC}"
    cd apps/api
    pnpm run workers &
    WORKERS_PID=$!
    cd ../..

    # Wait for Workers to start
    echo -e "${BLUE}Waiting for workers to start...${NC}"
    elapsed=0
    while ! test_port 3005 && [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        echo -n "."
    done
    echo ""

    if test_port 3005; then
        echo -e "${GREEN}✅ Workers started on port 3005${NC}"
    else
        echo -e "${RED}❌ Workers failed to start${NC}"
        kill $PLAYWRIGHT_PID $API_PID $WORKERS_PID 2>/dev/null || true
        return 1
    fi

    echo ""
    echo -e "${GREEN}🎉 All services started successfully!${NC}"
    echo ""
    echo -e "${CYAN}📋 Service URLs:${NC}"
    echo -e "   API:        http://localhost:3002"
    echo -e "   Test:       http://localhost:3002/test"
    echo -e "   Playwright: http://localhost:3003"
    echo -e "   Workers:    http://localhost:3005"
    echo ""
    echo -e "${CYAN}🧪 Test the API:${NC}"
    echo -e "   curl http://localhost:3002/test"
    echo -e "   curl -X POST http://localhost:3002/v1/scrape -H \"Content-Type: application/json\" -d '{\"url\": \"https://example.com\"}'"
    echo ""
    echo -e "${YELLOW}📖 For more information, see LOCAL_DEVELOPMENT_GUIDE.md${NC}"
    echo ""
    echo -e "${YELLOW}💡 To stop all services, run: ./start-firecrawl.sh --stop-all${NC}"

    # Save PIDs for later cleanup
    echo "$PLAYWRIGHT_PID $API_PID $WORKERS_PID" > .firecrawl_pids
}

# Parse command line arguments
case "${1:-}" in
    --help)
        show_help
        exit 0
        ;;
    --check-only)
        check_services
        exit $?
        ;;
    --stop-all)
        stop_all_services
        exit 0
        ;;
    "")
        # Default: Start services
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

# Main script logic
echo -e "${CYAN}🔥 Firecrawl Local Development Startup${NC}"
echo -e "${CYAN}=====================================${NC}"

# Check current status first
if check_services; then
    echo -e "${YELLOW}All services are already running! Use --stop-all to restart them.${NC}"
else
    start_services
fi
