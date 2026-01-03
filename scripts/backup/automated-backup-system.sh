#!/usr/bin/env bash
# Purpose: Coordinate all backup operations with scheduling, verification, and retention
# Usage: ./scripts/backup/automated-backup-system.sh [OPTIONS]
#   Options:
#     --backup-type <all|databases|volumes|full>  Type of backup to run
#     --verify                                    Verify backups after creation
#     --sync-offsite                             Sync backups to off-site storage
#     --cleanup                                  Clean up old backups
# Dependencies: backup-databases.sh, backup-volumes.sh, gpg
# Environment Variables:
#   BACKUP_TYPE - Type of backup (default: all)
#   VERIFY_BACKUPS - Verify backups after creation (default: false)
#   SYNC_OFFSITE - Sync to off-site storage (default: false)
#   CLEANUP_OLD - Clean up old backups (default: false)
#   BACKUP_DIR - Backup directory (default: $HOME/backups/inlock)
# Exit Codes: 0=success, 1=error
# Author: INLOCK Infrastructure Team
# Last Updated: 2026-01-03

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Log destinations (try project logs first, then /tmp fallback)
LOG_DIR_PRIMARY="$PROJECT_ROOT/logs"
LOG_DIR_FALLBACK="/tmp/inlock-logs"
LOG_FILE_PRIMARY="$LOG_DIR_PRIMARY/inlock-backup-system.log"
LOG_FILE_FALLBACK="$LOG_DIR_FALLBACK/inlock-backup-system.log"

# Pick a writable log file
if mkdir -p "$LOG_DIR_PRIMARY" && touch "$LOG_FILE_PRIMARY" >/dev/null 2>&1; then
  LOG_DIR="$LOG_DIR_PRIMARY"
  LOG_FILE="$LOG_FILE_PRIMARY"
else
  mkdir -p "$LOG_DIR_FALLBACK"
  LOG_DIR="$LOG_DIR_FALLBACK"
  LOG_FILE="$LOG_FILE_FALLBACK"
fi

# Enable trace to log for debugging
exec 3>&1 4>&2
exec > >(tee -a "$LOG_FILE") 2>&1
set -x
echo "=== backup start $(date -Iseconds) ==="
BACKUP_TYPE="${BACKUP_TYPE:-all}"
VERIFY_BACKUPS="${VERIFY_BACKUPS:-false}"
SYNC_OFFSITE="${SYNC_OFFSITE:-false}"
CLEANUP_OLD="${CLEANUP_OLD:-false}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --verify)
            VERIFY_BACKUPS=true
            shift
            ;;
        --sync-offsite)
            SYNC_OFFSITE=true
            shift
            ;;
        --cleanup)
            CLEANUP_OLD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR: $*"
    exit 1
}

log "=========================================="
log "  Automated Backup System"
log "=========================================="
log "Backup type: $BACKUP_TYPE"
log "Verify: $VERIFY_BACKUPS"
log "Sync off-site: $SYNC_OFFSITE"
log "Cleanup: $CLEANUP_OLD"
log ""

cd "$PROJECT_ROOT"

# Monitor Tailscale status before backup (to detect impact)
monitor_tailscale_status() {
    local phase="$1"
    log "--- Tailscale Status ($phase) ---"
    if command -v tailscale >/dev/null 2>&1; then
        if tailscale status >/dev/null 2>&1; then
            local status=$(tailscale status --json 2>/dev/null | grep -o '"Self":{[^}]*}' | head -1 || echo "")
            if [ -n "$status" ]; then
                log "  Tailscale: Connected"
                local ip=$(tailscale ip -4 2>/dev/null || echo "unknown")
                log "  Tailscale IP: $ip"
            else
                log "  Tailscale: Status check failed"
            fi
        else
            log "  Tailscale: Not running or not authenticated"
        fi
    else
        log "  Tailscale: Not installed"
    fi
    log ""
}

# Check Tailscale status before backup
monitor_tailscale_status "Pre-Backup"

# Run backups based on type
if [ "$BACKUP_TYPE" = "all" ] || [ "$BACKUP_TYPE" = "databases" ] || [ "$BACKUP_TYPE" = "full" ]; then
    log "Starting database backups..."
    
    if [ -f "$SCRIPT_DIR/backup-databases.sh" ]; then
        bash "$SCRIPT_DIR/backup-databases.sh" >> "$LOG_FILE" 2>&1 || {
            error "Database backup failed"
        }
        log "✓ Database backups completed"
    else
        log "⚠️  Database backup script not found"
    fi
    echo ""
fi

if [ "$BACKUP_TYPE" = "all" ] || [ "$BACKUP_TYPE" = "volumes" ] || [ "$BACKUP_TYPE" = "full" ]; then
    log "Starting volume backups..."
    
    if [ -f "$SCRIPT_DIR/backup-volumes.sh" ]; then
        bash "$SCRIPT_DIR/backup-volumes.sh" >> "$LOG_FILE" 2>&1 || {
            error "Volume backup failed"
        }
        log "✓ Volume backups completed"
    else
        log "⚠️  Volume backup script not found"
    fi
    echo ""
fi

# Verify backups
if [ "$VERIFY_BACKUPS" = "true" ]; then
    log "Verifying backups..."
    
    if [ -f "$SCRIPT_DIR/verify-backups.sh" ]; then
        bash "$SCRIPT_DIR/verify-backups.sh" >> "$LOG_FILE" 2>&1 || {
            log "⚠️  Backup verification found issues"
        }
        log "✓ Backup verification completed"
    else
        log "⚠️  Backup verification script not found"
    fi
    echo ""
fi

# Sync to off-site storage
if [ "$SYNC_OFFSITE" = "true" ]; then
    log "Syncing backups to off-site storage..."
    
    if [ -f "$SCRIPT_DIR/sync-backups-offsite.sh" ]; then
        bash "$SCRIPT_DIR/sync-backups-offsite.sh" >> "$LOG_FILE" 2>&1 || {
            log "⚠️  Off-site sync failed (non-fatal)"
        }
        log "✓ Off-site sync completed"
    else
        log "⚠️  Off-site sync script not found"
    fi
    echo ""
fi

# Cleanup old backups
if [ "$CLEANUP_OLD" = "true" ]; then
    log "Cleaning up old backups..."
    
    if [ -f "$SCRIPT_DIR/cleanup-old-backups.sh" ]; then
        bash "$SCRIPT_DIR/cleanup-old-backups.sh" >> "$LOG_FILE" 2>&1 || {
            log "⚠️  Cleanup failed (non-fatal)"
        }
        log "✓ Cleanup completed"
    else
        log "⚠️  Cleanup script not found"
    fi
    echo ""
fi

# Check Tailscale status after backup
monitor_tailscale_status "Post-Backup"

log "=========================================="
log "  Backup System Complete"
log "=========================================="
log ""

# Summary
log "Summary:"
log "  Backup type: $BACKUP_TYPE"
log "  Verification: $([ "$VERIFY_BACKUPS" = "true" ] && echo "Yes" || echo "No")"
log "  Off-site sync: $([ "$SYNC_OFFSITE" = "true" ] && echo "Yes" || echo "No")"
log "  Cleanup: $([ "$CLEANUP_OLD" = "true" ] && echo "Yes" || echo "No")"
log ""

# Check disk space
DISK_USAGE=$(df -h /var/backups 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
if [ "$DISK_USAGE" -gt 80 ]; then
    log "⚠️  WARNING: Disk usage is ${DISK_USAGE}%"
    log "  Consider cleaning up old backups"
fi

log "Log file: $LOG_FILE"
log ""











