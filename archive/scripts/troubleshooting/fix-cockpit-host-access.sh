#!/bin/bash
# Fix Cockpit access from Traefik by allowing Docker network access
# This script configures firewall to allow Docker containers to access host Cockpit

set -euo pipefail

echo "=== Fixing Cockpit Host Access ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# 1. Ensure Cockpit is running on host
echo "1. Checking Cockpit host service..."
if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
    echo "✓ Cockpit socket is active"
else
    echo "Starting Cockpit socket..."
    systemctl start cockpit.socket
    systemctl enable cockpit.socket
    echo "✓ Cockpit socket started"
fi
echo ""

# 2. Check UFW status
echo "2. Checking firewall status..."
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        echo "✓ UFW is active"
        echo ""
        echo "3. Adding firewall rule for Docker network..."
        # Allow Docker edge network (172.20.0.0/16) to access Cockpit
        ufw allow from 172.20.0.0/16 to any port 9090 comment 'Cockpit access from Docker network'
        echo "✓ Firewall rule added"
    else
        echo "⚠️  UFW is not active"
        echo "   If you have another firewall, add rule:"
        echo "   Allow 172.20.0.0/16 → port 9090"
    fi
else
    echo "⚠️  UFW not installed"
    echo "   Install with: sudo apt install ufw"
fi
echo ""

# 3. Test connectivity
echo "4. Testing connectivity..."
sleep 2

# Test from host
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 2>/dev/null || echo "000")
if [ "$LOCAL_CODE" = "200" ] || [ "$LOCAL_CODE" = "302" ]; then
    echo "✓ Cockpit responds on localhost (HTTP $LOCAL_CODE)"
else
    echo "✗ Cockpit not responding on localhost (HTTP $LOCAL_CODE)"
fi

# Test from Traefik container (if available)
if docker ps | grep -q traefik; then
    echo ""
    echo "5. Testing from Traefik container..."
    if docker exec compose-traefik-1 wget -qO- --timeout=3 http://172.20.0.1:9090 2>&1 | head -1 | grep -q "html\|Cockpit"; then
        echo "✓ Traefik can reach Cockpit"
    else
        echo "⚠️  Traefik cannot reach Cockpit (may need firewall rule)"
    fi
fi
echo ""

# 4. Restart Traefik to reload config
echo "6. Restarting Traefik..."
docker restart compose-traefik-1 2>&1 >/dev/null
sleep 3
echo "✓ Traefik restarted"
echo ""

# 5. Test via Traefik
echo "7. Testing via Traefik..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>&1 || echo "000")
case "$HTTP_CODE" in
    200|302)
        echo "✓ Cockpit is accessible via Traefik! (HTTP $HTTP_CODE)"
        ;;
    403)
        echo "⚠️  IP allowlist blocking (HTTP 403)"
        echo "   Access from allowed IP required"
        ;;
    502|503|504)
        echo "✗ Backend connectivity issue (HTTP $HTTP_CODE)"
        echo "   Check firewall rules and network connectivity"
        ;;
    *)
        echo "⚠️  Unexpected response (HTTP $HTTP_CODE)"
        ;;
esac
echo ""

echo "=== Summary ==="
echo "Cockpit URL: https://cockpit.inlock.ai"
echo "Status: HTTP $HTTP_CODE"
echo ""
echo "If still having issues:"
echo "1. Check firewall: sudo ufw status | grep 9090"
echo "2. Check Cockpit: systemctl status cockpit.socket"
echo "3. Check Traefik logs: docker logs compose-traefik-1 | grep cockpit"
echo ""

