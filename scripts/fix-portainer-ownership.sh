#!/bin/bash
# Fix Portainer data directory ownership

echo "=========================================="
echo "PORTAINER OWNERSHIP FIX"
echo "=========================================="
echo ""
echo "This script fixes Portainer data directory ownership."
echo "Requires sudo access."
echo ""

# Fix ownership
echo "1. Fixing ownership..."
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data

# Fix permissions
echo "2. Fixing permissions..."
sudo chmod 755 /home/comzis/apps/traefik/portainer_data

# Restart Portainer
echo "3. Restarting Portainer..."
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart portainer

echo ""
echo "4. Waiting for service to start..."
sleep 5

echo ""
echo "5. Checking status..."
docker compose -f compose/stack.yml --env-file .env ps portainer

echo ""
echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="

