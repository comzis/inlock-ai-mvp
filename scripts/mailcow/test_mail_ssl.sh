#!/bin/bash
# Test Mail SSL Connections for MacBook Mail
# Tests IMAP, SMTP SSL/TLS connections

set -euo pipefail

DOMAIN="mail.inlock.ai"
IMAP_PORT=993
SMTP_PORT=465
SMTP_STARTTLS_PORT=587

echo "========================================="
echo "Mail SSL Connection Test"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: IMAP SSL (993)
echo "1. Testing IMAP SSL (port 993)..."
IMAP_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(subject=|issuer=|Verify return code)" | head -5)

if echo "$IMAP_RESULT" | grep -q "Verify return code: 0"; then
    echo -e "${GREEN}✓${NC} IMAP SSL certificate is valid"
    echo "$IMAP_RESULT" | sed 's/^/   /'
else
    echo -e "${RED}✗${NC} IMAP SSL certificate issue detected"
    echo "$IMAP_RESULT" | sed 's/^/   /'
fi
echo ""

# Test 2: SMTP SSL (465)
echo "2. Testing SMTP SSL (port 465)..."
SMTP_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${SMTP_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(subject=|issuer=|Verify return code)" | head -5)

if echo "$SMTP_RESULT" | grep -q "Verify return code: 0"; then
    echo -e "${GREEN}✓${NC} SMTP SSL certificate is valid"
    echo "$SMTP_RESULT" | sed 's/^/   /'
else
    echo -e "${RED}✗${NC} SMTP SSL certificate issue detected"
    echo "$SMTP_RESULT" | sed 's/^/   /'
fi
echo ""

# Test 3: SMTP STARTTLS (587)
echo "3. Testing SMTP STARTTLS (port 587)..."
STARTTLS_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${SMTP_STARTTLS_PORT} -starttls smtp -servername ${DOMAIN} 2>&1 | grep -E "(subject=|issuer=|Verify return code)" | head -5)

if echo "$STARTTLS_RESULT" | grep -q "Verify return code: 0"; then
    echo -e "${GREEN}✓${NC} SMTP STARTTLS certificate is valid"
    echo "$STARTTLS_RESULT" | sed 's/^/   /'
else
    echo -e "${RED}✗${NC} SMTP STARTTLS certificate issue detected"
    echo "$STARTTLS_RESULT" | sed 's/^/   /'
fi
echo ""

# Test 4: Check certificate chain
echo "4. Checking certificate chain (IMAP)..."
CERT_CHAIN=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -showcerts 2>&1 | grep -c "BEGIN CERTIFICATE" || echo "0")
echo "   Certificate chain length: $CERT_CHAIN certificates"
echo ""

# Summary
echo "=== Summary ==="
echo ""
echo "MacBook Mail connection settings:"
echo "  IMAP Server: $DOMAIN"
echo "  IMAP Port: $IMAP_PORT (SSL)"
echo "  SMTP Server: $DOMAIN"
echo "  SMTP Port: $SMTP_PORT (SSL) or $SMTP_STARTTLS_PORT (STARTTLS)"
echo ""
echo "If SSL connections fail:"
echo "  1. Check if certificates are valid (should show 'Verify return code: 0')"
echo "  2. Verify Dovecot is running: docker ps --filter 'name=dovecot'"
echo "  3. Check Mailcow certificate configuration"
echo "  4. Try using STARTTLS instead of SSL (port 587)"
