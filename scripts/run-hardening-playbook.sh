#!/usr/bin/env bash
# Run Ansible hardening playbook with proper flags

set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Running Ansible Hardening Playbook ==="
echo ""
echo "This will configure the firewall and apply security hardening."
echo "You will be prompted for your sudo password."
echo ""

cd ansible

# Run with become password prompt
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml --ask-become-pass

echo ""
echo "=== Playbook Complete ==="
echo ""
echo "Verifying firewall status..."
sudo ufw status verbose




