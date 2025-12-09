#!/usr/bin/env bash
set -euo pipefail

# Complete manual deployment script (no Ansible required)
# Combines firewall, service fixes, and validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo "Manual Deployment - INLOCK.AI Stack"
echo "=========================================="
echo ""
echo "This script handles deployment without Ansible."
echo ""

# Check prerequisites
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "env.example" ]; then
    echo "⚠️  .env not found, using env.example"
    ENV_FILE="env.example"
  else
    echo "❌ No .env or env.example found"
    exit 1
  fi
fi

# Step 1: Firewall
echo "STEP 1: Configuring firewall..."
if [ "$EUID" -eq 0 ]; then
  bash "$SCRIPT_DIR/apply-firewall-manual.sh"
else
  echo "⚠️  Firewall configuration requires sudo"
  echo "   Run: sudo $SCRIPT_DIR/apply-firewall-manual.sh"
  echo ""
  read -p "Press Enter after configuring firewall, or Ctrl+C to exit..."
fi

# Step 2: Verify allowlist
echo ""
echo "STEP 2: Verifying IP allowlist..."
if grep -q "100.83.222.69/32\|100.96.110.8/32" traefik/dynamic/middlewares.yml; then
  echo "  ✅ Allowlist configured: 100.83.222.69/32, 100.96.110.8/32"
else
  echo "  ⚠️  Allowlist may need configuration"
  echo "  Edit: traefik/dynamic/middlewares.yml"
fi

# Step 3: Fix services
echo ""
echo "STEP 3: Fixing service permissions..."
bash "$SCRIPT_DIR/fix-and-restart-services.sh"

# Step 4: Validate compose
echo ""
echo "STEP 4: Validating Docker Compose configuration..."
if docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config > /dev/null 2>&1; then
  echo "  ✅ Compose configuration is valid"
else
  echo "  ❌ Compose configuration validation failed"
  docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config
  exit 1
fi

# Step 5: Deploy/restart services
echo ""
echo "STEP 5: Ensuring services are running..."
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" up -d

# Step 6: Status check
echo ""
echo "STEP 6: Service status..."
sleep 5
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" ps

echo ""
echo "=========================================="
echo "Manual Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure TLS: ./scripts/setup-tls.sh"
echo "2. Rotate secrets: ./scripts/rotate-secrets.sh"
echo "3. Test access control: ./scripts/test-access-control.sh (once TLS works)"
echo ""
echo "For detailed status: ./scripts/finalize-deployment.sh"

