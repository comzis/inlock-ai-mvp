#!/usr/bin/env bash
# Simple script to populate Portainer - runs inside Docker network
set -e

ADMIN_USER="${1:-admin}"
ADMIN_PASS="${2:-$(cat /home/comzis/apps/secrets-real/portainer-admin-password 2>/dev/null | head -1 || echo '')}"

[ -z "$ADMIN_PASS" ] && read -sp "Password: " ADMIN_PASS && echo ""

PORTAINER="http://portainer:9000"

echo "Authenticating..."
JWT=$(curl -s -X POST "${PORTAINER}/api/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" \
  | grep -o '"jwt":"[^"]*' | cut -d'"' -f4)

[ -z "$JWT" ] && echo "❌ Auth failed" && exit 1
echo "✓ Authenticated"

ENDPOINTS=$(curl -s -H "Authorization: Bearer ${JWT}" "${PORTAINER}/api/endpoints")
if echo "$ENDPOINTS" | grep -q '"Name":"local"'; then
    echo "✓ Local endpoint exists"
else
    echo "Creating local endpoint..."
    curl -s -X POST "${PORTAINER}/api/endpoints" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d '{"Name":"local","EndpointType":1,"URL":"tcp://docker-socket-proxy:2375","TLS":false,"GroupID":1}' \
      | grep -q '"Id"' && echo "✓ Created" || echo "⚠ Failed"
fi
