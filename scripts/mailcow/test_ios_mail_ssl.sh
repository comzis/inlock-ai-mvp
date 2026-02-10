#!/bin/bash
# Test SSL/TLS for iOS Mail Compatibility
# iOS Mail requires TLS 1.2+ and specific cipher suites

set -euo pipefail

DOMAIN="mail.inlock.ai"
IMAP_PORT=993
SMTP_PORT=465

echo "========================================="
echo "iOS Mail SSL/TLS Compatibility Test"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: TLS 1.2 (iOS 13+ requirement)
echo "1. Testing TLS 1.2 (iOS 13+ requirement)..."
TLS12_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -tls1_2 2>&1 | grep -E "(Protocol|Verify return code)" | head -3)

if echo "$TLS12_RESULT" | grep -q "Verify return code: 0"; then
    PROTOCOL=$(echo "$TLS12_RESULT" | grep "Protocol" | awk '{print $3}')
    echo -e "${GREEN}✓${NC} TLS 1.2 supported: $PROTOCOL"
else
    echo -e "${RED}✗${NC} TLS 1.2 test failed"
fi
echo "$TLS12_RESULT" | sed 's/^/   /'
echo ""

# Test 2: TLS 1.3 (iOS 14+ requirement)
echo "2. Testing TLS 1.3 (iOS 14+ requirement)..."
TLS13_RESULT=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -tls1_3 2>&1 | grep -E "(Protocol|Verify return code)" | head -3)

if echo "$TLS13_RESULT" | grep -q "Verify return code: 0"; then
    PROTOCOL=$(echo "$TLS13_RESULT" | grep "Protocol" | awk '{print $3}')
    echo -e "${GREEN}✓${NC} TLS 1.3 supported: $PROTOCOL"
else
    echo -e "${YELLOW}⚠${NC} TLS 1.3 not required (TLS 1.2 is minimum)"
fi
echo "$TLS13_RESULT" | sed 's/^/   /' 2>/dev/null || echo "   TLS 1.3 test skipped"
echo ""

# Test 3: Certificate chain
echo "3. Testing certificate chain completeness..."
CERT_CHAIN=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} -showcerts 2>&1 | grep -c "BEGIN CERTIFICATE" || echo "0")
echo "   Certificate chain length: $CERT_CHAIN certificates"
if [ "$CERT_CHAIN" -ge 2 ]; then
    echo -e "${GREEN}✓${NC} Certificate chain is complete"
else
    echo -e "${RED}✗${NC} Certificate chain may be incomplete"
fi
echo ""

# Test 4: SNI (Server Name Indication)
echo "4. Testing SNI support..."
SNI_TEST=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} 2>&1 | grep -E "(subject=|CN =)" | head -2)
echo "$SNI_TEST" | sed 's/^/   /'
if echo "$SNI_TEST" | grep -q "mail.inlock.ai"; then
    echo -e "${GREEN}✓${NC} SNI working correctly"
else
    echo -e "${RED}✗${NC} SNI issue detected"
fi
echo ""

# Test 5: Certificate validation
echo "5. Testing certificate validation..."
CERT_VALID=$(timeout 5 openssl s_client -connect ${DOMAIN}:${IMAP_PORT} -servername ${DOMAIN} 2>&1 | grep "Verify return code" | head -1)
echo "   $CERT_VALID"
if echo "$CERT_VALID" | grep -q "0 (ok)"; then
    echo -e "${GREEN}✓${NC} Certificate validation: OK"
else
    echo -e "${RED}✗${NC} Certificate validation failed"
fi
echo ""

# Summary
echo "=== iOS Mail Compatibility Summary ==="
echo ""
echo "iOS Mail Requirements:"
echo "  - TLS 1.2+ (required for iOS 13+)"
echo "  - Valid SSL certificate"
echo "  - Complete certificate chain"
echo "  - SNI support"
echo ""
echo "Recommended Settings:"
echo "  IMAP Server: $DOMAIN"
echo "  IMAP Port: $IMAP_PORT (SSL)"
echo "  SMTP Server: $DOMAIN"
echo "  SMTP Port: $SMTP_PORT (SSL) or 587 (STARTTLS)"
echo ""
echo "If connection fails:"
echo "  1. Check iOS Mail settings (correct server/port)"
echo "  2. Verify TLS 1.2+ is supported (should be ✓)"
echo "  3. Accept certificate if prompted"
echo "  4. Check system time on iOS device"
echo "  5. Try removing and re-adding account"
