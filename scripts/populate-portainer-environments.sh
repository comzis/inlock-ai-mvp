#!/usr/bin/env bash
# Populate Portainer Environments (Endpoints)
#
# This script configures Portainer with Docker environments after initial admin setup
#
# Usage:
#   ./scripts/populate-portainer-environments.sh [admin-username] [admin-password]
#
# If credentials not provided, will prompt interactively

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Portainer configuration
PORTAINER_URL="${PORTAINER_URL:-https://portainer.inlock.ai}"
ADMIN_USER="${1:-admin}"
ADMIN_PASS="${2:-}"

# If password not provided, prompt for it
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
    echo "  3. Portainer is accessible at $PORTAINER_URL"
    exit 1
fi

echo "   ✓ Authentication successful"
echo ""

# Step 2: Get current user ID (admin user)
echo "2. Getting user information..."
USER_INFO=$(curl -s -X GET "${PORTAINER_URL}/api/users" \
  -H "Authorization: Bearer ${JWT_TOKEN}")

USER_ID=$(echo "$USER_INFO" | grep -o '"Id":[0-9]*' | head -1 | cut -d':' -f2 || echo "1")
echo "   ✓ User ID: $USER_ID"
echo ""

# Step 3: Create Local Docker Environment
echo "3. Creating Local Docker environment..."

# Check if local endpoint already exists
ENDPOINTS=$(curl -s -X GET "${PORTAINER_URL}/api/endpoints" \
  -H "Authorization: Bearer ${JWT_TOKEN}")

LOCAL_EXISTS=$(echo "$ENDPOINTS" | grep -o '"Name":"local"' || echo "")

if [ -n "$LOCAL_EXISTS" ]; then
    echo "   ⚠ Local endpoint already exists, skipping..."
else
    # Create local Docker endpoint
    # Note: Portainer CE uses Docker socket proxy via tcp://docker-socket-proxy:2375
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
        echo "   ⚠ Failed to create local endpoint, may already exist"
        echo "   Response: $CREATE_RESPONSE"
    fi
fi
echo ""

# Step 4: List all endpoints
echo "4. Current Portainer endpoints:"
ENDPOINTS=$(curl -s -X GET "${PORTAINER_URL}/api/endpoints" \
  -H "Authorization: Bearer ${JWT_TOKEN}")

ENDPOINT_COUNT=$(echo "$ENDPOINTS" | grep -o '"Id":[0-9]*' | wc -l || echo "0")
echo "   Total endpoints: $ENDPOINT_COUNT"

# Extract endpoint names
echo "$ENDPOINTS" | grep -o '"Name":"[^"]*' | cut -d'"' -f4 | while read -r name; do
    if [ -n "$name" ]; then
        echo "     - $name"
    fi
done
echo ""

# Step 5: Verify Docker socket proxy connectivity (if local endpoint exists)
if echo "$ENDPOINTS" | grep -q '"Name":"local"'; then
    echo "5. Verifying Docker connectivity..."
    
    # Get local endpoint ID
    LOCAL_ID=$(echo "$ENDPOINTS" | grep -B 5 '"Name":"local"' | grep -o '"Id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -n "$LOCAL_ID" ]; then
        # Check endpoint status
        ENDPOINT_STATUS=$(curl -s -X GET "${PORTAINER_URL}/api/endpoints/${LOCAL_ID}" \
          -H "Authorization: Bearer ${JWT_TOKEN}")
        
        STATUS=$(echo "$ENDPOINT_STATUS" | grep -o '"Status":[0-9]*' | cut -d':' -f2 || echo "0")
        
        if [ "$STATUS" = "1" ]; then
            echo "   ✓ Docker endpoint is active and connected"
        else
            echo "   ⚠ Docker endpoint status: $STATUS (may need manual verification in UI)"
        fi
    fi
else
    echo "5. Skipping Docker connectivity check (no local endpoint found)"
fi
echo ""

echo "========================================="
echo "✅ Portainer Environment Setup Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Access Portainer: $PORTAINER_URL"
echo "  2. Verify environments in: Environments → Endpoints"
echo "  3. Test Docker operations"
echo ""

