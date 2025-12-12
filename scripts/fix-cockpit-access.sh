#!/bin/bash
# Fix Cockpit access - ensure router and service are configured
# Run: ./fix-cockpit-access.sh

set -euo pipefail

echo "=== Fixing Cockpit Access ==="
echo ""

# Check if Cockpit is running
if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
    echo "✓ Cockpit socket is active"
else
    echo "Starting Cockpit socket..."
    sudo systemctl start cockpit.socket
    sudo systemctl enable cockpit.socket
    echo "✓ Cockpit socket started"
fi

# Verify port is listening
if netstat -tulpn 2>/dev/null | grep -q ":9090" || ss -tulpn 2>/dev/null | grep -q ":9090"; then
    echo "✓ Cockpit is listening on port 9090"
else
    echo "✗ Cockpit is not listening on port 9090"
    exit 1
fi

# Check Traefik configuration
ROUTER_EXISTS=$(docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml 2>/dev/null | grep -c "cockpit:" || echo "0")
SERVICE_EXISTS=$(docker exec compose-traefik-1 cat /etc/traefik/dynamic/services.yml 2>/dev/null | grep -c "cockpit:" || echo "0")

if [ "$ROUTER_EXISTS" -gt 0 ] && [ "$SERVICE_EXISTS" -gt 0 ]; then
    echo "✓ Traefik configuration exists"
    echo ""
    echo "Restarting Traefik to ensure config is loaded..."
    docker restart compose-traefik-1
    sleep 3
    echo "✓ Traefik restarted"
else
    echo "✗ Traefik configuration missing"
    echo "  Router exists: $ROUTER_EXISTS"
    echo "  Service exists: $SERVICE_EXISTS"
    exit 1
fi

# Test access
echo ""
echo "Testing access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>/dev/null || echo "000")

case "$HTTP_CODE" in
    200|302)
        echo "✓ Cockpit is accessible! (HTTP $HTTP_CODE)"
        ;;
    403)
        echo "⚠️  Cockpit router working but blocked by IP allowlist (HTTP 403)"
        echo ""
        echo "This is expected - Cockpit requires Tailscale IP access."
        echo "Access from one of these IPs:"
        echo "  - 100.83.222.69 (Tailscale Server)"
        echo "  - 100.96.110.8 (Tailscale MacBook)"
        echo ""
        echo "If you're accessing from a Tailscale IP and still getting 403,"
        echo "check your current IP matches the allowlist."
        ;;
    404)
        echo "✗ Cockpit router not found (HTTP 404)"
        echo "  Check Traefik configuration"
        ;;
    502|503)
        echo "✗ Cockpit service not reachable (HTTP $HTTP_CODE)"
        echo "  Check network connectivity from Traefik to host"
        ;;
    *)
        echo "⚠️  Unexpected response (HTTP $HTTP_CODE)"
        ;;
esac

echo ""
echo "=== Summary ==="
echo "Cockpit URL: https://cockpit.inlock.ai"
echo "Access: Requires Tailscale IP (IP allowlist enforced)"
echo ""
