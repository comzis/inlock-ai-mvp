#!/bin/bash
# Migrate Cockpit from host service to Docker container
# Run with: sudo ./scripts/migrate-cockpit-to-container.sh

set -euo pipefail

echo "=== Migrating Cockpit to Docker Container ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# 1. Stop host Cockpit service
echo "1. Stopping host Cockpit service..."
systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
systemctl disable cockpit.socket 2>/dev/null || true
echo "✓ Host Cockpit stopped"
echo ""

# 2. Verify port is free
echo "2. Verifying port 9090 is free..."
if ss -tulpn 2>/dev/null | grep -q ":9090"; then
    echo "⚠️  Port 9090 is still in use:"
    ss -tulpn 2>/dev/null | grep ":9090"
    echo ""
    echo "Please stop the service using port 9090 manually"
    exit 1
else
    echo "✓ Port 9090 is free"
fi
echo ""

# 3. Start Docker container
echo "3. Starting Cockpit container..."
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d cockpit
echo "✓ Container started"
echo ""

# 4. Wait for container to start
echo "4. Waiting for container to be ready..."
sleep 5

# 5. Check container status
echo "5. Checking container status..."
if docker ps | grep -q cockpit; then
    echo "✓ Container is running"
    docker ps | grep cockpit
else
    echo "✗ Container is not running"
    echo "Checking logs..."
    docker logs compose-cockpit-1 --tail 20 2>&1 | tail -10
    exit 1
fi
echo ""

# 6. Test access
echo "6. Testing access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>&1 || echo "000")
case "$HTTP_CODE" in
    200|302)
        echo "✓ Cockpit is accessible! (HTTP $HTTP_CODE)"
        ;;
    403)
        echo "⚠️  IP allowlist blocking (HTTP 403)"
        echo "   Access from allowed IP required"
        ;;
    502|503|504)
        echo "⚠️  Backend connectivity issue (HTTP $HTTP_CODE)"
        echo "   Check Traefik configuration"
        ;;
    *)
        echo "⚠️  Unexpected response (HTTP $HTTP_CODE)"
        ;;
esac
echo ""

echo "=== Migration Complete ==="
echo ""
echo "Cockpit is now running in Docker container"
echo "Access: https://cockpit.inlock.ai"
echo ""
echo "To view logs: docker logs compose-cockpit-1"
echo "To restart: docker compose -f compose/stack.yml --env-file .env restart cockpit"
echo ""

