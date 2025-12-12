#!/bin/bash
# Test script for Auth0 Management API access token
# Usage: ./test-token.sh <access_token>
# Or: AUTH0_ACCESS_TOKEN=<token> ./test-token.sh

TOKEN="${1:-${AUTH0_ACCESS_TOKEN}}"

if [ -z "$TOKEN" ]; then
  echo "Error: Access token required"
  echo "Usage: $0 <access_token>"
  echo "   OR: AUTH0_ACCESS_TOKEN=<token> $0"
  exit 1
fi

AUTH0_DOMAIN="comzis.eu.auth0.com"
API_URL="https://${AUTH0_DOMAIN}/api/v2"

echo "Testing Auth0 Management API access..."
echo ""

# Test 1: List applications
echo "1. Listing applications:"
curl -s -X GET "${API_URL}/applications" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq -r '.[] | "  - \(.name) (\(.client_id))"' | head -10

echo ""
echo "2. Getting OAuth2 Proxy application details:"
curl -s -X GET "${API_URL}/applications/aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o" \
  -H "Authorization: Bearer ${TOKEN}" | \
  jq '{name, client_id, callbacks, allowed_logout_urls, allowed_origins}'

echo ""
echo "3. Token info (decoded):"
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '{iss, sub, aud, iat, exp, scope: (.scope | split(" ")[0:10])}' 2>/dev/null || echo "  (Could not decode token)"

