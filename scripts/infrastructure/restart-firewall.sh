#!/bin/bash
# Restart/reload firewall and add Cockpit access rule
# Run with: sudo ./scripts/restart-firewall.sh

set -euo pipefail

echo "=== Restarting Firewall ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# 1. Check UFW
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status | head -1 | grep -o "active\|inactive" || echo "inactive")
    echo "1. UFW Status: $UFW_STATUS"
    
    if [ "$UFW_STATUS" = "active" ]; then
        echo ""
        echo "2. Reloading UFW..."
        ufw reload
        echo "✓ UFW reloaded"
        
        # Add Cockpit rule if not exists
        if ! ufw status numbered | grep -q "9090"; then
            echo ""
            echo "3. Adding Cockpit access rule to UFW..."
            ufw allow from 172.20.0.0/16 to any port 9090 comment 'Cockpit access from Docker network'
            echo "✓ UFW rule added"
        else
            echo "   Cockpit rule already exists in UFW"
        fi
    else
        echo "   UFW is not active"
    fi
else
    echo "   UFW not installed"
fi
echo ""

# 2. Add/verify iptables rule (works regardless of UFW)
echo "4. Verifying iptables rule for Cockpit..."
if iptables -C INPUT -s 172.20.0.0/16 -p tcp --dport 9090 -j ACCEPT 2>/dev/null; then
    echo "   ✓ Cockpit access rule exists in iptables"
else
    echo "   Adding Cockpit access rule to iptables..."
    iptables -I INPUT -s 172.20.0.0/16 -p tcp --dport 9090 -j ACCEPT
    echo "   ✓ iptables rule added"
fi
echo ""

# 3. Show current firewall status
echo "5. Current firewall status:"
echo ""
if command -v ufw >/dev/null 2>&1 && [ "$UFW_STATUS" = "active" ]; then
    echo "UFW rules for port 9090:"
    ufw status numbered | grep -E "(9090|172\.20)" || echo "  (no matching rules)"
fi
echo ""
echo "iptables rules for port 9090:"
iptables -L INPUT -n -v | grep -E "(9090|172\.20)" || echo "  (no matching rules)"
echo ""

# 4. Test connectivity
echo "6. Testing connectivity..."
sleep 2
if docker ps | grep -q traefik; then
    if docker exec compose-traefik-1 wget -qO- --timeout=3 http://172.20.0.1:9090 2>&1 | head -1 | grep -q "html\|Cockpit"; then
        echo "   ✓ Traefik can reach Cockpit!"
    else
        echo "   ⚠️  Traefik still cannot reach Cockpit"
        echo "      Rule may need a moment to take effect"
    fi
fi
echo ""

echo "=== Firewall Restart Complete ==="
echo ""
echo "Test Cockpit access:"
echo "  curl -k -I https://cockpit.inlock.ai"
echo ""

