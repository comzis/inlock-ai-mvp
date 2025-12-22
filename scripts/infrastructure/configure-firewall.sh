#!/bin/bash
# Configure UFW Firewall - Restrict all unnecessary ports
# Run with: sudo ./configure-firewall.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Configuring UFW Firewall"
echo "  Started: $(date)"
echo "=========================================="
echo ""

# Install UFW if not present
if ! command -v ufw >/dev/null 2>&1; then
    echo "Installing UFW..."
    apt-get update -qq
    apt-get install -y ufw
    echo "  ✓ UFW installed"
fi

# Backup existing rules
if [ -f /etc/ufw/user.rules ]; then
    BACKUP="/etc/ufw/user.rules.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/ufw/user.rules "$BACKUP"
    echo "Backup created: $BACKUP"
fi

# Enable UFW if not already enabled
if ! ufw status | grep -q "Status: active"; then
    echo "Enabling UFW firewall..."
    ufw --force enable
    echo "  ✓ UFW enabled"
else
    echo "  UFW is already active"
fi

# Set default policies
echo ""
echo "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing
echo "  ✓ Default policies: deny incoming, allow outgoing"

# Allow Tailscale
echo ""
echo "Configuring Tailscale access..."
ufw allow 41641/udp comment 'Tailscale'
echo "  ✓ Tailscale port allowed"

# Allow HTTP/HTTPS (required for Traefik)
echo ""
echo "Configuring web access..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
echo "  ✓ HTTP/HTTPS allowed"

# Restrict SSH to Tailscale IPs only
echo ""
echo "Restricting SSH access..."
# Remove existing SSH rules
ufw status numbered | grep "22/tcp" | awk -F'[][]' '{print $2}' | sort -rn | while read num; do
    echo "y" | ufw delete "$num" >/dev/null 2>&1 || true
done

# Add Tailscale-specific SSH rules
ufw allow from 100.83.222.69/32 to any port 22 comment 'SSH - Tailscale Server'
ufw allow from 100.96.110.8/32 to any port 22 comment 'SSH - Tailscale MacBook'
echo "  ✓ SSH restricted to Tailscale IPs"

# Block unnecessary ports
echo ""
echo "Blocking unnecessary ports..."
ufw deny 11434/tcp comment 'Ollama - Internal only'
ufw deny 3040/tcp comment 'Port 3040 - Internal only'
ufw deny 5432/tcp comment 'PostgreSQL - Internal only'
echo "  ✓ Unnecessary ports blocked"

# Allow internal Docker networks
echo ""
echo "Configuring internal network access..."
ufw allow from 172.20.0.0/16 comment 'Docker edge network'
ufw allow from 172.18.0.0/16 comment 'Docker default network'
ufw allow from 172.17.0.0/16 comment 'Docker bridge network'
echo "  ✓ Internal Docker networks allowed"

# Show final status
echo ""
echo "=========================================="
echo "  Firewall Configuration Complete"
echo "=========================================="
echo ""
echo "Firewall status:"
ufw status numbered
echo ""
echo "Summary:"
echo "✓ SSH restricted to Tailscale IPs (100.83.222.69, 100.96.110.8)"
echo "✓ HTTP/HTTPS allowed (80, 443)"
echo "✓ Tailscale allowed (41641/udp)"
echo "✓ Unnecessary ports blocked (11434, 3040, 5432)"
echo "✓ Internal Docker networks allowed"
echo ""
echo "Next steps:"
echo "1. Test SSH access from Tailscale IPs"
echo "2. Verify Docker containers can communicate internally"
echo "3. Check firewall logs: sudo tail -f /var/log/ufw.log"
echo ""


