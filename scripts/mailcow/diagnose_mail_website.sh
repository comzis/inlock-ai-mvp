#!/bin/bash
# Diagnostic script for mail.inlock.ai website loading issues

set -euo pipefail

echo "=== mail.inlock.ai Diagnostic Script ==="
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
    exit 1
fi

# Test 2: HTTPS Connectivity
echo ""
echo "2. Testing HTTPS Connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://mail.inlock.ai 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} HTTPS connection successful (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}✗${NC} HTTPS connection failed (timeout or connection refused)"
    echo "   This could indicate:"
    echo "   - Firewall blocking port 443"
    echo "   - Server is down"
    echo "   - Network connectivity issues"
    exit 1
else
    echo -e "${YELLOW}⚠${NC} HTTPS connection returned HTTP $HTTP_CODE"
fi

# Test 3: SSL Certificate
echo ""
echo "3. Testing SSL Certificate..."
SSL_CHECK=$(echo | openssl s_client -connect mail.inlock.ai:443 -servername mail.inlock.ai 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
if [ -n "$SSL_CHECK" ]; then
    echo -e "${GREEN}✓${NC} SSL certificate is valid"
    echo "$SSL_CHECK" | sed 's/^/   /'
else
    echo -e "${RED}✗${NC} SSL certificate check failed"
fi

# Test 4: Content Retrieval
echo ""
echo "4. Testing Content Retrieval..."
CONTENT_CHECK=$(curl -s -L --max-time 10 https://mail.inlock.ai 2>/dev/null | head -30 | grep -qiE "mailcow|mail UI|DOCTYPE html|login" && echo "OK" || echo "FAIL")
if [ "$CONTENT_CHECK" = "OK" ]; then
    echo -e "${GREEN}✓${NC} Content is being served correctly"
    echo "   Sample content (first 100 chars):"
    curl -s -L --max-time 10 https://mail.inlock.ai 2>/dev/null | head -5 | tr -d '\n' | cut -c1-100 | sed 's/^/   /'
    echo ""
else
    echo -e "${YELLOW}⚠${NC} Content check had issues (may be normal)"
fi

# Test 5: Response Headers
echo ""
echo "5. Checking Response Headers..."
echo "   HTTP Status:"
curl -I --max-time 10 https://mail.inlock.ai 2>/dev/null | head -5 | sed 's/^/     /'

# Summary
echo ""
echo "=== Summary ==="
if [ "$HTTP_CODE" = "200" ] && [ "$CONTENT_CHECK" = "OK" ]; then
    echo -e "${GREEN}Server-side checks: All passing${NC}"
    echo ""
    echo "If the website still doesn't load in your browser, try:"
    echo "1. Clear browser cache (Ctrl+Shift+Delete)"
    echo "2. Try incognito/private browsing mode"
    echo "3. Disable browser extensions temporarily"
    echo "4. Try a different browser"
    echo "5. Check browser console for errors (F12)"
    echo "6. Verify firewall/proxy settings"
    echo "7. Try accessing from a different network"
else
    echo -e "${RED}Server-side issues detected${NC}"
    echo "Please check server configuration and service status"
fi
