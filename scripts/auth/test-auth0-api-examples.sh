#!/bin/bash
# Auth0 Management API Test Examples
# Created by: API Tester Buddy (Agent 7)
# Purpose: Example curl/jq snippets for test-auth0-api.sh validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load environment variables
if [ -f .env ]; then
    source .env
fi

AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"
CLIENT_ID="${AUTH0_ADMIN_CLIENT_ID:-aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o}"

echo "=========================================="
echo "Auth0 Management API Test Examples"
echo "=========================================="
echo ""

# Check if Management API credentials are set
if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
    echo "⚠️  Management API credentials not set"
    echo ""
    echo "Set these in .env:"
    echo "  AUTH0_MGMT_CLIENT_ID=your-m2m-client-id"
    echo "  AUTH0_MGMT_CLIENT_SECRET=your-m2m-client-secret"
    echo ""
    echo "Or run: ./scripts/setup-auth0-management-api.sh"
    echo ""
    exit 1
fi

echo "1. Getting Management API Access Token"
echo "----------------------------------------"
TOKEN_RESPONSE=$(curl -s -X POST "${AUTH0_API_URL}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo "❌ Failed to get access token"
    # Security: Only show error code, not full token response (may contain sensitive data)
    ERROR_CODE=$(echo "$TOKEN_RESPONSE" | jq -r '.error // "unknown"')
    ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // "See Auth0 logs for details"')
    echo "Error: $ERROR_CODE"
    echo "Description: $ERROR_DESC"
    exit 1
fi

echo "✅ Access token obtained"
echo ""

echo "2. Getting Application Details"
echo "--------------------------------"
APP_RESPONSE=$(curl -s -X GET "${AUTH0_API_URL}/applications/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

APP_NAME=$(echo "$APP_RESPONSE" | jq -r '.name // "unknown"')
echo "Application: $APP_NAME"
echo ""

echo "3. Checking Callback URLs"
echo "-------------------------"
CALLBACKS=$(echo "$APP_RESPONSE" | jq -r '.callbacks[]' 2>/dev/null || echo "")
if echo "$CALLBACKS" | grep -q "auth.inlock.ai/oauth2/callback"; then
    echo "✅ Callback URL configured:"
    echo "$CALLBACKS" | grep "auth.inlock.ai/oauth2/callback"
else
    echo "❌ Callback URL NOT found:"
    echo "Expected: https://auth.inlock.ai/oauth2/callback"
    echo "Current callbacks:"
    echo "$CALLBACKS" | sed 's/^/  /'
fi
echo ""

echo "4. Checking Logout URLs"
echo "-----------------------"
LOGOUTS=$(echo "$APP_RESPONSE" | jq -r '.allowed_logout_urls[]' 2>/dev/null || echo "")
if [ -n "$LOGOUTS" ]; then
    echo "✅ Logout URLs configured:"
    echo "$LOGOUTS" | sed 's/^/  /'
else
    echo "⚠️  No logout URLs configured"
fi
echo ""

echo "5. Checking Web Origins"
echo "----------------------"
ORIGINS=$(echo "$APP_RESPONSE" | jq -r '.allowed_origins[]' 2>/dev/null || echo "")
if echo "$ORIGINS" | grep -q "auth.inlock.ai"; then
    echo "✅ Web Origin configured:"
    echo "$ORIGINS" | grep "auth.inlock.ai"
else
    echo "⚠️  Web Origin NOT found:"
    echo "Expected: https://auth.inlock.ai"
    echo "Current origins:"
    echo "$ORIGINS" | sed 's/^/  /'
fi
echo ""

echo "6. Checking Application Type"
echo "----------------------------"
APP_TYPE=$(echo "$APP_RESPONSE" | jq -r '.app_type // "unknown"')
echo "Application Type: $APP_TYPE"
if [ "$APP_TYPE" = "regular_web" ]; then
    echo "✅ Correct application type"
else
    echo "⚠️  Expected: regular_web"
fi
echo ""

echo "7. Checking OIDC Conformant"
echo "---------------------------"
OIDC_CONFORMANT=$(echo "$APP_RESPONSE" | jq -r '.oidc_conformant // false')
if [ "$OIDC_CONFORMANT" = "true" ]; then
    echo "✅ OIDC Conformant: Enabled"
else
    echo "⚠️  OIDC Conformant: Disabled (should be enabled)"
fi
echo ""

echo "8. Checking Grant Types"
echo "----------------------"
GRANT_TYPES=$(echo "$APP_RESPONSE" | jq -r '.grant_types[]' 2>/dev/null || echo "")
echo "Grant Types:"
echo "$GRANT_TYPES" | sed 's/^/  /'
if echo "$GRANT_TYPES" | grep -q "authorization_code"; then
    echo "✅ Authorization Code grant enabled"
else
    echo "❌ Authorization Code grant NOT enabled"
fi
echo ""

echo "=========================================="
echo "Test Complete"
echo "=========================================="
echo ""
echo "Full Application JSON:"
echo "$APP_RESPONSE" | jq '.' 2>/dev/null || echo "$APP_RESPONSE"

