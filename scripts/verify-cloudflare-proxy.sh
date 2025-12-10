#!/bin/bash
# Verify Cloudflare proxy status for admin subdomains
# Ensures DNS records are gray-clouded (proxy OFF) when Traefik IP allowlist is used
#
# Usage: ./scripts/verify-cloudflare-proxy.sh [domain]
#   If domain not provided, checks all admin subdomains from config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Admin subdomains that should be gray-clouded (proxy OFF) for IP allowlist to work
ADMIN_SUBDOMAINS=(
  "traefik.inlock.ai"
  "portainer.inlock.ai"
  "n8n.inlock.ai"
  "grafana.inlock.ai"
  "deploy.inlock.ai"
)

# Load domain from .env if not provided
if [ -z "$1" ]; then
  if [ -f ".env" ]; then
    DOMAIN=$(grep "^DOMAIN=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "inlock.ai")
  else
    DOMAIN="inlock.ai"
  fi
else
  DOMAIN="$1"
fi

# Check if Cloudflare API credentials are available
if [ ! -f ".env" ]; then
  echo "❌ ERROR: .env file not found"
  exit 1
fi

CLOUDFLARE_API_TOKEN=$(grep "^CLOUDFLARE_API_TOKEN=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")
CLOUDFLARE_ZONE_ID=$(grep "^CLOUDFLARE_ZONE_ID=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")

if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  echo "⚠️  WARNING: Cloudflare API credentials not found in .env"
  echo "   Set CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID to verify proxy status"
  exit 0
fi

echo "========================================="
echo "Cloudflare Proxy Status Verification"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Admin subdomains that should be gray-clouded (proxy OFF):"
echo ""

FAILED=0
PASSED=0

for SUBDOMAIN in "${ADMIN_SUBDOMAINS[@]}"; do
  echo -n "Checking $SUBDOMAIN... "
  
  # Get DNS record details from Cloudflare API
  RESPONSE=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=${SUBDOMAIN}" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo "❌ API request failed"
    FAILED=$((FAILED + 1))
    continue
  fi
  
  # Check if record exists and get proxy status
  PROXIED=$(echo "$RESPONSE" | grep -o '"proxied":true' || echo "")
  RECORD_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || echo "")
  
  if [ -z "$RECORD_ID" ]; then
    echo "⚠️  DNS record not found"
    continue
  fi
  
  if [ -n "$PROXIED" ]; then
    echo "❌ PROXIED (orange cloud) - IP allowlist will NOT work!"
    echo "   → Traefik sees Cloudflare IPs, not real client IPs"
    echo "   → Fix: Set DNS record to 'DNS only' (gray cloud) in Cloudflare dashboard"
    FAILED=$((FAILED + 1))
  else
    echo "✅ DNS only (gray cloud) - IP allowlist will work"
    PASSED=$((PASSED + 1))
  fi
done

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
  echo "✅ All admin subdomains are gray-clouded"
  exit 0
else
  echo "❌ $FAILED subdomain(s) are proxied (proxy should be OFF)"
  echo ""
  echo "To fix:"
  echo "1. Go to Cloudflare Dashboard → DNS → Records"
  echo "2. For each proxied admin subdomain, click the orange cloud"
  echo "3. Change to gray cloud (DNS only)"
  echo ""
  echo "OR if you want to keep proxy ON:"
  echo "- Use Cloudflare WAF rules for IP filtering instead"
  echo "- Or add Cloudflare CIDRs to Traefik ipStrategy (see docs/CLOUDFLARE-IP-ALLOWLIST.md)"
  exit 1
fi

