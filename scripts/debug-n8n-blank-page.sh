#!/bin/bash
# Debug n8n blank page - check API endpoints and browser issues
# Run: ./scripts/debug-n8n-blank-page.sh

set -euo pipefail

echo "=== n8n Blank Page Debug ==="
echo ""

# 1. Check n8n status
echo "1. n8n Service Status:"
if docker ps | grep -q compose-n8n-1; then
    STATUS=$(docker ps | grep compose-n8n-1 | awk '{print $7}')
    echo "   ✓ Running ($STATUS)"
else
    echo "   ✗ Not running"
    exit 1
fi
echo ""

# 2. Check HTTP access
echo "2. HTTP Access:"
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
echo "   HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ Accessible"
else
    echo "   ✗ Not accessible"
fi
echo ""

# 3. Check database users
echo "3. Database Users:"
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "?")
echo "   Users: $USER_COUNT"
if [ "$USER_COUNT" = "0" ]; then
    echo "   → Should show SETUP page"
else
    echo "   → Should show LOGIN page"
fi
echo ""

# 4. Test API endpoints
echo "4. Testing API Endpoints:"

# Test owner/setup endpoint
echo "   Testing /api/v1/owner/setup..."
SETUP_RESPONSE=$(curl -k -s https://n8n.inlock.ai/api/v1/owner/setup 2>&1 | head -5)
if echo "$SETUP_RESPONSE" | grep -q "setup\|owner\|user"; then
    echo "   ✓ Setup endpoint responding"
elif echo "$SETUP_RESPONSE" | grep -q "404\|not found"; then
    echo "   ⚠️  Setup endpoint not found (may be different path in v1.123.5)"
else
    echo "   ? Response: $(echo "$SETUP_RESPONSE" | head -1)"
fi

# Test login endpoint
echo "   Testing /rest/login..."
LOGIN_RESPONSE=$(curl -k -s https://n8n.inlock.ai/rest/login 2>&1 | head -5)
if echo "$LOGIN_RESPONSE" | grep -q "unauthorized\|401"; then
    echo "   ✓ Login endpoint responding (401 = expected)"
elif echo "$LOGIN_RESPONSE" | grep -q "404\|not found"; then
    echo "   ⚠️  Login endpoint not found"
else
    echo "   ? Response: $(echo "$LOGIN_RESPONSE" | head -1)"
fi
echo ""

# 5. Check environment variables
echo "5. Environment Variables:"
TRUSTED_PROXIES=$(docker exec compose-n8n-1 env | grep N8N_TRUSTED_PROXIES || echo "NOT SET")
echo "   N8N_TRUSTED_PROXIES: $TRUSTED_PROXIES"
if echo "$TRUSTED_PROXIES" | grep -q "loopback\|linklocal"; then
    echo "   ✓ Proxy trust configured"
else
    echo "   ⚠️  Proxy trust may not be configured"
fi
echo ""

# 6. Check Traefik logs
echo "6. Recent Traefik Requests:"
docker logs compose-traefik-1 --tail 10 2>&1 | grep n8n | tail -3 || echo "   No recent n8n requests"
echo ""

# 7. Check for errors
echo "7. Recent Errors (excluding license warnings):"
ERRORS=$(docker logs compose-n8n-1 --tail 100 2>&1 | grep -i -E "(error|exception|fatal)" | grep -v "license SDK" | tail -5 || true)
if [ -n "$ERRORS" ]; then
    echo "   ⚠️  Found errors:"
    echo "$ERRORS" | sed 's/^/     /'
else
    echo "   ✓ No critical errors"
fi
echo ""

# 8. Browser debugging instructions
echo "=== Browser Debugging ==="
echo ""
echo "Since sidebar is visible but content is blank, this is likely:"
echo "  1. JavaScript error (check browser console)"
echo "  2. API call failure (check Network tab)"
echo ""
echo "Steps to debug in browser:"
echo ""
echo "1. Open Developer Tools:"
echo "   - Press F12 (or Cmd+Option+I on Mac)"
echo ""
echo "2. Check Console tab:"
echo "   - Look for RED error messages"
echo "   - Common errors:"
echo "     • 'Failed to fetch'"
echo "     • 'CORS error'"
echo "     • 'Network error'"
echo "     • '404 Not Found'"
echo ""
echo "3. Check Network tab:"
echo "   - Reload page (Ctrl+R or Cmd+R)"
echo "   - Look for failed requests (RED entries)"
echo "   - Check which API calls are failing:"
echo "     • /api/v1/owner/setup"
echo "     • /api/v1/me"
echo "     • /rest/login"
echo ""
echo "4. Try fixes:"
echo "   - Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R)"
echo "   - Incognito window"
echo "   - Different browser"
echo ""
echo "5. Share the error:"
echo "   - Copy the RED error from Console tab"
echo "   - Or screenshot the Network tab showing failed requests"
echo ""

