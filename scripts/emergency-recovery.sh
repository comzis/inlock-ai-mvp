#!/usr/bin/env bash
set -euo pipefail

# Emergency recovery script to restore SSH access after Tailscale fix broke connectivity
# This script temporarily allows SSH from public IP, reverts Tailscale changes, then restores firewall

echo "=== Emergency Recovery Script ==="
echo ""
echo "This script will:"
echo "1. Temporarily allow SSH from public IP (for recovery)"
echo "2. Revert Tailscale systemd override"
echo "3. Restart Tailscale"
echo "4. Restore firewall to Tailscale-only SSH (after 60 seconds)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

# Step 1: Temporarily allow SSH from public IP
echo "Step 1: Temporarily allowing SSH from public IP..."
ufw allow 22/tcp comment 'SSH - Emergency Recovery (TEMP)'
echo "✅ SSH temporarily allowed from any IP"
echo ""

# Step 2: Remove Tailscale systemd override
echo "Step 2: Removing Tailscale systemd override..."
if [ -f /etc/systemd/system/tailscaled.service.d/override.conf ]; then
    rm /etc/systemd/system/tailscaled.service.d/override.conf
    echo "✅ Override file removed"
    
    # Remove directory if empty
    if [ -d /etc/systemd/system/tailscaled.service.d ]; then
        rmdir /etc/systemd/system/tailscaled.service.d 2>/dev/null || true
    fi
else
    echo "⚠️  Override file not found (may have already been removed)"
fi
echo ""

# Step 3: Reload systemd and restart Tailscale
echo "Step 3: Reloading systemd and restarting Tailscale..."
systemctl daemon-reload
systemctl restart tailscaled
echo "✅ Systemd reloaded and Tailscale restarted"
echo ""

# Wait for Tailscale to start
echo "Waiting for Tailscale to initialize..."
sleep 5

# Step 4: Verify Tailscale
echo "Step 4: Verifying Tailscale status..."
if systemctl is-active --quiet tailscaled; then
    echo "✅ Tailscale is running"
    echo ""
    echo "Tailscale status:"
    tailscale status | head -10 || echo "⚠️  tailscale command not available, but service is running"
else
    echo "❌ WARNING: Tailscale failed to start"
    echo "Check logs with: journalctl -u tailscaled -n 50"
fi
echo ""

# Step 5: Schedule firewall restoration
echo "Step 5: Scheduling firewall restoration..."
cat > /tmp/restore-firewall.sh <<'EOF'
#!/bin/bash
# Remove temporary SSH rule and restore Tailscale-only access
ufw delete allow 22/tcp comment 'SSH - Emergency Recovery (TEMP)' 2>/dev/null || true

# Restore Tailscale-only SSH rules
ufw allow from 100.83.222.69/32 to any port 22 comment 'SSH - Tailscale Server' 2>/dev/null || true
ufw allow from 100.96.110.8/32 to any port 22 comment 'SSH - Tailscale MacBook' 2>/dev/null || true

echo "✅ Firewall restored to Tailscale-only SSH access"
rm -f /tmp/restore-firewall.sh
EOF

chmod +x /tmp/restore-firewall.sh

# Schedule restoration in 60 seconds
echo "⚠️  IMPORTANT: Temporary SSH access will be removed in 60 seconds"
echo "   Make sure you can connect via Tailscale before then!"
echo ""
echo "To manually restore firewall later, run:"
echo "  sudo bash /tmp/restore-firewall.sh"
echo ""

# Run restoration in background after 60 seconds
(sleep 60 && bash /tmp/restore-firewall.sh) &

echo "=== Recovery Complete ==="
echo ""
echo "Next steps:"
echo "1. Test SSH access via Tailscale: ssh comzis@100.83.222.69"
echo "2. If Tailscale works, the firewall will auto-restore in 60 seconds"
echo "3. If Tailscale doesn't work, manually restore firewall: sudo bash /tmp/restore-firewall.sh"
echo ""


