#!/bin/bash
#
# Add Coolify SSH public key to root's authorized_keys
# This allows Coolify to connect as root user
#
# Usage: sudo ./scripts/add-ssh-key-to-root.sh

set -e

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai"

echo "=== Adding SSH Key to Root's authorized_keys ==="
echo ""

# Create .ssh directory for root if it doesn't exist
if [ ! -d /root/.ssh ]; then
    echo "Creating /root/.ssh directory..."
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
fi

# Check if key already exists
if grep -q "deploy.inlock.ai" /root/.ssh/authorized_keys 2>/dev/null; then
    echo "✓ SSH key already exists in root's authorized_keys"
else
    echo "Adding SSH public key to /root/.ssh/authorized_keys..."
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "✓ SSH key added successfully"
fi

echo ""
echo "=== Verification ==="
echo ""
echo "Checking authorized_keys:"
grep "deploy.inlock.ai" /root/.ssh/authorized_keys || echo "Key not found (this shouldn't happen)"

echo ""
echo "=== Fix Complete ==="

