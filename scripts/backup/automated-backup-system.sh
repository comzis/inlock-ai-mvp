#!/bin/bash
#
# Automated backup system
# Coordinates all backup operations with scheduling, verification, and retention
#
# Usage: ./scripts/backup/automated-backup-system.sh [OPTIONS]
# Options:
#   --backup-type <all|databases|volumes|full>  Type of backup to run
#   --verify                                    Verify backups after creation
#   --sync-offsite                             Sync backups to off-site storage
#   --cleanup                                  Clean up old backups

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/var/log/inlock-backup-system.log"
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




