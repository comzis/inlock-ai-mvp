#!/usr/bin/env bash
set -euo pipefail

# Monitor Tailscale status during backup operations
# This helps identify if backups are causing network interface churn

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-/tmp/tailscale-backup-monitor.log}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_tailscale_status() {
    if ! command -v tailscale >/dev/null 2>&1; then
        echo -e "${RED}Tailscale not installed${NC}"
        return 1
    fi

    if ! tailscale status >/dev/null 2>&1; then
        echo -e "${RED}Tailscale not running or not authenticated${NC}"
        return 1
    fi

    local ip=$(tailscale ip -4 2>/dev/null || echo "unknown")
    local status=$(tailscale status --json 2>/dev/null | jq -r '.Self.Online' 2>/dev/null || echo "unknown")
    
    if [ "$status" = "true" ]; then
        echo -e "${GREEN}Tailscale: Connected (IP: $ip)${NC}"
        return 0
    else
        echo -e "${YELLOW}Tailscale: Status unknown (IP: $ip)${NC}"
        return 1
    fi
}

monitor_interface_changes() {
    log "Monitoring network interface changes..."
    
    # Get initial interface count
    local initial_count=$(ip link show | grep -c "^[0-9]" || echo "0")
    log "Initial network interfaces: $initial_count"
    
    # Monitor for 60 seconds
    local end_time=$(($(date +%s) + 60))
    local change_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        local current_count=$(ip link show | grep -c "^[0-9]" || echo "0")
        if [ "$current_count" -ne "$initial_count" ]; then
            change_count=$((change_count + 1))
            log "⚠️  Network interface count changed: $initial_count -> $current_count"
            initial_count=$current_count
        fi
        sleep 5
    done
    
    if [ "$change_count" -eq 0 ]; then
        log "✅ No network interface changes detected"
    else
        log "⚠️  Detected $change_count network interface changes"
    fi
}

check_tailscale_rebinds() {
    log "Checking Tailscale rebind events..."
    
    # Check for recent rebind events in journal
    local rebind_count=$(journalctl -u tailscaled --since "5 minutes ago" 2>/dev/null | grep -c "Rebind" || echo "0")
    
    if [ "$rebind_count" -eq 0 ]; then
        log "✅ No Tailscale rebind events in last 5 minutes"
    else
        log "⚠️  Detected $rebind_count Tailscale rebind events in last 5 minutes"
        log "Recent rebind events:"
        journalctl -u tailscaled --since "5 minutes ago" 2>/dev/null | grep "Rebind" | tail -5 | while read line; do
            log "  $line"
        done
    fi
}

# Main monitoring function
main() {
    echo "=== Tailscale Backup Impact Monitor ==="
    echo ""
    
    log "Starting Tailscale status check..."
    check_tailscale_status
    echo ""
    
    log "Checking for recent rebind events..."
    check_tailscale_rebinds
    echo ""
    
    log "Monitoring network interface changes (60 seconds)..."
    monitor_interface_changes
    echo ""
    
    log "Final Tailscale status check..."
    check_tailscale_status
    echo ""
    
    log "=== Monitoring Complete ==="
    log "Log file: $LOG_FILE"
}

main "$@"

