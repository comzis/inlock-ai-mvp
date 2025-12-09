#!/bin/bash
# Health check script for backup readiness
# Checks GPG key availability and backup script configuration

set -e

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
    echo "  ./scripts/import-gpg-key.sh /path/to/admin-inlock-ai.pub"
    echo ""
    exit 1
fi

echo ""

# Check backup script exists
if [ ! -f "scripts/backup-volumes.sh" ]; then
    echo "❌ Backup script not found: scripts/backup-volumes.sh"
    exit 1
fi
echo "✅ Backup script found"

# Check backup script is executable
if [ ! -x "scripts/backup-volumes.sh" ]; then
    echo "⚠️  Backup script is not executable, fixing..."
    chmod +x scripts/backup-volumes.sh
fi
echo "✅ Backup script is executable"

echo ""
echo "=========================================="
echo "✅ BACKUP SYSTEM READY"
echo "=========================================="
echo ""
echo "You can now run encrypted backups with:"
echo "  ./scripts/backup-volumes.sh"
