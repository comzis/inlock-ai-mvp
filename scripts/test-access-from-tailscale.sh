#!/bin/bash
# Test access from Tailscale-connected host

echo "=========================================="
echo "ACCESS TEST FROM TAILSCALE IP"
echo "=========================================="
echo ""
echo "This script should be run from a Tailscale-connected host."
echo "Expected: HTTP 200 (allowed) or 401 (auth required)"
echo ""

# Check if tailscale command exists
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
    echo "Your Tailscale IP: $TAILSCALE_IP"
    echo ""
else
    echo "⚠️  Tailscale CLI not found"
    echo "Please ensure you're connected to Tailscale VPN"
    echo ""
fi

echo "Testing admin services..."
echo ""

for domain in traefik.inlock.ai portainer.inlock.ai n8n.inlock.ai; do
    echo -n "  $domain: "
    STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://$domain 2>&1)
    if [ "$STATUS" = "200" ]; then
        echo "✅ HTTP 200 (Allowed)"
    elif [ "$STATUS" = "401" ]; then
        echo "✅ HTTP 401 (Auth Required - Correct)"
    elif [ "$STATUS" = "403" ]; then
        echo "❌ HTTP 403 (Blocked - IP not in allowlist)"
    else
        echo "⚠️  HTTP $STATUS (Unexpected)"
    fi
done

echo ""
echo "=========================================="

