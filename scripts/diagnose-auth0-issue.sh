#!/bin/bash
# Auth0 Issue Diagnostic Script
# This script checks the current Auth0 configuration status and helps identify issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=========================================="
echo "Auth0 Configuration Diagnostic"
echo "=========================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Check OAuth2-Proxy status
echo "1. OAuth2-Proxy Service Status"
echo "-------------------------------"
if docker ps --filter "name=oauth2-proxy" --format "{{.Names}}" | grep -q oauth2-proxy; then
    STATUS=$(docker ps --filter "name=oauth2-proxy" --format "{{.Status}}")
    echo "   ✅ OAuth2-Proxy is running: $STATUS"
else
    echo "   ❌ OAuth2-Proxy is not running"
    exit 1
fi
echo ""

# Check configuration
echo "2. OAuth2-Proxy Configuration"
echo "-------------------------------"
if [ -n "$AUTH0_ADMIN_CLIENT_ID" ]; then
    echo "   ✅ AUTH0_ADMIN_CLIENT_ID: ${AUTH0_ADMIN_CLIENT_ID:0:20}..."
else
    echo "   ❌ AUTH0_ADMIN_CLIENT_ID: Missing"
fi

if [ -n "$AUTH0_ADMIN_CLIENT_SECRET" ]; then
    echo "   ✅ AUTH0_ADMIN_CLIENT_SECRET: Set"
else
    echo "   ❌ AUTH0_ADMIN_CLIENT_SECRET: Missing"
fi

if [ -n "$AUTH0_ISSUER" ]; then
    echo "   ✅ AUTH0_ISSUER: $AUTH0_ISSUER"
else
    echo "   ❌ AUTH0_ISSUER: Missing"
fi

if [ -n "$OAUTH2_PROXY_COOKIE_SECRET" ]; then
    echo "   ✅ OAUTH2_PROXY_COOKIE_SECRET: Set"
else
    echo "   ❌ OAUTH2_PROXY_COOKIE_SECRET: Missing"
fi
echo ""

# Check callback endpoint
echo "3. Callback Endpoint Accessibility"
echo "-----------------------------------"
CALLBACK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://auth.inlock.ai/oauth2/callback 2>&1)
if [ "$CALLBACK_STATUS" = "403" ]; then
    echo "   ✅ Callback endpoint accessible (403 expected without OAuth params)"
elif [ "$CALLBACK_STATUS" = "200" ]; then
    echo "   ⚠️  Callback endpoint returns 200 (unexpected)"
else
    echo "   ❌ Callback endpoint returned: $CALLBACK_STATUS"
fi
echo ""

# Check OAuth2 start endpoint
echo "4. OAuth2 Start Endpoint"
echo "-------------------------"
START_RESPONSE=$(curl -s -I https://auth.inlock.ai/oauth2/start 2>&1 | head -1)
if echo "$START_RESPONSE" | grep -q "302\|301"; then
    echo "   ✅ Start endpoint redirects correctly"
    REDIRECT_URL=$(curl -s -I https://auth.inlock.ai/oauth2/start 2>&1 | grep -i "location:" | cut -d' ' -f2 | tr -d '\r')
    if echo "$REDIRECT_URL" | grep -q "auth.inlock.ai/oauth2/callback"; then
        echo "   ✅ Redirect URL contains correct callback: auth.inlock.ai/oauth2/callback"
    else
        echo "   ⚠️  Redirect URL: $REDIRECT_URL"
    fi
else
    echo "   ❌ Start endpoint issue: $START_RESPONSE"
fi
echo ""

# Check recent OAuth2-Proxy logs
echo "5. Recent OAuth2-Proxy Logs (last 10 entries)"
echo "----------------------------------------------"
RECENT_LOGS=$(docker logs compose-oauth2-proxy-1 --tail 10 2>&1)
CALLBACK_COUNT=$(echo "$RECENT_LOGS" | grep -c "callback" || echo "0")
ERROR_COUNT=$(echo "$RECENT_LOGS" | grep -ic "error" || echo "0")

echo "   Callback requests in last 10 log entries: $CALLBACK_COUNT"
echo "   Errors in last 10 log entries: $ERROR_COUNT"

if [ "$CALLBACK_COUNT" -gt 0 ]; then
    echo "   ✅ Callback requests detected in logs"
    echo ""
    echo "   Recent callback-related logs:"
    echo "$RECENT_LOGS" | grep -i "callback" | tail -3 | sed 's/^/      /'
else
    echo "   ⚠️  No callback requests in recent logs"
    echo "   This suggests Auth0 is not redirecting back after login"
fi
echo ""

# Check for Auth0 callback errors
echo "6. Auth0 Callback Error Analysis"
echo "---------------------------------"
CALLBACK_ERRORS=$(docker logs compose-oauth2-proxy-1 --tail 50 2>&1 | grep -i "callback.*error\|invalid.*callback\|callback.*failed" || echo "")
if [ -n "$CALLBACK_ERRORS" ]; then
    echo "   ⚠️  Callback errors detected:"
    echo "$CALLBACK_ERRORS" | tail -3 | sed 's/^/      /'
else
    echo "   ✅ No callback errors in recent logs"
fi
echo ""

# Summary and recommendations
echo "=========================================="
echo "Diagnostic Summary"
echo "=========================================="
echo ""

if [ "$CALLBACK_COUNT" -eq 0 ]; then
    echo "❌ ISSUE IDENTIFIED: No callback requests from Auth0"
    echo ""
    echo "This indicates that Auth0 is not configured to redirect back to:"
    echo "  https://auth.inlock.ai/oauth2/callback"
    echo ""
    echo "ACTION REQUIRED:"
    echo "1. Go to: https://manage.auth0.com/"
    echo "2. Navigate to: Applications → Applications → inlock-admin"
    echo "3. Check 'Allowed Callback URLs' field"
    echo "4. Add if missing: https://auth.inlock.ai/oauth2/callback"
    echo "5. Click 'Save Changes'"
    echo ""
    echo "After fixing, run this script again to verify."
else
    echo "✅ Callback requests are being received"
    echo ""
    echo "If authentication still fails, check:"
    echo "1. Auth0 application settings (callback URLs)"
    echo "2. OAuth2-Proxy logs for specific errors"
    echo "3. Browser console for JavaScript errors"
fi
echo ""

# Test authentication flow
echo "7. Testing Authentication Flow"
echo "-------------------------------"
echo "   Testing redirect to Auth0..."
TEST_REDIRECT=$(curl -s -I "https://grafana.inlock.ai" 2>&1 | grep -i "location:" | head -1)
if echo "$TEST_REDIRECT" | grep -q "auth0.com"; then
    echo "   ✅ Grafana redirects to Auth0 correctly"
    if echo "$TEST_REDIRECT" | grep -q "auth.inlock.ai/oauth2/callback"; then
        echo "   ✅ Redirect URL includes correct callback"
    else
        echo "   ⚠️  Redirect URL may be incorrect"
        echo "   $TEST_REDIRECT"
    fi
else
    echo "   ❌ Grafana does not redirect to Auth0"
    echo "   Response: $TEST_REDIRECT"
fi
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

