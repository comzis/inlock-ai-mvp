#!/bin/bash
# Audit secret ages and expiry dates
# Checks if secrets need rotation based on cadence in docs/SECRET-MANAGEMENT.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "========================================="
echo "Secret Age & Expiry Audit"
echo "========================================="
echo ""

WARNINGS=0

# Check SSL certificate expiry
if docker secret ls | grep -q positive_ssl_cert; then
  echo "📜 SSL Certificate:"
  CERT_DATE=$(docker secret inspect positive_ssl_cert --format '{{.CreatedAt}}' 2>/dev/null | cut -d'T' -f1 || echo "unknown")
  echo "   Created: $CERT_DATE"
  
  # Check actual certificate expiry if possible
  if command -v openssl &> /dev/null; then
    echo "   Checking expiry..."
    # Note: Can't easily check Docker secret expiry without extracting it
    echo "   ⚠️  Manual check recommended: openssl x509 -in cert.crt -noout -dates"
  fi
  echo ""
fi

# Check .env file age
if [ -f ".env" ]; then
  echo "🔐 .env file:"
  ENV_AGE=$(find .env -mtime +90 2>/dev/null && echo "old" || echo "recent")
  ENV_DATE=$(stat -c %y .env 2>/dev/null | cut -d' ' -f1 || echo "unknown")
  echo "   Modified: $ENV_DATE"
  if [ "$ENV_AGE" = "old" ]; then
    echo "   ⚠️  WARNING: .env not modified in 90+ days - consider rotation"
    WARNINGS=$((WARNINGS + 1))
  fi
  echo ""
fi

# Check .env.production age
if [ -f "/opt/inlock-ai-secure-mvp/.env.production" ]; then
  echo "🔐 Application .env.production:"
  APP_ENV_AGE=$(find /opt/inlock-ai-secure-mvp/.env.production -mtime +30 2>/dev/null && echo "old" || echo "recent")
  APP_ENV_DATE=$(stat -c %y /opt/inlock-ai-secure-mvp/.env.production 2>/dev/null | cut -d' ' -f1 || echo "unknown")
  echo "   Modified: $APP_ENV_DATE"
  if [ "$APP_ENV_AGE" = "old" ]; then
    echo "   ⚠️  WARNING: .env.production not modified in 30+ days - consider rotation"
    WARNINGS=$((WARNINGS + 1))
  fi
  echo ""
fi

# Check Traefik basic auth secret age
if docker secret ls | grep -q traefik-basicauth; then
  echo "🔐 Traefik Basic Auth:"
  AUTH_DATE=$(docker secret inspect traefik-basicauth --format '{{.CreatedAt}}' 2>/dev/null | cut -d'T' -f1 || echo "unknown")
  echo "   Created: $AUTH_DATE"
  echo "   ⚠️  Check if rotation needed (quarterly cadence)"
  echo ""
fi

echo "========================================="
if [ $WARNINGS -eq 0 ]; then
  echo "✅ No immediate rotation warnings"
else
  echo "⚠️  $WARNINGS warning(s) - review secret rotation cadence"
fi
echo ""
echo "For rotation procedures, see: docs/SECRET-MANAGEMENT.md"

