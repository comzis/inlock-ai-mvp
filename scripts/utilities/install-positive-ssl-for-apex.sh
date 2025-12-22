#!/usr/bin/env bash
set -euo pipefail

# Install PositiveSSL certificate for inlock.ai apex domain
# Usage: ./scripts/install-positive-ssl-for-apex.sh [path-to-key-file]

KEY_FILE="${1:-/tmp/inlock_ai-positive-ssl.key}"
CERT_FILE="/tmp/inlock_ai-positive-ssl-combined.crt"

if [ ! -f "$KEY_FILE" ]; then
  echo "❌ Private key file not found: $KEY_FILE"
  echo ""
  echo "Usage: $0 [path-to-private-key.key]"
  echo ""
  echo "The key file must match the PositiveSSL certificate."
  exit 1
fi

if [ ! -f "$CERT_FILE" ]; then
  echo "❌ Combined certificate file not found: $CERT_FILE"
  echo "Please ensure PositiveSSL certificate files are in /tmp/"
  exit 1
fi

echo "=========================================="
echo "Installing PositiveSSL Certificate"
echo "=========================================="
echo ""

# Verify key matches certificate
echo "Step 1: Verifying certificate and key match..."
CERT_MOD=$(openssl x509 -noout -modulus -in "$CERT_FILE" 2>/dev/null | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "$KEY_FILE" 2>/dev/null | openssl md5)

# Extract domain cert to check
DOMAIN_CERT="/tmp/inlock_ai.crt"
if [ -f "$DOMAIN_CERT" ]; then
  CERT_MOD=$(openssl x509 -noout -modulus -in "$DOMAIN_CERT" 2>/dev/null | openssl md5)
fi

if [ "$CERT_MOD" != "$KEY_MOD" ]; then
  echo "❌ ERROR: Certificate and key don't match!"
  echo "   Certificate modulus: $CERT_MOD"
  echo "   Key modulus: $KEY_MOD"
  exit 1
fi

echo "✅ Certificate and key match"
echo ""

# Create backup
echo "Step 2: Creating backup..."
SECRETS_DIR="/home/comzis/apps/secrets"
mkdir -p "$SECRETS_DIR"

if [ -f "$SECRETS_DIR/positive-ssl.crt" ]; then
  cp "$SECRETS_DIR/positive-ssl.crt" "${SECRETS_DIR}/positive-ssl.crt.backup-$(date +%F-%H%M%S)"
  echo "  ✅ Backed up existing certificate"
fi
if [ -f "$SECRETS_DIR/positive-ssl.key" ]; then
  cp "$SECRETS_DIR/positive-ssl.key" "${SECRETS_DIR}/positive-ssl.key.backup-$(date +%F-%H%M%S)"
  echo "  ✅ Backed up existing key"
fi

# Install certificate and key
echo ""
echo "Step 3: Installing certificate files..."
cp "$CERT_FILE" "$SECRETS_DIR/positive-ssl.crt"
cp "$KEY_FILE" "$SECRETS_DIR/positive-ssl.key"

chmod 600 "$SECRETS_DIR/positive-ssl.crt"
chmod 600 "$SECRETS_DIR/positive-ssl.key"

echo "  ✅ Certificate installed: $SECRETS_DIR/positive-ssl.crt"
echo "  ✅ Private key installed: $SECRETS_DIR/positive-ssl.key"

# Verify certificate
echo ""
echo "Step 4: Verifying certificate..."
openssl x509 -in "$SECRETS_DIR/positive-ssl.crt" -noout -subject -issuer -dates

# Restart Traefik
echo ""
echo "Step 5: Restarting Traefik..."
cd "$(dirname "$0")/.."
docker compose -f compose/stack.yml --env-file .env restart traefik

echo ""
echo "=========================================="
echo "✅ PositiveSSL Certificate Installed!"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  - inlock.ai → PositiveSSL certificate"
echo "  - Subdomains → Let's Encrypt (automatic)"
echo ""
echo "Next steps:"
echo "1. Check Traefik logs: docker logs compose-traefik-1"
echo "2. Test HTTPS: curl -k -v https://inlock.ai"
echo "3. Verify no certificate errors in Traefik logs"










