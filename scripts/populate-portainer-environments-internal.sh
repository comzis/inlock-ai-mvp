#!/usr/bin/env bash
# Populate Portainer Environments via Internal Network
#
# This script runs from within Docker network to access Portainer API directly
# Usage: Run from a container on the same network, or via docker compose exec
#
# Example:
#   docker compose -f compose/stack.yml exec -T oauth2-proxy sh -c "wget -qO- /scripts/populate-portainer-environments-internal.sh | sh"

set -euo pipefail

# Portainer internal URL (via Docker network)
PORTAINER_URL="http://portainer:9000"
ADMIN_USER="${1:-admin}"
ADMIN_PASS="${2:-}"

# If password not provided, try to read from mounted secret
if [ -z "$ADMIN_PASS" ] && [ -f "/run/secrets/portainer_admin_password" ]; then
    ADMIN_PASS=$(cat /run/secrets/portainer_admin_password | head -1 | tr -d '\n' | tr -d '\r')
fi

# If still no password, prompt
if [ -z "$ADMIN_PASS" ]; then
    read -sp "Enter Portainer admin password: " ADMIN_PASS
    echo ""
fi

if [ -z "$ADMIN_PASS" ]; then
    echo "❌ Error: Password required"
    exit 1
fi

echo "========================================="
echo "Populating Portainer Environments"
echo "========================================="
echo "Portainer URL: $PORTAINER_URL"
echo "Admin User: $ADMIN_USER"
echo ""

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl not found. Install curl in the container."
    exit 1
fi

# Step 1: Get authentication token
echo "1. Authenticating with Portainer..."
AUTH_RESPONSE=$(curl -s -X POST "${PORTAINER_URL}/api/auth" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USER}\",
    \"password\": \"${ADMIN_PASS}\"
  }" 2>/dev/null || echo '{"err":"connection_failed"}')

# Check if auth succeeded
JWT_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"jwt":"[^"]*' | cut -d'"' -f4 || echo "")

if [ -z "$JWT_TOKEN" ]; then
    echo "❌ Error: Failed to authenticate with Portainer"
    echo "Response: $AUTH_RESPONSE"
    echo ""
    echo "Make sure:"
    echo "  1. You've created the admin account in Portainer UI"
    echo "  2. The credentials are correct"
    echo "  3. Portainer is running and accessible"
    exit 1
fi

echo "   ✓ Authentication successful"
echo ""

# Step 2: Get current endpoints
echo "2. Checking existing endpoints..."
ENDPOINTS=$(curl -s -X GET "${PORTAINER_URL}/api/endpoints" \
  -H "Authorization: Bearer ${JWT_TOKEN}")

LOCAL_EXISTS=$(echo "$ENDPOINTS" | grep -o '"Name":"local"' || echo "")

# Step 3: Create Local Docker Environment
if [ -n "$LOCAL_EXISTS" ]; then
    echo "3. Local Docker endpoint already exists, skipping creation..."
else
    echo "3. Creating Local Docker environment..."
    
    CREATE_RESPONSE=$(curl -s -X POST "${PORTAINER_URL}/api/endpoints" \
      -H "Authorization: Bearer ${JWT_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"Name\": \"local\",
        \"EndpointType\": 1,
        \"URL\": \"tcp://docker-socket-proxy:2375\",
        \"TLS\": false,
        \"PublicURL\": \"\",
        \"GroupID\": 1,
        \"TagIDs\": []
      }")

    ENDPOINT_ID=$(echo "$CREATE_RESPONSE" | grep -o '"Id":[0-9]*' | head -1 | cut -d':' -f2 || echo "")
    
    if [ -n "$ENDPOINT_ID" ]; then
        echo "   ✓ Local Docker environment created (ID: $ENDPOINT_ID)"
    else
        echo "   ⚠ Response: $CREATE_RESPONSE"
    fi
fi
echo ""

# Step 4: List all endpoints
echo "4. Current Portainer endpoints:"
ENDPOINTS=$(curl -s -X GET "${PORTAINER_URL}/api/endpoints" \
  -H "Authorization: Bearer ${JWT_TOKEN}")

ENDPOINT_COUNT=$(echo "$ENDPOINTS" | grep -o '"Id":[0-9]*' | wc -l || echo "0")
echo "   Total endpoints: $ENDPOINT_COUNT"

echo "$ENDPOINTS" | grep -o '"Name":"[^"]*' | cut -d'"' -f4 | while read -r name; do
    if [ -n "$name" ]; then
        echo "     - $name"
    fi
done
echo ""

echo "========================================="
echo "✅ Portainer Environment Setup Complete"
echo "========================================="

