#!/bin/bash
# Fix n8n blank page after login
# Run: ./scripts/fix-n8n-blank-page.sh

set -euo pipefail

echo "=== Fixing n8n Blank Page Issue ==="
echo ""

# 1. Check encryption key
echo "1. Checking encryption key..."
ENCRYPTION_KEY=$(cat /home/comzis/apps/secrets-real/n8n-encryption-key 2>/dev/null | tr -d '\n\r' || echo "")
if [ -z "$ENCRYPTION_KEY" ] || [ "$ENCRYPTION_KEY" = "replace-with-strong-key" ]; then
    echo "   ⚠️  Encryption key is missing or default"
    echo "   Generating new encryption key..."
    # Generate a secure random key
    NEW_KEY=$(openssl rand -base64 32 | tr -d '\n\r')
    echo "$NEW_KEY" > /home/comzis/apps/secrets-real/n8n-encryption-key
    chmod 600 /home/comzis/apps/secrets-real/n8n-encryption-key
    echo "   ✓ New encryption key generated"
    ENCRYPTION_KEY_UPDATED=true
else
    echo "   ✓ Encryption key exists"
    ENCRYPTION_KEY_UPDATED=false
fi
echo ""

# 2. Check n8n is running
echo "2. Checking n8n status..."
if docker ps | grep -q compose-n8n-1; then
    echo "   ✓ n8n is running"
    N8N_RUNNING=true
else
    echo "   ✗ n8n is not running"
    N8N_RUNNING=false
fi
echo ""

# 3. Check database connection
echo "3. Checking database connection..."
if docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT 1;" >/dev/null 2>&1; then
    echo "   ✓ Database connection OK"
else
    echo "   ✗ Database connection failed"
fi
echo ""

# 4. Check API endpoint
echo "4. Testing API endpoint..."
API_RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai/rest/login 2>&1 || echo "000")
if [ "$API_RESPONSE" = "200" ] || [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "405" ]; then
    echo "   ✓ API endpoint responding (HTTP $API_RESPONSE)"
else
    echo "   ⚠️  API endpoint issue (HTTP $API_RESPONSE)"
fi
echo ""

# 5. Clear browser cache suggestion
echo "5. Browser cache..."
echo "   If you see a blank page, try:"
echo "   - Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   - Clear browser cache for n8n.inlock.ai"
echo "   - Try incognito/private window"
echo ""

# 6. Restart n8n if encryption key was updated
if [ "$ENCRYPTION_KEY_UPDATED" = "true" ] && [ "$N8N_RUNNING" = "true" ]; then
    echo "6. Restarting n8n with new encryption key..."
    docker compose -f compose/n8n.yml --env-file .env restart n8n 2>&1 >/dev/null
    sleep 10
    echo "   ✓ n8n restarted"
    echo ""
fi

# 7. Check for JavaScript errors
echo "7. Checking static assets..."
ASSET_RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai/assets/index-qmt2pxHw.js 2>&1 || echo "000")
if [ "$ASSET_RESPONSE" = "200" ]; then
    echo "   ✓ Static assets loading"
else
    echo "   ⚠️  Static assets may have issues (HTTP $ASSET_RESPONSE)"
    echo "   Asset paths may have changed in new version"
fi
echo ""

# 8. Check n8n logs for errors
echo "8. Recent n8n logs:"
docker logs compose-n8n-1 --tail 20 2>&1 | tail -10
echo ""

echo "=== Troubleshooting Steps ==="
echo ""
echo "If blank page persists:"
echo ""
echo "1. Check browser console (F12) for JavaScript errors"
echo "2. Verify you're accessing from allowed IP (Tailscale or server IP)"
echo "3. Try accessing directly: docker port compose-n8n-1 5678"
echo "4. Check n8n logs: docker logs compose-n8n-1 --tail 50"
echo "5. Restart n8n: docker compose -f compose/n8n.yml --env-file .env restart n8n"
echo ""
echo "Common causes:"
echo "  - Browser cache (hard refresh)"
echo "  - JavaScript assets not loading"
echo "  - API endpoint issues"
echo "  - Encryption key problems"
echo ""

