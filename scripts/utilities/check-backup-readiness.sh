#!/bin/bash
# Health check script for backup readiness
# Checks GPG key availability and backup script configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "BACKUP READINESS CHECK"
echo "=========================================="
echo ""

# Check GPG key
echo "Checking GPG key for admin@inlock.ai..."
if gpg --list-keys admin@inlock.ai > /dev/null 2>&1; then
    echo "✅ GPG key found for admin@inlock.ai"
    gpg --list-keys admin@inlock.ai | head -3
else
    echo "❌ GPG key NOT found for admin@inlock.ai"
    echo ""
    echo "To import a key, run:"
    echo "  $PROJECT_ROOT/scripts/utilities/import-gpg-key.sh /path/to/admin-inlock-ai.pub"
    echo ""
    exit 1
fi

echo ""

# Check backup script exists (use absolute path resolution)
BACKUP_SCRIPT="$PROJECT_ROOT/scripts/backup/backup-volumes.sh"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "❌ Backup script not found: $BACKUP_SCRIPT"
    echo "   Expected location: scripts/backup/backup-volumes.sh"
    exit 1
fi
echo "✅ Backup script found: $BACKUP_SCRIPT"

# Check backup script is executable
if [ ! -x "$BACKUP_SCRIPT" ]; then
    echo "⚠️  Backup script is not executable, fixing..."
    chmod +x "$BACKUP_SCRIPT"
fi
echo "✅ Backup script is executable"

echo ""
echo "=========================================="
echo "✅ BACKUP SYSTEM READY"
echo "=========================================="
echo ""
echo "You can now run encrypted backups with:"
echo "  $PROJECT_ROOT/scripts/backup/backup-volumes.sh"
