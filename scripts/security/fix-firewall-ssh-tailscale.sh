#!/usr/bin/env bash
set -euo pipefail

# Fix firewall SSH rules to allow entire Tailscale subnet (100.64.0.0/10)
# This matches .cursorrules-security requirement: "Port 22 → ONLY 100.64.0.0/10 (Tailscale)"
# 
# The issue: Current firewall uses specific IPs (100.83.222.69/32, 100.96.110.8/32)
# The fix: Use entire Tailscale subnet (100.64.0.0/10) to allow any Tailscale device

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Fix Firewall SSH Rules for Tailscale ==="
echo ""
echo "This script will update SSH firewall rules to allow the entire Tailscale subnet"
echo "instead of specific IPs, matching .cursorrules-security requirements."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Check if UFW is installed
if ! command -v ufw >/dev/null 2>&1; then
    echo -e "${RED}Error: UFW is not installed${NC}"
    exit 1
fi

# Check if UFW is active
UFW_ACTIVE=false
if ufw status | grep -qiE "Status: active|active|enabled"; then
    UFW_ACTIVE=true
fi

if [ "$UFW_ACTIVE" = "false" ]; then
    echo -e "${YELLOW}⚠️  UFW is not active${NC}"
    echo "Enabling UFW..."
    ufw --force enable
    UFW_ACTIVE=true
fi

echo "1. Removing existing SSH rules..."
# Remove all existing SSH rules (both specific IPs and subnet)
SSH_RULES=$(ufw status numbered | grep -E "22/tcp|22 " | awk -F'[][]' '{print $2}' | sort -rn || true)

if [ -n "$SSH_RULES" ]; then
    while IFS= read -r rule_num; do
        if [ -n "$rule_num" ]; then
            echo "  Removing SSH rule #$rule_num..."
            echo "y" | ufw delete "$rule_num" >/dev/null 2>&1 || true
        fi
    done <<< "$SSH_RULES"
    echo -e "${GREEN}✅ Existing SSH rules removed${NC}"
else
    echo -e "${YELLOW}⚠️  No existing SSH rules found${NC}"
fi

echo ""
echo "2. Adding Tailscale subnet SSH rule..."
# Check if the correct rule already exists
if ufw status numbered | grep -q "100.64.0.0/10.*22"; then
    echo -e "${YELLOW}⚠️  Tailscale subnet SSH rule already exists${NC}"
else
    # Add rule for entire Tailscale subnet
    ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale (100.64.0.0/10)'
    echo -e "${GREEN}✅ SSH rule added for Tailscale subnet (100.64.0.0/10)${NC}"
fi

echo ""
echo "3. Verifying firewall rules..."
echo ""
echo "Current SSH firewall rules:"
ufw status numbered | grep -E "22|ssh|100\.64" || echo "  (none found)"

echo ""
echo "=== Summary ==="
echo -e "${GREEN}✅ Firewall SSH rules updated${NC}"
echo ""
echo "SSH access is now restricted to:"
echo "  - Tailscale subnet: 100.64.0.0/10 (any Tailscale device)"
echo ""
echo "This matches .cursorrules-security requirement:"
echo "  'Port 22 → ONLY 100.64.0.0/10 (Tailscale)'"
echo ""
echo "Next steps:"
echo "1. Test SSH access from your MacBook via Tailscale"
echo "2. Verify firewall status: sudo ufw status numbered"
echo ""


