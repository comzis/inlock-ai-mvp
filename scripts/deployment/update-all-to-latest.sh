#!/bin/bash
# Update ALL services to latest versions (no hardcoded versions)
# Run: ./scripts/update-all-to-latest.sh

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
echo "This script will update all services to use 'latest' tags"
echo "and remove any hardcoded version pins."
echo ""

read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Update cancelled"
    exit 0
fi

echo ""
echo "=== Updating Compose Files ==="
echo ""

# Function to update image to latest
update_to_latest() {
    local file="$1"
    local pattern="$2"
    
    # Remove SHA256 pins
    sed -i "s|image: ${pattern}@sha256:[^ ]*|image: ${pattern}:latest|g" "$file"
    # Remove version tags (v1.2.3, 1.2.3, etc.)
    sed -i "s|image: ${pattern}:[0-9].*|image: ${pattern}:latest|g" "$file"
    # Ensure it's latest (catch any remaining)
    sed -i "s|image: ${pattern}[^:]*|image: ${pattern}:latest|g" "$file"
}

# Update n8n
echo "1. Updating n8n.yml..."
update_to_latest "compose/n8n.yml" "n8nio/n8n"
echo "   ✓ n8n.yml updated"

# Update stack.yml services
echo "2. Updating stack.yml..."
update_to_latest "compose/stack.yml" "traefik"
update_to_latest "compose/stack.yml" "grafana/grafana"
update_to_latest "compose/stack.yml" "portainer/portainer-ce"
update_to_latest "compose/stack.yml" "gcr.io/cadvisor/cadvisor"
update_to_latest "compose/stack.yml" "prom/prometheus"
update_to_latest "compose/stack.yml" "prom/alertmanager"
update_to_latest "compose/stack.yml" "prom/node-exporter"
update_to_latest "compose/stack.yml" "prom/blackbox-exporter"
echo "   ✓ stack.yml updated"
echo ""

# Verify changes
echo "3. Verifying updates..."
echo ""
echo "n8n image:"
grep "image:" compose/n8n.yml | grep n8n
echo ""
echo "Stack images:"
grep "image:" compose/stack.yml | grep -E "(traefik|grafana|portainer|cadvisor|prometheus|alertmanager|node-exporter|blackbox)" | head -10
echo ""

# Pull latest images
echo "4. Pulling latest images..."
echo ""
echo "   Pulling n8n..."
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 | tail -3
echo ""
echo "   Pulling stack services..."
docker compose -f compose/stack.yml --env-file .env pull traefik grafana portainer cadvisor prometheus alertmanager node-exporter blackbox-exporter 2>&1 | tail -10
echo ""

# Restart services
echo "5. Restarting services with latest images..."
echo ""
echo "   Restarting n8n..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 | tail -3
echo ""
echo "   Restarting stack services..."
docker compose -f compose/stack.yml --env-file .env up -d 2>&1 | tail -5
echo ""

# Wait for services
echo "6. Waiting for services to be ready..."
sleep 15
echo "   ✓ Services should be ready"
echo ""

# Show versions
echo "7. Current versions:"
echo ""
if docker ps | grep -q n8n; then
    echo "   n8n:"
    docker exec compose-n8n-1 n8n --version 2>&1 | head -1 || echo "     (version check unavailable)"
fi
echo ""
echo "   Check all services:"
echo "     docker compose -f compose/stack.yml --env-file .env ps"
echo "     docker compose -f compose/n8n.yml --env-file .env ps"
echo ""

echo "=== Update Complete ==="
echo ""
echo "All services have been updated to use 'latest' tags."
echo ""
echo "Note: Services will now automatically use the latest version"
echo "when you run 'docker compose pull' in the future."
echo ""

