#!/bin/bash
#
# Update libexpat1 Package
# Quick update script for libexpat1 (no reboot required)
#
# Usage: sudo ./scripts/maintenance/update-libexpat1.sh

set -e

LOG_FILE="/tmp/libexpat1-update-$(date +%Y%m%d-%H%M%S).log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

log "=== libexpat1 Update Script ==="
log ""

CURRENT_VERSION="$(dpkg -l | awk '$2=="libexpat1" {print $3; exit}')"
if [ -z "$CURRENT_VERSION" ]; then
    log "${YELLOW}libexpat1 is not installed (installing)${NC}"
else
    log "Current version: $CURRENT_VERSION"
fi

log "Updating package list..."
apt update -qq > /dev/null 2>&1

if apt list --upgradable 2>/dev/null | grep -q "^libexpat1/"; then
    log "Update available for libexpat1"
    log "Updating libexpat1..."
    if apt install -y libexpat1 2>&1 | tee -a "$LOG_FILE"; then
        NEW_VERSION="$(dpkg -l | awk '$2=="libexpat1" {print $3; exit}')"
        log "${GREEN}✓ Successfully updated libexpat1${NC}"
        [ -n "$CURRENT_VERSION" ] && log "Old version: $CURRENT_VERSION"
        log "New version: $NEW_VERSION"
    else
        log "${RED}✗ Error updating libexpat1${NC}"
        exit 1
    fi
else
    log "${GREEN}libexpat1 is already up to date${NC}"
fi

log ""
log "=== Update Complete ==="
log "No reboot required for this update"
log "Log file: $LOG_FILE"
