#!/bin/bash
# Fix SSH security issues identified by verify-ssh-restrictions.sh
# 1. Add UFW rule to restrict SSH to Tailscale subnet
# 2. Disable root login in SSH config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== SSH Security Fix Script ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Fix 1: Add UFW SSH rule
echo "1. Adding UFW rule to restrict SSH to Tailscale subnet..."

# Check UFW status - try multiple methods
UFW_ACTIVE=false
if command -v ufw >/dev/null 2>&1; then
    # Method 1: Check status output
    UFW_OUTPUT=$(ufw status 2>/dev/null || echo "")
    if echo "$UFW_OUTPUT" | grep -qiE "Status: active|active|enabled"; then
        UFW_ACTIVE=true
    fi
    
    # Method 2: Check verbose status
    if [ "$UFW_ACTIVE" = "false" ]; then
        UFW_VERBOSE=$(ufw status verbose 2>/dev/null | head -1 || echo "")
        if echo "$UFW_VERBOSE" | grep -qiE "Status: active|active"; then
            UFW_ACTIVE=true
        fi
    fi
    
    # Method 3: Check if UFW is enabled in systemd
    if [ "$UFW_ACTIVE" = "false" ]; then
        if systemctl is-active ufw >/dev/null 2>&1 || systemctl is-enabled ufw >/dev/null 2>&1; then
            UFW_ACTIVE=true
        fi
    fi
fi

if [ "$UFW_ACTIVE" = "true" ]; then
    # Check if rule already exists
    if ufw status numbered | grep -q "100.64.0.0/10.*22"; then
        echo -e "${YELLOW}⚠️  SSH rule for Tailscale subnet already exists${NC}"
    else
        # Remove any existing SSH rules first
        while ufw status numbered | grep -q "22/tcp"; do
            RULE_NUM=$(ufw status numbered | grep "22/tcp" | head -1 | sed 's/\[\([0-9]*\)\].*/\1/')
            if [ -n "$RULE_NUM" ]; then
                echo "  Removing existing SSH rule #$RULE_NUM..."
                echo "y" | ufw delete "$RULE_NUM" >/dev/null 2>&1 || true
            else
                break
            fi
        done
        
        # Add new restricted rule
        ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'
        echo -e "${GREEN}✅ SSH rule added: Only accessible from Tailscale subnet (100.64.0.0/10)${NC}"
    fi
    
    # Show current SSH rules
    echo ""
    echo "Current SSH firewall rules:"
    ufw status numbered | grep -E "22|ssh" || echo "  (none found)"
else
    echo -e "${YELLOW}⚠️  UFW is not active${NC}"
    echo "Enabling UFW first..."
    
    # Enable UFW with default policies
    if ufw --force enable; then
        echo -e "${GREEN}✅ UFW enabled${NC}"
        
        # Set default policies if not already set
        ufw default deny incoming >/dev/null 2>&1 || true
        ufw default allow outgoing >/dev/null 2>&1 || true
        
        # Add required firewall rules per .cursorrules-security
        echo "Adding required firewall rules..."
        
        # SSH - Tailscale only
        ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'
        echo -e "${GREEN}✅ SSH rule added: Only accessible from Tailscale subnet (100.64.0.0/10)${NC}"
        
        # HTTP/HTTPS - Required for Traefik
        ufw allow 80/tcp comment 'HTTP (Traefik)'
        ufw allow 443/tcp comment 'HTTPS (Traefik)'
        echo -e "${GREEN}✅ HTTP/HTTPS rules added${NC}"
        
        # Tailscale UDP
        ufw allow 41641/udp comment 'Tailscale'
        echo -e "${GREEN}✅ Tailscale UDP rule added${NC}"
        
        # Show all rules
        echo ""
        echo "Current firewall rules:"
        ufw status numbered
    else
        echo -e "${RED}❌ Failed to enable UFW${NC}"
        exit 1
    fi
fi

echo ""

# Fix 2: Disable root login
echo "2. Disabling root login in SSH config..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo -e "${RED}❌ SSH config file not found: $SSH_CONFIG${NC}"
    exit 1
fi

# Create backup
BACKUP_FILE="${SSH_CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$SSH_CONFIG" "$BACKUP_FILE"
echo "  Backup created: $BACKUP_FILE"

# Check current setting
CURRENT_SETTING=$(grep -E "^PermitRootLogin|^#PermitRootLogin" "$SSH_CONFIG" | tail -1 || echo "")
echo "  Current setting: $CURRENT_SETTING"

# Update to disable root login
if grep -q "^PermitRootLogin no" "$SSH_CONFIG"; then
    echo -e "${GREEN}✅ Root login already disabled${NC}"
elif grep -q "^#PermitRootLogin no" "$SSH_CONFIG"; then
    # Uncomment existing setting
    sed -i 's/^#PermitRootLogin no/PermitRootLogin no/' "$SSH_CONFIG"
    echo -e "${GREEN}✅ Root login disabled (uncommented existing setting)${NC}"
else
    # Add or replace setting
    if grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
        # Replace existing setting
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    else
        # Add new setting
        echo "PermitRootLogin no" >> "$SSH_CONFIG"
    fi
    echo -e "${GREEN}✅ Root login disabled${NC}"
fi

# Verify new setting
NEW_SETTING=$(grep "^PermitRootLogin" "$SSH_CONFIG" | tail -1)
echo "  New setting: $NEW_SETTING"

# Verify SSH config syntax
echo ""
echo "3. Verifying SSH config syntax..."
if sshd -t 2>/dev/null; then
    echo -e "${GREEN}✅ SSH config syntax is valid${NC}"
else
    echo -e "${RED}❌ SSH config syntax error!${NC}"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$SSH_CONFIG"
    exit 1
fi

echo ""
echo "=== Summary ==="
echo -e "${GREEN}✅ All fixes applied successfully${NC}"
echo ""
echo "Changes made:"
echo "1. UFW rule: SSH restricted to Tailscale subnet (100.64.0.0/10)"
echo "2. SSH config: Root login disabled"
echo ""
echo "Next steps:"
echo "1. Restart SSH service to apply config changes:"
echo "   sudo systemctl restart sshd"
echo ""
echo "2. Verify changes:"
echo "   sudo ufw status numbered | grep 22"
echo "   sudo grep '^PermitRootLogin' /etc/ssh/sshd_config"
echo ""
echo "3. Test SSH access from Tailscale device"
echo ""

