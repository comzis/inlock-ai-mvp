#!/bin/bash
# Fetch Cloudflare IP ranges for IPv4 and IPv6
# Use these in Traefik ipStrategy when Cloudflare proxy is ON
#
# Usage: ./scripts/get-cloudflare-cidrs.sh

set -e

echo "Fetching Cloudflare IP ranges..."
echo ""

# Fetch IPv4 ranges
echo "IPv4 CIDRs:"
curl -s https://www.cloudflare.com/ips-v4 | sed 's/^/  - "/' | sed 's/$/"/'

echo ""
echo "IPv6 CIDRs:"
curl -s https://www.cloudflare.com/ips-v6 | sed 's/^/  - "/' | sed 's/$/"/'

echo ""
echo ""
echo "To use these in Traefik middlewares.yml with ipStrategy:"
echo ""
echo "allowed-admins:"
echo "  ipAllowList:"
echo "    sourceRange:"
echo "      - \"100.83.222.69/32\"  # Your Tailscale IPs"
echo "      # ... other allowed IPs ..."
echo "  ipStrategy:"
echo "    depth: 1"
echo "    excludedIPs:"
echo "      # Add Cloudflare IPv4 ranges here"
echo "      # Then add real client IPs to sourceRange above"

