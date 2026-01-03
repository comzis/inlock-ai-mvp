#!/usr/bin/env bash
set -euo pipefail

# Safe Project Cleanup Script
# Removes old log files and temporary files without breaking working configurations

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Safe Project Cleanup ==="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Date: $(date +%Y-%m-%d)"
echo ""
echo "This script will safely remove:"
echo "  - Old log files (older than 30 days)"
echo "  - Temporary files (*.tmp, *~, *.swp, .DS_Store)"
echo "  - Old backup files in logs/ (older than 30 days)"
echo ""
echo "⚠️  This will NOT remove:"
echo "  - Active configuration files"
echo "  - Recent log files (< 30 days)"
echo "  - Archive documentation"
echo "  - Any files referenced by services"
echo ""

# Ask for confirmation
read -p "Continue with cleanup? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
TOTAL_SIZE_FREED=0
FILES_REMOVED=0

# 1. Clean old log files (older than 30 days)
echo "1. Cleaning old log files (older than 30 days)..."
cd "$PROJECT_ROOT"
OLD_LOGS=$(find . -type f -name "*.log" -mtime +30 2>/dev/null | grep -v ".git" || true)
if [ -n "$OLD_LOGS" ]; then
    while IFS= read -r logfile; do
        if [ -f "$logfile" ]; then
            SIZE=$(du -b "$logfile" 2>/dev/null | cut -f1 || echo "0")
            echo "  Removing: $logfile ($(du -h "$logfile" 2>/dev/null | cut -f1))"
            rm -f "$logfile"
            FILES_REMOVED=$((FILES_REMOVED + 1))
            TOTAL_SIZE_FREED=$((TOTAL_SIZE_FREED + SIZE))
        fi
    done <<< "$OLD_LOGS"
    echo -e "${GREEN}✅ Removed old log files${NC}"
else
    echo -e "${GREEN}✅ No old log files found${NC}"
fi
echo ""

# 2. Clean temporary files
echo "2. Cleaning temporary files..."
TEMP_FILES=$(find . -type f \( -name "*.tmp" -o -name "*~" -o -name "*.swp" -o -name ".DS_Store" -o -name "Thumbs.db" \) 2>/dev/null | grep -v ".git" || true)
if [ -n "$TEMP_FILES" ]; then
    while IFS= read -r tempfile; do
        if [ -f "$tempfile" ]; then
            SIZE=$(du -b "$tempfile" 2>/dev/null | cut -f1 || echo "0")
            echo "  Removing: $tempfile"
            rm -f "$tempfile"
            FILES_REMOVED=$((FILES_REMOVED + 1))
            TOTAL_SIZE_FREED=$((TOTAL_SIZE_FREED + SIZE))
        fi
    done <<< "$TEMP_FILES"
    echo -e "${GREEN}✅ Removed temporary files${NC}"
else
    echo -e "${GREEN}✅ No temporary files found${NC}"
fi
echo ""

# 3. Clean old backup files in logs/ directory (older than 30 days)
echo "3. Cleaning old backup files in logs/ directory..."
if [ -d "$PROJECT_ROOT/logs" ]; then
    OLD_BACKUPS=$(find "$PROJECT_ROOT/logs" -type f -mtime +30 2>/dev/null || true)
    if [ -n "$OLD_BACKUPS" ]; then
        while IFS= read -r backupfile; do
            if [ -f "$backupfile" ]; then
                SIZE=$(du -b "$backupfile" 2>/dev/null | cut -f1 || echo "0")
                echo "  Removing: $backupfile ($(du -h "$backupfile" 2>/dev/null | cut -f1))"
                rm -f "$backupfile"
                FILES_REMOVED=$((FILES_REMOVED + 1))
                TOTAL_SIZE_FREED=$((TOTAL_SIZE_FREED + SIZE))
            fi
        done <<< "$OLD_BACKUPS"
        echo -e "${GREEN}✅ Removed old backup files${NC}"
    else
        echo -e "${GREEN}✅ No old backup files found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  logs/ directory not found${NC}"
fi
echo ""

# 4. Clean empty directories (except important ones)
echo "4. Cleaning empty directories..."
EMPTY_DIRS=$(find . -type d -empty 2>/dev/null | grep -vE "^\.$|^\./\.git|^\./compose|^\./config|^\./docs|^\./scripts|^\./traefik|^\./archive|^\./logs|^\./secrets|^\./ansible|^\./e2e" || true)
if [ -n "$EMPTY_DIRS" ]; then
    while IFS= read -r emptydir; do
        if [ -d "$emptydir" ] && [ -z "$(ls -A "$emptydir" 2>/dev/null)" ]; then
            echo "  Removing empty directory: $emptydir"
            rmdir "$emptydir" 2>/dev/null || true
        fi
    done <<< "$EMPTY_DIRS"
    echo -e "${GREEN}✅ Cleaned empty directories${NC}"
else
    echo -e "${GREEN}✅ No empty directories to clean${NC}"
fi
echo ""

# 5. Show current log file sizes (for reference)
echo "5. Current log file status..."
if [ -d "$PROJECT_ROOT/logs" ]; then
    CURRENT_LOGS=$(find "$PROJECT_ROOT/logs" -type f -name "*.log" 2>/dev/null || true)
    if [ -n "$CURRENT_LOGS" ]; then
        echo "Active log files (kept):"
        while IFS= read -r logfile; do
            if [ -f "$logfile" ]; then
                SIZE=$(du -h "$logfile" 2>/dev/null | cut -f1)
                AGE=$(find "$logfile" -printf "%Ad/%Am/%AY" 2>/dev/null || echo "unknown")
                echo "  - $logfile ($SIZE, modified: $AGE)"
            fi
        done <<< "$CURRENT_LOGS"
    else
        echo "  No log files found in logs/ directory"
    fi
fi
echo ""

# Summary
echo "=== Cleanup Summary ==="
echo ""
echo "Files Removed: $FILES_REMOVED"
if [ "$TOTAL_SIZE_FREED" -gt 0 ]; then
    SIZE_MB=$((TOTAL_SIZE_FREED / 1024 / 1024))
    SIZE_KB=$((TOTAL_SIZE_FREED / 1024))
    if [ "$SIZE_MB" -gt 0 ]; then
        echo "Space Freed: ${SIZE_MB}MB (${TOTAL_SIZE_FREED} bytes)"
    else
        echo "Space Freed: ${SIZE_KB}KB (${TOTAL_SIZE_FREED} bytes)"
    fi
else
    echo "Space Freed: 0 bytes"
fi
echo ""

if [ "$FILES_REMOVED" -eq 0 ]; then
    echo -e "${GREEN}✅ No cleanup needed - project is already clean!${NC}"
else
    echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
fi
echo ""

