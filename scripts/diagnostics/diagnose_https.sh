#!/bin/bash

# Detailed HTTPS diagnosis script
DOMAIN="inlock.ai"

FAILING_SUBDOMAINS=(
    "mailcow"
    "auth0"
    "api"
    "app"
    "admin"
    "portal"
    "webmail"
    "smtp"
    "imap"
    "pop"
)

echo "========================================="
echo "Detailed HTTPS Diagnosis"
echo "========================================="
echo ""

for subdomain in "${FAILING_SUBDOMAINS[@]}"; do
    full_domain="${subdomain}.${DOMAIN}"
    echo "Testing: $full_domain"
    echo "----------------------------------------"
    
    # Check SSL certificate
    echo "SSL Certificate Info:"
    timeout 5 openssl s_client -connect "${full_domain}:443" -servername "${full_domain}" </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "  ❌ Cannot retrieve certificate"
    
    # Check TLS version
    echo -n "TLS Connection: "
    timeout 5 openssl s_client -connect "${full_domain}:443" -servername "${full_domain}" </dev/null 2>/dev/null | grep -E "Protocol|Cipher" | head -2 || echo "  ❌ Cannot connect"
    
    # Detailed curl output
    echo "Curl Details:"
    curl -v -k --connect-timeout 5 "https://${full_domain}" 2>&1 | grep -E "Connected|SSL|HTTP|error" | head -5
    
    echo ""
done
