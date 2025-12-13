#!/bin/bash
# Mailu Secrets and Environment Validation Script

set -e
set -o pipefail

echo "=== Mailu Secrets and Environment Validation ==="
echo ""

# Check secrets
echo "1. Checking Secret Files..."
SECRETS_DIR="/home/comzis/apps/secrets-real"
for secret in mailu-secret-key mailu-admin-password mailu-db-password; do
  if [ -s "$SECRETS_DIR/$secret" ]; then
    size=$(wc -c < "$SECRETS_DIR/$secret")
    echo "   ✅ $secret: OK ($size bytes)"
  else
    echo "   ❌ $secret: MISSING OR EMPTY"
  fi
done

echo ""
echo "2. Checking Environment Variables (front service)..."
if docker ps | grep -q compose-mailu-front-1; then
  docker exec compose-mailu-front-1 env 2>/dev/null | grep -E "^DOMAIN=|^SECRET_KEY_FILE=|^DB_|^REDIS_|^TLS_|^POSTMASTER=|^MESSAGE_SIZE_LIMIT=" | while read line; do
    echo "   ✅ $line"
  done
else
  echo "   ⚠️  Front service not running"
fi

echo ""
echo "3. Checking Secret File Accessibility..."
if docker ps | grep -q compose-mailu-front-1; then
  for secret in mailu-secret-key mailu-db-password; do
    if docker exec compose-mailu-front-1 test -r "/run/secrets/$secret" 2>/dev/null; then
      echo "   ✅ $secret: Accessible in container"
    else
      echo "   ❌ $secret: NOT accessible in container"
    fi
  done
else
  echo "   ⚠️  Front service not running"
fi

echo ""
echo "=== Validation Complete ==="

