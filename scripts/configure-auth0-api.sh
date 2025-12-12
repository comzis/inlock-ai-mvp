#!/bin/bash
# Configure Auth0 Application Settings via Management API
# 
# Usage:
#   ./scripts/configure-auth0-api.sh [--client-id CLIENT_ID] [--client-secret SECRET] [--domain DOMAIN]
#
# Environment variables can also be used:
#   AUTH0_MGMT_CLIENT_ID - Management API Client ID
#   AUTH0_MGMT_CLIENT_SECRET - Management API Client Secret  
#   AUTH0_DOMAIN - Auth0 Domain (e.g., comzis.eu.auth0.com)
#   AUTH0_APP_CLIENT_ID - Application Client ID to configure (defaults to inlock-admin)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Default values
AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_APP_CLIENT_ID="${AUTH0_APP_CLIENT_ID:-aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o}"  # inlock-admin

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --client-id)
      AUTH0_MGMT_CLIENT_ID="$2"
      shift 2
      ;;
    --client-secret)
      AUTH0_MGMT_CLIENT_SECRET="$2"
      shift 2
      ;;
    --domain)
      AUTH0_DOMAIN="$2"
      shift 2
      ;;
    --app-client-id)
      AUTH0_APP_CLIENT_ID="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --client-id ID        Auth0 Management API Client ID"
      echo "  --client-secret SECRET Auth0 Management API Client Secret"
      echo "  --domain DOMAIN       Auth0 Domain (default: comzis.eu.auth0.com)"
      echo "  --app-client-id ID    Application Client ID to configure (default: inlock-admin)"
      echo ""
      echo "Environment variables:"
      echo "  AUTH0_MGMT_CLIENT_ID      Management API Client ID"
      echo "  AUTH0_MGMT_CLIENT_SECRET  Management API Client Secret"
      echo "  AUTH0_DOMAIN              Auth0 Domain"
      echo "  AUTH0_APP_CLIENT_ID       Application Client ID"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check required variables
if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
  echo "Error: Management API credentials required"
  echo ""
  echo "Set environment variables:"
  echo "  export AUTH0_MGMT_CLIENT_ID=your-management-api-client-id"
  echo "  export AUTH0_MGMT_CLIENT_SECRET=your-management-api-client-secret"
  echo ""
  echo "Or use command line options:"
  echo "  $0 --client-id ID --client-secret SECRET"
  echo ""
  echo "To get Management API credentials:"
  echo "  1. Go to Auth0 Dashboard → Applications → APIs → Auth0 Management API"
  echo "  2. Go to Machine to Machine Applications tab"
  echo "  3. Authorize your application and select scopes:"
  echo "     - update:applications"
  echo "     - read:applications"
  exit 1
fi

AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"

echo "=== Auth0 Management API Configuration ==="
echo "Domain: $AUTH0_DOMAIN"
echo "Application Client ID: $AUTH0_APP_CLIENT_ID"
echo ""

# Get Management API Access Token
echo "1. Getting Management API access token..."
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
  echo "Error: Failed to get access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "   ✓ Access token obtained"
echo ""

# Get current application settings
echo "2. Fetching current application settings..."
CURRENT_APP=$(curl -s -X GET "${AUTH0_API_URL}/applications/${AUTH0_APP_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

APP_NAME=$(echo "$CURRENT_APP" | jq -r '.name // "unknown"')
echo "   Application: $APP_NAME"
echo ""

# Define URLs
CALLBACK_URLS="https://auth.inlock.ai/oauth2/callback"
LOGOUT_URLS="https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai"

# Update application settings
echo "3. Updating application settings..."

UPDATE_PAYLOAD=$(jq -n \
  --arg callbacks "$CALLBACK_URLS" \
  --arg logouts "$LOGOUT_URLS" \
  '{
    callbacks: [$callbacks],
    allowed_logout_urls: ($logouts | split(",") | map(ltrimstr(" ") | rtrimstr(" ")))
  }')

UPDATE_RESPONSE=$(curl -s -X PATCH "${AUTH0_API_URL}/applications/${AUTH0_APP_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$UPDATE_PAYLOAD")

# Check for errors
ERROR=$(echo "$UPDATE_RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "Error: Failed to update application"
  echo "Response: $UPDATE_RESPONSE"
  exit 1
fi

echo "   ✓ Application settings updated"
echo ""

# Verify settings
echo "4. Verifying updated settings..."
UPDATED_APP=$(curl -s -X GET "${AUTH0_API_URL}/applications/${AUTH0_APP_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

UPDATED_CALLBACKS=$(echo "$UPDATED_APP" | jq -r '.callbacks[]' | tr '\n' ',' | sed 's/,$//')
UPDATED_LOGOUTS=$(echo "$UPDATED_APP" | jq -r '.allowed_logout_urls[]' | tr '\n' ',' | sed 's/,$//')

echo "   Callback URLs:"
echo "     $UPDATED_CALLBACKS"
echo ""
echo "   Logout URLs:"
echo "     $UPDATED_LOGOUTS"
echo ""

echo "=== Configuration Complete ==="
echo ""
echo "Next steps:"
echo "  1. Test authentication: Visit https://grafana.inlock.ai"
echo "  2. Verify callback flow works end-to-end"
echo "  3. Check OAuth2-Proxy logs for callback requests"

