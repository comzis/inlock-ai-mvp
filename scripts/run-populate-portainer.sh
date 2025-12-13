#!/usr/bin/env bash
# Wrapper script to populate Portainer environments via internal network
#
# This script runs the population script inside a container on the mgmt network
# Usage: ./scripts/run-populate-portainer.sh [admin-username] [admin-password]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

ADMIN_USER="${1:-admin}"
ADMIN_PASS="${2:-}"

# Try to read from secret file
SECRET_FILE="/home/comzis/apps/secrets-real/portainer-admin-password"
if [ -z "$ADMIN_PASS" ] && [ -f "$SECRET_FILE" ]; then
    ADMIN_PASS=$(cat "$SECRET_FILE" | head -1 | tr -d '\n' | tr -d '\r')
fi

if [ -z "$ADMIN_PASS" ]; then
    read -sp "Enter Portainer admin password: " ADMIN_PASS
    echo ""
fi

if [ -z "$ADMIN_PASS" ]; then
    echo "❌ Error: Password required"
    exit 1
fi

echo "Running Portainer environment population via internal network..."
echo ""

# Copy script to a container that has network access and curl
# Use oauth2-proxy or another container on mgmt network
docker compose -f compose/stack.yml --env-file .env exec -T oauth2-proxy sh <<EOF
PORTAINER_URL="http://portainer:9000"
ADMIN_USER="${ADMIN_USER}"
ADMIN_PASS="${ADMIN_PASS}"

echo "1. Authenticating with Portainer..."
AUTH_RESPONSE=\$(wget -qO- --post-data="{\\\"username\\\":\\\"\${ADMIN_USER}\\\",\\\"password\\\":\\\"\${ADMIN_PASS}\\\"}" \\
  --header="Content-Type: application/json" \\
  "\${PORTAINER_URL}/api/auth" 2>/dev/null || echo '{"err":"connection_failed"}')

JWT_TOKEN=\$(echo "\$AUTH_RESPONSE" | grep -o '"jwt":"[^"]*' | cut -d'"' -f4 || echo "")

if [ -z "\$JWT_TOKEN" ]; then
    echo "❌ Error: Failed to authenticate"
    echo "Response: \$AUTH_RESPONSE"
    exit 1
fi

echo "   ✓ Authentication successful"
echo ""

echo "2. Checking existing endpoints..."
ENDPOINTS=\$(wget -qO- --header="Authorization: Bearer \${JWT_TOKEN}" \\
  "\${PORTAINER_URL}/api/endpoints" 2>/dev/null)

if echo "\$ENDPOINTS" | grep -q '"Name":"local"'; then
    echo "   ✓ Local endpoint already exists"
else
    echo "3. Creating Local Docker environment..."
    CREATE_RESPONSE=\$(wget -qO- --post-data='{"Name":"local","EndpointType":1,"URL":"tcp://docker-socket-proxy:2375","TLS":false,"PublicURL":"","GroupID":1,"TagIDs":[]}' \\
      --header="Authorization: Bearer \${JWT_TOKEN}" \\
      --header="Content-Type: application/json" \\
      "\${PORTAINER_URL}/api/endpoints" 2>/dev/null)
    
    if echo "\$CREATE_RESPONSE" | grep -q '"Id"'; then
        echo "   ✓ Local Docker environment created"
    else
        echo "   Response: \$CREATE_RESPONSE"
    fi
fi

echo ""
echo "✅ Complete"
EOF

