#!/bin/bash
# Diagnose why mail.inlock.ai is not loading
# Checks server status, services, and network connectivity

set -euo pipefail

echo "=== Mailcow Service Diagnostic ==="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: DNS Resolution
echo "1. Testing DNS Resolution..."
DNS_RESULT=$(dig +short mail.inlock.ai 2>/dev/null | head -1)
if [ -n "$DNS_RESULT" ]; then
    echo -e "${GREEN}✓${NC} DNS resolves to: $DNS_RESULT"
else
    echo -e "${RED}✗${NC} DNS resolution failed"
fi
echo ""

# Test 2: HTTPS Connectivity
echo "2. Testing HTTPS Connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://mail.inlock.ai 2>&1 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} HTTPS connection successful (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}✗${NC} HTTPS connection failed (timeout or connection refused)"
    echo "   This could indicate:"
    echo "   - Mailcow service is down"
    echo "   - Traefik reverse proxy is down"
    echo "   - Server is unreachable"
    echo "   - Firewall blocking connection"
else
    echo -e "${YELLOW}⚠${NC} HTTPS connection returned HTTP $HTTP_CODE"
fi
echo ""

# Test 3: Server Reachability
echo "3. Testing Server Reachability..."
if ping -c 1 -W 2 mail.inlock.ai > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Server is reachable"
else
    echo -e "${RED}✗${NC} Server is not reachable"
fi
echo ""

# Test 4: Check Mailcow Services (if SSH works)
echo "4. Checking Mailcow Services (requires SSH)..."
MAILCOW_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=mailcow' --format '{{.Names}}: {{.Status}}' | head -5" 2>&1 || echo "SSH_FAILED")

if [ "$MAILCOW_STATUS" = "SSH_FAILED" ]; then
    echo -e "${YELLOW}⚠${NC} Cannot check services (SSH connection failed or timed out)"
    echo "   Run manually: ssh comzis@100.83.222.69 'docker ps | grep mailcow'"
else
    if [ -z "$MAILCOW_STATUS" ]; then
        echo -e "${RED}✗${NC} No Mailcow containers found!"
    else
        echo -e "${GREEN}✓${NC} Mailcow containers status:"
        echo "$MAILCOW_STATUS" | sed 's/^/   /'
    fi
fi
echo ""

# Test 5: Check Traefik (if SSH works)
echo "5. Checking Traefik Service (requires SSH)..."
TRAEFIK_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=traefik' --format '{{.Names}}: {{.Status}}'" 2>&1 || echo "SSH_FAILED")

if [ "$TRAEFIK_STATUS" = "SSH_FAILED" ]; then
    echo -e "${YELLOW}⚠${NC} Cannot check Traefik (SSH connection failed or timed out)"
else
    if [ -z "$TRAEFIK_STATUS" ]; then
        echo -e "${RED}✗${NC} Traefik container not found!"
        echo "   This could be the cause of the connection failure"
    else
        echo -e "${GREEN}✓${NC} Traefik status:"
        echo "$TRAEFIK_STATUS" | sed 's/^/   /'
    fi
fi
echo ""

# Summary
echo "=== Summary ==="
if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}Server is not responding correctly${NC}"
    echo ""
    echo "Possible causes:"
    echo "  1. Mailcow services crashed"
    echo "  2. Traefik reverse proxy is down"
    echo "  3. Server is overloaded"
    echo "  4. Network connectivity issues"
    echo ""
    echo "Next steps:"
    echo "  1. SSH to server: ssh comzis@100.83.222.69"
    echo "  2. Check Mailcow containers: docker ps | grep mailcow"
    echo "  3. Check Traefik: docker ps | grep traefik"
    echo "  4. Check logs: docker logs services-traefik-1 --tail 50"
    echo "  5. Restart services if needed"
else
    echo -e "${GREEN}Server is responding correctly${NC}"
fi
