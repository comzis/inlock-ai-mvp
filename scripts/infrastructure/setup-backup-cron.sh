#!/bin/bash
# DEPRECATED: This script is deprecated. Use scripts/backup/install-backup-cron.sh instead.
# This script is kept for backward compatibility but redirects to the new script.

set -e

echo "⚠️  WARNING: This script is deprecated."
echo "Please use: scripts/backup/install-backup-cron.sh"
echo ""
echo "Redirecting to the new script..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Redirect to the new script
exec "$PROJECT_ROOT/scripts/backup/install-backup-cron.sh" "$@"
