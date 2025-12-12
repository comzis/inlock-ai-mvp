#!/bin/bash
# Quick Auth0 Management API helper
# Usage: ./auth0-api-quick.sh <access_token> <endpoint>
# Or: AUTH0_ACCESS_TOKEN=<token> ./auth0-api-quick.sh "" <endpoint>

TOKEN="${1:-${AUTH0_ACCESS_TOKEN}}"

if [ -z "$TOKEN" ]; then
  echo "Error: Access token required"
  echo "Usage: $0 <access_token> <endpoint>"
  echo "   OR: AUTH0_ACCESS_TOKEN=<token> $0 \"\" <endpoint>"
  exit 1
fi

AUTH0_DOMAIN="comzis.eu.auth0.com"
API_URL="https://${AUTH0_DOMAIN}/api/v2"

ENDPOINT="${2:-clients}"

curl -s --request GET \
  --url "${API_URL}/${ENDPOINT}" \
  --header "authorization: Bearer ${TOKEN}" | \
  python3 -m json.tool 2>/dev/null || \
  curl -s --request GET \
    --url "${API_URL}/${ENDPOINT}" \
    --header "authorization: Bearer ${TOKEN}"

