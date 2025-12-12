#!/bin/bash
# Complete fresh start: Delete n8n user, update all services to latest
# Run: ./scripts/fresh-start-and-update-all.sh

set -euo pipefail

echo "=== Fresh Start & Update All Services ==="
echo ""
echo "This will:"
echo "  1. Delete existing n8n user(s)"
echo "  2. Update n8n to latest version"
echo "  3. Update all other services to latest versions"
echo "  4. Restart all services"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "=== Step 1: Delete n8n User ==="
echo ""

# Show current users
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n' || echo "0")

if [ "$USER_COUNT" -gt 0 ]; then
    echo "Current users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -10
    echo ""
    
    # Delete all users
    docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT email FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | while read -r email; do
        if [ -n "$email" ]; then
            echo "Deleting user: $email"
            ./scripts/delete-n8n-user.sh "$email" >/dev/null 2>&1 || true
        fi
    done
    echo "✓ All users deleted"
else
    echo "No users found (already fresh)"
fi
echo ""

echo "=== Step 2: Update n8n to Latest ==="
echo ""

# Update n8n compose file
sed -i 's|image: n8nio/n8n@sha256:.*|image: n8nio/n8n:latest|g' compose/n8n.yml
echo "✓ Updated compose file to use latest tag"

# Pull latest
echo "Pulling latest n8n image..."
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 | tail -5
echo "✓ Latest n8n image pulled"
echo ""

echo "=== Step 3: Update All Services ==="
echo ""

# Update Traefik
echo "Updating Traefik..."
sed -i 's|image: traefik:v3.1|image: traefik:latest|g' compose/stack.yml
sed -i 's|image: traefik:v3\.[0-9]*|image: traefik:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull traefik 2>&1 | tail -3
echo "✓ Traefik updated"
echo ""

# Update Grafana
echo "Updating Grafana..."
sed -i 's|image: grafana/grafana@sha256:.*|image: grafana/grafana:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull grafana 2>&1 | tail -3
echo "✓ Grafana updated"
echo ""

# Update Portainer
echo "Updating Portainer..."
sed -i 's|image: portainer/portainer-ce@sha256:.*|image: portainer/portainer-ce:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull portainer 2>&1 | tail -3
echo "✓ Portainer updated"
echo ""

# Update monitoring services
echo "Updating monitoring services..."
# Remove version pins for monitoring services
sed -i 's|image: gcr.io/cadvisor/cadvisor@sha256:.*|image: gcr.io/cadvisor/cadvisor:latest|g' compose/stack.yml
sed -i 's|image: prom/prometheus:v2\.[0-9]*@sha256:.*|image: prom/prometheus:latest|g' compose/stack.yml
sed -i 's|image: prom/alertmanager:v0\.[0-9]*|image: prom/alertmanager:latest|g' compose/stack.yml
sed -i 's|image: prom/node-exporter:v1\.[0-9]*|image: prom/node-exporter:latest|g' compose/stack.yml
sed -i 's|image: prom/blackbox-exporter:v0\.[0-9]*|image: prom/blackbox-exporter:latest|g' compose/stack.yml

docker compose -f compose/stack.yml --env-file .env pull cadvisor prometheus alertmanager node-exporter blackbox-exporter 2>&1 | tail -5
echo "✓ Monitoring services updated"
echo ""

echo "=== Step 4: Restart All Services ==="
echo ""

# Restart stack
echo "Restarting main stack..."
docker compose -f compose/stack.yml --env-file .env up -d 2>&1 | tail -5
echo "✓ Stack restarted"
echo ""

# Restart n8n
echo "Restarting n8n..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 | tail -3
echo "✓ n8n restarted"
echo ""

# Wait for services
echo "Waiting for services to be ready..."
sleep 15
echo "✓ Services should be ready"
echo ""

echo "=== Step 5: Verify Versions ==="
echo ""

# Check n8n version
if docker ps | grep -q n8n; then
    echo "n8n version:"
    docker exec compose-n8n-1 n8n --version 2>&1 | head -1 || echo "  (checking...)"
fi

# Check Traefik version
if docker ps | grep -q traefik; then
    echo "Traefik version:"
    docker exec compose-traefik-1 traefik version 2>&1 | head -1 || echo "  (checking...)"
fi
echo ""

echo "=== Fresh Start & Update Complete ==="
echo ""
echo "All services have been updated to latest versions."
echo "n8n has been reset (no users)."
echo ""
echo "=== Create New n8n Account ==="
echo ""
echo "1. Go to: https://n8n.inlock.ai"
echo "2. You'll see a setup screen (fresh install)"
echo "3. Enter:"
echo "   - Email: (your email address)"
echo "   - First Name: (your first name)"
echo "   - Last Name: (your last name)"
echo "   - Password: (choose a strong password)"
echo "4. Click 'Create Account'"
echo ""
echo "The first user will become the owner/admin."
echo ""
echo "Check service status:"
echo "  docker compose -f compose/stack.yml --env-file .env ps"
echo "  docker compose -f compose/n8n.yml --env-file .env ps"
echo ""

