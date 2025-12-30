#!/bin/bash
#
# Disable root login and restore secure configuration
# Reverts changes made by enable-root-for-coolify.sh
#
# Usage: sudo ./scripts/infrastructure/disable-root-access.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Disabling Root Login"
echo "  Restoring Secure Configuration"
echo "=========================================="
echo ""

# Backup SSH config if it exists
if [ -f /etc/ssh/sshd_config ]; then
    BACKUP="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/ssh/sshd_config "$BACKUP"
    echo "✓ SSH config backed up to: $BACKUP"
fi

# Disable root login
echo "Disabling root login..."
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Verify the change
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    echo "✓ Root login disabled"
else
    echo "⚠️  Warning: Could not verify PermitRootLogin setting"
fi

# Remove root's authorized_keys (security best practice)
echo ""
echo "Removing root's SSH authorized_keys..."
if [ -f /root/.ssh/authorized_keys ]; then
    rm -f /root/.ssh/authorized_keys
    echo "✓ Root's authorized_keys removed"
else
    echo "✓ Root's authorized_keys already removed or doesn't exist"
fi

# Test SSH config syntax
echo ""
echo "Testing SSH configuration..."
if sshd -t; then
    echo "✓ SSH configuration is valid"
else
    echo "❌ ERROR: SSH configuration has syntax errors!"
    exit 1
fi

# Restart SSH service
echo ""
echo "Restarting SSH service..."
systemctl restart sshd
sleep 2

if systemctl is-active --quiet sshd; then
    echo "✓ SSH service restarted successfully"
else
    echo "❌ ERROR: SSH service failed to start!"
    exit 1
fi

# Verify configuration
echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""
echo "SSH Configuration:"
sshd -T | grep -E "permitrootlogin|passwordauthentication" | sed 's/^/  /'

if [ -f /root/.ssh/authorized_keys ]; then
    echo ""
    echo "⚠️  Warning: /root/.ssh/authorized_keys still exists"
else
    echo ""
    echo "✓ Root's authorized_keys removed"
fi

echo ""
echo "=========================================="
echo "  Configuration Reverted"
echo "=========================================="
echo ""
echo "Security Status:"
echo "  ✓ Root login disabled (PermitRootLogin no)"
echo "  ✓ Root's authorized_keys removed"
echo "  ✓ SSH service restarted"
echo ""
echo "Next steps for Coolify:"
echo "  1. Use user: comzis (not root)"
echo "  2. Use IP: 100.83.222.69 (Tailscale IP)"
echo "  3. Use SSH key: deploy-inlock-ai-key"
echo "  4. For sudo access, you may need to configure passwordless sudo"
echo "     for specific commands (see documentation)"




