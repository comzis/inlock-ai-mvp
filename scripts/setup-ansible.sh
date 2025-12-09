#!/usr/bin/env bash
# Setup Ansible for firewall hardening

set -euo pipefail

echo "=== Ansible Setup for Firewall Hardening ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges."
  echo "Run with: sudo $0"
  exit 1
fi

echo "Step 1: Installing Ansible..."
apt update
apt install -y ansible python3-pip

echo ""
echo "Step 2: Installing Ansible community.general collection..."
ansible-galaxy collection install community.general

echo ""
echo "✅ Ansible setup complete!"
echo ""
echo "You can now run the hardening playbook:"
echo "  cd /home/comzis/inlock-infra"
echo "  ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml"
