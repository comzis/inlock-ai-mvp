#!/usr/bin/env bash
set -euo pipefail

# Safely enable firewall with SSH access from both Tailscale and public IP
# This allows you to keep the firewall enabled while maintaining access from Cursor

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Enable Firewall with SSH Access ==="
echo ""
echo "This script will:"
echo "1. Enable UFW firewall"
echo "2. Configure SSH access from Tailscale subnet (100.64.0.0/10)"
echo "3. Configure SSH access from your public IP (for Cursor)"
echo "4. Configure other required ports (HTTP, HTTPS, Tailscale UDP)"
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
    echo "Please provide your public IP address (or press Enter to skip public IP rule):"
    read -r PUBLIC_IP
    if [ -z "$PUBLIC_IP" ]; then
        echo -e "${YELLOW}⚠️  Skipping public IP rule - you'll need to connect via Tailscale${NC}"
        PUBLIC_IP=""
    fi
fi

# Step 1: Enable UFW
echo ""
echo "Step 1: Enabling UFW firewall..."
if ufw status | grep -qi "Status: inactive"; then
    ufw --force enable
    echo -e "${GREEN}✅ UFW enabled${NC}"
else
    echo -e "${GREEN}✅ UFW is already active${NC}"
fi

# Step 2: Set default policies
echo ""
echo "Step 2: Setting default policies..."
ufw default deny incoming >/dev/null 2>&1 || true
ufw default allow outgoing >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Default policies set (deny incoming, allow outgoing)${NC}"

# Step 3: Remove existing SSH rules
echo ""
echo "Step 3: Cleaning up existing SSH rules..."
SSH_RULE_NUMS=$(ufw status numbered 2>/dev/null | grep -E "22/tcp|22 " | awk -F'[][]' '{print $2}' | sort -rn || true)

if [ -n "$SSH_RULE_NUMS" ]; then
    REMOVED_COUNT=0
    while IFS= read -r rule_num; do
        if [ -n "$rule_num" ] && [ "$rule_num" -gt 0 ] 2>/dev/null; then
            echo "  Removing SSH rule #$rule_num..."
            echo "y" | ufw delete "$rule_num" >/dev/null 2>&1 && REMOVED_COUNT=$((REMOVED_COUNT + 1)) || true
        fi
    done <<< "$SSH_RULE_NUMS"
    
    if [ $REMOVED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ Removed $REMOVED_COUNT SSH rule(s)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No existing SSH rules found${NC}"
fi

# Step 4: Add required firewall rules
echo ""
echo "Step 4: Adding required firewall rules..."

# SSH - Tailscale subnet (100.64.0.0/10)
if ! ufw status numbered 2>/dev/null | grep -q "100.64.0.0/10.*22"; then
    ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale (100.64.0.0/10)'
    echo -e "${GREEN}✅ SSH rule added (Tailscale subnet 100.64.0.0/10)${NC}"
fi

# SSH - Public IP (if provided)
if [ -n "$PUBLIC_IP" ]; then
    if ! ufw status numbered 2>/dev/null | grep -q "$PUBLIC_IP.*22"; then
        ufw allow from "$PUBLIC_IP" to any port 22 proto tcp comment 'SSH - Cursor Access (TEMP - Remove when using Tailscale)'
        echo -e "${GREEN}✅ SSH rule added (Public IP: $PUBLIC_IP)${NC}"
        echo -e "${YELLOW}⚠️  NOTE: This is a temporary rule. Consider using Tailscale instead.${NC}"
    else
        echo -e "${YELLOW}⚠️  SSH rule for $PUBLIC_IP already exists${NC}"
    fi
fi

# HTTP
if ! ufw status numbered 2>/dev/null | grep -q "80/tcp"; then
    ufw allow 80/tcp comment 'HTTP (Traefik)'
    echo -e "${GREEN}✅ HTTP rule added${NC}"
fi

# HTTPS
if ! ufw status numbered 2>/dev/null | grep -q "443/tcp"; then
    ufw allow 443/tcp comment 'HTTPS (Traefik)'
    echo -e "${GREEN}✅ HTTPS rule added${NC}"
fi

# Tailscale UDP
if ! ufw status numbered 2>/dev/null | grep -q "41641/udp"; then
    ufw allow 41641/udp comment 'Tailscale'
    echo -e "${GREEN}✅ Tailscale UDP rule added${NC}"
fi

# Step 5: Show final status
echo ""
echo "=== Final UFW Status ==="
ufw status numbered | head -20

echo ""
echo "=== Summary ==="
echo -e "${GREEN}✅ Firewall enabled with SSH access!${NC}"
echo ""
echo "SSH access configured for:"
echo "  - Tailscale subnet: 100.64.0.0/10 (any Tailscale device)"
if [ -n "$PUBLIC_IP" ]; then
    echo "  - Public IP: $PUBLIC_IP (Cursor access - TEMPORARY)"
fi
echo ""
if [ -n "$PUBLIC_IP" ]; then
    echo -e "${YELLOW}⚠️  SECURITY NOTE:${NC}"
    echo "The public IP rule is temporary. For better security, configure Cursor to use Tailscale."
    echo ""
    echo "To remove the public IP rule later:"
    echo "  sudo ufw delete allow from $PUBLIC_IP to any port 22"
    echo ""
fi
echo "Test SSH access:"
if [ -n "$PUBLIC_IP" ]; then
    echo "  - From Cursor (public IP): ssh comzis@156.67.29.52"
fi
echo "  - From Tailscale: ssh comzis@100.83.222.69"
echo ""

