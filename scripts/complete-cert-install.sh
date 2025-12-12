#!/usr/bin/env bash
set -euo pipefail

# Complete certificate installation - run this once you have the private key

CERT_FILE="/tmp/inlock_ai-combined.crt"
KEY_FILE="${1:-/tmp/inlock_ai.key}"

if [ ! -f "$KEY_FILE" ]; then
  echo "❌ Private key file not found: $KEY_FILE"
  echo ""
  echo "Usage: $0 [path-to-private-key.key]"
  echo ""
  echo "If your key file is in /tmp with a different name, specify it:"
  echo "  $0 /tmp/your-key-file.key"
  echo ""
  echo "The key file should start with:"
  echo "  -----BEGIN PRIVATE KEY-----"
  echo "  or"
  echo "  -----BEGIN RSA PRIVATE KEY-----"
  exit 1
fi

if [ ! -f "$CERT_FILE" ]; then
  echo "❌ Combined certificate file not found: $CERT_FILE"
  echo "Please run the certificate preparation first"
  exit 1
fi

echo "=========================================="
echo "Completing PositiveSSL Certificate Installation"
echo "=========================================="
echo ""

# Use the install script
cd "$(dirname "$0")/.."
./scripts/install-positive-ssl.sh "$CERT_FILE" "$KEY_FILE"










