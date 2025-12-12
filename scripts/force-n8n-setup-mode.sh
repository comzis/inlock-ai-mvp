#!/bin/bash
# Force n8n into setup mode by ensuring no users exist
# Run: ./scripts/force-n8n-setup-mode.sh

set -euo pipefail

echo "=== Forcing n8n Setup Mode ==="
echo ""

# 1. Check current users
echo "1. Checking existing users..."
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "0")
echo "   Found $USER_COUNT user(s)"
echo ""

if [ "$USER_COUNT" != "0" ]; then
    echo "2. Listing existing users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "rows)" | grep -v "^$" | tail -n +3
    echo ""
    
    read -p "Do you want to delete all users to enable setup mode? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "   Cancelled. Users remain."
        exit 0
    fi
    
    echo "3. Deleting all users..."
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
    echo ""
else
    echo "2. No users found - setup mode should be available"
    echo ""
fi

# 4. Restart n8n
echo "4. Restarting n8n..."
docker compose -f compose/n8n.yml --env-file .env restart n8n 2>&1 >/dev/null
sleep 10
echo "   ✓ n8n restarted"
echo ""

# 5. Verify
echo "5. Verifying setup mode..."
sleep 5
USER_COUNT_AFTER=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "0")
if [ "$USER_COUNT_AFTER" = "0" ]; then
    echo "   ✓ No users - setup mode should be active"
else
    echo "   ⚠️  Still found $USER_COUNT_AFTER user(s)"
fi
echo ""

# 6. Test access
echo "6. Testing access..."
N8N_HTTP=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
if [ "$N8N_HTTP" = "200" ]; then
    echo "   ✓ n8n is accessible (HTTP $N8N_HTTP)"
    echo ""
    echo "   Now visit: https://n8n.inlock.ai"
    echo "   You should see the setup page to create the first user"
else
    echo "   ⚠️  n8n returned HTTP $N8N_HTTP"
    echo "   Check logs: docker logs compose-n8n-1 --tail 50"
fi
echo ""

echo "=== Done ==="
echo ""
echo "If you still see the login page:"
echo "  1. Hard refresh: Ctrl+Shift+R"
echo "  2. Clear browser cache"
echo "  3. Try incognito window"
echo "  4. Check browser console (F12) for errors"
echo ""

