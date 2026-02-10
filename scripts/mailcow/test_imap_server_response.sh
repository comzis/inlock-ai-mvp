#!/bin/bash
# Test IMAP Server Response
# Tests if IMAP server is actually responding to connections

set -euo pipefail

DOMAIN="mail.inlock.ai"
IMAP_PORT=993

echo "========================================="
echo "IMAP Server Response Test"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Port: $IMAP_PORT (IMAP SSL)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Port connectivity
echo "1. Testing port connectivity..."
if nc -zv -w 3 ${DOMAIN} ${IMAP_PORT} 2>&1 | grep -q "succeeded\|open"; then
    echo -e "${GREEN}✓${NC} Port ${IMAP_PORT} is open"
else
    echo -e "${RED}✗${NC} Port ${IMAP_PORT} is not accessible"
    echo "   This could indicate:"
    echo "   - Firewall blocking port"
    echo "   - Dovecot not running"
    echo "   - Network connectivity issue"
fi
echo ""

# Test 2: SSL handshake
echo "2. Testing SSL handshake..."
SSL_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)

if echo "$SSL_RESULT" | grep -q "CONNECTED"; then
    echo -e "${GREEN}✓${NC} SSL handshake successful"
    if echo "$SSL_RESULT" | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓${NC} Certificate valid"
    fi
else
    echo -e "${RED}✗${NC} SSL handshake failed"
fi
echo "$SSL_RESULT" | sed 's/^/   /'
echo ""

# Test 3: IMAP server response
echo "3. Testing IMAP server response..."
IMAP_RESPONSE=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -quiet 2>&1 <<< "" | head -3 | grep -E "\* (OK|PREAUTH|BYE|CAPABILITY)" || echo "")

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

# Test 4: IMAP capability
echo "4. Testing IMAP CAPABILITY command..."
CAPABILITY=$(echo "a1 CAPABILITY" | timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -quiet 2>&1 | grep -iE "CAPABILITY|OK|BYE" | head -3 || echo "")

if [ -n "$CAPABILITY" ]; then
    echo -e "${GREEN}✓${NC} IMAP protocol is working"
    echo "$CAPABILITY" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠${NC} IMAP CAPABILITY test inconclusive"
    echo "   (This is normal if server requires authentication first)"
fi
echo ""

# Test 5: Service status check
echo "5. Checking service status (requires SSH)..."
SERVICE_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=dovecot' --format '{{.Status}}'" 2>&1 || echo "SSH check failed")

if echo "$SERVICE_STATUS" | grep -q "Up"; then
    echo -e "${GREEN}✓${NC} Dovecot container is running: $SERVICE_STATUS"
else
    echo -e "${RED}✗${NC} Dovecot container status: $SERVICE_STATUS"
fi
echo ""

# Summary
echo "=== Summary ==="
echo ""
if echo "$IMAP_RESPONSE" | grep -qE "\* (OK|PREAUTH)"; then
    echo -e "${GREEN}✓ IMAP server is responding correctly${NC}"
    echo ""
    echo "If iOS Mail still shows 'IMAP server is null - not responding':"
    echo "  1. Check iOS Mail settings (server name: mail.inlock.ai)"
    echo "  2. Verify port: 993 (IMAP SSL)"
    echo "  3. Check iOS network connectivity"
    echo "  4. Try removing and re-adding account"
    echo "  5. Check iOS system time"
else
    echo -e "${RED}✗ IMAP server is NOT responding${NC}"
    echo ""
    echo "Possible causes:"
    echo "  1. Dovecot IMAP service not running"
    echo "  2. IMAP service disabled in configuration"
    echo "  3. Port 993 blocked by firewall"
    echo "  4. Network connectivity issue"
    echo "  5. Dovecot configuration error"
    echo ""
    echo "Next steps:"
    echo "  1. Check Dovecot logs: docker logs mailcowdockerized-dovecot-mailcow-1"
    echo "  2. Verify Dovecot is running: docker ps --filter 'name=dovecot'"
    echo "  3. Check IMAP service is enabled"
    echo "  4. Verify port 993 is listening"
fi
echo ""
