#!/bin/bash

# Log Management Script for AWS Health Notification Deployments
# This script helps manage deployment log files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_DIR="logs"

echo -e "${BLUE}📋 Deployment Log Management${NC}"
echo "============================"
echo ""

# Check if logs directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}⚠️  No logs directory found${NC}"
    exit 0
fi

# Count log files
LOG_COUNT=$(find "$LOG_DIR" -name "deployment-*.log" 2>/dev/null | wc -l)

if [ "$LOG_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✨ No deployment logs found${NC}"
    exit 0
fi

echo -e "${BLUE}📊 Log File Summary:${NC}"
echo "  • Total deployment logs: $LOG_COUNT"

# Calculate total size
TOTAL_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
echo "  • Total log size: $TOTAL_SIZE"

# Show most recent logs
echo ""
echo -e "${BLUE}📅 Recent Deployment Logs:${NC}"
echo "────────────────────────────────────────────────────────"
ls -lt "$LOG_DIR"/deployment-*.log 2>/dev/null | head -5 | while read -r line; do
    echo "  $line"
done
echo "────────────────────────────────────────────────────────"

echo ""
echo -e "${BLUE}🔧 Management Options:${NC}"
echo "1. View latest log"
echo "2. Clean up old logs (keep last 10)"
echo "3. Clean up logs older than 30 days"
echo "4. View all logs"
echo "5. Search logs for errors"
echo "6. Exit"

echo ""
read -p "$(echo -e ${YELLOW}Select option [1-6]: ${NC})" choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}📄 Latest Deployment Log:${NC}"
        echo "════════════════════════════════════════"
        LATEST_LOG=$(ls -t "$LOG_DIR"/deployment-*.log 2>/dev/null | head -1)
        if [ -n "$LATEST_LOG" ]; then
            echo "File: $LATEST_LOG"
            echo ""
            cat "$LATEST_LOG"
        else
            echo "No logs found"
        fi
        ;;
    2)
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up old logs (keeping last 10)...${NC}"
        LOGS_TO_DELETE=$(ls -t "$LOG_DIR"/deployment-*.log 2>/dev/null | tail -n +11)
        if [ -n "$LOGS_TO_DELETE" ]; then
            echo "$LOGS_TO_DELETE" | xargs rm -f
            DELETED_COUNT=$(echo "$LOGS_TO_DELETE" | wc -l)
            echo -e "${GREEN}✅ Deleted $DELETED_COUNT old log files${NC}"
        else
            echo -e "${GREEN}✨ No old logs to clean up${NC}"
        fi
        ;;
    3)
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up logs older than 30 days...${NC}"
        OLD_LOGS=$(find "$LOG_DIR" -name "deployment-*.log" -mtime +30 2>/dev/null)
        if [ -n "$OLD_LOGS" ]; then
            echo "$OLD_LOGS" | xargs rm -f
            DELETED_COUNT=$(echo "$OLD_LOGS" | wc -l)
            echo -e "${GREEN}✅ Deleted $DELETED_COUNT old log files${NC}"
        else
            echo -e "${GREEN}✨ No logs older than 30 days found${NC}"
        fi
        ;;
    4)
        echo ""
        echo -e "${BLUE}📋 All Deployment Logs:${NC}"
        echo "════════════════════════════════════════"
        ls -la "$LOG_DIR"/deployment-*.log 2>/dev/null || echo "No logs found"
        ;;
    5)
        echo ""
        echo -e "${YELLOW}🔍 Searching for errors in logs...${NC}"
        echo "════════════════════════════════════════"
        if grep -r "ERROR" "$LOG_DIR"/ 2>/dev/null; then
            echo ""
            echo -e "${RED}❌ Errors found in logs above${NC}"
        else
            echo -e "${GREEN}✅ No errors found in any logs${NC}"
        fi
        ;;
    6)
        echo -e "${GREEN}👋 Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📋 Current Status:${NC}"
REMAINING_LOGS=$(find "$LOG_DIR" -name "deployment-*.log" 2>/dev/null | wc -l)
REMAINING_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
echo "  • Remaining logs: $REMAINING_LOGS"
echo "  • Total size: $REMAINING_SIZE"
