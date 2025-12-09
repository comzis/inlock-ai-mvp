#!/usr/bin/env bash
set -euo pipefail

# Script to test Traefik IP allowlist access control
# Run from a non-Tailscale IP to verify 403 responses

DOMAIN="${DOMAIN:-inlock.ai}"
SERVER_IP="${SERVER_IP:-localhost}"

echo "Testing Traefik IP Allowlist Access Control"
echo "============================================"
echo ""
echo "Expected behavior:"
echo "  - From Tailscale IPs (100.83.222.69, 100.96.110.8): Should allow access"
echo "  - From other IPs: Should return 403 Forbidden"
echo ""
echo "Current server IP: $SERVER_IP"
echo ""

# Test admin endpoints (should be blocked for non-allowlisted IPs)
ENDPOINTS=(
  "traefik.${DOMAIN}"
  "portainer.${DOMAIN}"
  "n8n.${DOMAIN}"
)

for endpoint in "${ENDPOINTS[@]}"; do
  echo "Testing: $endpoint"
  
  # Test HTTP (will redirect, but should show middleware behavior)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $endpoint" http://${SERVER_IP} 2>/dev/null || echo "000")
  
  # Test HTTPS (where allowlist middleware is actually applied)
  HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: $endpoint" https://${SERVER_IP} 2>/dev/null || echo "000")
  
  echo "  HTTP: $HTTP_CODE  HTTPS: $HTTPS_CODE"
  
  if [ "$HTTPS_CODE" = "403" ]; then
    echo "  ✅ Access correctly blocked (403)"
  elif [ "$HTTPS_CODE" = "000" ]; then
    echo "  ⚠️  HTTPS not available (SSL certs not configured yet)"
  elif [ "$HTTPS_CODE" = "200" ] || [ "$HTTPS_CODE" = "401" ]; then
    echo "  ⚠️  Access allowed - verify IP is in allowlist"
  else
    echo "  ℹ️  Status: $HTTPS_CODE"
  fi
  echo ""
done

echo "Note: Allowlist middleware is applied on HTTPS (websecure) entrypoint."
echo "HTTP requests redirect to HTTPS before middleware evaluation."
echo ""
echo "To verify allowlist is working:"
echo "1. Ensure SSL certificates are configured"
echo "2. Test from a non-Tailscale IP (should get 403)"
echo "3. Test from Tailscale IPs 100.83.222.69 or 100.96.110.8 (should allow)"

