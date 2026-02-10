#!/bin/bash

# Script to check status of all subdomains for inlock.ai
DOMAIN="inlock.ai"

echo "========================================="
echo "Checking Subdomain Status for $DOMAIN"
echo "========================================="
echo ""

# Common subdomains to check
SUBDOMAINS=(
    "www"
    "mail"
    "mailcow"
    "auth"
    "auth0"
    "api"
    "app"
    "admin"
    "dashboard"
    "portal"
    "webmail"
    "smtp"
    "imap"
    "pop"
)

# Function to check DNS resolution
check_dns() {
    local subdomain=$1
    local full_domain="${subdomain}.${DOMAIN}"
    
    echo "Checking: $full_domain"
    echo "----------------------------------------"
    
    # Check DNS A record
    echo -n "DNS A Record: "
    A_RECORD=$(dig +short "$full_domain" A 2>/dev/null | head -1)
    if [ -z "$A_RECORD" ]; then
        echo "❌ NOT FOUND"
    else
        echo "✅ $A_RECORD"
    fi
    
    # Check DNS AAAA record (IPv6)
    echo -n "DNS AAAA Record: "
    AAAA_RECORD=$(dig +short "$full_domain" AAAA 2>/dev/null | head -1)
    if [ -z "$AAAA_RECORD" ]; then
        echo "   (none)"
    else
        echo "✅ $AAAA_RECORD"
    fi
    
    # Check CNAME
    echo -n "DNS CNAME Record: "
    CNAME_RECORD=$(dig +short "$full_domain" CNAME 2>/dev/null | head -1)
    if [ -z "$CNAME_RECORD" ]; then
        echo "   (none)"
    else
        echo "✅ $CNAME_RECORD"
    fi
    
    # Check MX record
    echo -n "DNS MX Record: "
    MX_RECORD=$(dig +short "$full_domain" MX 2>/dev/null | head -1)
    if [ -z "$MX_RECORD" ]; then
        echo "   (none)"
    else
        echo "✅ $MX_RECORD"
    fi
    
    # Check HTTP/HTTPS connectivity
    if [ -n "$A_RECORD" ] || [ -n "$CNAME_RECORD" ]; then
        echo -n "HTTP Status: "
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${full_domain}" 2>/dev/null)
        if [ "$HTTP_CODE" = "000" ]; then
            echo "❌ Cannot connect"
        else
            echo "✅ $HTTP_CODE"
        fi
        
        echo -n "HTTPS Status: "
        HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -k "https://${full_domain}" 2>/dev/null)
        if [ "$HTTPS_CODE" = "000" ]; then
            echo "❌ Cannot connect"
        else
            echo "✅ $HTTPS_CODE"
        fi
    fi
    
    echo ""
}

# Check root domain
echo "Checking root domain: $DOMAIN"
echo "----------------------------------------"
echo -n "DNS A Record: "
ROOT_A=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
if [ -z "$ROOT_A" ]; then
    echo "❌ NOT FOUND"
else
    echo "✅ $ROOT_A"
fi
echo ""

# Check all subdomains
for subdomain in "${SUBDOMAINS[@]}"; do
    check_dns "$subdomain"
done

# Also check for any wildcard or discover subdomains via DNS enumeration
echo "========================================="
echo "Checking for additional DNS records..."
echo "========================================="
echo ""

# Try to get all DNS records from nameserver
echo "Attempting to list all DNS records (this may require zone transfer access)..."
dig AXFR "$DOMAIN" 2>/dev/null | grep -E "^[a-zA-Z0-9_-]+\.$DOMAIN" | head -20 || echo "Zone transfer not available (this is normal)"

echo ""
echo "========================================="
echo "Summary: Check completed"
echo "========================================="
