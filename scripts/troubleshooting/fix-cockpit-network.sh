#!/bin/bash
# Fix Cockpit network connectivity from Docker
# This script helps diagnose and fix Cockpit access issues

set -euo pipefail

echo "=== Fixing Cockpit Network Access ==="
echo ""

# Check if Cockpit is running
if ! systemctl is-active --quiet cockpit.socket 2>/dev/null; then
    echo "Starting Cockpit socket..."
    sudo systemctl start cockpit.socket
    sudo systemctl enable cockpit.socket
fi

echo "✓ Cockpit socket is active"
echo ""

# Check listening port
echo "Checking Cockpit port..."
if ss -tulpn 2>/dev/null | grep -q ":9090"; then
    echo "✓ Cockpit is listening on port 9090"
    ss -tulpn 2>/dev/null | grep ":9090"
else
    echo "✗ Cockpit is not listening on port 9090"
    exit 1
fi
echo ""

# Test localhost access
echo "Testing localhost access..."
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 2>/dev/null || echo "000")
if [ "$LOCAL_CODE" = "200" ] || [ "$LOCAL_CODE" = "302" ]; then
    echo "✓ Cockpit responds on localhost (HTTP $LOCAL_CODE)"
else
    echo "✗ Cockpit not responding on localhost (HTTP $LOCAL_CODE)"
fi
echo ""

# Get host IPs
HOST_IP=$(hostname -I | awk '{print $1}')
GATEWAY_IP=$(docker network inspect edge --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.20.0.1")

echo "Host IP: $HOST_IP"
echo "Docker Gateway IP: $GATEWAY_IP"
echo ""

# Test connectivity from Traefik
echo "Testing connectivity from Traefik container..."
if docker exec compose-traefik-1 ping -c 1 -W 2 "$HOST_IP" >/dev/null 2>&1; then
    echo "✓ Traefik can ping host IP ($HOST_IP)"
else
    echo "✗ Traefik cannot ping host IP"
fi

if docker exec compose-traefik-1 ping -c 1 -W 2 "$GATEWAY_IP" >/dev/null 2>&1; then
    echo "✓ Traefik can ping gateway IP ($GATEWAY_IP)"
else
    echo "✗ Traefik cannot ping gateway IP"
fi
echo ""

# Check Traefik configuration
echo "Checking Traefik configuration..."
if docker exec compose-traefik-1 cat /etc/traefik/dynamic/services.yml 2>/dev/null | grep -q "cockpit:"; then
    echo "✓ Cockpit service configured"
    COCKPIT_URL=$(docker exec compose-traefik-1 cat /etc/traefik/dynamic/services.yml 2>/dev/null | grep -A 3 "cockpit:" | grep "url:" | awk '{print $2}' | tr -d '"')
    echo "  Service URL: $COCKPIT_URL"
else
    echo "✗ Cockpit service not configured"
fi

if docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml 2>/dev/null | grep -q "cockpit:"; then
    echo "✓ Cockpit router configured"
else
    echo "✗ Cockpit router not configured"
fi
echo ""

# Test access
echo "Testing access via Traefik..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>/dev/null || echo "000")
case "$HTTP_CODE" in
    200|302)
        echo "✓ Cockpit is accessible! (HTTP $HTTP_CODE)"
        ;;
    403)
        echo "⚠️  IP allowlist blocking (HTTP 403)"
        echo "   Your IP needs to be added to the allowlist"
        echo "   Run: ./scripts/add-cockpit-ip.sh <YOUR_IP>"
        ;;
    404)
        echo "✗ Router not found (HTTP 404)"
        ;;
    502|503|504)
        echo "✗ Backend connectivity issue (HTTP $HTTP_CODE)"
        echo "   Traefik cannot reach Cockpit backend"
        echo "   Check network configuration"
        ;;
    *)
        echo "⚠️  Unexpected response (HTTP $HTTP_CODE)"
        ;;
esac
echo ""

echo "=== Summary ==="
echo "Cockpit URL: https://cockpit.inlock.ai"
echo "Current Status: HTTP $HTTP_CODE"
echo ""

