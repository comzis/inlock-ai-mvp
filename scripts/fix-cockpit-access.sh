#!/bin/bash
# Fix Cockpit access from Docker containers

echo "=== Fixing Cockpit Access from Containers ==="

# Allow Docker network to access Cockpit
echo "Allowing Docker mgmt network (172.18.0.0/16) to access Cockpit..."
sudo ufw allow from 172.18.0.0/16 to any port 9090

# Verify Cockpit is listening
echo ""
echo "Verifying Cockpit is listening..."
ss -tlnp | grep 9090

echo ""
echo "✅ Firewall rule added. Test from container:"
echo "   docker compose -f compose/stack.yml --env-file .env exec traefik wget -qO- --timeout=5 http://172.18.0.1:9090"
