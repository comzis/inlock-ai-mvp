#!/bin/bash
# Fix n8n and Cockpit access issues
# Run: ./scripts/fix-n8n-cockpit-access.sh

set -euo pipefail

echo "=== Fixing n8n and Cockpit Access ==="
echo ""

# 1. Check n8n users
echo "1. Checking n8n users..."
N8N_USERS=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n\r' || echo "0")
if [ "$N8N_USERS" = "0" ] || [ -z "$N8N_USERS" ]; then
    echo "   ✓ No users found - you can create a new account"
    N8N_NEEDS_USER=true
else
    echo "   ⚠️  Found $N8N_USERS existing user(s)"
    echo "   Listing users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "rows)" | grep -v "^$" | tail -n +3
    N8N_NEEDS_USER=false
fi
echo ""

# 2. Check n8n service
echo "2. Checking n8n service..."
if docker ps | grep -q compose-n8n-1; then
    echo "   ✓ n8n container is running"
    N8N_RUNNING=true
else
    echo "   ✗ n8n container is not running"
    N8N_RUNNING=false
fi
echo ""

# 3. Check Cockpit service
echo "3. Checking Cockpit service..."
if systemctl is-active --quiet cockpit.socket; then
    echo "   ✓ Cockpit socket is active"
    COCKPIT_SOCKET=true
else
    echo "   ✗ Cockpit socket is not active"
    COCKPIT_SOCKET=false
fi

if systemctl is-active --quiet cockpit.service; then
    echo "   ✓ Cockpit service is running"
    COCKPIT_SERVICE=true
else
    echo "   ⚠️  Cockpit service is not running (may start on demand)"
    COCKPIT_SERVICE=false
fi

if ss -tlnp | grep -q ":9090"; then
    echo "   ✓ Port 9090 is listening"
    COCKPIT_PORT=true
else
    echo "   ✗ Port 9090 is not listening"
    COCKPIT_PORT=false
fi
echo ""

# 4. Check Traefik connectivity
echo "4. Checking Traefik connectivity..."
if docker exec compose-traefik-1 wget -qO- --timeout=3 http://n8n:5678 >/dev/null 2>&1; then
    echo "   ✓ Traefik can reach n8n"
    TRAEFIK_N8N=true
else
    echo "   ✗ Traefik cannot reach n8n"
    TRAEFIK_N8N=false
fi

if docker exec compose-traefik-1 wget -qO- --timeout=3 http://172.20.0.1:9090 >/dev/null 2>&1; then
    echo "   ✓ Traefik can reach Cockpit"
    TRAEFIK_COCKPIT=true
else
    echo "   ✗ Traefik cannot reach Cockpit"
    TRAEFIK_COCKPIT=false
fi
echo ""

# 5. Fix n8n user issue
if [ "$N8N_NEEDS_USER" = "false" ] && [ "$N8N_RUNNING" = "true" ]; then
    echo "5. n8n User Management..."
    echo "   You have existing users. Options:"
    echo ""
    echo "   Option A: Reset password for existing user"
    echo "     ./scripts/reset-n8n-password.sh"
    echo ""
    echo "   Option B: Delete existing user and create new one"
    echo "     ./scripts/recreate-n8n-user.sh"
    echo ""
    echo "   Option C: Delete all users (fresh start)"
    echo "     ./scripts/fresh-start-n8n.sh"
    echo ""
fi

# 6. Fix Cockpit access
if [ "$COCKPIT_SOCKET" = "false" ] || [ "$COCKPIT_PORT" = "false" ]; then
    echo "6. Starting Cockpit..."
    sudo systemctl start cockpit.socket 2>&1 || echo "   ⚠️  Could not start Cockpit socket"
    sleep 2
    if systemctl is-active --quiet cockpit.socket; then
        echo "   ✓ Cockpit socket started"
    else
        echo "   ✗ Failed to start Cockpit socket"
    fi
    echo ""
fi

if [ "$TRAEFIK_COCKPIT" = "false" ] && [ "$COCKPIT_PORT" = "true" ]; then
    echo "7. Fixing Cockpit firewall access..."
    echo "   Adding firewall rule for Docker network..."
    sudo iptables -C DOCKER-USER -s 172.20.0.0/16 -d 172.20.0.1 -p tcp --dport 9090 -j ACCEPT 2>/dev/null || \
        sudo iptables -I DOCKER-USER -s 172.20.0.0/16 -d 172.20.0.1 -p tcp --dport 9090 -j ACCEPT
    echo "   ✓ Firewall rule added (if needed)"
    echo ""
fi

# 8. Restart services if needed
if [ "$N8N_RUNNING" = "false" ]; then
    echo "8. Starting n8n..."
    docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 >/dev/null
    sleep 5
    echo "   ✓ n8n started"
    echo ""
fi

# 9. Test access
echo "9. Testing access..."
sleep 2

N8N_HTTP=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
if [ "$N8N_HTTP" = "200" ]; then
    echo "   ✓ n8n is accessible (HTTP $N8N_HTTP)"
else
    echo "   ⚠️  n8n returned HTTP $N8N_HTTP"
fi

COCKPIT_HTTP=$(curl -k -s -o /dev/null -w "%{http_code}" https://cockpit.inlock.ai 2>&1 || echo "000")
if [ "$COCKPIT_HTTP" = "200" ] || [ "$COCKPIT_HTTP" = "401" ] || [ "$COCKPIT_HTTP" = "302" ]; then
    echo "   ✓ Cockpit is accessible (HTTP $COCKPIT_HTTP)"
else
    echo "   ⚠️  Cockpit returned HTTP $COCKPIT_HTTP"
fi
echo ""

# 10. Summary
echo "=== Summary ==="
echo ""
echo "n8n:"
if [ "$N8N_NEEDS_USER" = "false" ]; then
    echo "  - Existing users found - use reset/delete scripts above"
else
    echo "  - No users - you can create a new account"
fi
echo "  - Access: https://n8n.inlock.ai"
echo ""
echo "Cockpit:"
if [ "$COCKPIT_PORT" = "true" ]; then
    echo "  - Service is running"
else
    echo "  - Service needs to be started"
fi
echo "  - Access: https://cockpit.inlock.ai"
echo "  - Login with any system user (e.g., your SSH user)"
echo ""
echo "If issues persist:"
echo "  - Check logs: docker logs compose-n8n-1"
echo "  - Check Cockpit: sudo systemctl status cockpit.socket"
echo "  - Check Traefik: docker logs compose-traefik-1 --tail 50"
echo ""

