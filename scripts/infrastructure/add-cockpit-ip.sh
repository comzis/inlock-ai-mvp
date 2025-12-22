#!/bin/bash
# Add your current IP to Cockpit allowlist
# Run: ./add-cockpit-ip.sh [IP_ADDRESS]

set -euo pipefail

MIDDLEWARE_FILE="/home/comzis/inlock-infra/traefik/dynamic/middlewares.yml"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <IP_ADDRESS>"
    echo ""
    echo "Example: $0 100.83.222.69"
    echo ""
    echo "Current allowlist IPs:"
    grep -A 10 "allowed-admins:" "$MIDDLEWARE_FILE" | grep "sourceRange:" -A 10 | grep "- \"" | sed 's/.*- "\(.*\)".*/\1/'
    exit 1
fi

NEW_IP="$1"
COMMENT="${2:-Temporary access}"

echo "Adding IP $NEW_IP to Cockpit allowlist..."
echo ""

# Backup
cp "$MIDDLEWARE_FILE" "${MIDDLEWARE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Check if IP already exists
if grep -q "$NEW_IP" "$MIDDLEWARE_FILE"; then
    echo "IP $NEW_IP is already in the allowlist"
    exit 0
fi

# Add IP to sourceRange
sed -i "/sourceRange:/a\          - \"$NEW_IP/32\"  # $COMMENT" "$MIDDLEWARE_FILE"

echo "✓ IP $NEW_IP added to allowlist"
echo ""
echo "Restarting Traefik to apply changes..."
docker restart compose-traefik-1
sleep 3
echo "✓ Traefik restarted"
echo ""
echo "Test access:"
echo "  curl -k -I https://cockpit.inlock.ai"
echo ""

