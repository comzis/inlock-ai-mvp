#!/bin/bash
# Force n8n to show setup page by ensuring 0 users and clearing cache
# Run: sudo ./scripts/force-n8n-setup-page.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

cd /home/comzis/inlock-infra

echo "=== Forcing n8n Setup Page ==="
echo ""

# 1. Check current users
echo "1. Checking database users..."
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "0")
echo "   Found $USER_COUNT user(s)"
echo ""

if [ "$USER_COUNT" != "0" ]; then
    echo "2. Deleting all users to show setup page..."
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
    echo "2. ✓ No users found (setup page should show)"
fi
echo ""

# 3. Restart n8n
echo "3. Restarting n8n..."
docker compose -f compose/n8n.yml --env-file .env restart n8n 2>&1 >/dev/null
sleep 10
echo "   ✓ n8n restarted"
echo ""

# 4. Verify
echo "4. Verifying..."
FINAL_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "?")
if [ "$FINAL_COUNT" = "0" ]; then
    echo "   ✓ Database has 0 users"
    echo "   ✓ Setup page should be available"
else
    echo "   ⚠️  Still found $FINAL_COUNT user(s)"
fi
echo ""

# 5. Test access
echo "5. Testing access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ n8n is accessible (HTTP $HTTP_CODE)"
else
    echo "   ⚠️  n8n returned HTTP $HTTP_CODE"
fi
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Wait 30 seconds for n8n to fully start"
echo "2. Visit: https://n8n.inlock.ai"
echo "3. IMPORTANT: Clear browser cache:"
echo "   - Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R)"
echo "   - Or use incognito/private window"
echo "   - Or clear cache: Settings → Privacy → Clear browsing data"
echo ""
echo "4. You should see:"
echo "   - 'Create your account' form (SETUP PAGE)"
echo "   - NOT 'Sign in' form (LOGIN PAGE)"
echo ""
echo "If you still see login page after clearing cache:"
echo "  - Check browser console (F12) for errors"
echo "  - Try different browser"
echo "  - Check: docker logs compose-n8n-1 --tail 50"
echo ""

