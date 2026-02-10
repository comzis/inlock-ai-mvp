#!/bin/bash
# Re-enable ClamAV and FTS After Memory Increase
# Use this script after increasing server RAM

set -euo pipefail

MAILCOW_DIR="/home/comzis/mailcow"
CONFIG_FILE="$MAILCOW_DIR/mailcow.conf"

echo "========================================="
echo "Re-enable ClamAV and FTS"
echo "========================================="
echo ""
echo "⚠️  WARNING: Only run this AFTER increasing server RAM!"
echo ""
echo "Recommended RAM: 6GB-8GB minimum"
echo ""

# Check if running on server
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: mailcow.conf not found"
    echo "Run this script ON THE SERVER (not from remote)"
    exit 1
fi

# Check memory (optional warning)
echo "Checking memory..."
FREE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')

echo "Total RAM: ${TOTAL_MEM}MB"
echo "Available RAM: ${FREE_MEM}MB"
echo ""

if [ "$TOTAL_MEM" -lt 6144 ]; then
    echo "⚠️  WARNING: Total RAM is less than 6GB (${TOTAL_MEM}MB)"
    echo "Recommended: At least 6GB RAM for ClamAV + FTS"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Re-enable ClamAV
echo "Re-enabling ClamAV..."
sudo sed -i 's/^SKIP_CLAMD=y/SKIP_CLAMD=n/' "$CONFIG_FILE"

# Re-enable FTS
echo "Re-enabling FTS..."
sudo sed -i 's/^SKIP_FTS=y/SKIP_FTS=n/' "$CONFIG_FILE"

# Verify changes
echo ""
echo "Verifying configuration changes..."
sudo grep -E '^SKIP_CLAMD=|^SKIP_FTS=' "$CONFIG_FILE"

echo ""
echo "Configuration updated. Restarting services..."
cd "$MAILCOW_DIR"
docker compose down
docker compose up -d

echo ""
echo "✅ Services restarted. Waiting 60 seconds for services to start..."
sleep 60

# Verify services
echo ""
echo "Verifying services..."
echo ""
echo "ClamAV status:"
docker ps --filter 'name=clamd' --format 'table {{.Names}}\t{{.Status}}' || echo "ClamAV not running"

echo ""
echo "Dovecot status:"
docker ps --filter 'name=dovecot' --format 'table {{.Names}}\t{{.Status}}' || echo "Dovecot not running"

echo ""
echo "Memory usage:"
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}' | grep -E 'NAME|clamd|dovecot' | head -5

echo ""
echo "========================================="
echo "✅ Re-enable Complete"
echo "========================================="
echo ""
echo "If ClamAV or Dovecot are not running, check logs:"
echo "  docker logs mailcowdockerized-clamd-mailcow-1 --tail 50"
echo "  docker logs mailcowdockerized-dovecot-mailcow-1 --tail 50"
