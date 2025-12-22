#!/usr/bin/env bash
set -euo pipefail

# Script to install PositiveSSL certificate files
# Usage: ./scripts/install-positive-ssl.sh <certificate.crt> <private.key> [intermediate.crt]

if [ $# -lt 2 ]; then
  echo "Usage: $0 <certificate.crt> <private.key> [intermediate.crt]"
  echo ""
  echo "Example:"
  echo "  $0 /path/to/inlock-ai.crt /path/to/private.key /path/to/intermediate.crt"
  exit 1
fi

CERT_FILE="$1"
KEY_FILE="$2"
INTERMEDIATE_FILE="${3:-}"

SECRETS_DIR="/home/comzis/apps/secrets"
FINAL_CERT="$SECRETS_DIR/positive-ssl.crt"
FINAL_KEY="$SECRETS_DIR/positive-ssl.key"

echo "Installing PositiveSSL Certificate"
echo "=================================="
echo ""

# Validate input files
if [ ! -f "$CERT_FILE" ]; then
  echo "❌ Certificate file not found: $CERT_FILE"
  exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
  echo "❌ Private key file not found: $KEY_FILE"
  exit 1
fi

# Check certificate matches key
echo "Step 1: Validating certificate and key match..."
CERT_MODULUS=$(openssl x509 -noout -modulus -in "$CERT_FILE" 2>/dev/null | openssl md5)
KEY_MODULUS=$(openssl rsa -noout -modulus -in "$KEY_FILE" 2>/dev/null | openssl md5)

if [ "$CERT_MODULUS" != "$KEY_MODULUS" ]; then
  echo "⚠️  WARNING: Certificate and key moduli don't match!"
  echo "   Certificate: $CERT_MODULUS"
  echo "   Key: $KEY_MODULUS"
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  echo "✅ Certificate and key match"
fi

# Create backup
echo ""
echo "Step 2: Creating backup..."
mkdir -p "$SECRETS_DIR"
if [ -f "$FINAL_CERT" ]; then
  cp "$FINAL_CERT" "${FINAL_CERT}.backup-$(date +%F-%H%M%S)"
  echo "  ✅ Backed up existing certificate"
fi
if [ -f "$FINAL_KEY" ]; then
  cp "$FINAL_KEY" "${FINAL_KEY}.backup-$(date +%F-%H%M%S)"
  echo "  ✅ Backed up existing key"
fi

# Combine certificate with intermediate if provided
echo ""
echo "Step 3: Installing certificate files..."
if [ -n "$INTERMEDIATE_FILE" ] && [ -f "$INTERMEDIATE_FILE" ]; then
  echo "  Combining certificate with intermediate chain..."
  cat "$CERT_FILE" "$INTERMEDIATE_FILE" > "$FINAL_CERT"
else
  cp "$CERT_FILE" "$FINAL_CERT"
  echo "  ⚠️  No intermediate certificate provided"
  echo "     You may need to combine it manually if required"
fi

cp "$KEY_FILE" "$FINAL_KEY"

# Set permissions
chmod 600 "$FINAL_CERT"
chmod 600 "$FINAL_KEY"

echo "  ✅ Certificate installed: $FINAL_CERT"
echo "  ✅ Private key installed: $FINAL_KEY"

# Verify certificate
echo ""
echo "Step 4: Verifying certificate..."
CERT_SUBJECT=$(openssl x509 -noout -subject -in "$FINAL_CERT" 2>/dev/null | sed 's/subject=//')
CERT_ISSUER=$(openssl x509 -noout -issuer -in "$FINAL_CERT" 2>/dev/null | sed 's/issuer=//')
CERT_EXPIRY=$(openssl x509 -noout -enddate -in "$FINAL_CERT" 2>/dev/null | sed 's/notAfter=//')

echo "  Subject: $CERT_SUBJECT"
echo "  Issuer: $CERT_ISSUER"
echo "  Expires: $CERT_EXPIRY"

# Check expiry
EXPIRY_DATE=$(date -d "$CERT_EXPIRY" +%s 2>/dev/null || echo "0")
CURRENT_DATE=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( (EXPIRY_DATE - CURRENT_DATE) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 0 ]; then
  echo "  ⚠️  WARNING: Certificate has expired!"
elif [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
  echo "  ⚠️  WARNING: Certificate expires in $DAYS_UNTIL_EXPIRY days"
else
  echo "  ✅ Certificate valid for $DAYS_UNTIL_EXPIRY days"
fi

echo ""
echo "Step 5: Restarting Traefik..."
cd "$(dirname "$0")/.."
docker compose -f compose/stack.yml --env-file .env restart traefik

echo ""
echo "=================================="
echo "✅ Certificate installation complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Check Traefik logs: docker logs compose-traefik-1"
echo "2. Test HTTPS: curl -k -v https://inlock.ai"
echo "3. Verify certificate loads without errors in Traefik logs"

