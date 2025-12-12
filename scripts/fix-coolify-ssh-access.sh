#!/bin/bash
#
# Fix Coolify SSH access by allowing Docker networks through UFW
# This allows Coolify container to SSH to the host via Tailscale IP
#
# Usage: sudo ./scripts/fix-coolify-ssh-access.sh

set -e

echo "=== Fixing Coolify SSH Access ==="
echo ""

# Get Docker network ranges
DOCKER_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "^coolify|^mgmt" || echo "")

echo "Found Docker networks:"
echo "$DOCKER_NETWORKS"
echo ""

# Allow SSH from Docker bridge networks
echo "Adding UFW rules to allow SSH from Docker networks..."

# Allow common Docker bridge network ranges
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment "Docker networks SSH access"
sudo ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment "Docker networks SSH access"

echo ""
echo "=== Current UFW SSH Rules ==="
sudo ufw status | grep -E "22|SSH" || echo "No SSH rules found"

echo ""
echo "=== Testing SSH from Docker network ==="
# Test if we can reach SSH from a test container
docker run --rm --network coolify_coolify alpine nc -zv 100.83.222.69 22 2>&1 || echo "⚠️  Test failed - may need to restart Coolify"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. Restart Coolify: cd /home/comzis/inlock-infra && docker compose -f compose/coolify.yml --env-file .env restart coolify"
echo "2. In Coolify UI, try validating the server connection again"
echo "3. If using Tailscale IP, you can also try using 'deploy-host' as hostname (mapped via extra_hosts)"

