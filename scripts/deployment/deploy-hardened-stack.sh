#!/usr/bin/env bash
set -euo pipefail

# Master deployment script for hardened INLOCK.AI stack
# Follows the three-step security review process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================="
echo "INLOCK.AI Hardened Stack Deployment"
echo "=========================================="
echo ""

# Step 1: Capture Tailnet Posture
echo "STEP 1: Capturing Tailnet and infrastructure status..."
if [ "$EUID" -eq 0 ]; then
  bash "$SCRIPT_DIR/capture-tailnet-status.sh"
else
  echo "⚠️  This step requires root privileges."
  echo "   Run manually: sudo $SCRIPT_DIR/capture-tailnet-status.sh"
  read -p "   Press Enter after capturing status..."
fi

# Step 2: Update IP Allowlists
echo ""
echo "STEP 2: Updating IP allowlists with Tailscale peer IPs..."
PEER_IPS_FILE=$(ls -t /tmp/inlock-audit/tailscale-peer-ips-*.txt 2>/dev/null | head -1)
if [ -n "$PEER_IPS_FILE" ] && [ -f "$PEER_IPS_FILE" ]; then
  echo "Found peer IPs file: $PEER_IPS_FILE"
  bash "$SCRIPT_DIR/update-allowlists.sh" "$PEER_IPS_FILE"
else
  echo "⚠️  Peer IPs file not found."
  echo ""
  echo "Options:"
  echo "  1. Run Step 1 first: sudo $SCRIPT_DIR/capture-tailnet-status.sh"
  echo "  2. Manually update: traefik/dynamic/middlewares.yml"
  echo "     Current allowlist IPs: 100.83.222.69/32, 100.96.110.8/32"
  echo ""
  read -p "Press Enter to continue (allowlist already configured)..."
fi

# Step 3: Apply Firewall Hardening
echo ""
echo "STEP 3: Applying firewall hardening via Ansible..."
if command -v ansible-playbook &> /dev/null; then
  echo "Running hardening playbook..."
  ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml
  echo ""
  echo "✅ Firewall hardening applied!"
  echo "   Verify with: sudo ufw status verbose"
else
  echo "⚠️  ansible-playbook not found."
  echo ""
  echo "Options:"
  echo "  1. Install Ansible:"
  echo "     sudo apt update && sudo apt install -y ansible"
  echo "     ansible-galaxy collection install community.docker community.general"
  echo "  2. Run from operator machine with Ansible installed"
  echo "  3. Apply firewall manually:"
  echo "     sudo ufw default deny incoming"
  echo "     sudo ufw default allow outgoing"
  echo "     sudo ufw allow 41641/udp comment 'Tailscale'"
  echo "     sudo ufw allow 22/tcp comment 'SSH'"
  echo "     sudo ufw allow 80/tcp comment 'HTTP'"
  echo "     sudo ufw allow 443/tcp comment 'HTTPS'"
  echo "     sudo ufw enable"
  echo ""
  read -p "Press Enter to continue (firewall can be configured later)..."
fi

# Step 4: Validate Compose Config
echo ""
echo "STEP 4: Validating Docker Compose configuration..."
if [ ! -f ".env" ]; then
  echo "⚠️  .env file not found. Using env.example for validation..."
  ENV_FILE="env.example"
else
  ENV_FILE=".env"
fi

if docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config > /dev/null 2>&1; then
  echo "✅ Compose configuration is valid!"
else
  echo "❌ Compose configuration validation failed!"
  echo "   Run manually: docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file $ENV_FILE config"
  exit 1
fi

# Step 5: Deploy Stack
echo ""
echo "STEP 5: Deploying stack..."
read -p "Deploy stack now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v ansible-playbook &> /dev/null; then
    ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml
  else
    echo "⚠️  ansible-playbook not found. Deploy manually:"
    echo "   cd $PROJECT_ROOT"
    echo "   docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file $ENV_FILE up -d"
  fi
else
  echo "Skipping deployment. Deploy manually when ready."
fi

echo ""
echo "=========================================="
echo "Deployment Checklist Complete!"
echo "=========================================="
echo ""
echo "Remaining manual steps:"
echo "1. ✅ Tailnet status captured"
echo "2. ✅ IP allowlists updated"
echo "3. ✅ Firewall hardening applied"
echo "4. ⚠️  Verify secrets are at /home/comzis/apps/secrets/"
echo "5. ⚠️  Rotate any previously committed credentials"
echo "6. ⚠️  Test access denial from unauthorized IPs (should return 403)"
echo "7. ⚠️  Consider image digest pinning (see docs/image-pinning-guide.md)"
echo ""

