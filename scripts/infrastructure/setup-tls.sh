#!/usr/bin/env bash
set -euo pipefail

# Script to configure TLS/SSL certificates for Traefik
# Sets up Cloudflare DNS challenge for Let's Encrypt

ENV_FILE="${1:-.env}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "TLS/SSL Certificate Setup"
echo "========================="
echo ""

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  .env file not found: $ENV_FILE"
  echo "   Copy from env.example and configure:"
  echo "   cp env.example $ENV_FILE"
  exit 1
fi

# Check for Cloudflare API token
if grep -q "CLOUDFLARE_API_TOKEN=replace-me" "$ENV_FILE" || grep -q "CLOUDFLARE_API_TOKEN=$" "$ENV_FILE"; then
  echo "⚠️  Cloudflare API token not configured in $ENV_FILE"
  echo ""
  echo "To get your Cloudflare API token:"
  echo "1. Log in to Cloudflare dashboard"
  echo "2. Go to My Profile > API Tokens"
  echo "3. Create Token > Use 'Edit zone DNS' template"
  echo "4. Permissions: Zone:DNS:Edit, Zone:Zone:Read"
  echo "5. Zone Resources: Include > Specific zone > inlock.ai"
  echo "6. Copy token and add to $ENV_FILE:"
  echo "   CLOUDFLARE_API_TOKEN=your-token-here"
  echo ""
  read -p "Press Enter after configuring CLOUDFLARE_API_TOKEN..."
fi

# Verify token is set
if ! grep -q "CLOUDFLARE_API_TOKEN=" "$ENV_FILE" || grep -q "CLOUDFLARE_API_TOKEN=replace-me" "$ENV_FILE"; then
  echo "❌ Cloudflare API token still not configured"
  exit 1
fi

echo "✅ Cloudflare API token configured"
echo ""

# Check PositiveSSL certs
POSITIVE_SSL_CERT="/home/comzis/apps/secrets-real/positive-ssl.crt"
POSITIVE_SSL_KEY="/home/comzis/apps/secrets-real/positive-ssl.key"

if [ ! -f "$POSITIVE_SSL_CERT" ] || [ ! -s "$POSITIVE_SSL_CERT" ]; then
  echo "⚠️  PositiveSSL certificate not found or empty: $POSITIVE_SSL_CERT"
  echo "   This is required for apex domain (inlock.ai)"
  echo "   Place your PositiveSSL cert and key in:"
  echo "   - $POSITIVE_SSL_CERT"
  echo "   - $POSITIVE_SSL_KEY"
  echo ""
fi

# Verify ACME storage
ACME_DIR="$PROJECT_ROOT/traefik/acme"
if [ ! -d "$ACME_DIR" ]; then
  mkdir -p "$ACME_DIR"
  chmod 700 "$ACME_DIR"
  echo "✅ Created ACME storage directory: $ACME_DIR"
fi

if [ ! -f "$ACME_DIR/acme.json" ]; then
  touch "$ACME_DIR/acme.json"
  chmod 600 "$ACME_DIR/acme.json"
  echo "✅ Created ACME storage file: $ACME_DIR/acme.json"
fi

echo ""
echo "TLS Configuration Summary"
echo "========================="
echo "Cloudflare DNS: Configured for Let's Encrypt DNS challenge"
echo "PositiveSSL: $(if [ -f "$POSITIVE_SSL_CERT" ] && [ -s "$POSITIVE_SSL_CERT" ]; then echo 'Configured'; else echo 'Needs setup'; fi)"
echo "ACME Storage: $ACME_DIR/acme.json"
echo ""
echo "Next steps:"
echo "1. Ensure DNS records point to this server"
echo "2. Restart Traefik: docker compose -f compose/stack.yml --env-file $ENV_FILE restart traefik"
echo "3. Monitor logs: docker logs compose-traefik-1 -f"
echo "4. Certificates will be automatically obtained via Let's Encrypt"

