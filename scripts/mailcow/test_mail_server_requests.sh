#!/bin/bash
# Comprehensive Mail Server Connection Test
# Tests IMAP, SMTP, SSL, and connectivity

set -euo pipefail

DOMAIN="mail.inlock.ai"
IMAP_PORT=993
SMTP_SSL_PORT=465
SMTP_STARTTLS_PORT=587
IP_TO_CHECK="31.10.147.220"

echo "========================================="
echo "Mail Server Connection Test Suite"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Your IP: $IP_TO_CHECK"
echo "Date: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        ((TESTS_FAILED++))
    fi
}

# Test 1: DNS Resolution
echo -e "${BLUE}1. DNS Resolution${NC}"
DNS_RESULT=$(dig +short $DOMAIN 2>&1 | head -1)
if [ -n "$DNS_RESULT" ] && [[ "$DNS_RESULT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_result "PASS" "DNS resolves to: $DNS_RESULT"
else
    print_result "FAIL" "DNS resolution failed"
fi
echo ""

# Test 2: Ping Test
echo -e "${BLUE}2. Network Connectivity (Ping)${NC}"
PING_RESULT=$(timeout 3 ping -c 1 $DOMAIN 2>&1 | grep -E "1 packets transmitted|1 received" || echo "")
if echo "$PING_RESULT" | grep -q "1 received"; then
    print_result "PASS" "Ping successful"
else
    print_result "FAIL" "Ping failed or timeout"
fi
echo ""

# Test 3: IMAP Port 993 Connectivity
echo -e "${BLUE}3. IMAP Port 993 Connectivity${NC}"
IMAP_PORT_CHECK=$(timeout 5 nc -zv $DOMAIN $IMAP_PORT 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")
if [ "$IMAP_PORT_CHECK" = "OK" ]; then
    print_result "PASS" "Port $IMAP_PORT is accessible"
else
    print_result "FAIL" "Port $IMAP_PORT is not accessible"
fi
echo ""

# Test 4: IMAP SSL Certificate
echo -e "${BLUE}4. IMAP SSL Certificate (Port 993)${NC}"
IMAP_SSL=$(timeout 5 openssl s_client -connect $DOMAIN:$IMAP_PORT -servername $DOMAIN 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)
if echo "$IMAP_SSL" | grep -q "CONNECTED" && echo "$IMAP_SSL" | grep -q "Verify return code: 0"; then
    print_result "PASS" "IMAP SSL certificate is valid"
    CERT_INFO=$(timeout 5 openssl s_client -connect $DOMAIN:$IMAP_PORT -servername $DOMAIN 2>&1 | grep -E "(subject=|issuer=)" | head -2)
    echo "   $CERT_INFO" | sed 's/^/   /'
else
    print_result "FAIL" "IMAP SSL certificate validation failed"
fi
echo ""

# Test 5: IMAP Server Response
echo -e "${BLUE}5. IMAP Server Response${NC}"
IMAP_RESPONSE=$(timeout 5 openssl s_client -connect $DOMAIN:$IMAP_PORT -servername $DOMAIN -quiet 2>&1 <<< "" | head -3 | grep -E "^\* (OK|PREAUTH|BYE|CAPABILITY)" || echo "")
if [ -n "$IMAP_RESPONSE" ]; then
    print_result "PASS" "IMAP server is responding"
    echo "$IMAP_RESPONSE" | sed 's/^/   /'
else
    print_result "FAIL" "IMAP server is NOT responding"
    echo "   (This may indicate IP is blocked or service issue)"
fi
echo ""

# Test 6: SMTP Port 465 Connectivity
echo -e "${BLUE}6. SMTP Port 465 Connectivity (SSL)${NC}"
SMTP465_CHECK=$(timeout 5 nc -zv $DOMAIN $SMTP_SSL_PORT 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")
if [ "$SMTP465_CHECK" = "OK" ]; then
    print_result "PASS" "Port $SMTP_SSL_PORT is accessible"
else
    print_result "FAIL" "Port $SMTP_SSL_PORT is not accessible"
fi
echo ""

# Test 7: SMTP SSL Certificate (Port 465)
echo -e "${BLUE}7. SMTP SSL Certificate (Port 465)${NC}"
SMTP_SSL=$(timeout 5 openssl s_client -connect $DOMAIN:$SMTP_SSL_PORT -servername $DOMAIN 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)
if echo "$SMTP_SSL" | grep -q "CONNECTED" && echo "$SMTP_SSL" | grep -q "Verify return code: 0"; then
    print_result "PASS" "SMTP SSL certificate is valid"
else
    print_result "FAIL" "SMTP SSL certificate validation failed"
fi
echo ""

# Test 8: SMTP Port 587 Connectivity
echo -e "${BLUE}8. SMTP Port 587 Connectivity (STARTTLS)${NC}"
SMTP587_CHECK=$(timeout 5 nc -zv $DOMAIN $SMTP_STARTTLS_PORT 2>&1 | grep -q "succeeded\|open" && echo "OK" || echo "FAIL")
if [ "$SMTP587_CHECK" = "OK" ]; then
    print_result "PASS" "Port $SMTP_STARTTLS_PORT is accessible"
else
    print_result "FAIL" "Port $SMTP_STARTTLS_PORT is not accessible"
fi
echo ""

# Test 9: SMTP STARTTLS Certificate (Port 587)
echo -e "${BLUE}9. SMTP STARTTLS Certificate (Port 587)${NC}"
STARTTLS_SSL=$(timeout 5 openssl s_client -connect $DOMAIN:$SMTP_STARTTLS_PORT -starttls smtp -servername $DOMAIN 2>&1 | grep -E "(CONNECTED|Verify return code)" | head -2)
if echo "$STARTTLS_SSL" | grep -q "CONNECTED" && echo "$STARTTLS_SSL" | grep -q "Verify return code: 0"; then
    print_result "PASS" "SMTP STARTTLS certificate is valid"
else
    print_result "FAIL" "SMTP STARTTLS certificate validation failed"
fi
echo ""

# Test 10: HTTPS Webmail (Port 443)
echo -e "${BLUE}10. HTTPS Webmail (Port 443)${NC}"
HTTPS_CHECK=$(timeout 5 curl -I -s https://$DOMAIN 2>&1 | head -1 | grep -E "HTTP/[12] 200|HTTP/[12] 301|HTTP/[12] 302" || echo "")
if [ -n "$HTTPS_CHECK" ]; then
    print_result "PASS" "HTTPS webmail is accessible"
    echo "   $HTTPS_CHECK" | sed 's/^/   /'
else
    print_result "FAIL" "HTTPS webmail is not accessible"
fi
echo ""

# Test 11: Service Status (requires SSH)
echo -e "${BLUE}11. Service Status Check${NC}"
DOVECOT_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=dovecot' --format '{{.Status}}'" 2>&1 || echo "SSH failed")
if echo "$DOVECOT_STATUS" | grep -q "Up"; then
    print_result "PASS" "Dovecot is running: $DOVECOT_STATUS"
else
    print_result "FAIL" "Dovecot status: $DOVECOT_STATUS"
fi

POSTFIX_STATUS=$(timeout 10 ssh comzis@100.83.222.69 "docker ps --filter 'name=postfix' --format '{{.Status}}'" 2>&1 | head -1 || echo "SSH failed")
if echo "$POSTFIX_STATUS" | grep -q "Up"; then
    print_result "PASS" "Postfix is running: $POSTFIX_STATUS"
else
    print_result "FAIL" "Postfix status: $POSTFIX_STATUS"
fi
echo ""

# Test 12: IP Block Check (requires SSH and sudo)
echo -e "${BLUE}12. IP Block Check (Your IP: $IP_TO_CHECK)${NC}"
echo "   ⚠️  This requires manual check on server:"
echo "      ssh comzis@100.83.222.69"
echo "      sudo iptables -L -n | grep '$IP_TO_CHECK'"
echo "      sudo fail2ban-client status dovecot | grep '$IP_TO_CHECK'"
echo "      sudo fail2ban-client status postfix | grep '$IP_TO_CHECK'"
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "If you're still experiencing issues:"
    echo "  1. Check if IP $IP_TO_CHECK is blocked by fail2ban"
    echo "  2. Verify mail client settings are correct"
    echo "  3. Check network connectivity from your device"
elif [ $TESTS_FAILED -le 2 ]; then
    echo -e "${YELLOW}⚠ Some tests failed${NC}"
    echo ""
    echo "Most likely issues:"
    echo "  1. IP $IP_TO_CHECK may be blocked by fail2ban"
    echo "  2. Service may be down (check service status)"
    echo "  3. Network connectivity issue"
else
    echo -e "${RED}✗ Multiple tests failed${NC}"
    echo ""
    echo "Possible causes:"
    echo "  1. Server is down or unreachable"
    echo "  2. Network connectivity issues"
    echo "  3. Firewall blocking connections"
    echo "  4. DNS resolution problems"
fi
echo ""

# Configuration Summary
echo "========================================="
echo "Mail Client Configuration"
echo "========================================="
echo ""
echo "IMAP Settings (Incoming Mail):"
echo "  Server: $DOMAIN"
echo "  Port: $IMAP_PORT"
echo "  SSL: ON"
echo "  Username: Full email address (e.g., admin@inlock.ai)"
echo ""
echo "SMTP Settings (Outgoing Mail):"
echo "  Server: $DOMAIN"
echo "  Port: $SMTP_SSL_PORT (SSL) or $SMTP_STARTTLS_PORT (STARTTLS)"
echo "  SSL: ON"
echo "  Username: Full email address"
echo ""
echo "========================================="
