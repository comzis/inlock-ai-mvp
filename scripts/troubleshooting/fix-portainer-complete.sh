#!/usr/bin/env bash
# Complete Portainer fix script

set -euo pipefail

echo "=== Fixing Portainer Issues ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges."
  echo "Run with: sudo $0"
  exit 1
fi

echo "Step 1: Fixing Portainer data directory permissions..."
chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
chmod -R 755 /home/comzis/apps/traefik/portainer_data

echo "Step 2: Restarting Portainer..."
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart portainer

echo "Step 3: Waiting for Portainer to start..."
sleep 5

echo "Step 4: Checking Portainer status..."
docker ps | grep portainer

echo ""
echo "✅ Portainer fix complete!"
echo ""
echo "Check logs: docker logs compose-portainer-1"
echo "Access: https://portainer.inlock.ai (requires Tailscale VPN)"
