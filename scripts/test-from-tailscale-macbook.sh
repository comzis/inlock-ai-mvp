#!/bin/bash
# Test script for Tailscale-connected MacBook
# Run this from your MacBook to verify access

echo "=========================================="
echo "TAILSCALE MACBOOK ACCESS TEST"
echo "=========================================="
echo ""
echo "This script tests all admin endpoints from a Tailscale-connected MacBook."
echo "Expected: HTTP 200 (allowed) or 401 (auth required)"
echo ""

# Check Tailscale connection
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
    echo "Your Tailscale IP: $TAILSCALE_IP"
    if [[ "$TAILSCALE_IP" == "100.96.110.8" ]]; then
        echo "✅ IP matches allowlist (100.96.110.8)"
    else
        echo "⚠️  IP doesn't match expected (100.96.110.8)"
        echo "   Current IP: $TAILSCALE_IP"
        echo "   If different, update allowlist in traefik/dynamic/middlewares.yml"
    fi
else
    echo "⚠️  Tailscale CLI not found"
    echo "   Check Tailscale app is running and connected"
fi
echo ""

# Test all admin endpoints
echo "Testing admin endpoints..."
echo ""

declare -A endpoints=(
    ["Traefik Dashboard"]="https://traefik.inlock.ai/dashboard/"
    ["Portainer"]="https://portainer.inlock.ai"
    ["n8n"]="https://n8n.inlock.ai"
    ["Cockpit"]="https://cockpit.inlock.ai"
    ["Homepage (Public)"]="https://inlock.ai"
)

for name in "${!endpoints[@]}"; do
    url="${endpoints[$name]}"
    echo -n "  $name ($(echo $url | cut -d'/' -f3)): "
    
    STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" 2>&1)
    
    if [ "$STATUS" = "200" ]; then
        echo "✅ HTTP 200 (Allowed)"
    elif [ "$STATUS" = "401" ]; then
        echo "✅ HTTP 401 (Auth Required - Correct)"
    elif [ "$STATUS" = "403" ]; then
        echo "❌ HTTP 403 (Blocked - IP not in allowlist)"
        echo "     Check your Tailscale IP matches allowlist"
    elif [ "$STATUS" = "404" ]; then
        echo "⚠️  HTTP 404 (Not Found - Service may not be running)"
    else
        echo "⚠️  HTTP $STATUS (Unexpected)"
    fi
done

echo ""
echo "=========================================="
echo "TEST COMPLETE"
echo "=========================================="
echo ""
echo "Expected Results:"
echo "  - Traefik Dashboard: 401 (auth required)"
echo "  - Portainer: 200 (if healthy)"
echo "  - n8n: 200 (if healthy)"
echo "  - Cockpit: 200 or 404 (if service available)"
echo "  - Homepage: 200 (public)"
echo ""
echo "If any endpoint shows 403, check:"
echo "  1. Tailscale is connected"
echo "  2. Your IP matches allowlist (100.96.110.8)"
echo "  3. DNS has propagated"
echo ""

