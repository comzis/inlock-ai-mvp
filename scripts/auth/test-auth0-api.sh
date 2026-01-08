#!/bin/bash
# Test Auth0 Management API Access
#
# Usage:
#   ./scripts/test-auth0-api.sh
#
# Environment variables:
#   AUTH0_MGMT_CLIENT_ID - Management API Client ID
#   AUTH0_MGMT_CLIENT_SECRET - Management API Client Secret
#   AUTH0_DOMAIN - Auth0 Domain (default: comzis.eu.auth0.com)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"

echo "=== Auth0 Management API Test ==="
echo "Domain: $AUTH0_DOMAIN"
echo ""

# Check for credentials
if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
  echo "❌ Error: Management API credentials not found"
  echo ""
  echo "Please add to .env file:"
  echo "  AUTH0_MGMT_CLIENT_ID=your-management-api-client-id"
  echo "  AUTH0_MGMT_CLIENT_SECRET=your-management-api-client-secret"
  echo ""
  echo "See docs/AUTH0-MANAGEMENT-API-SETUP.md for setup instructions"
  exit 1
fi

echo "✓ Credentials found"
echo ""

# Get access token
echo "1. Getting access token..."
TOKEN_RESPONSE=$(curl -s -X POST "${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')
ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

if [ -n "$ERROR" ] || [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Failed to get access token"
  # Security: Only show error code, not full token response (may contain sensitive data)
  ERROR_CODE=$(echo "$TOKEN_RESPONSE" | jq -r '.error // "unknown"')
  ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // "See Auth0 logs for details"')
  echo "Error: $ERROR_CODE"
  echo "Description: $ERROR_DESC"
  exit 1
fi

echo "   ✓ Access token obtained"
echo ""

# Test API access - Get applications
echo "2. Testing API access (fetching applications)..."
APPS_RESPONSE=$(curl -s -X GET "${AUTH0_API_URL}/applications" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

ERROR=$(echo "$APPS_RESPONSE" | jq -r '.error // empty')

if [ -n "$ERROR" ]; then
  echo "❌ API request failed"
  echo "Response: $APPS_RESPONSE"
  exit 1
fi

APP_COUNT=$(echo "$APPS_RESPONSE" | jq '. | length')
echo "   ✓ Successfully accessed Management API"
echo "   ✓ Found $APP_COUNT applications"
echo ""

# Get current admin app
echo "3. Fetching admin application details..."
ADMIN_APP=$(curl -s -X GET "${AUTH0_API_URL}/applications/${AUTH0_ADMIN_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

APP_NAME=$(echo "$ADMIN_APP" | jq -r '.name // "unknown"')
CALLBACKS=$(echo "$ADMIN_APP" | jq -r '.callbacks[] // empty' | head -3)

echo "   Application: $APP_NAME"
if [ -n "$CALLBACKS" ]; then
  echo "   Callback URLs:"
  echo "$CALLBACKS" | while read -r url; do
    echo "     - $url"
  done
fi
echo ""

echo "=== Test Complete ==="
echo "✓ Management API access is working correctly"
echo ""
echo "You can now use the Management API for automation:"
echo "  - ./scripts/configure-auth0-api.sh"
echo "  - Custom automation scripts"

