#!/bin/bash
# Backup wrapper with pre-flight checks and error handling
# Usage: ./scripts/backup-with-checks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/inlock-backup.log"
ALERT_EMAIL="${BACKUP_ALERT_EMAIL:-}"  # Optional: set to receive alerts

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR: $*"
    if [ -n "$ALERT_EMAIL" ]; then
        echo "Backup failed: $*" | mail -s "INLOCK Backup Failed" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    exit 1
}

log "=== Starting backup with pre-flight checks ==="

# Pre-flight check: Verify backup readiness
if ! "$SCRIPT_DIR/check-backup-readiness.sh" >> "$LOG_FILE" 2>&1; then
    error "Backup readiness check failed - see $LOG_FILE for details"
fi

# Pre-flight check: Verify services are running
log "Checking service health..."
if ! docker compose -f "$SCRIPT_DIR/compose/stack.yml" -f "$SCRIPT_DIR/compose/postgres.yml" -f "$SCRIPT_DIR/compose/n8n.yml" --env-file "$SCRIPT_DIR/.env" ps | grep -q "Up.*healthy"; then
    log "WARNING: Some services may not be healthy, but proceeding with backup"
fi

# Set GPG recipient
export GPG_RECIPIENT="admin@inlock.ai"

# Run backup
log "Starting encrypted backup..."
cd "$SCRIPT_DIR"

# 1. Database Logical Backups (Safety)
if ./scripts/backup-databases.sh >> "$LOG_FILE" 2>&1; then
    log "✅ Database logical backups completed"
else
    error "Database backup failed - see $LOG_FILE. Aborting to preserve previous backups."
fi

# 2. Volume Backups (Assets & Redundancy)
log "Starting volume backup..."
if ./scripts/backup-volumes.sh >> "$LOG_FILE" 2>&1; then
    log "✅ Backup completed successfully"
    
    # Optional: Check backup file exists and is recent
    # Use consistent backup directory (align with other scripts)
    BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/inlock}"
    ENCRYPTED_DIR="${BACKUP_ENCRYPTED_DIR:-$BACKUP_DIR/encrypted}"
    BACKUP_FILE=$(ls -t "$ENCRYPTED_DIR"/volumes-*.tar.gz.gpg 2>/dev/null | head -1)
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "Backup file: $BACKUP_FILE ($BACKUP_SIZE)"
    else
        log "⚠️  WARNING: Backup file not found in expected location: $ENCRYPTED_DIR"
    fi
else
    error "Backup script failed - see $LOG_FILE for details"
fi

log "=== Backup process completed ==="
