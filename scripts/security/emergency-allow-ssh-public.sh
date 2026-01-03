#!/usr/bin/env bash
set -euo pipefail

# Emergency script to temporarily allow SSH from public IP
# This is needed when Cursor connects via public IP instead of Tailscale

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Emergency SSH Access - Allow Public IP ==="
echo ""
echo "This script will temporarily allow SSH from your public IP"
echo "so you can reconnect via Cursor."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Detect public IP from current connections
PUBLIC_IP=$(who | grep -E "pts/[0-9]+" | grep -v "100\." | head -1 | awk '{print $NF}' | tr -d '()' || echo "")
if [ -z "$PUBLIC_IP" ]; then
    # Try to get from last login
    PUBLIC_IP=$(last -n 1 | grep -v "100\." | awk '{print $3}' | grep -E "^[0-9]" | head -1 || echo "")
fi

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${YELLOW}⚠️  Could not auto-detect public IP${NC}"
    echo "Please provide your public IP address:"
    read -r PUBLIC_IP
fi

echo "Detected/Using public IP: $PUBLIC_IP"
echo ""

# Check if UFW is active
if ! ufw status | grep -qi "Status: active"; then
    echo -e "${YELLOW}⚠️  UFW is not active${NC}"
    echo "Enabling UFW..."
    ufw --force enable
fi

# Add temporary SSH rule for public IP
echo "Adding temporary SSH rule for $PUBLIC_IP..."
if ufw status numbered 2>/dev/null | grep -q "$PUBLIC_IP.*22"; then
    echo -e "${YELLOW}⚠️  SSH rule for $PUBLIC_IP already exists${NC}"
else
    ufw allow from "$PUBLIC_IP" to any port 22 proto tcp comment 'SSH - Emergency Access (TEMP - Remove after reconnecting via Tailscale)'
    echo -e "${GREEN}✅ SSH rule added for $PUBLIC_IP${NC}"
fi

echo ""
echo "=== Current SSH Firewall Rules ==="
ufw status numbered | grep -E "22|ssh|$PUBLIC_IP" || echo "  (none found)"

echo ""
echo -e "${GREEN}✅ Emergency SSH access enabled!${NC}"
echo ""
echo "You should now be able to SSH from Cursor using public IP."
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: After reconnecting, you should:${NC}"
echo "1. Connect via Tailscale instead (recommended): ssh comzis@100.83.222.69"
echo "2. Or remove this temporary rule: sudo ufw delete allow from $PUBLIC_IP to any port 22"
echo ""
echo "To remove the temporary rule later, run:"
echo "  sudo ufw delete allow from $PUBLIC_IP to any port 22"
echo ""

