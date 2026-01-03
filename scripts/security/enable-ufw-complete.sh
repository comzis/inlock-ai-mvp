#!/bin/bash
# Complete UFW setup with all required rules
# This ensures UFW is enabled and all rules are properly configured

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Complete UFW Setup ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Step 1: Enable UFW
echo "1. Enabling UFW..."
if ufw status | grep -qi "inactive"; then
    ufw --force enable
    echo -e "${GREEN}✅ UFW enabled${NC}"
else
    echo -e "${GREEN}✅ UFW is already active${NC}"
fi

# Step 2: Set default policies
echo ""
echo "2. Setting default policies..."
ufw default deny incoming >/dev/null 2>&1 || true
ufw default allow outgoing >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Default policies set (deny incoming, allow outgoing)${NC}"

# Step 3: Remove any existing SSH rules first
echo ""
echo "3. Cleaning up existing SSH rules..."
# Get all SSH rules by number, sorted in reverse order
SSH_RULE_NUMS=$(ufw status numbered 2>/dev/null | grep -E "22/tcp|22 " | awk -F'[][]' '{print $2}' | sort -rn || true)

if [ -n "$SSH_RULE_NUMS" ]; then
    REMOVED_COUNT=0
    while IFS= read -r rule_num; do
        if [ -n "$rule_num" ] && [ "$rule_num" -gt 0 ] 2>/dev/null; then
            echo "  Removing SSH rule #$rule_num..."
            echo "y" | ufw delete "$rule_num" >/dev/null 2>&1 && REMOVED_COUNT=$((REMOVED_COUNT + 1)) || true
        fi
    done <<< "$SSH_RULE_NUMS"
    
    # Double-check: if any SSH rules remain, try removing them again (max 3 iterations to prevent infinite loop)
    ITERATION=0
    MAX_ITERATIONS=3
    while [ $ITERATION -lt $MAX_ITERATIONS ] && ufw status numbered 2>/dev/null | grep -qE "22/tcp|22 "; do
        ITERATION=$((ITERATION + 1))
        REMAINING_RULES=$(ufw status numbered 2>/dev/null | grep -E "22/tcp|22 " | awk -F'[][]' '{print $2}' | sort -rn | head -1 || echo "")
        if [ -n "$REMAINING_RULES" ] && [ "$REMAINING_RULES" -gt 0 ] 2>/dev/null; then
            echo "  Removing remaining SSH rule #$REMAINING_RULES (iteration $ITERATION)..."
            echo "y" | ufw delete "$REMAINING_RULES" >/dev/null 2>&1 || true
        else
            break
        fi
    done
    
    if [ $REMOVED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ Removed $REMOVED_COUNT SSH rule(s)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No existing SSH rules found${NC}"
fi

# Step 4: Add required rules
echo ""
echo "4. Adding required firewall rules..."

# SSH - Tailscale only
if ! ufw status numbered 2>/dev/null | grep -q "100.64.0.0/10.*22"; then
    ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'
    echo -e "${GREEN}✅ SSH rule added (Tailscale subnet only)${NC}"
else
    echo -e "${YELLOW}⚠️  SSH rule already exists${NC}"
fi

# HTTP
if ! ufw status numbered 2>/dev/null | grep -q "80/tcp"; then
    ufw allow 80/tcp comment 'HTTP (Traefik)'
    echo -e "${GREEN}✅ HTTP rule added${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP rule already exists${NC}"
fi

# HTTPS
if ! ufw status numbered 2>/dev/null | grep -q "443/tcp"; then
    ufw allow 443/tcp comment 'HTTPS (Traefik)'
    echo -e "${GREEN}✅ HTTPS rule added${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS rule already exists${NC}"
fi

# Tailscale UDP
if ! ufw status numbered 2>/dev/null | grep -q "41641/udp"; then
    ufw allow 41641/udp comment 'Tailscale'
    echo -e "${GREEN}✅ Tailscale UDP rule added${NC}"
else
    echo -e "${YELLOW}⚠️  Tailscale UDP rule already exists${NC}"
fi

# Step 5: Show final status
echo ""
echo "=== Final UFW Status ==="
ufw status numbered

echo ""
echo -e "${GREEN}✅ UFW setup complete!${NC}"
echo ""
echo "Verification:"
echo "  sudo ufw status verbose"
echo "  sudo ./scripts/security/verify-ssh-restrictions.sh"

