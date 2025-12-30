#!/bin/bash
# Fix firewall to allow Docker network access to Cockpit
# Run with: sudo ./scripts/fix-cockpit-firewall.sh

set -euo pipefail

echo "=== Fixing Firewall for Cockpit Access ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# 1. Check UFW status
echo "1. Checking UFW status..."
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status | head -1 | grep -o "active\|inactive" || echo "unknown")
    echo "   UFW status: $UFW_STATUS"
    
    if [ "$UFW_STATUS" = "active" ]; then
        echo ""
        echo "2. Adding UFW rule for Cockpit..."
        ufw allow from 172.20.0.0/16 to any port 9090 comment 'Cockpit access from Docker network'
        echo "✓ UFW rule added"
    else
        echo "   UFW is not active, will use iptables instead"
    fi
else
    echo "   UFW not installed"
fi
echo ""

# 2. Add iptables rule (works regardless of UFW)
echo "3. Adding iptables rule..."
# Check if rule already exists
if iptables -C INPUT -s 172.20.0.0/16 -p tcp --dport 9090 -j ACCEPT 2>/dev/null; then
    echo "   Rule already exists"
else
    iptables -I INPUT -s 172.20.0.0/16 -p tcp --dport 9090 -j ACCEPT
    echo "✓ iptables rule added"
fi
echo ""

# 3. Verify rule
echo "4. Verifying firewall rules..."
echo "   iptables rules for port 9090:"
iptables -L INPUT -n | grep -E "(9090|172\.20)" || echo "   (no matching rules found)"
echo ""

# 4. Test connectivity from Traefik
echo "5. Testing connectivity..."
sleep 2
if docker ps | grep -q traefik; then
    echo "   Testing from Traefik container..."
    if docker exec compose-traefik-1 wget -qO- --timeout=3 http://172.20.0.1:9090 2>&1 | head -1 | grep -q "html\|Cockpit"; then
        echo "   ✓ Traefik can now reach Cockpit!"
    else
        echo "   ⚠️  Traefik still cannot reach Cockpit"
        echo "      This may take a moment to take effect"
    fi
else
    echo "   Traefik container not running"
fi
echo ""

# 5. Update Traefik service config
echo "6. Updating Traefik configuration..."
# Update service to use gateway IP directly
sed -i 's|url: http://cockpit-proxy:8080|url: http://172.20.0.1:9090|g' /home/comzis/inlock-infra/traefik/dynamic/services.yml
echo "✓ Traefik service updated to use gateway IP"
echo ""

# 6. Restart Traefik
echo "7. Restarting Traefik..."
docker restart compose-traefik-1 >/dev/null 2>&1
sleep 3
echo "✓ Traefik restarted"
echo ""

# 7. Test access
echo "8. Testing Cockpit access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>&1 || echo "000")
case "$HTTP_CODE" in
    200|302)
        echo "   ✓ Cockpit is accessible! (HTTP $HTTP_CODE)"
        echo ""
        echo "   Access: https://cockpit.inlock.ai"
        ;;
    403)
        echo "   ⚠️  IP allowlist blocking (HTTP 403)"
        echo "      Access from allowed IP required"
        ;;
    502|503|504)
        echo "   ⚠️  Still getting backend error (HTTP $HTTP_CODE)"
        echo "      Firewall rule may need a moment to take effect"
        echo "      Or check if Cockpit is running: systemctl status cockpit.socket"
        ;;
    *)
        echo "   ⚠️  Unexpected response (HTTP $HTTP_CODE)"
        ;;
esac
echo ""

echo "=== Summary ==="
echo "Firewall rules added:"
echo "  - iptables: Allow 172.20.0.0/16 → port 9090"
if [ "$UFW_STATUS" = "active" ]; then
    echo "  - UFW: Allow 172.20.0.0/16 → port 9090"
fi
echo ""
echo "Traefik service updated to: http://172.20.0.1:9090"
echo "Cockpit URL: https://cockpit.inlock.ai"
echo ""

