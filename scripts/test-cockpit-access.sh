#!/bin/bash
# Test Cockpit access
# Run: ./test-cockpit-access.sh

echo "=== Testing Cockpit Access ==="
echo ""

# 1. Check Cockpit service
echo "1. Checking Cockpit service status..."
if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
    echo "  ✓ Cockpit socket is active"
else
    echo "  ✗ Cockpit socket is not active"
fi

# 2. Check Cockpit port
echo ""
echo "2. Checking Cockpit port (9090)..."
if netstat -tulpn 2>/dev/null | grep -q ":9090" || ss -tulpn 2>/dev/null | grep -q ":9090"; then
    echo "  ✓ Port 9090 is listening"
    netstat -tulpn 2>/dev/null | grep ":9090" || ss -tulpn 2>/dev/null | grep ":9090"
else
    echo "  ✗ Port 9090 is not listening"
fi

# 3. Test localhost access
echo ""
echo "3. Testing localhost access..."
LOCAL_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" http://localhost:9090 2>/dev/null || echo "000")
if [ "$LOCAL_CODE" = "200" ] || [ "$LOCAL_CODE" = "302" ]; then
    echo "  ✓ Cockpit responds on localhost (HTTP $LOCAL_CODE)"
else
    echo "  ✗ Cockpit not responding on localhost (HTTP $LOCAL_CODE)"
fi

# 4. Test via Traefik
echo ""
echo "4. Testing via Traefik (cockpit.inlock.ai)..."
TRAEFIK_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>/dev/null || echo "000")
case "$TRAEFIK_CODE" in
    200|302)
        echo "  ✓ Cockpit accessible via Traefik (HTTP $TRAEFIK_CODE)"
        ;;
    403)
        echo "  ⚠️  Cockpit router working but blocked by IP allowlist (HTTP 403)"
        echo "     Access from Tailscale IP required"
        ;;
    404)
        echo "  ✗ Cockpit router not configured (HTTP 404)"
        ;;
    502|503)
        echo "  ✗ Cockpit service not reachable from Traefik (HTTP $TRAEFIK_CODE)"
        ;;
    *)
        echo "  ⚠️  Unexpected response (HTTP $TRAEFIK_CODE)"
        ;;
esac

# 5. Check Traefik configuration
echo ""
echo "5. Checking Traefik configuration..."
if docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml 2>/dev/null | grep -q "cockpit:"; then
    echo "  ✓ Cockpit router configured in Traefik"
else
    echo "  ✗ Cockpit router not found in Traefik"
fi

if docker exec compose-traefik-1 cat /etc/traefik/dynamic/services.yml 2>/dev/null | grep -q "cockpit:"; then
    echo "  ✓ Cockpit service configured in Traefik"
else
    echo "  ✗ Cockpit service not found in Traefik"
fi

# 6. Test network connectivity
echo ""
echo "6. Testing network connectivity from Traefik to host..."
if docker exec compose-traefik-1 wget -qO- --timeout=2 http://172.20.0.1:9090 2>&1 | head -1 | grep -q "html\|Cockpit"; then
    echo "  ✓ Traefik can reach host Cockpit"
else
    echo "  ✗ Traefik cannot reach host Cockpit"
    echo "     Gateway IP: 172.20.0.1"
fi

echo ""
echo "=== Summary ==="
echo ""
if [ "$TRAEFIK_CODE" = "403" ]; then
    echo "Status: Cockpit is configured correctly!"
    echo "Access: Use Tailscale IP to access https://cockpit.inlock.ai"
    echo ""
    echo "Your Tailscale IPs:"
    echo "  - 100.83.222.69 (Server)"
    echo "  - 100.96.110.8 (MacBook)"
elif [ "$TRAEFIK_CODE" = "200" ] || [ "$TRAEFIK_CODE" = "302" ]; then
    echo "Status: ✓ Cockpit is accessible!"
else
    echo "Status: ⚠️  Cockpit needs configuration"
    echo "Run: sudo ./scripts/fix-cockpit-access.sh"
fi
echo ""

