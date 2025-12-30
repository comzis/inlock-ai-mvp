#!/bin/bash
# Fix Portainer permissions and restart

set -e

echo "=== Fixing Portainer Permissions ==="
echo "Setting ownership to 1000:1000 (Portainer user)..."
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data

echo "✅ Permissions fixed"
echo ""

echo "=== Verifying Directory Structure ==="
ls -lah /home/comzis/apps/traefik/portainer_data/ | head -10

echo ""
echo "=== Restarting Portainer ==="
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart portainer

echo ""
echo "✅ Portainer restarted"
echo ""
echo "=== Waiting for Portainer to start ==="
sleep 8

echo ""
echo "=== Checking Portainer Status ==="
docker compose -f compose/stack.yml --env-file .env ps portainer

echo ""
echo "=== Recent Logs ==="
docker compose -f compose/stack.yml --env-file .env logs --tail 10 portainer

echo ""
echo "=== Testing Portainer Endpoint ==="
curl -k -I https://portainer.inlock.ai 2>&1 | head -5 || echo "Portainer not yet accessible"
