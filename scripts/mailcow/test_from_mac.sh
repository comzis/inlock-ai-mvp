#!/bin/bash
# Test Mail Server from Mac (Client-Side Tests)
# Run this from your Mac to diagnose client-side issues

DOMAIN="mail.inlock.ai"

echo "========================================="
echo "Mail Server Test - From Your Mac"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: System Time
echo "1. System Time Check"
SYSTEM_TIME=$(date +%s)
CURRENT_TIME=$(date -r $SYSTEM_TIME +%Y-%m-%d\ %H:%M:%S)
echo "   System time: $CURRENT_TIME"
if [ $SYSTEM_TIME -gt $(($(date +%s) - 300)) ] && [ $SYSTEM_TIME -lt $(($(date +%s) + 300)) ]; then
    echo -e "   ${GREEN}✓${NC} System time appears correct"
else
    echo -e "   ${RED}✗${NC} System time may be incorrect (SSL will fail)"
    echo "   Fix: System Settings → General → Date & Time → Set Automatically"
fi
echo ""

# Test 2: DNS Resolution
echo "2. DNS Resolution"
DNS_RESULT=$(nslookup $DOMAIN 2>&1 | grep -A 1 "Name:" | tail -1 | awk '{print $2}')
if [ -n "$DNS_RESULT" ] && [[ "$DNS_RESULT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "   ${GREEN}✓${NC} DNS resolves to: $DNS_RESULT"
else
    echo -e "   ${RED}✗${NC} DNS resolution failed"
    echo "   Fix: Check network settings or try different DNS (8.8.8.8)"
fi
echo ""

# Test 3: Port Connectivity
echo "3. Port 993 Connectivity (IMAP)"
if timeout 5 nc -zv $DOMAIN 993 2>&1 | grep -q "succeeded"; then
    echo -e "   ${GREEN}✓${NC} Port 993 is accessible from your Mac"
else
    echo -e "   ${RED}✗${NC} Port 993 is NOT accessible from your Mac"
    echo "   Possible causes:"
    echo "   - Firewall blocking port 993"
    echo "   - VPN routing incorrectly"
    echo "   - Network/ISP blocking IMAP"
    echo "   - Proxy blocking connection"
fi
echo ""

# Test 4: SSL Certificate
echo "4. SSL Certificate Validation"
SSL_CHECK=$(timeout 5 openssl s_client -connect $DOMAIN:993 -servername $DOMAIN 2>&1 | grep "Verify return code")
if echo "$SSL_CHECK" | grep -q "Verify return code: 0"; then
    echo -e "   ${GREEN}✓${NC} SSL certificate is valid"
else
    echo -e "   ${RED}✗${NC} SSL certificate validation failed"
    echo "   Possible causes:"
    echo "   - System time incorrect"
    echo "   - Certificate not trusted"
    echo "   - Network intercepting SSL"
fi
echo "$SSL_CHECK" | sed 's/^/   /'
echo ""

# Test 5: IMAP Response
echo "5. IMAP Server Response"
IMAP_RESPONSE=$(timeout 5 openssl s_client -connect $DOMAIN:993 -servername $DOMAIN -quiet 2>&1 <<< "" | head -3 | grep -E "^\* (OK|PREAUTH)" || echo "")
if [ -n "$IMAP_RESPONSE" ]; then
    echo -e "   ${GREEN}✓${NC} IMAP server is responding"
    echo "$IMAP_RESPONSE" | sed 's/^/   /'
else
    echo -e "   ${YELLOW}⚠${NC} IMAP response not detected (may be normal)"
    echo "   Note: Server may require authentication first"
fi
echo ""

# Summary
echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo "If all tests pass but Mail app still fails:"
echo "  1. Check Mail app settings:"
echo "     - Server: mail.inlock.ai (exactly this)"
echo "     - Port: 993 (in Advanced settings)"
echo "     - SSL: ON"
echo "     - Username: Full email address"
echo ""
echo "  2. Try removing and re-adding account"
echo ""
echo "  3. Check Keychain for certificate trust:"
echo "     - Keychain Access → Search 'mail.inlock.ai'"
echo "     - Set to 'Always Trust' if found"
echo ""
