#!/bin/bash
# Mailcow API Test Script
# Tests Mailcow API authentication and endpoints

set -euo pipefail

BASE_URL="https://mail.inlock.ai"
API_BASE="${BASE_URL}/api/v1"
USERNAME="${1:-admin}"
PASSWORD="${2:-MailcowAdmin123!}"

echo "=== Mailcow API Test ==="
echo "Base URL: $API_BASE"
echo "Username: $USERNAME"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check API endpoint exists
echo "1. Testing API endpoint availability..."
API_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/" 2>/dev/null || echo "000")
if [ "$API_CHECK" = "200" ]; then
    echo -e "${GREEN}✓${NC} API endpoint is accessible (HTTP $API_CHECK)"
else
    echo -e "${YELLOW}⚠${NC} API endpoint returned HTTP $API_CHECK"
fi
echo ""

# Test 2: Try status endpoint without auth
echo "2. Testing status endpoint without authentication..."
STATUS_NO_AUTH=$(curl -s "$API_BASE/get/status" 2>&1)
if echo "$STATUS_NO_AUTH" | grep -qi "error\|unauthorized\|401"; then
    echo -e "${YELLOW}⚠${NC} Status endpoint requires authentication (expected)"
    echo "   Response: $(echo "$STATUS_NO_AUTH" | head -c 100)..."
elif echo "$STATUS_NO_AUTH" | grep -qi "success\|status"; then
    echo -e "${GREEN}✓${NC} Status endpoint accessible without auth (unexpected)"
    echo "   Response: $STATUS_NO_AUTH"
else
    echo -e "${YELLOW}?${NC} Unknown response: $(echo "$STATUS_NO_AUTH" | head -c 100)..."
fi
echo ""

# Test 3: Try status endpoint with Basic Auth
echo "3. Testing status endpoint with Basic Authentication..."
STATUS_BASIC=$(curl -s -u "$USERNAME:$PASSWORD" "$API_BASE/get/status" 2>&1)
if echo "$STATUS_BASIC" | grep -qi "success\|status\|version"; then
    echo -e "${GREEN}✓${NC} Basic Auth works!"
    echo "   Response: $STATUS_BASIC"
elif echo "$STATUS_BASIC" | grep -qi "error\|unauthorized\|401"; then
    echo -e "${RED}✗${NC} Basic Auth failed"
    echo "   Response: $STATUS_BASIC"
else
    echo -e "${YELLOW}?${NC} Unknown response: $(echo "$STATUS_BASIC" | head -c 200)..."
fi
echo ""

# Test 4: Try login endpoint
echo "4. Testing login endpoint..."
LOGIN_RESPONSE=$(curl -s -u "$USERNAME:$PASSWORD" "$API_BASE/get/login" 2>&1)
if echo "$LOGIN_RESPONSE" | grep -qi "success\|token\|api"; then
    echo -e "${GREEN}✓${NC} Login endpoint response:"
    echo "   $LOGIN_RESPONSE"
elif echo "$LOGIN_RESPONSE" | grep -qi "error"; then
    echo -e "${YELLOW}⚠${NC} Login endpoint returned: $LOGIN_RESPONSE"
else
    echo -e "${YELLOW}?${NC} Response: $(echo "$LOGIN_RESPONSE" | head -c 200)..."
fi
echo ""

# Test 5: List available API endpoints (if Swagger is accessible)
echo "5. Checking API documentation..."
SWAGGER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/" 2>/dev/null || echo "000")
if [ "$SWAGGER_CHECK" = "200" ]; then
    echo -e "${GREEN}✓${NC} API Swagger documentation available at: $BASE_URL/api/"
    echo "   Visit this URL in a browser to see available endpoints"
else
    echo -e "${YELLOW}⚠${NC} Swagger documentation not accessible (HTTP $SWAGGER_CHECK)"
fi
echo ""

# Summary
echo "=== Summary ==="
echo "Mailcow API uses API key authentication (X-API-Key header)"
echo "To generate an API key:"
echo "  1. Login to admin panel: $BASE_URL/admin"
echo "  2. Navigate to: Configuration → System → API"
echo "  3. Generate API key"
echo ""
echo "Then use it with:"
echo "  curl -H 'X-API-Key: YOUR_API_KEY' $API_BASE/get/status"
