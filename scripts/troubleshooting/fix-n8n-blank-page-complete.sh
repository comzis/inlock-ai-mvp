#!/bin/bash
# Fix n8n blank page issue
# Run: sudo ./scripts/fix-n8n-blank-page-complete.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "=== Fixing n8n Blank Page ==="
echo ""

cd /home/comzis/inlock-infra

# 1. Check n8n status
echo "1. Checking n8n status..."
if docker ps | grep -q compose-n8n-1; then
    STATUS=$(docker ps | grep compose-n8n-1 | awk '{print $7}')
    echo "   Status: $STATUS"
    if [ "$STATUS" != "(healthy)" ] && [[ "$STATUS" != "(health:"* ]]; then
        echo "   ⚠️  n8n is not healthy"
    fi
else
    echo "   ✗ n8n is not running"
    exit 1
fi
echo ""

# 2. Check for real errors (not license warnings)
echo "2. Checking for errors..."
ERRORS=$(docker logs compose-n8n-1 --tail 200 2>&1 | grep -i -E "(error|exception|fatal)" | grep -v "license SDK" | tail -10 || true)
if [ -n "$ERRORS" ]; then
    echo "   ⚠️  Found errors:"
    echo "$ERRORS" | sed 's/^/     /'
else
    echo "   ✓ No critical errors (license SDK warnings are harmless)"
fi
echo ""

# 3. Check database
echo "3. Checking database..."
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "?")
echo "   Users in database: $USER_COUNT"
echo ""

# 4. Check API endpoints
echo "4. Testing API endpoints..."
API_ME=$(docker exec compose-n8n-1 wget -qO- --timeout=5 http://localhost:5678/api/v1/me 2>&1 | head -5 || echo "FAILED")
if echo "$API_ME" | grep -q "401\|unauthorized"; then
    echo "   ✓ API responding (401 = not authenticated, expected)"
elif echo "$API_ME" | grep -q "404\|not found"; then
    echo "   ⚠️  API endpoint not found (may be different in this version)"
else
    echo "   ? API response: $(echo "$API_ME" | head -1)"
fi
echo ""

# 5. Check static assets
echo "5. Testing static assets..."
ASSET_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai/assets/index-qmt2pxHw.js 2>&1 || echo "000")
if [ "$ASSET_CODE" = "200" ]; then
    echo "   ✓ Static assets loading (HTTP $ASSET_CODE)"
else
    echo "   ⚠️  Static assets issue (HTTP $ASSET_CODE)"
    echo "   Asset paths may have changed - try clearing browser cache"
fi
echo ""

# 6. Restart n8n to clear any stuck state
echo "6. Restarting n8n..."
docker compose -f compose/n8n.yml --env-file .env restart n8n 2>&1 >/dev/null
echo "   ✓ n8n restarted"
echo ""

# 7. Wait for startup
echo "7. Waiting for n8n to start..."
sleep 15
echo "   ✓ Wait complete"
echo ""

# 8. Test access
echo "8. Testing access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ n8n is accessible (HTTP $HTTP_CODE)"
else
    echo "   ⚠️  n8n returned HTTP $HTTP_CODE"
fi
echo ""

echo "=== Summary ==="
echo ""
echo "n8n Status:"
echo "  - Service: Running"
echo "  - Database users: $USER_COUNT"
echo "  - HTTP response: $HTTP_CODE"
echo ""
echo "Blank page is usually caused by:"
echo "  1. JavaScript errors (check browser console: F12)"
echo "  2. API calls failing"
echo "  3. Browser cache issues"
echo ""
echo "Next steps:"
echo "  1. Open browser Developer Tools (F12)"
echo "  2. Go to Console tab - look for RED errors"
echo "  3. Go to Network tab - look for failed requests (red)"
echo "  4. Try hard refresh: Ctrl+Shift+R (or Cmd+Shift+R)"
echo "  5. Try incognito window"
echo ""
echo "Common fixes:"
echo "  - Clear browser cache completely"
echo "  - Disable browser extensions"
echo "  - Try different browser"
echo "  - Check browser console for JavaScript errors"
echo ""
echo "License SDK warnings are harmless - they don't cause blank pages."
echo ""

