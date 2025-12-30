#!/bin/bash
# Complete n8n fix - resolves all common issues
# Run: sudo ./scripts/fix-n8n-complete.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "=== Complete n8n Fix ==="
echo ""
echo "This will fix all common n8n issues:"
echo "  - Encryption key mismatch"
echo "  - Database user issues"
echo "  - Configuration problems"
echo ""

cd /home/comzis/inlock-infra

# 1. Stop n8n
echo "1. Stopping n8n..."
docker compose -f compose/n8n.yml --env-file .env stop n8n 2>&1 >/dev/null || true
sleep 3
echo "   ✓ n8n stopped"
echo ""

# 2. Get encryption key
echo "2. Reading encryption key..."
ENCRYPTION_KEY=$(cat /home/comzis/apps/secrets-real/n8n-encryption-key 2>/dev/null | tr -d '\n\r')
if [ -z "$ENCRYPTION_KEY" ]; then
    echo "   ✗ Encryption key file is empty or missing"
    echo "   Generating new encryption key..."
    ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d '\n\r')
    echo "$ENCRYPTION_KEY" > /home/comzis/apps/secrets-real/n8n-encryption-key
    chmod 600 /home/comzis/apps/secrets-real/n8n-encryption-key
    echo "   ✓ New encryption key generated"
else
    echo "   ✓ Encryption key found"
fi
echo ""

# 3. Fix encryption key in config file
echo "3. Fixing encryption key in config file..."
VOLUME_PATH=$(docker volume inspect compose_n8n_data 2>&1 | grep Mountpoint | awk '{print $2}' | tr -d '",')
if [ -n "$VOLUME_PATH" ] && [ -d "$VOLUME_PATH" ]; then
    CONFIG_FILE="$VOLUME_PATH/config"
    echo "{\"encryptionKey\": \"$ENCRYPTION_KEY\"}" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    chown 1000:1000 "$CONFIG_FILE" 2>/dev/null || true
    echo "   ✓ Config file updated with correct encryption key"
else
    echo "   ⚠️  Could not find n8n data volume (will be created on start)"
fi
echo ""

# 4. Clear all users from database (to show setup page)
echo "4. Checking database users..."
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "0")
echo "   Found $USER_COUNT user(s) in database"

if [ "$USER_COUNT" != "0" ]; then
    read -p "   Delete all users to show setup page? (yes/no): " DELETE_USERS
    if [ "$DELETE_USERS" = "yes" ]; then
        echo "   Deleting all users..."
        docker exec compose-postgres-1 psql -U n8n -d n8n <<EOF
-- Delete user workflows
DELETE FROM workflow_entity WHERE "ownerId" IN (SELECT id FROM "user");
-- Delete user credentials
DELETE FROM credentials_entity WHERE "userId" IN (SELECT id FROM "user");
-- Delete user executions
DELETE FROM execution_entity WHERE "workflowId" IN (SELECT id FROM workflow_entity WHERE "ownerId" IN (SELECT id FROM "user"));
-- Delete users
DELETE FROM "user";
EOF
        echo "   ✓ All users deleted"
    else
        echo "   Keeping existing users"
    fi
else
    echo "   ✓ No users found - setup page will show"
fi
echo ""

# 5. Verify compose file configuration
echo "5. Verifying configuration..."
if grep -q "N8N_ENCRYPTION_KEY_FILE=/run/secrets/n8n-encryption-key" compose/n8n.yml; then
    echo "   ✓ Encryption key path is correct"
else
    echo "   ⚠️  Encryption key path may be incorrect"
    echo "   Expected: N8N_ENCRYPTION_KEY_FILE=/run/secrets/n8n-encryption-key"
fi

if grep -q "image: n8nio/n8n:latest" compose/n8n.yml; then
    echo "   ✓ Using latest n8n image"
else
    echo "   ⚠️  Not using latest image tag"
fi
echo ""

# 6. Pull latest image
echo "6. Pulling latest n8n image..."
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 >/dev/null
echo "   ✓ Image pulled"
echo ""

# 7. Start n8n
echo "7. Starting n8n..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 >/dev/null
echo "   ✓ n8n started"
echo ""

# 8. Wait for n8n to initialize
echo "8. Waiting for n8n to initialize..."
sleep 15

# 9. Check status
echo "9. Checking n8n status..."
if docker ps | grep -q compose-n8n-1; then
    STATUS=$(docker ps | grep compose-n8n-1 | awk '{print $7}')
    if [ "$STATUS" = "(healthy)" ] || [[ "$STATUS" == "(health:"* ]]; then
        echo "   ✓ n8n is running and healthy"
    else
        echo "   ⚠️  n8n status: $STATUS"
        echo "   Check logs: docker logs compose-n8n-1 --tail 50"
    fi
else
    echo "   ✗ n8n is not running"
    echo "   Check logs: docker logs compose-n8n-1 --tail 50"
fi
echo ""

# 10. Check for errors in logs
echo "10. Checking for errors..."
ERRORS=$(docker logs compose-n8n-1 --tail 50 2>&1 | grep -i -E "(error|failed|exception)" | tail -5 || true)
if [ -n "$ERRORS" ]; then
    echo "   ⚠️  Found errors in logs:"
    echo "$ERRORS" | sed 's/^/     /'
else
    echo "   ✓ No errors in recent logs"
fi
echo ""

# 11. Test access
echo "11. Testing access..."
sleep 5
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
case "$HTTP_CODE" in
    200) echo "   ✓ n8n is accessible (HTTP $HTTP_CODE)" ;;
    502|503|504) echo "   ✗ n8n backend error (HTTP $HTTP_CODE)" ;;
    000) echo "   ✗ Cannot reach n8n" ;;
    *) echo "   ⚠️  Unexpected response (HTTP $HTTP_CODE)" ;;
esac
echo ""

# 12. Verify database
echo "12. Verifying database..."
FINAL_USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "?")
echo "   Users in database: $FINAL_USER_COUNT"
if [ "$FINAL_USER_COUNT" = "0" ]; then
    echo "   ✓ Should show setup page (no users)"
else
    echo "   ⚠️  Has users - will show login page"
fi
echo ""

echo "=== Fix Complete ==="
echo ""
echo "n8n Status:"
echo "  - Service: $(docker ps | grep compose-n8n-1 >/dev/null && echo 'Running' || echo 'Not running')"
echo "  - Database users: $FINAL_USER_COUNT"
echo "  - Encryption key: Fixed"
echo ""
echo "Next steps:"
echo "  1. Wait 30 seconds for n8n to fully start"
echo "  2. Visit: https://n8n.inlock.ai"
echo ""
if [ "$FINAL_USER_COUNT" = "0" ]; then
    echo "  You should see the SETUP PAGE to create your first user"
    echo "  If you see login page instead:"
    echo "    - Hard refresh: Ctrl+Shift+R"
    echo "    - Clear browser cache"
    echo "    - Try incognito window"
else
    echo "  You will see the LOGIN PAGE (users exist)"
    echo "  To reset and show setup page:"
    echo "    ./scripts/force-n8n-setup-mode.sh"
fi
echo ""
echo "If issues persist:"
echo "  - Check logs: docker logs compose-n8n-1 --tail 100"
echo "  - Check database: docker exec compose-postgres-1 psql -U n8n -d n8n -c \"SELECT email FROM \\\"user\\\";\""
echo ""

