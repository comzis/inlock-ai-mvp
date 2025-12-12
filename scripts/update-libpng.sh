#!/bin/bash
#
# Update libpng16-16 Package
# Quick update script for libpng library (no reboot required)
#
# Usage: sudo ./scripts/update-libpng.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/libpng-update-$(date +%Y%m%d-%H%M%S).log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

log "=== libpng16-16 Update Script ==="
log ""

# Check current version
CURRENT_VERSION=$(dpkg -l | grep libpng16-16 | awk '{print $3}')
log "Current version: $CURRENT_VERSION"

# Update package list
log "Updating package list..."
apt update -qq > /dev/null 2>&1

# Check if update is available
if apt list --upgradable 2>/dev/null | grep -q libpng16-16; then
    log "Update available for libpng16-16"
    
    # Update the package
    log "Updating libpng16-16..."
    if apt install -y libpng16-16 2>&1 | tee -a "$LOG_FILE"; then
        NEW_VERSION=$(dpkg -l | grep libpng16-16 | awk '{print $3}')
        log "${GREEN}✓ Successfully updated libpng16-16${NC}"
        log "Old version: $CURRENT_VERSION"
        log "New version: $NEW_VERSION"
    else
        log "${RED}✗ Error updating libpng16-16${NC}"
        exit 1
    fi
else
    log "${GREEN}libpng16-16 is already up to date${NC}"
fi

log ""
log "=== Update Complete ==="
log "No reboot required for this update"
log "Log file: $LOG_FILE"
