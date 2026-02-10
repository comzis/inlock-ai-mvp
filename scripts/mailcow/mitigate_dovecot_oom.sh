#!/bin/bash
# Dovecot OOM Mitigation Script
# Restores mailcow.conf from archive and disables ClamAV/FTS to resolve OOM issues

set -euo pipefail

ARCHIVE_PATH="/home/comzis/archive/cleanup_20260111/mailcow"
MAILCOW_PATH="/home/comzis/mailcow"
CONFIG_FILE="$MAILCOW_PATH/mailcow.conf"

echo "========================================="
echo "Dovecot OOM Mitigation"
echo "========================================="
echo ""

# Check if we can access the server
echo "Note: This script needs to be run ON THE SERVER with sudo access"
echo ""
echo "Commands to run on the server:"
echo ""
echo "1. Restore configuration files from archive:"
echo "   sudo cp -rn $ARCHIVE_PATH/* $MAILCOW_PATH/"
echo ""
echo "2. Disable ClamAV (reduce memory usage):"
echo "   sudo sed -i 's/^SKIP_CLAMD=n/SKIP_CLAMD=y/' $CONFIG_FILE"
echo ""
echo "3. Disable FTS (reduce memory usage):"
echo "   sudo sed -i 's/^SKIP_FTS=n/SKIP_FTS=y/' $CONFIG_FILE"
echo ""
echo "4. Verify changes:"
echo "   grep -E '^SKIP_CLAMD=|^SKIP_FTS=' $CONFIG_FILE"
echo ""
echo "5. Restart Mailcow services:"
echo "   cd $MAILCOW_PATH"
echo "   docker compose down"
echo "   docker compose up -d"
echo ""
echo "6. Wait for services to start (30-60 seconds)"
echo ""
echo "7. Check Dovecot status:"
echo "   docker ps --filter 'name=dovecot' --format 'table {{.Names}}\t{{.Status}}'"
echo ""

echo "========================================="
echo "One-liner command (run on server):"
echo "========================================="
echo ""
echo "sudo cp -rn $ARCHIVE_PATH/* $MAILCOW_PATH/ && \\"
echo "sudo sed -i 's/^SKIP_CLAMD=n/SKIP_CLAMD=y/' $CONFIG_FILE && \\"
echo "sudo sed -i 's/^SKIP_FTS=n/SKIP_FTS=y/' $CONFIG_FILE && \\"
echo "cd $MAILCOW_PATH && docker compose up -d"
echo ""
