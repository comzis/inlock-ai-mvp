#!/usr/bin/env bash
set -euo pipefail

# Manual firewall configuration script (no Ansible required)
# Applies UFW rules for hardened INLOCK.AI stack

echo "Manual Firewall Configuration"
echo "============================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  This script requires root privileges."
  echo "   Run with: sudo $0"
  exit 1
fi

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
  echo "Installing UFW..."
  apt update && apt install -y ufw
fi

echo "Step 1: Setting default policies..."
ufw default deny incoming
ufw default allow outgoing
ufw default allow routed

echo "Step 2: Allowing required ports..."
ufw allow 41641/udp comment 'Tailscale'
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

echo "Step 3: Enabling firewall..."
ufw --force enable

echo ""
echo "✅ Firewall configuration complete!"
echo ""
echo "Current status:"
ufw status verbose

echo ""
echo "Note: If you need to allow additional ports later:"
echo "  sudo ufw allow <port>/<protocol> comment 'description'"

