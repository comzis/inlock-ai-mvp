#!/bin/bash
# Verify that a recent Mailcow backup exists (runs after backup cron, e.g. 04:00).
# On failure: log to syslog and optionally alert.
set -euo pipefail

BACKUP_DIR="${MAILCOW_BACKUP_LOCATION:-/home/comzis/mailcow/backups}"
# -mtime -1 = modified in last 24 hours
MAX_AGE_DAYS="${MAX_AGE_DAYS:-1}"
TAG="mailcow-backup"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SH="${ALERT_SH:-$SCRIPT_DIR/alert.sh}"

alert_critical() {
  local subject="$1"
  local message="$2"
  if [ -x "$ALERT_SH" ]; then
    ALERT_SEVERITY=critical "$ALERT_SH" "$subject" "$message" || true
  fi
}

if [ ! -d "$BACKUP_DIR" ]; then
  logger -t "$TAG" "FAIL: backup directory missing: $BACKUP_DIR"
  alert_critical "mailcow backup missing" "Backup directory missing: $BACKUP_DIR"
  exit 1
fi

# Any mailcow-* dir modified within last MAX_AGE_DAYS?
if find "$BACKUP_DIR" -maxdepth 1 -type d -name "mailcow-*" -mtime "-${MAX_AGE_DAYS}" -print -quit | grep -q .; then
  logger -t "$TAG" "OK: recent backup found in $BACKUP_DIR"
  exit 0
fi

logger -t "$TAG" "FAIL: no recent backup (no mailcow-* dir in $BACKUP_DIR with mtime within ${MAX_AGE_DAYS} day(s))"
alert_critical "mailcow backup stale" "No mailcow-* dir in $BACKUP_DIR modified within ${MAX_AGE_DAYS} day(s)."
exit 1
