#!/bin/bash
# Test script for Auth0 Management API access token
# Usage: ./test-token.sh <access_token>
# Or: AUTH0_ACCESS_TOKEN=<token> ./test-token.sh

TOKEN="${1:-${AUTH0_ACCESS_TOKEN}}"

if [ -z "$TOKEN" ]; then
  echo "Error: Access token required"
  echo "Usage: $0 <access_token>"
  echo "   OR: AUTH0_ACCESS_TOKEN=<token> $0"
  echo ""
  echo "To get a token, use the Auth0 Management API M2M application"
  echo "or run: ./auth0-api-helper.sh get_token"
  exit 1
fi

AUTH0_DOMAIN="comzis.eu.auth0.com"
API_URL="https://${AUTH0_DOMAIN}/api/v2"

echo "Testing Auth0 Management API access..."
echo ""

# Test 1: List applications
echo "1. Listing applications:"
curl -s -X GET "${API_URL}/clients" \
  -H "Authorization: Bearer ${TOKEN}" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  - {c.get(\"name\")} ({c.get(\"client_id\")})') for c in d[:10]]" 2>/dev/null || \
  echo "  (Could not parse response - check token validity)"

echo ""
echo "2. Getting OAuth2 Proxy application details:"
curl -s -X GET "${API_URL}/clients/aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o" \
  -H "Authorization: Bearer ${TOKEN}" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps({k:d.get(k) for k in ['name','client_id','callbacks','allowed_logout_urls','allowed_origins']}, indent=2))" 2>/dev/null || \
  echo "  (Could not parse response)"

echo ""
echo "3. Token info (decoded):"
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps({'iss':d.get('iss'),'sub':d.get('sub'),'aud':d.get('aud'),'iat':d.get('iat'),'exp':d.get('exp'),'scopes_preview':d.get('scope','').split()[:10]}, indent=2))" 2>/dev/null || echo "  (Could not decode token)"
