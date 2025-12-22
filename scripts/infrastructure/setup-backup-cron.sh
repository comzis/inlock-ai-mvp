#!/bin/bash
# Setup cron job for automated backups
# Usage: ./scripts/setup-backup-cron.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_TIME="${BACKUP_CRON_TIME:-0 2}"  # Default: 2 AM daily
CRON_ENTRY="$CRON_TIME * * * $SCRIPT_DIR/scripts/backup-with-checks.sh >> /var/log/inlock-backup.log 2>&1"

echo "Setting up cron job for automated backups..."
echo "Schedule: Daily at 2 AM (customize with BACKUP_CRON_TIME env var)"
echo ""

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "backup-with-checks.sh"; then
    echo "⚠️  Cron entry already exists. Removing old entry..."
    crontab -l 2>/dev/null | grep -v "backup-with-checks.sh" | crontab -
fi

# Add new cron entry
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo "✅ Cron job installed"
echo ""
echo "Current crontab:"
crontab -l | grep "backup-with-checks"
echo ""
echo "To view backup logs: tail -f /var/log/inlock-backup.log"
echo "To remove: crontab -e (then delete the backup line)"
