#!/usr/bin/env bash
# Populate Portainer Environments
# Usage: ./scripts/populate-portainer.sh [password]

set -e

ADMIN_USER="${1:-admin}"
ADMIN_PASS="${2:-$(cat /home/comzis/apps/secrets-real/portainer-admin-password 2>/dev/null | head -1 || echo '')}"

[ -z "$ADMIN_PASS" ] && read -sp "Enter Portainer admin password: " ADMIN_PASS && echo ""
[ -z "$ADMIN_PASS" ] && echo "❌ Password required" && exit 1

echo "=== Populating Portainer Environments ==="
echo "Authenticating..."

JWT=$(docker run --rm --network mgmt curlimages/curl:latest curl -s -X POST "http://portainer:9000/api/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" | \
  grep -o '"jwt":"[^"]*' | cut -d'"' -f4 || echo "")

if [ -z "$JWT" ]; then
    echo "❌ Authentication failed"
    echo ""
    echo "Make sure you've created the admin account in Portainer UI:"
    echo "  1. Go to: https://portainer.inlock.ai"
    echo "  2. Authenticate via Auth0"
    echo "  3. Create admin account"
    echo "  4. Update secret: echo 'your-password' > /home/comzis/apps/secrets-real/portainer-admin-password"
    exit 1
fi

echo "✓ Authenticated"

echo "Checking endpoints..."
ENDPOINTS=$(docker run --rm --network mgmt curlimages/curl:latest curl -s -H "Authorization: Bearer ${JWT}" "http://portainer:9000/api/endpoints")

if echo "$ENDPOINTS" | grep -q '"Name":"local"'; then
    echo "✓ Local endpoint exists"
else
    echo "Creating local endpoint..."
    docker run --rm --network mgmt curlimages/curl:latest curl -s -X POST "http://portainer:9000/api/endpoints" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d '{"Name":"local","EndpointType":1,"URL":"tcp://docker-socket-proxy:2375","TLS":false,"GroupID":1}' | \
      grep -q '"Id"' && echo "✓ Created" || echo "⚠ Failed"
fi

echo ""
echo "✅ Complete"

