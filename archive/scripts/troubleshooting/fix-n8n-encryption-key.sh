#!/bin/bash
# Fix n8n encryption key mismatch
# Run: sudo ./scripts/fix-n8n-encryption-key.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "=== Fixing n8n Encryption Key Mismatch ==="
echo ""

# 1. Stop n8n
echo "1. Stopping n8n..."
cd /home/comzis/inlock-infra
docker compose -f compose/n8n.yml --env-file .env stop n8n 2>&1 >/dev/null || true
sleep 2
echo "   ✓ n8n stopped"
echo ""

# 2. Get encryption key from secret file
echo "2. Reading encryption key..."
ENCRYPTION_KEY=$(cat /home/comzis/apps/secrets-real/n8n-encryption-key | tr -d '\n\r')
if [ -z "$ENCRYPTION_KEY" ]; then
    echo "   ✗ Encryption key file is empty"
    exit 1
fi
echo "   ✓ Encryption key loaded"
echo ""

# 3. Get volume mount point
echo "3. Finding n8n data volume..."
VOLUME_PATH=$(docker volume inspect compose_n8n_data 2>&1 | grep Mountpoint | awk '{print $2}' | tr -d '",')
if [ -z "$VOLUME_PATH" ]; then
    echo "   ✗ Could not find n8n data volume"
    exit 1
fi
echo "   ✓ Volume path: $VOLUME_PATH"
echo ""

# 4. Update config file
echo "4. Updating config file..."
CONFIG_FILE="$VOLUME_PATH/config"
echo "{\"encryptionKey\": \"$ENCRYPTION_KEY\"}" > "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"
chown 1000:1000 "$CONFIG_FILE" 2>/dev/null || true
echo "   ✓ Config file updated"
echo ""

# 5. Verify
echo "5. Verifying config..."
if grep -q "$ENCRYPTION_KEY" "$CONFIG_FILE"; then
    echo "   ✓ Config file contains correct key"
else
    echo "   ⚠️  Config file verification failed"
fi
echo ""

# 6. Start n8n
echo "6. Starting n8n..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 >/dev/null
sleep 5
echo "   ✓ n8n started"
echo ""

# 7. Wait and check
echo "7. Waiting for n8n to initialize..."
sleep 15

if docker ps | grep -q compose-n8n-1; then
    STATUS=$(docker ps | grep compose-n8n-1 | awk '{print $7}')
    if [ "$STATUS" = "(healthy)" ] || [ "$STATUS" = "(health:" ]; then
        echo "   ✓ n8n is running"
    else
        echo "   ⚠️  n8n status: $STATUS"
        echo "   Check logs: docker logs compose-n8n-1 --tail 30"
    fi
else
    echo "   ✗ n8n is not running"
    echo "   Check logs: docker logs compose-n8n-1 --tail 30"
fi
echo ""

echo "=== Done ==="
echo ""
echo "n8n should now start correctly."
echo "Visit https://n8n.inlock.ai"
echo ""
echo "If you have 0 users in the database, you should see the setup page."
echo "If you still see login page, run: ./scripts/force-n8n-setup-mode.sh"
echo ""

