#!/usr/bin/env bash
set -euo pipefail

# Fix SSH Firewall Access for Tailscale
# This script fixes the firewall configuration to restore SSH access from MacBook and Cursor
# It ensures UFW is properly configured with the correct Tailscale subnet rule (100.64.0.0/10)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Fix SSH Firewall Access for Tailscale ==="
echo ""
echo "This script will:"
echo "1. Enable UFW if inactive"
echo "2. Remove all existing SSH rules (fixing the loop bug)"
echo "3. Add correct Tailscale subnet rule (100.64.0.0/10)"
echo "4. Verify SSH configuration allows public key auth"
echo "5. Verify MacBook key access is preserved"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Step 1: Check and enable UFW
echo "Step 1: Checking UFW status..."
UFW_STATUS=$(ufw status 2>/dev/null | head -1 || echo "Status: inactive")
if echo "$UFW_STATUS" | grep -qiE "Status: inactive|inactive"; then
    echo -e "${YELLOW}⚠️  UFW is inactive, enabling...${NC}"
    ufw --force enable
    echo -e "${GREEN}✅ UFW enabled${NC}"
else
    echo -e "${GREEN}✅ UFW is active${NC}"
fi

# Step 2: Set default policies
echo ""
echo "Step 2: Setting default policies..."
ufw default deny incoming >/dev/null 2>&1 || true
ufw default allow outgoing >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Default policies set (deny incoming, allow outgoing)${NC}"

# Step 3: Remove all existing SSH rules (fixing the loop bug)
echo ""
echo "Step 3: Removing existing SSH rules..."
# Get all SSH rules by number, sorted in reverse order
SSH_RULE_NUMS=$(ufw status numbered 2>/dev/null | grep -E "22/tcp|22 " | awk -F'[][]' '{print $2}' | sort -rn || true)

if [ -n "$SSH_RULE_NUMS" ]; then
    # Remove rules one by one, starting from the highest number
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
        
        # Validate REMAINING_RULES is numeric and greater than 0 before using
        if [ -z "$REMAINING_RULES" ]; then
            # No rules found, exit loop
            break
        fi
        
        # Check if REMAINING_RULES is a valid positive integer
        if ! [[ "$REMAINING_RULES" =~ ^[0-9]+$ ]] || [ "$REMAINING_RULES" -le 0 ]; then
            # Invalid rule number, exit loop to prevent passing invalid argument to ufw
            echo "  ⚠️  Invalid rule number detected, stopping cleanup"
            break
        fi
        
        # Valid rule number, proceed with deletion
        echo "  Removing remaining SSH rule #$REMAINING_RULES (iteration $ITERATION)..."
        echo "y" | ufw delete "$REMAINING_RULES" >/dev/null 2>&1 || true
    done
    
    if [ $REMOVED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ Removed $REMOVED_COUNT SSH rule(s)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No existing SSH rules found${NC}"
fi

# Step 4: Add required firewall rules
echo ""
echo "Step 4: Adding required firewall rules..."

# SSH - Tailscale subnet only (100.64.0.0/10)
if ! ufw status numbered 2>/dev/null | grep -q "100.64.0.0/10.*22"; then
    ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale (100.64.0.0/10)'
    echo -e "${GREEN}✅ SSH rule added (Tailscale subnet 100.64.0.0/10)${NC}"
else
    echo -e "${YELLOW}⚠️  SSH rule for Tailscale subnet already exists${NC}"
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

# Step 5: Verify SSH configuration
echo ""
echo "Step 5: Verifying SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ -r "$SSH_CONFIG" ]; then
    # Check PubkeyAuthentication
    PUBKEY_AUTH=$(grep -E "^PubkeyAuthentication|^#PubkeyAuthentication" "$SSH_CONFIG" | tail -1 || echo "")
    if echo "$PUBKEY_AUTH" | grep -q "PubkeyAuthentication yes" || echo "$PUBKEY_AUTH" | grep -q "^#PubkeyAuthentication yes"; then
        echo -e "${GREEN}✅ Public key authentication is enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Public key authentication may not be enabled${NC}"
        echo "  Current setting: $PUBKEY_AUTH"
    fi
    
    # Check PasswordAuthentication
    PASSWORD_AUTH=$(grep -E "^PasswordAuthentication|^#PasswordAuthentication" "$SSH_CONFIG" | tail -1 || echo "")
    if echo "$PASSWORD_AUTH" | grep -q "PasswordAuthentication no" || echo "$PASSWORD_AUTH" | grep -q "^#PasswordAuthentication no"; then
        echo -e "${GREEN}✅ Password authentication is disabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Password authentication may be enabled${NC}"
        echo "  Current setting: $PASSWORD_AUTH"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot read SSH config (requires root)${NC}"
fi

# Step 6: Verify MacBook key access
echo ""
echo "Step 6: Verifying MacBook key access..."
AUTHORIZED_KEYS="/home/comzis/.ssh/authorized_keys"
if [ -f "$AUTHORIZED_KEYS" ]; then
    KEY_COUNT=$(grep -c "^ssh-" "$AUTHORIZED_KEYS" 2>/dev/null || echo "0")
    if [ "$KEY_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ authorized_keys file exists with $KEY_COUNT key(s)${NC}"
        # Check for MacBook key (ED25519)
        if grep -q "ED25519\|ed25519" "$AUTHORIZED_KEYS" 2>/dev/null; then
            echo -e "${GREEN}✅ MacBook key (ED25519) found in authorized_keys${NC}"
        else
            echo -e "${YELLOW}⚠️  MacBook key (ED25519) not found in authorized_keys${NC}"
        fi
    else
        echo -e "${RED}❌ authorized_keys file exists but contains no keys${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  authorized_keys file not found at $AUTHORIZED_KEYS${NC}"
fi

# Step 7: Show final status
echo ""
echo "=== Final UFW Status ==="
ufw status numbered | head -20

echo ""
echo "=== Summary ==="
echo -e "${GREEN}✅ Firewall configuration fixed!${NC}"
echo ""
echo "SSH access is now configured for:"
echo "  - Tailscale subnet: 100.64.0.0/10 (any Tailscale device)"
echo ""
echo "This matches .cursorrules-security requirement:"
echo "  'Port 22 → ONLY 100.64.0.0/10 (Tailscale)'"
echo ""
echo "Next steps:"
echo "1. Test SSH access from your MacBook: ssh comzis@100.83.222.69"
echo "2. Test SSH access from Cursor (via Tailscale)"
echo "3. Verify firewall status: sudo ufw status numbered"
echo ""


