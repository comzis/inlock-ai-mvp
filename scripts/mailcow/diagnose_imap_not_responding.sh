#!/bin/bash
# Diagnose IMAP Not Responding Issue

set -euo pipefail

DOMAIN="mail.inlock.ai"
IMAP_PORT=993
IP_TO_CHECK="31.10.147.220"

echo "========================================="
echo "IMAP Not Responding - Diagnosis"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Port: $IMAP_PORT (IMAP SSL)"
echo "Your IP: $IP_TO_CHECK"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Port connectivity
echo "1. Testing port connectivity..."
PORT_CHECK=$(timeout 5 nc -zv ${DOMAIN} ${IMAP_PORT} 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")

if [ "$PORT_CHECK" = "OK" ]; then
    echo -e "${GREEN}✓${NC} Port ${IMAP_PORT} is accessible"
else
    echo -e "${RED}✗${NC} Port ${IMAP_PORT} is NOT accessible"
    echo "   Possible causes:"
    echo "   - Firewall blocking port"
    echo "   - Dovecot not running"
    echo "   - Network connectivity issue"
fi
echo ""

# Test 2: SSL handshake
echo "2. Testing SSL handshake..."
SSL_CHECK=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)

if echo "$SSL_CHECK" | grep -q "CONNECTED"; then
    echo -e "${GREEN}✓${NC} SSL handshake successful"
    if echo "$SSL_CHECK" | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓${NC} Certificate valid"
    else
        echo -e "${YELLOW}⚠${NC} Certificate validation issue"
    fi
else
    echo -e "${RED}✗${NC} SSL handshake failed"
fi
echo "$SSL_CHECK" | sed 's/^/   /'
echo ""

# Test 3: IMAP server response
echo "3. Testing IMAP server response..."
IMAP_RESPONSE=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -quiet 2>&1 <<< "" | head -3 | grep -E "^\* (OK|PREAUTH|BYE|CAPABILITY)" || echo "")

if [ -n "$IMAP_RESPONSE" ]; then
    echo -e "${GREEN}✓${NC} IMAP server is responding"
    echo "$IMAP_RESPONSE" | sed 's/^/   /'
else
    echo -e "${RED}✗${NC} IMAP server is NOT responding"
    echo "   This indicates:"
    echo "   - IMAP service is not running"
    echo "   - Dovecot IMAP is disabled"
    echo "   - Service is not listening on port ${IMAP_PORT}"
fi
echo ""

# Test 4: Service status
echo "4. Checking Dovecot service status..."
SERVICE_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=dovecot' --format '{{.Status}}'" 2>&1 || echo "Check failed")

if echo "$SERVICE_STATUS" | grep -q "Up"; then
    echo -e "${GREEN}✓${NC} Dovecot container is running: $SERVICE_STATUS"
else
    echo -e "${RED}✗${NC} Dovecot container status: $SERVICE_STATUS"
    echo "   Dovecot may be down or restarting"
fi
echo ""

# Test 5: IP block check
echo "5. Checking if IP is blocked by fail2ban..."
echo "   Your IP: $IP_TO_CHECK"
echo ""
echo "   ⚠️  To check if blocked, run on server:"
echo "      ssh comzis@100.83.222.69"
echo "      sudo iptables -L -n | grep '$IP_TO_CHECK'"
echo "      sudo fail2ban-client status dovecot | grep '$IP_TO_CHECK'"
echo ""
echo "   If blocked, unban:"
echo "      sudo fail2ban-client unban $IP_TO_CHECK"
echo ""

# Summary
echo "=== Summary ==="
echo ""
if [ "$PORT_CHECK" = "OK" ] && echo "$SSL_CHECK" | grep -q "CONNECTED" && [ -n "$IMAP_RESPONSE" ]; then
    echo -e "${GREEN}✓ IMAP server is responding correctly${NC}"
    echo ""
    echo "If your mail client still shows 'IMAP is not responding':"
    echo "  1. Check mail client settings (server: mail.inlock.ai, port: 993, SSL: ON)"
    echo "  2. Verify IP $IP_TO_CHECK is not blocked by fail2ban"
    echo "  3. Check network connectivity from your device"
    echo "  4. Try removing and re-adding account"
    echo "  5. Check system time on your device"
else
    echo -e "${RED}✗ IMAP server is NOT responding${NC}"
    echo ""
    echo "Possible causes:"
    echo "  1. Dovecot IMAP service not running"
    echo "  2. IMAP service disabled in configuration"
    echo "  3. Port 993 blocked by firewall"
    echo "  4. Network connectivity issue"
    echo "  5. IP $IP_TO_CHECK blocked by fail2ban"
    echo ""
    echo "Next steps:"
    echo "  1. Check Dovecot logs: docker logs mailcowdockerized-dovecot-mailcow-1"
    echo "  2. Verify Dovecot is running: docker ps --filter 'name=dovecot'"
    echo "  3. Check IMAP service is enabled"
    echo "  4. Verify port 993 is listening"
    echo "  5. Check if IP is blocked: sudo fail2ban-client status dovecot"
fi
echo ""
