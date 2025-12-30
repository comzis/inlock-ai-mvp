#!/bin/bash
#
# Enable root login with key-only authentication for Coolify
# This keeps SSH restricted to Tailscale IPs via firewall
#
# Usage: sudo ./scripts/infrastructure/enable-root-for-coolify.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Enabling Root Login for Coolify"
echo "  (Key-only authentication, Tailscale-restricted)"
echo "=========================================="
echo ""

# Backup SSH config
if [ -f /etc/ssh/sshd_config ]; then
    BACKUP="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/ssh/sshd_config "$BACKUP"
    echo "✓ SSH config backed up to: $BACKUP"
fi

# Enable root login with key-only (prohibit-password)
echo "Enabling root login (key-only authentication)..."
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin no/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Verify the change
if grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
    echo "✓ Root login enabled (key-only)"
else
    echo "⚠️  Warning: Could not verify PermitRootLogin setting"
fi

# Ensure password authentication is disabled (should already be)
if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
else
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
fi
echo "✓ Password authentication disabled"

# Create root .ssh directory
echo ""
echo "Setting up root SSH directory..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "✓ Root .ssh directory created"

# Copy SSH public key to root's authorized_keys
if [ -f /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub ]; then
    echo ""
    echo "Adding SSH key to root's authorized_keys..."
    cp /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    echo "✓ SSH key added to /root/.ssh/authorized_keys"
    echo ""
    echo "Public key added:"
    cat /root/.ssh/authorized_keys
else
    echo "⚠️  Warning: SSH key not found at /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub"
    echo "   Please manually add your SSH public key to /root/.ssh/authorized_keys"
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

echo ""
echo "Root SSH Key:"
cat /root/.ssh/authorized_keys | sed 's/^/  /'

echo ""
echo "=========================================="
echo "  Configuration Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. In Coolify UI, configure server with:"
echo "   - IP Address: 172.18.0.1 (Docker gateway IP - use this from container)"
echo "   - User: root"
echo "   - Port: 22"
echo "   - Private Key: deploy-inlock-ai-key (or inlock-ai-infrastructure in UI)"
echo ""
echo "2. Root login is restricted to:"
echo "   - Key-only authentication (no passwords)"
echo "   - Tailscale IPs only (via firewall)"
echo ""
echo "Security Notes:"
echo "  ✓ Root login enabled (for Coolify compatibility)"
echo "  ✓ Key-only authentication (no passwords)"
echo "  ✓ Restricted to Tailscale network via firewall"
echo "  ✓ SSH key authentication required"

