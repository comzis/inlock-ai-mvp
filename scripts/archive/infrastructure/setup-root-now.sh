#!/bin/bash
#
# Quick setup script for root access for Coolify
# Run with: sudo bash setup-root-now.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

SSH_KEY_FILE="/home/comzis/projects/inlock-ai-mvp/root-ssh-key.txt"

echo "=========================================="
echo "  Enabling Root Login for Coolify"
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

# Ensure password authentication is disabled
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

# Add SSH key to root's authorized_keys
if [ -f "$SSH_KEY_FILE" ]; then
    echo ""
    echo "Adding SSH key to root's authorized_keys..."
    cat "$SSH_KEY_FILE" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    echo "✓ SSH key added to /root/.ssh/authorized_keys"
    echo ""
    echo "Public key added:"
    cat /root/.ssh/authorized_keys
else
    echo "⚠️  Warning: SSH key file not found at $SSH_KEY_FILE"
    echo "   Copying from /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub"
    if [ -f /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub ]; then
        cp /home/comzis/.ssh/keys/deploy-inlock-ai-key.pub /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        chown root:root /root/.ssh/authorized_keys
        echo "✓ SSH key added"
    fi
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

echo ""
echo "=========================================="
echo "  ✅ Configuration Complete!"
echo "=========================================="
echo ""
echo "Next steps in Coolify UI:"
echo "  - IP Address: 172.18.0.1"
echo "  - User: root"
echo "  - Port: 22"
echo "  - Private Key: inlock-ai-infrastructure"
echo ""
echo "Then click 'Validate & configure' - it should work! 🚀"

