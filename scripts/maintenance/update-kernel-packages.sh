#!/bin/bash
#
# Update Kernel Packages Script
# Safely updates kernel packages and optionally reboots
#
# Usage:
#   ./scripts/update-kernel-packages.sh              # Update without reboot
#   ./scripts/update-kernel-packages.sh --reboot     # Update and reboot
#   ./scripts/update-kernel-packages.sh --dry-run    # Show what would be updated

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/kernel-update-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
AUTO_REBOOT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --reboot)
            AUTO_REBOOT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--reboot] [--dry-run]"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

log "=== Kernel Package Update Script ==="
log "Started by: $(whoami)"
log "Dry run: $DRY_RUN"
log "Auto reboot: $AUTO_REBOOT"
log ""

# Check current kernel
CURRENT_KERNEL=$(uname -r)
log "Current kernel: $CURRENT_KERNEL"

# Check available updates
log "Checking for available updates..."
apt update -qq > /dev/null 2>&1

# List kernel packages that can be updated
KERNEL_PACKAGES=$(apt list --upgradable 2>/dev/null | grep -E "^linux-(headers|image|virtual)" | cut -d'/' -f1 | tr '\n' ' ')

if [ -z "$KERNEL_PACKAGES" ]; then
    log "${GREEN}No kernel packages to update${NC}"
    exit 0
fi

log "Packages to update: $KERNEL_PACKAGES"
log ""

# Show what will be updated
log "=== Packages to be updated ==="
apt list --upgradable 2>/dev/null | grep -E "^linux-(headers|image|virtual)" || true
log ""

if [ "$DRY_RUN" = true ]; then
    log "${YELLOW}DRY RUN: Would update the above packages${NC}"
    exit 0
fi

# Confirm before proceeding
if [ "$AUTO_REBOOT" = false ]; then
    echo -e "${YELLOW}This will update kernel packages. A reboot will be required after update.${NC}"
    echo -e "${YELLOW}Continue? (y/N): ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Update cancelled by user"
        exit 0
    fi
fi

# Backup current kernel info
log "Backing up current kernel information..."
echo "Current kernel: $CURRENT_KERNEL" > /tmp/kernel-backup-info.txt
dpkg -l | grep -E "linux-(headers|image)" >> /tmp/kernel-backup-info.txt
log "Backup saved to: /tmp/kernel-backup-info.txt"

# Update packages
log "Updating kernel packages..."
if apt upgrade -y $KERNEL_PACKAGES 2>&1 | tee -a "$LOG_FILE"; then
    log "${GREEN}✓ Kernel packages updated successfully${NC}"
else
    log "${RED}✗ Error updating kernel packages${NC}"
    exit 1
fi

# Show new kernel version
NEW_KERNEL=$(ls /boot/vmlinuz-* | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')
log "New kernel available: $NEW_KERNEL"

# Check if reboot is needed
if [ "$CURRENT_KERNEL" != "$NEW_KERNEL" ]; then
    log "${YELLOW}⚠ Reboot required to use new kernel${NC}"
    log "Current: $CURRENT_KERNEL"
    log "New:     $NEW_KERNEL"
    
    if [ "$AUTO_REBOOT" = true ]; then
        log "Rebooting in 10 seconds... (Ctrl+C to cancel)"
        sleep 10
        log "Rebooting now..."
        reboot
    else
        log ""
        log "${YELLOW}To complete the update, reboot the server:${NC}"
        log "  sudo reboot"
        log ""
        log "After reboot, verify with: uname -r"
    fi
else
    log "${GREEN}No reboot needed - kernel version unchanged${NC}"
fi

log ""
log "=== Update Complete ==="
log "Log file: $LOG_FILE"
log "Backup info: /tmp/kernel-backup-info.txt"
