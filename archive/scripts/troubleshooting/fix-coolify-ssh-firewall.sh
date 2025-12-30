#!/bin/bash
#
# Fix UFW firewall to allow Coolify SSH connections
# This script adds rules to allow SSH from Docker networks
#
# Usage: sudo ./scripts/fix-coolify-ssh-firewall.sh

set -e

echo "=== Fixing UFW Firewall for Coolify SSH Access ==="
echo ""

# Get Docker network subnets
MGMT_SUBNET=$(docker network inspect mgmt --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.18.0.0/16")
COOLIFY_SUBNET=$(docker network inspect coolify --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.23.0.0/16")

echo "Detected Docker networks:"
echo "  - mgmt network: $MGMT_SUBNET"
echo "  - coolify network: $COOLIFY_SUBNET"
echo ""

# Extract base subnet (first 3 octets)
MGMT_BASE=$(echo $MGMT_SUBNET | cut -d'/' -f1 | cut -d'.' -f1-3)
COOLIFY_BASE=$(echo $COOLIFY_SUBNET | cut -d'/' -f1 | cut -d'.' -f1-3)

echo "Adding UFW rules..."
echo ""

# Allow SSH from mgmt network (where Coolify is)
if sudo ufw status | grep -q "172.18.0.0/16.*22"; then
    echo "✓ Rule for mgmt network already exists"
else
    echo "Adding rule: Allow SSH from mgmt network ($MGMT_SUBNET)"
    sudo ufw allow from $MGMT_SUBNET to any port 22 proto tcp comment 'Coolify SSH access (mgmt network)'
fi

# Allow SSH from coolify network
if sudo ufw status | grep -q "172.23.0.0/16.*22"; then
    echo "✓ Rule for coolify network already exists"
else
    echo "Adding rule: Allow SSH from coolify network ($COOLIFY_SUBNET)"
    sudo ufw allow from $COOLIFY_SUBNET to any port 22 proto tcp comment 'Coolify SSH access (coolify network)'
fi

# Also allow broader Docker network range (172.16.0.0/12 covers all Docker networks)
if sudo ufw status | grep -q "172.16.0.0/12.*22"; then
    echo "✓ Rule for Docker networks already exists"
else
    echo "Adding rule: Allow SSH from all Docker networks (172.16.0.0/12)"
    sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'Docker networks SSH access'
fi

echo ""
echo "Reloading UFW..."
sudo ufw reload

echo ""
echo "=== Verification ==="
echo ""
echo "Current UFW rules for SSH:"
sudo ufw status numbered | grep -E "22|SSH|Coolify|Docker" || sudo ufw status | grep 22

echo ""
echo "Testing SSH connection from Coolify container..."
if docker exec services-coolify-1 nc -zv -w 5 100.83.222.69 22 2>&1 | grep -q "succeeded\|open"; then
    echo "✅ SUCCESS: SSH port 22 is now accessible from Coolify container!"
    echo ""
    echo "You can now retry the server validation in Coolify UI."
else
    echo "⚠️  Connection test still failing. Checking firewall status..."
    sudo ufw status verbose | head -10
    echo ""
    echo "If still failing, check:"
    echo "  1. UFW is enabled: sudo ufw status | grep Status"
    echo "  2. SSH service is running: sudo systemctl status sshd"
    echo "  3. SSH is listening: sudo ss -tlnp | grep :22"
fi

echo ""
echo "=== Fix Complete ==="

