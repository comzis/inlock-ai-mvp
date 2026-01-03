#!/usr/bin/env bash
set -euo pipefail

# Revert Tailscale stability fix by removing the systemd override
# This restores Tailscale to its default configuration

echo "=== Reverting Tailscale Configuration ==="
echo ""

# Remove systemd override
echo "1. Removing systemd override..."
if [ -f /etc/systemd/system/tailscaled.service.d/override.conf ]; then
    sudo rm /etc/systemd/system/tailscaled.service.d/override.conf
    echo "✅ Override file removed"
    
    # Remove directory if empty
    if [ -d /etc/systemd/system/tailscaled.service.d ]; then
        rmdir /etc/systemd/system/tailscaled.service.d 2>/dev/null || true
    fi
else
    echo "⚠️  Override file not found (may have already been removed)"
fi

echo ""

# Reload systemd
echo "2. Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "✅ Systemd reloaded"
echo ""

# Restart Tailscale
echo "3. Restarting Tailscale service..."
sudo systemctl restart tailscaled
echo "✅ Tailscale restarted"
echo ""

# Wait a moment for service to start
sleep 3

# Verify service is running
echo "4. Verifying Tailscale status..."
if systemctl is-active --quiet tailscaled; then
    echo "✅ Tailscale is running"
    echo ""
    echo "Tailscale status:"
    tailscale status | head -10
else
    echo "❌ ERROR: Tailscale failed to start"
    echo "Check logs with: sudo journalctl -u tailscaled -n 50"
    exit 1
fi

echo ""
echo "=== Revert Complete ==="
echo ""
echo "Tailscale has been restored to default configuration."
echo "You should be able to reconnect via Tailscale now."


