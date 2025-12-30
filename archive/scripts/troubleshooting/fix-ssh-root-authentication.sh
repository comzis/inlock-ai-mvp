#!/bin/bash
set -e
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai"
echo "=== Fixing SSH Root Authentication ==="
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if ! grep -q "deploy.inlock.ai" /root/.ssh/authorized_keys 2>/dev/null; then
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
fi
chmod 600 /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys
chown root:root /root/.ssh
SSH_CONFIG="/etc/ssh/sshd_config"
NEEDS_RESTART=false
if grep -q "^PermitRootLogin.*no" $SSH_CONFIG; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSH_CONFIG
    NEEDS_RESTART=true
fi
if ! grep -q "^PermitRootLogin" $SSH_CONFIG; then
    echo "PermitRootLogin prohibit-password" >> $SSH_CONFIG
    NEEDS_RESTART=true
fi
if grep -q "^PubkeyAuthentication.*no" $SSH_CONFIG; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSH_CONFIG
    NEEDS_RESTART=true
fi
if ! grep -q "^PubkeyAuthentication" $SSH_CONFIG; then
    echo "PubkeyAuthentication yes" >> $SSH_CONFIG
    NEEDS_RESTART=true
fi
if [ "$NEEDS_RESTART" = true ]; then
    systemctl restart sshd
fi
echo "✓ Fix complete"

