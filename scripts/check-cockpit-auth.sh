#!/bin/bash
# Check Cockpit authentication status
# Run: ./scripts/check-cockpit-auth.sh

set -euo pipefail

echo "=== Cockpit Authentication Status ==="
echo ""

# 1. SSH Configuration
echo "1. SSH Configuration:"
SSH_PASS=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config 2>&1 | grep -v "^#" | awk '{print $2}' || echo "yes")
SSH_KEY=$(grep "^PubkeyAuthentication" /etc/ssh/sshd_config 2>&1 | grep -v "^#" | awk '{print $2}' || echo "yes")
echo "   Password Authentication: $SSH_PASS"
echo "   Key Authentication: $SSH_KEY"
echo ""

# 2. Cockpit Service
echo "2. Cockpit Service:"
if systemctl is-active --quiet cockpit.socket; then
    echo "   ✓ Socket is active"
else
    echo "   ✗ Socket is not active"
fi

if systemctl is-active --quiet cockpit.service; then
    echo "   ✓ Service is running"
else
    echo "   ⚠️  Service not running (may start on demand)"
fi

if ss -tlnp | grep -q ":9090"; then
    echo "   ✓ Port 9090 is listening"
else
    echo "   ✗ Port 9090 is not listening"
fi
echo ""

# 3. PAM Configuration
echo "3. PAM Configuration:"
if [ -f /etc/pam.d/cockpit ]; then
    echo "   ✓ Cockpit PAM config exists"
    echo "   Using: $(grep '^auth' /etc/pam.d/cockpit | head -1 | awk '{print $2, $3}')"
else
    echo "   ✗ Cockpit PAM config not found"
fi
echo ""

# 4. User Password Status
echo "4. User Password Status:"
CURRENT_USER=$(whoami)
if sudo -n true 2>/dev/null; then
    PASSWD_STATUS=$(sudo passwd -S "$CURRENT_USER" 2>&1 | awk '{print $2}')
    case "$PASSWD_STATUS" in
        P) echo "   ✓ User '$CURRENT_USER' has password set" ;;
        L) echo "   ⚠️  User '$CURRENT_USER' account is locked" ;;
        NP) echo "   ✗ User '$CURRENT_USER' has NO password set" ;;
        *) echo "   ? User '$CURRENT_USER' status: $PASSWD_STATUS" ;;
    esac
else
    echo "   ⚠️  Cannot check password status (needs sudo)"
    echo "   Run: sudo passwd -S $CURRENT_USER"
fi
echo ""

# 5. Test Access
echo "5. Network Access:"
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>&1 || echo "000")
case "$HTTP_CODE" in
    200) echo "   ✓ Cockpit is accessible (HTTP $HTTP_CODE)" ;;
    401|403) echo "   ✓ Cockpit is accessible but requires authentication (HTTP $HTTP_CODE)" ;;
    502|503|504) echo "   ✗ Cockpit backend error (HTTP $HTTP_CODE)" ;;
    000) echo "   ✗ Cannot reach Cockpit" ;;
    *) echo "   ⚠️  Unexpected response (HTTP $HTTP_CODE)" ;;
esac
echo ""

# 6. Summary
echo "=== Summary ==="
echo ""
if [ "$SSH_PASS" = "no" ]; then
    echo "SSH password authentication is DISABLED"
    echo ""
    echo "Cockpit authentication:"
    if sudo -n true 2>/dev/null && [ "$PASSWD_STATUS" = "P" ]; then
        echo "  ✓ Should work - user has password set"
        echo "  ✓ PAM allows password authentication"
        echo ""
        echo "  You can login to Cockpit with:"
        echo "    Username: $CURRENT_USER"
        echo "    Password: (your system password)"
    elif sudo -n true 2>/dev/null && [ "$PASSWD_STATUS" = "NP" ]; then
        echo "  ✗ Will NOT work - user has no password set"
        echo ""
        echo "  To fix:"
        echo "    sudo passwd $CURRENT_USER"
        echo "    (Set a password for Cockpit login)"
    else
        echo "  ? Cannot determine - check password status manually:"
        echo "    sudo passwd -S $CURRENT_USER"
        echo ""
        echo "  If status shows 'NP' (no password), set one:"
        echo "    sudo passwd $CURRENT_USER"
    fi
else
    echo "SSH password authentication is ENABLED"
    echo "Cockpit should work with password authentication"
fi
echo ""
echo "Access Cockpit at: https://cockpit.inlock.ai"
echo ""

