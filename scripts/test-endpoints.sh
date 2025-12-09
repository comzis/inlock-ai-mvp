#!/usr/bin/env bash
# Test all endpoints and features

set -euo pipefail

echo "=========================================="
echo "ENDPOINT & FEATURE TEST"
echo "=========================================="
echo ""

SERVER_IP="localhost"
# Uncomment to test from external IP:
# SERVER_IP="your-server-ip"

echo "Testing endpoints on: $SERVER_IP"
echo ""

# Test HTTP redirect
echo "=== HTTP → HTTPS Redirect ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: inlock.ai" http://$SERVER_IP 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "308" ]; then
    echo "✅ HTTP redirect working (Status: $HTTP_CODE)"
else
    echo "⚠️  HTTP redirect: Status $HTTP_CODE"
fi
echo ""

# Test HTTPS endpoints
echo "=== HTTPS Endpoints ==="
echo ""

ENDPOINTS=(
    "inlock.ai:Homepage"
    "traefik.inlock.ai:Traefik Dashboard"
    "portainer.inlock.ai:Portainer"
    "n8n.inlock.ai:n8n"
)

for endpoint in "${ENDPOINTS[@]}"; do
    HOST="${endpoint%%:*}"
    NAME="${endpoint##*:}"
    
    echo "Testing $NAME ($HOST)..."
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: $HOST" https://$SERVER_IP 2>/dev/null || echo "000")
    SSL_VERIFY=$(curl -k -s -o /dev/null -w "%{ssl_verify_result}" -H "Host: $HOST" https://$SERVER_IP 2>/dev/null || echo "1")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "  ✅ Accessible (HTTP $HTTP_CODE)"
        if [ "$SSL_VERIFY" = "0" ]; then
            echo "  ✅ SSL valid"
        else
            echo "  ⚠️  SSL warning (self-signed cert)"
        fi
    else
        echo "  ❌ Not accessible (HTTP $HTTP_CODE)"
    fi
    echo ""
done

# Test internal services
echo "=== Internal Service Connectivity ==="
echo ""

if docker exec compose-homepage-1 wget -qO- http://localhost 2>/dev/null | head -1 > /dev/null 2>&1; then
    echo "✅ Homepage: Internal connectivity working"
else
    echo "⚠️  Homepage: Internal connectivity issue"
fi

if docker exec compose-postgres-1 pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ Postgres: Database accessible"
else
    echo "⚠️  Postgres: Database not accessible"
fi

if docker exec compose-n8n-1 wget -qO- http://localhost:5678 2>/dev/null | head -1 > /dev/null 2>&1; then
    echo "✅ n8n: Service accessible"
else
    echo "⚠️  n8n: Service not accessible (may still be starting)"
fi
echo ""

# Test access control
echo "=== Access Control Test ==="
echo ""
echo "Testing IP allowlist (should work from Tailscale IP, block others)..."
echo "Note: Test from external IP to verify 403 response"
echo ""

# Test certificate
echo "=== Certificate Test ==="
echo ""
if [ -f "/home/comzis/apps/secrets/positive-ssl.crt" ]; then
    CERT_SUBJECT=$(openssl x509 -in /home/comzis/apps/secrets/positive-ssl.crt -noout -subject 2>/dev/null | sed 's/subject=//')
    CERT_EXPIRY=$(openssl x509 -in /home/comzis/apps/secrets/positive-ssl.crt -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    echo "✅ Certificate installed"
    echo "  Subject: $CERT_SUBJECT"
    echo "  Expires: $CERT_EXPIRY"
else
    echo "❌ Certificate not found"
fi
echo ""

echo "=========================================="
echo "TEST COMPLETE"
echo "=========================================="
echo ""
echo "To test from external IP:"
echo "  curl -k -v https://inlock.ai"
echo "  curl -k -v https://traefik.inlock.ai"
echo ""



