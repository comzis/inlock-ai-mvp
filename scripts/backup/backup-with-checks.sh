#!/bin/bash
# Backup wrapper with pre-flight checks and error handling
# Usage: ./scripts/backup/backup-with-checks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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
READINESS_SCRIPT="$PROJECT_ROOT/scripts/utilities/check-backup-readiness.sh"
if [ ! -x "$READINESS_SCRIPT" ]; then
    error "Backup readiness script not found or not executable: $READINESS_SCRIPT"
fi
if ! "$READINESS_SCRIPT" >> "$LOG_FILE" 2>&1; then
    error "Backup readiness check failed - see $LOG_FILE for details"
fi

# Pre-flight check: Verify services are running
log "Checking service health..."
if ! docker compose -f "$PROJECT_ROOT/compose/services/stack.yml" -f "$PROJECT_ROOT/compose/services/postgres.yml" -f "$PROJECT_ROOT/compose/services/n8n.yml" --env-file "$PROJECT_ROOT/.env" ps | grep -q "Up.*healthy"; then
    log "WARNING: Some services may not be healthy, but proceeding with backup"
fi

# Set GPG recipient
export GPG_RECIPIENT="admin@inlock.ai"

# Run backup
log "Starting encrypted backup..."
cd "$PROJECT_ROOT"

# 1. Database Logical Backups (Safety)
if "$SCRIPT_DIR/backup-databases.sh" >> "$LOG_FILE" 2>&1; then
    log "✅ Database logical backups completed"
else
    error "Database backup failed - see $LOG_FILE. Aborting to preserve previous backups."
fi

# 2. Volume Backups (Assets & Redundancy)
log "Starting volume backup..."
if "$SCRIPT_DIR/backup-volumes.sh" >> "$LOG_FILE" 2>&1; then
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
