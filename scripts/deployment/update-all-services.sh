#!/bin/bash
# Update all services to latest versions
# Run: ./scripts/update-all-services.sh

# SECURITY: THIS SCRIPT IS DISABLED
# This script automatically updates all Docker images to :latest tags, which:
# - Introduces unpredictable breaking changes
# - Can silently introduce security vulnerabilities
# - Makes deployments non-reproducible
# - Violates security best practices for production
#
# RECOMMENDATION: Use manual version pinning with security review instead.
# - Check release notes for breaking changes
# - Test in staging environment
# - Update compose files with specific version tags or SHA256 digests
# - Review security advisories before updating
#
# See: docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md
# See: docs/security/AUDIT-RECOMMENDATIONS-REVIEW-2026-01-08.md

echo "ERROR: This script has been disabled for security reasons." >&2
echo "It automatically updates all services to :latest, which introduces security risks." >&2
echo "" >&2
echo "For safe updates:" >&2
echo "  1. Review release notes and security advisories" >&2
echo "  2. Test updates in staging environment" >&2
echo "  3. Update compose files with specific version tags or SHA256 digests" >&2
echo "  4. Commit changes with security review" >&2
echo "" >&2
echo "See docs/security/ for security guidelines." >&2
exit 1

set -euo pipefail

echo "=== Update All Services to Latest Versions ==="
echo ""

# Services to update
SERVICES=(
    "n8n:n8nio/n8n:latest"
    "traefik:traefik:latest"
    "grafana:grafana/grafana:latest"
    "portainer:portainer/portainer-ce:latest"
    "cadvisor:gcr.io/cadvisor/cadvisor:latest"
    "prometheus:prom/prometheus:latest"
    "alertmanager:prom/alertmanager:latest"
    "node-exporter:prom/node-exporter:latest"
    "blackbox-exporter:prom/blackbox-exporter:latest"
)

echo "Services to update:"
for service in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo "$service" | cut -d: -f1)
    IMAGE=$(echo "$service" | cut -d: -f2-)
    echo "  - $SERVICE_NAME → $IMAGE"
done
echo ""

read -p "Continue with updates? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Update cancelled"
    exit 0
fi

echo ""
echo "=== Updating Services ==="
echo ""

# Update n8n
echo "1. Updating n8n..."
# Remove SHA256 pins and version tags, set to latest
sed -i 's|image: n8nio/n8n@sha256:[^ ]*|image: n8nio/n8n:latest|g' compose/n8n.yml
sed -i 's|image: n8nio/n8n:[0-9].*|image: n8nio/n8n:latest|g' compose/n8n.yml
sed -i 's|image: n8nio/n8n.*|image: n8nio/n8n:latest|g' compose/n8n.yml
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 | tail -3
echo "   ✓ n8n updated to latest"
echo ""

# Update Traefik
echo "2. Updating Traefik..."
# Remove version tags, set to latest
sed -i 's|image: traefik:v[0-9].*|image: traefik:latest|g' compose/stack.yml
sed -i 's|image: traefik:.*|image: traefik:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull traefik 2>&1 | tail -3
echo "   ✓ Traefik updated to latest"
echo ""

# Update Grafana
echo "3. Updating Grafana..."
# Remove SHA256 pins and version tags, set to latest
sed -i 's|image: grafana/grafana@sha256:[^ ]*|image: grafana/grafana:latest|g' compose/stack.yml
sed -i 's|image: grafana/grafana:[0-9].*|image: grafana/grafana:latest|g' compose/stack.yml
sed -i 's|image: grafana/grafana.*|image: grafana/grafana:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull grafana 2>&1 | tail -3
echo "   ✓ Grafana updated to latest"
echo ""

# Update Portainer
echo "4. Updating Portainer..."
# Remove SHA256 pins and version tags, set to latest
sed -i 's|image: portainer/portainer-ce@sha256:[^ ]*|image: portainer/portainer-ce:latest|g' compose/stack.yml
sed -i 's|image: portainer/portainer-ce:[0-9].*|image: portainer/portainer-ce:latest|g' compose/stack.yml
sed -i 's|image: portainer/portainer-ce.*|image: portainer/portainer-ce:latest|g' compose/stack.yml
docker compose -f compose/stack.yml --env-file .env pull portainer 2>&1 | tail -3
echo "   ✓ Portainer updated to latest"
echo ""

# Update monitoring services
echo "5. Updating monitoring services..."
# Update cadvisor
sed -i 's|image: gcr.io/cadvisor/cadvisor@sha256:[^ ]*|image: gcr.io/cadvisor/cadvisor:latest|g' compose/stack.yml
sed -i 's|image: gcr.io/cadvisor/cadvisor.*|image: gcr.io/cadvisor/cadvisor:latest|g' compose/stack.yml

# Update prometheus
sed -i 's|image: prom/prometheus:v[0-9].*|image: prom/prometheus:latest|g' compose/stack.yml
sed -i 's|image: prom/prometheus@sha256:[^ ]*|image: prom/prometheus:latest|g' compose/stack.yml
sed -i 's|image: prom/prometheus.*|image: prom/prometheus:latest|g' compose/stack.yml

# Update alertmanager
sed -i 's|image: prom/alertmanager:v[0-9].*|image: prom/alertmanager:latest|g' compose/stack.yml
sed -i 's|image: prom/alertmanager.*|image: prom/alertmanager:latest|g' compose/stack.yml

# Update node-exporter
sed -i 's|image: prom/node-exporter:v[0-9].*|image: prom/node-exporter:latest|g' compose/stack.yml
sed -i 's|image: prom/node-exporter.*|image: prom/node-exporter:latest|g' compose/stack.yml

# Update blackbox-exporter
sed -i 's|image: prom/blackbox-exporter:v[0-9].*|image: prom/blackbox-exporter:latest|g' compose/stack.yml
sed -i 's|image: prom/blackbox-exporter.*|image: prom/blackbox-exporter:latest|g' compose/stack.yml

docker compose -f compose/stack.yml --env-file .env pull cadvisor prometheus alertmanager node-exporter blackbox-exporter 2>&1 | tail -5
echo "   ✓ Monitoring services updated to latest"
echo ""

echo "=== Restarting Services ==="
echo ""

# Restart services
echo "6. Restarting services with new images..."
docker compose -f compose/stack.yml --env-file .env up -d 2>&1 | tail -5
docker compose -f compose/n8n.yml --env-file .env up -d 2>&1 | tail -3
echo "   ✓ Services restarted"
echo ""

# Wait for services
echo "7. Waiting for services to be ready..."
sleep 10
echo "   ✓ Services should be ready"
echo ""

echo "=== Update Complete ==="
echo ""
echo "All services have been updated to latest versions."
echo ""
echo "Check service status:"
echo "  docker compose -f compose/stack.yml --env-file .env ps"
echo "  docker compose -f compose/n8n.yml --env-file .env ps"
echo ""
echo "View logs:"
echo "  docker compose -f compose/stack.yml --env-file .env logs --tail 20"
echo ""

