#!/bin/bash
echo "=== Testing Traefik Dashboard Access ==="
echo ""
echo "Your current IP:"
curl -s ifconfig.me
echo ""
echo ""
echo "Tailscale IP:"
tailscale ip -4 2>/dev/null || echo "Not available"
echo ""
echo ""
echo "Allowed IPs in config:"
grep -A 5 "allowed-admins:" /home/comzis/inlock-infra/traefik/dynamic/middlewares.yml | grep -E "100\.|sourceRange"
echo ""
echo ""
echo "Testing dashboard (will show 403 if IP not allowed):"
curl -k -u "admin:65Gbr1cPsqFI71YOakEtBrJB" -I https://traefik.inlock.ai/dashboard/ 2>&1 | head -5
