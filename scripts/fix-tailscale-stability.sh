#!/usr/bin/env bash
set -euo pipefail

# Fix Tailscale stability by configuring it to ignore Docker network interface churn
# This prevents excessive rebinds that cause connection drops

echo "=== Tailscale Stability Fix ==="
echo ""

# Create systemd override directory
echo "1. Creating systemd override directory..."
sudo mkdir -p /etc/systemd/system/tailscaled.service.d

# Create override file
echo "2. Creating systemd override configuration..."
sudo tee /etc/systemd/system/tailscaled.service.d/override.conf > /dev/null <<EOF
[Service]
# Configure Tailscale to be less sensitive to Docker network interface changes
# --netfilter-mode=off uses userspace networking, reducing sensitivity to interface churn
ExecStart=
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --netfilter-mode=off
EOF

echo "✅ Override configuration created"
echo ""

# Reload systemd
echo "3. Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "✅ Systemd reloaded"
echo ""

# Restart Tailscale
echo "4. Restarting Tailscale service..."
sudo systemctl restart tailscaled
echo "✅ Tailscale restarted"
echo ""

# Wait a moment for service to start
sleep 2

# Verify service is running
echo "5. Verifying Tailscale status..."
if systemctl is-active --quiet tailscaled; then
    echo "✅ Tailscale is running"
    tailscale status | head -5
else
    echo "❌ ERROR: Tailscale failed to start"
    echo "Check logs with: sudo journalctl -u tailscaled -n 50"
    exit 1
fi

echo ""
echo "=== Fix Applied Successfully ==="
echo ""
echo "Monitor Tailscale stability with:"
echo "  journalctl -u tailscaled -f | grep -E '(Rebind|LinkChange)'"
echo ""
echo "You should see significantly fewer rebind events now."

