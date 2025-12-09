#!/bin/bash
# Test Portainer access from MacBook

echo "=========================================="
echo "PORTAINER ACCESS TEST"
echo "=========================================="
echo ""
echo "This script tests Portainer access."
echo "Run this from your MacBook (not the server)."
echo ""
echo "1. Checking Tailscale connection..."
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
    echo "   Your Tailscale IP: $TAILSCALE_IP"
    if [[ "$TAILSCALE_IP" == "100.96.110.8" ]]; then
        echo "   ✅ IP matches allowlist"
    else
        echo "   ⚠️  IP doesn't match (expected: 100.96.110.8)"
    fi
else
    echo "   ⚠️  Tailscale CLI not found"
    echo "   Check Tailscale app on MacBook"
fi
echo ""
echo "2. Testing Portainer access..."
RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" https://portainer.inlock.ai 2>&1)
if [[ "$RESPONSE" == "200" ]]; then
    echo "   ✅ Access allowed (HTTP 200)"
elif [[ "$RESPONSE" == "403" ]]; then
    echo "   ❌ Access blocked (HTTP 403)"
    echo "   IP allowlist is blocking"
else
    echo "   ⚠️  Unexpected response: HTTP $RESPONSE"
fi
echo ""
echo "3. If blocked, check:"
echo "   - Tailscale is connected"
echo "   - Your IP is 100.96.110.8"
echo "   - DNS has propagated (wait 2-3 minutes)"
echo "   - Try in incognito/private window"
