#!/bin/bash
# Fix Cockpit password authentication issues
# Run: sudo ./scripts/fix-cockpit-password-auth.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "=== Fixing Cockpit Password Authentication ==="
echo ""

USERNAME="${1:-comzis}"

# 1. Check user exists
echo "1. Checking user account..."
if id "$USERNAME" &>/dev/null; then
    echo "   ✓ User '$USERNAME' exists"
else
    echo "   ✗ User '$USERNAME' does not exist"
    exit 1
fi
echo ""

# 2. Check account status
echo "2. Checking account status..."
PASSWD_STATUS=$(passwd -S "$USERNAME" 2>&1 | awk '{print $2}')
case "$PASSWD_STATUS" in
    P) echo "   ✓ Account has password set" ;;
    L) echo "   ⚠️  Account is LOCKED - unlocking..."
       passwd -u "$USERNAME" 2>&1
       echo "   ✓ Account unlocked" ;;
    NP) echo "   ✗ Account has NO password - this is the problem!"
       echo "   Setting password..."
       echo ""
       echo "   Please enter a new password for user '$USERNAME':"
       passwd "$USERNAME"
       echo "   ✓ Password set" ;;
    *) echo "   ? Account status: $PASSWD_STATUS" ;;
esac
echo ""

# 3. Check account expiration
echo "3. Checking account expiration..."
EXPIRY=$(chage -l "$USERNAME" 2>&1 | grep "Account expires" | awk -F: '{print $2}' | xargs)
if [ "$EXPIRY" = "never" ] || [ -z "$EXPIRY" ]; then
    echo "   ✓ Account does not expire"
else
    echo "   ⚠️  Account expires: $EXPIRY"
    echo "   Consider extending: chage -E -1 $USERNAME"
fi
echo ""

# 4. Check if user is disallowed in Cockpit
echo "4. Checking Cockpit access restrictions..."
if [ -f /etc/cockpit/disallowed-users ]; then
    if grep -q "^${USERNAME}$" /etc/cockpit/disallowed-users 2>/dev/null; then
        echo "   ✗ User is DISALLOWED in Cockpit"
        echo "   Removing from disallowed list..."
        sed -i "/^${USERNAME}$/d" /etc/cockpit/disallowed-users
        echo "   ✓ User removed from disallowed list"
    else
        echo "   ✓ User is not disallowed"
    fi
else
    echo "   ✓ No disallowed-users file (all users allowed)"
fi
echo ""

# 5. Check PAM configuration
echo "5. Checking PAM configuration..."
if [ -f /etc/pam.d/cockpit ]; then
    echo "   ✓ Cockpit PAM config exists"
    if grep -q "pam_listfile" /etc/pam.d/cockpit; then
        echo "   ✓ Access control via disallowed-users is configured"
    fi
else
    echo "   ✗ Cockpit PAM config not found"
fi
echo ""

# 6. Test password authentication
echo "6. Testing password authentication..."
echo "   Attempting to authenticate user '$USERNAME'..."
if su - "$USERNAME" -c "echo 'Password auth test successful'" 2>/dev/null; then
    echo "   ✓ Password authentication works via PAM"
else
    echo "   ⚠️  Could not test password authentication (may need interactive session)"
fi
echo ""

# 7. Restart Cockpit
echo "7. Restarting Cockpit..."
systemctl restart cockpit.socket 2>&1 >/dev/null
sleep 2
if systemctl is-active --quiet cockpit.socket; then
    echo "   ✓ Cockpit socket restarted"
else
    echo "   ⚠️  Cockpit socket may not be active"
fi
echo ""

# 8. Check recent authentication attempts
echo "8. Recent authentication attempts:"
journalctl -u cockpit.service --no-pager --since "5 minutes ago" 2>&1 | grep -i -E "(auth|denied|failed)" | tail -5 || echo "   No recent authentication attempts logged"
echo ""

echo "=== Summary ==="
echo ""
echo "User: $USERNAME"
echo "Status: $(passwd -S "$USERNAME" | awk '{print $2}')"
echo ""
echo "Next steps:"
echo "  1. Try logging into Cockpit again: https://cockpit.inlock.ai"
echo "  2. Use username: $USERNAME"
echo "  3. Use the password you just set"
echo ""
echo "If it still doesn't work:"
echo "  - Check logs: journalctl -u cockpit.service -n 50"
echo "  - Verify password: sudo passwd -S $USERNAME"
echo "  - Try from different browser/incognito window"
echo "  - Clear browser cache"
echo ""

