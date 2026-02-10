#!/bin/bash
# Test SMTP Connection for Mac Mail
# Tests SMTP ports 465 (SSL) and 587 (STARTTLS)

set -euo pipefail

DOMAIN="mail.inlock.ai"
SMTP_SSL_PORT=465
SMTP_STARTTLS_PORT=587

echo "========================================="
echo "SMTP Connection Test for Mac Mail"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Port 465 (SMTP SSL)
echo "1. Testing SMTP SSL (port 465)..."
PORT465_CHECK=$(timeout 5 nc -zv ${DOMAIN} ${SMTP_SSL_PORT} 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")

if [ "$PORT465_CHECK" = "OK" ]; then
    echo -e "${GREEN}✓${NC} Port 465 is accessible"
else
    echo -e "${RED}✗${NC} Port 465 is not accessible"
fi

SSL465_CHECK=$(timeout 5 openssl s_client -connect ${DOMAIN}:${SMTP_SSL_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)

if echo "$SSL465_CHECK" | grep -q "CONNECTED"; then
    if echo "$SSL465_CHECK" | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓${NC} SSL certificate is valid"
    else
        echo -e "${YELLOW}⚠${NC} SSL certificate issue"
    fi
else
    echo -e "${RED}✗${NC} SSL handshake failed"
fi
echo "$SSL465_CHECK" | sed 's/^/   /'
echo ""

# Test 2: Port 587 (SMTP STARTTLS)
echo "2. Testing SMTP STARTTLS (port 587)..."
PORT587_CHECK=$(timeout 5 nc -zv ${DOMAIN} ${SMTP_STARTTLS_PORT} 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")

if [ "$PORT587_CHECK" = "OK" ]; then
    echo -e "${GREEN}✓${NC} Port 587 is accessible"
else
    echo -e "${RED}✗${NC} Port 587 is not accessible"
fi

STARTTLS_CHECK=$(timeout 5 openssl s_client -connect ${DOMAIN}:${SMTP_STARTTLS_PORT} -starttls smtp -servername ${DOMAIN} 2>&1 | grep -E "(CONNECTED|Verify return code|220|250)" | head -5)

if echo "$STARTTLS_CHECK" | grep -q "CONNECTED"; then
    if echo "$STARTTLS_CHECK" | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✓${NC} STARTTLS certificate is valid"
    else
        echo -e "${YELLOW}⚠${NC} STARTTLS certificate issue"
    fi
    if echo "$STARTTLS_CHECK" | grep -q "220"; then
        echo -e "${GREEN}✓${NC} SMTP server is responding"
    fi
else
    echo -e "${RED}✗${NC} STARTTLS handshake failed"
fi
echo "$STARTTLS_CHECK" | sed 's/^/   /'
echo ""

# Test 3: SMTP server response
echo "3. Testing SMTP server response..."
SMTP_RESPONSE=$(timeout 5 (echo "EHLO test"; sleep 1) | openssl s_client -connect ${DOMAIN}:${SMTP_SSL_PORT} -servername ${DOMAIN} -quiet 2>&1 | grep -E "250|220|EHLO" | head -3 || echo "")

if [ -n "$SMTP_RESPONSE" ]; then
    echo -e "${GREEN}✓${NC} SMTP server is responding"
    echo "$SMTP_RESPONSE" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠${NC} SMTP response test inconclusive"
    echo "   (This is normal - server may require authentication first)"
fi
echo ""

# Summary
echo "=== Mac Mail SMTP Configuration ==="
echo ""
echo "Option 1: SSL (Port 465) - Recommended"
echo "  SMTP Server: $DOMAIN"
echo "  Port: 465"
echo "  Use SSL: ✅ Yes"
echo "  Authentication: Password"
echo "  Username: Your email address (e.g., admin@inlock.ai)"
echo "  Password: Your email password"
echo ""
echo "Option 2: STARTTLS (Port 587) - Alternative"
echo "  SMTP Server: $DOMAIN"
echo "  Port: 587"
echo "  Use SSL: ✅ Yes (STARTTLS)"
echo "  Authentication: Password"
echo "  Username: Your email address"
echo "  Password: Your email password"
echo ""
echo "=== Troubleshooting ==="
echo ""
echo "If 'Could not connect to SMTP server' error:"
echo "  1. Verify server: $DOMAIN (not IP address)"
echo "  2. Check port: 465 (SSL) or 587 (STARTTLS)"
echo "  3. Ensure SSL is enabled"
echo "  4. Check username: Full email address"
echo "  5. Verify password is correct"
echo "  6. Check if IP is blocked: ./scripts/check_fail2ban_ip.sh <YOUR_IP>"
echo ""
