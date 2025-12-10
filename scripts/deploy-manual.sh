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
  echo "❌ ERROR: .env file not found at $ENV_FILE"
  echo ""
  echo "   The deployment script requires a valid .env file with:"
  echo "   - DOMAIN variable"
  echo "   - CLOUDFLARE_API_TOKEN"
  echo "   - All required secrets"
  echo ""
  echo "   Do NOT use env.example for production deployments!"
  echo "   Create .env from env.example and fill in real values."
  echo ""
  exit 1
fi

# Pre-deployment security checks
echo "🔒 Running pre-deployment security checks..."
echo ""

# Check secret rotation status (non-blocking warnings)
if [ -f "$SCRIPT_DIR/audit-secrets.sh" ]; then
  SECRET_WARNINGS=$(bash "$SCRIPT_DIR/audit-secrets.sh" 2>&1 | grep -c "WARNING" || echo "0")
  if [ "$SECRET_WARNINGS" -gt 0 ]; then
    echo "⚠️  WARNING: Some secrets may need rotation"
    echo "   Review: docs/SECRET-MANAGEMENT.md"
    echo "   Run: ./scripts/audit-secrets.sh"
    echo ""
    read -p "Continue with deployment? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Deployment cancelled."
      exit 1
    fi
  fi
fi

echo "✅ Security checks passed"
echo ""

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

