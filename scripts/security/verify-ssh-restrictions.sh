#!/bin/bash
# Verify SSH firewall restrictions and fail2ban configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== SSH Security Verification ==="
echo ""

ERRORS=0
WARNINGS=0

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Warning: Some checks require root privileges${NC}"
    echo "Run with: sudo $0"
    echo ""
fi

# Check UFW status
echo "1. Checking UFW Firewall Status..."
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1 || echo "inactive")
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo -e "${GREEN}✅ UFW is active${NC}"
    else
        echo -e "${RED}❌ UFW is not active${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check SSH rules
    echo ""
    echo "2. Checking SSH Firewall Rules..."
    SSH_RULES=$(sudo ufw status numbered 2>/dev/null | grep -E "22|ssh" || echo "")
    if [ -n "$SSH_RULES" ]; then
        echo "SSH-related rules:"
        echo "$SSH_RULES" | while IFS= read -r line; do
            echo "  $line"
            # Check if restricted to Tailscale subnet
            if echo "$line" | grep -q "100.64.0.0/10"; then
                echo -e "    ${GREEN}✅ Restricted to Tailscale subnet${NC}"
            elif echo "$line" | grep -q "anywhere"; then
                echo -e "    ${YELLOW}⚠️  SSH accessible from anywhere (consider restricting to Tailscale)${NC}"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No SSH rules found in UFW${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  UFW not installed${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check fail2ban SSH jail
echo ""
echo "3. Checking fail2ban SSH Jail..."
if command -v fail2ban-client >/dev/null 2>&1; then
    if sudo systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${GREEN}✅ fail2ban service is active${NC}"
        
        # Check SSH jail status
        SSH_JAIL=$(sudo fail2ban-client status sshd 2>/dev/null || echo "")
        if [ -n "$SSH_JAIL" ]; then
            echo -e "${GREEN}✅ SSH jail is configured${NC}"
            echo "SSH jail status:"
            echo "$SSH_JAIL" | head -5 | sed 's/^/  /'
        else
            echo -e "${YELLOW}⚠️  SSH jail not found or not active${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}❌ fail2ban service is not active${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  fail2ban not installed${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check SSH configuration (if accessible)
echo ""
echo "4. Checking SSH Configuration..."
if [ -r /etc/ssh/sshd_config ]; then
    # Check password authentication
    PASSWORD_AUTH=$(sudo grep -E "^PasswordAuthentication|^#PasswordAuthentication" /etc/ssh/sshd_config | tail -1 || echo "")
    if echo "$PASSWORD_AUTH" | grep -q "PasswordAuthentication no" || echo "$PASSWORD_AUTH" | grep -q "^#PasswordAuthentication no"; then
        echo -e "${GREEN}✅ Password authentication is disabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Password authentication may be enabled${NC}"
        echo "  Current setting: $PASSWORD_AUTH"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check root login
    ROOT_LOGIN=$(sudo grep -E "^PermitRootLogin|^#PermitRootLogin" /etc/ssh/sshd_config | tail -1 || echo "")
    if echo "$ROOT_LOGIN" | grep -q "PermitRootLogin no" || echo "$ROOT_LOGIN" | grep -q "^#PermitRootLogin no"; then
        echo -e "${GREEN}✅ Root login is disabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Root login may be enabled${NC}"
        echo "  Current setting: $ROOT_LOGIN"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Cannot read /etc/ssh/sshd_config (requires root)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Tailscale status
echo ""
echo "5. Checking Tailscale Status..."
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_STATUS=$(tailscale status 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_STATUS" ]; then
        echo -e "${GREEN}✅ Tailscale is installed${NC}"
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$TAILSCALE_IP" ]; then
            echo "  Tailscale IP: $TAILSCALE_IP"
            if echo "$TAILSCALE_IP" | grep -q "^100\."; then
                echo -e "  ${GREEN}✅ IP is in Tailscale range (100.x.x.x)${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Tailscale status unavailable${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Tailscale not installed${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Recommendations:"
    echo "- Verify SSH is restricted to Tailscale subnet (100.64.0.0/10)"
    echo "- Ensure fail2ban SSH jail is active"
    echo "- Review SSH configuration for security best practices"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) found, $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please address the errors above."
    echo "See docs/security/SSH-ACCESS-POLICY.md for details."
    exit 1
fi

