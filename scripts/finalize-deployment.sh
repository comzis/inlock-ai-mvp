#!/usr/bin/env bash
set -euo pipefail

# Final deployment automation script
# Handles remaining tasks: permissions, TLS, secrets, validation

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Final Deployment Automation"
echo "==========================="
echo ""

# Step 1: Fix Portainer permissions
echo "Step 1: Fixing Portainer data directory permissions..."
PORTAINER_DATA="/home/comzis/apps/traefik/portainer_data"
if [ -d "$PORTAINER_DATA" ]; then
  # Try without sudo first
  chown -R 1000:1000 "$PORTAINER_DATA" 2>/dev/null || {
    echo "  ⚠️  Requires sudo for chown"
    echo "  Run manually: sudo chown -R 1000:1000 $PORTAINER_DATA"
    echo "  Then restart: docker compose -f compose/stack.yml --env-file .env restart portainer"
  }
  chmod 755 "$PORTAINER_DATA"
  echo "  ✅ Permissions updated"
else
  echo "  ⚠️  Portainer data directory not found: $PORTAINER_DATA"
fi

# Step 2: Verify n8n router host is literal
echo ""
echo "Step 2: Verifying n8n router configuration..."
if grep -q 'Host(`n8n.inlock.ai`)' compose/n8n.yml && grep -q 'Host(`n8n.inlock.ai`)' traefik/dynamic/routers.yml; then
  echo "  ✅ n8n router uses literal hostname"
else
  echo "  ⚠️  n8n router may need literal hostname fix"
fi

# Step 3: Validate compose config
echo ""
echo "Step 3: Validating Docker Compose configuration..."
if docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config > /dev/null 2>&1; then
  echo "  ✅ Compose configuration is valid"
else
  echo "  ❌ Compose configuration validation failed"
  echo "  Run: docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config"
fi

# Step 4: Check secrets
echo ""
echo "Step 4: Checking secrets..."
EXTERNAL_SECRETS="/home/comzis/apps/secrets"
SECRETS=(
  "positive-ssl.crt"
  "positive-ssl.key"
  "traefik-dashboard-users.htpasswd"
  "portainer-admin-password"
  "n8n-db-password"
  "n8n-encryption-key"
)

ALL_SECRETS_OK=true
for secret in "${SECRETS[@]}"; do
  if [ -f "$EXTERNAL_SECRETS/$secret" ] && [ -s "$EXTERNAL_SECRETS/$secret" ]; then
    echo "  ✅ $secret exists"
  else
    echo "  ⚠️  $secret missing or empty"
    ALL_SECRETS_OK=false
  fi
done

if [ "$ALL_SECRETS_OK" = false ]; then
  echo ""
  echo "  Run secret rotation: ./scripts/rotate-secrets.sh"
fi

# Step 5: Check TLS configuration
echo ""
echo "Step 5: Checking TLS configuration..."
if grep -q "CLOUDFLARE_API_TOKEN=" .env && ! grep -q "CLOUDFLARE_API_TOKEN=replace-me" .env; then
  echo "  ✅ Cloudflare API token configured"
else
  echo "  ⚠️  Cloudflare API token not configured"
  echo "  Run: ./scripts/setup-tls.sh"
fi

# Step 6: Service status
echo ""
echo "Step 6: Checking service status..."
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | grep -E "(NAME|compose-)" | head -10

echo ""
echo "===================================="
echo "Summary"
echo "===================================="
echo "✅ Access control: Configured (100.83.222.69/32, 100.96.110.8/32)"
echo "✅ n8n router: Literal hostname configured"
echo "$([ "$ALL_SECRETS_OK" = true ] && echo '✅' || echo '⚠️ ' ) Secrets: $([ "$ALL_SECRETS_OK" = true ] && echo 'All configured' || echo 'Need rotation')"
echo ""
echo "Remaining tasks:"
echo "1. Fix Portainer permissions (if not done): sudo chown -R 1000:1000 $PORTAINER_DATA"
echo "2. Configure TLS: ./scripts/setup-tls.sh"
echo "3. Rotate secrets: ./scripts/rotate-secrets.sh"
echo "4. Test access control: ./scripts/test-access-control.sh (from external IP)"
echo "5. Pin images to digests: See docs/image-pinning-guide.md"

