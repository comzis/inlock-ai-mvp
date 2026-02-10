#!/bin/bash
# Certificate Health Check Script
# Run this script before and after any certificate-related changes

set -e

DOMAIN="inlock.ai"
EXPECTED_POSITIVE_SSL_FP="FB:FD:85:7E:20:F0:E3:9C:79:D4:0D:BC:7B:7F:5A:2C:5F:E9:1D:39:BF:08:41:C4:53:A4:06:D5:E4:D2:2B:E8"
REPO_PATH="/home/comzis/projects/inlock-ai-mvp"

echo "========================================="
echo "Certificate Health Check"
echo "========================================="
echo ""

# Function to check certificate
check_cert() {
    local domain=$1
    local expected_fp=$2
    local description=$3
    
    echo "Checking: $domain ($description)"
    echo "----------------------------------------"
    
    # Get certificate fingerprint
    local fp=$(echo | openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | \
        openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d'=' -f2)
    
    if [ -z "$fp" ]; then
        echo "❌ Cannot retrieve certificate"
        return 1
    fi
    
    # Get certificate details
    local issuer=$(echo | openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | \
        openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
    local subject=$(echo | openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | \
        openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
    local dates=$(echo | openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | \
        openssl x509 -noout -dates 2>/dev/null)
    
    echo "Fingerprint: $fp"
    echo "Issuer: $issuer"
    echo "Subject: $subject"
    echo "$dates"
    
    # Check if fingerprint matches expected
    if [ -n "$expected_fp" ] && [ "$fp" = "$expected_fp" ]; then
        echo "✅ Certificate fingerprint matches expected Positive SSL"
        return 0
    elif [ -n "$expected_fp" ]; then
        echo "❌ Certificate fingerprint MISMATCH"
        echo "   Expected: $expected_fp"
        echo "   Got:      $fp"
        return 1
    else
        echo "✅ Certificate is valid"
        return 0
    fi
}

# Check Positive SSL domains
echo "=== Positive SSL Certificate Check ==="
echo ""

check_cert "inlock.ai" "$EXPECTED_POSITIVE_SSL_FP" "Main domain (MUST use Positive SSL)"
INLOCK_STATUS=$?

echo ""
check_cert "www.inlock.ai" "$EXPECTED_POSITIVE_SSL_FP" "WWW domain (MUST use Positive SSL)"
WWW_STATUS=$?

echo ""
echo "=== Traefik Configuration Check ==="
echo ""

# Check Traefik TLS configuration
if [ -f "$REPO_PATH/traefik/dynamic/tls.yml" ]; then
    if grep -q "positive_ssl_cert" "$REPO_PATH/traefik/dynamic/tls.yml"; then
        echo "✅ Positive SSL configured in tls.yml"
    else
        echo "❌ Positive SSL NOT found in tls.yml"
    fi
else
    echo "❌ tls.yml not found"
fi

# Check router configuration
if [ -f "$REPO_PATH/traefik/dynamic/routers.yml" ]; then
    if grep -A 10 "inlock-ai:" "$REPO_PATH/traefik/dynamic/routers.yml" | grep -q "options: default"; then
        echo "✅ inlock-ai router uses Positive SSL (options: default)"
    else
        echo "❌ inlock-ai router does NOT use Positive SSL"
    fi
else
    echo "❌ routers.yml not found"
fi

echo ""
echo "=== Cloudflare Token Check ==="
echo ""

# Check Cloudflare token
if [ -f "/home/comzis/inlock/.env" ]; then
    TOKEN=$(grep "^CLOUDFLARE_API_TOKEN=" /home/comzis/inlock/.env | cut -d'=' -f2- | head -1)
    if [ -n "$TOKEN" ]; then
        RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json")
        
        if echo "$RESPONSE" | grep -q '"success":true'; then
            echo "✅ Cloudflare API token is valid"
        else
            echo "❌ Cloudflare API token is invalid"
            echo "$RESPONSE" | python3 -m json.tool 2>/dev/null | head -10
        fi
    else
        echo "❌ Cloudflare API token not found in .env"
    fi
else
    echo "❌ .env file not found"
fi

echo ""
echo "=== Subdomain Certificate Check ==="
echo ""

# Check subdomains
SUBDOMAINS=("mail" "auth" "dashboard" "n8n" "grafana" "deploy" "portainer" "cockpit" "traefik" "mailcow" "auth0" "api" "app" "admin" "portal" "webmail")

for subdomain in "${SUBDOMAINS[@]}"; do
    domain="${subdomain}.${DOMAIN}"
    echo -n "Checking ${domain}: "
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://${domain}" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "000" ]; then
        echo "❌ Cannot connect"
    elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
        echo "✅ HTTPS working (HTTP $HTTP_CODE)"
    else
        echo "⚠️  HTTPS returns $HTTP_CODE"
    fi
done

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo ""

if [ $INLOCK_STATUS -eq 0 ] && [ $WWW_STATUS -eq 0 ]; then
    echo "✅ Positive SSL certificates verified for inlock.ai and www.inlock.ai"
    echo "✅ Platform certificate configuration is healthy"
    exit 0
else
    echo "❌ CRITICAL: Positive SSL certificate verification failed"
    echo "❌ Platform may be experiencing certificate issues"
    echo ""
    echo "IMMEDIATE ACTION REQUIRED:"
    echo "1. Check Traefik configuration"
    echo "2. Verify certificate files are mounted"
    echo "3. Review Traefik logs: docker compose -f compose/services/stack.yml logs traefik"
    echo "4. Consider rollback if recent changes were made"
    exit 1
fi
