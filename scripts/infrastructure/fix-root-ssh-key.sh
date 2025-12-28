#!/bin/bash
#
# Fix root SSH key for Coolify
# Run with: sudo bash fix-root-ssh-key.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

SSH_KEY="/home/comzis/.ssh/keys/deploy-inlock-ai-key.pub"

echo "=========================================="
echo "  Fixing Root SSH Key for Coolify"
echo "=========================================="
echo ""

# Create root .ssh directory
echo "Creating /root/.ssh directory..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "✓ Directory created"

# Add SSH key to root's authorized_keys
echo ""
echo "Adding SSH key to root's authorized_keys..."
if [ -f "$SSH_KEY" ]; then
    cp "$SSH_KEY" /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    echo "✓ SSH key added"
    echo ""
    echo "Key added:"
    cat /root/.ssh/authorized_keys
else
    echo "❌ ERROR: SSH key not found at $SSH_KEY"
    exit 1
fi

# Verify SSH config allows root login
echo ""
echo "Checking SSH configuration..."
if grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config || grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    echo "✓ Root login is enabled (key-only)"
else
    echo "⚠️  Warning: Root login might not be enabled"
    echo "   Current setting:"
    grep "^PermitRootLogin" /etc/ssh/sshd_config || echo "   (not found - will be added)"
    echo ""
    read -p "Enable root login? (yes/no): " enable
    if [ "$enable" = "yes" ]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        sed -i 's/^PermitRootLogin no/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
            echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
        fi
        sshd -t && systemctl restart sshd
        echo "✓ Root login enabled and SSH restarted"
    fi
fi

# Verify permissions
echo ""
echo "Verifying permissions..."
ls -la /root/.ssh/
echo ""
echo "=========================================="
echo "  ✅ Fix Complete!"
echo "=========================================="
echo ""
echo "Test SSH connection:"
echo "  ssh -i /home/comzis/.ssh/keys/deploy-inlock-ai-key root@172.18.0.1 'echo test'"
echo ""
echo "Then try Coolify validation again!"

