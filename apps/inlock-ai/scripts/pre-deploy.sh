#!/bin/bash
# Pre-deployment safety checks for Inlock AI
# - Runs regression suite
# - Verifies branding cleanup
# - Confirms required env + build artifacts

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "========================================="
echo "Inlock AI Pre-Deployment Checks"
echo "========================================="
echo ""

if [ ! -x "$ROOT_DIR/scripts/regression-check.sh" ]; then
  echo "❌ regression-check.sh is missing or not executable."
  exit 1
fi

echo "1️⃣ Regression suite"
"$ROOT_DIR/scripts/regression-check.sh"

echo ""
echo "2️⃣ Branding verification"
if rg -i "streamart" --files-with-matches --glob '!*node_modules*' >/tmp/predeploy-streamart.txt; then
  echo "❌ Found deprecated 'StreamArt' references:"
  cat /tmp/predeploy-streamart.txt
  rm -f /tmp/predeploy-streamart.txt
  exit 1
fi
rm -f /tmp/predeploy-streamart.txt || true
echo "✅ Branding looks consistent"

echo ""
echo "3️⃣ Environment + build artifacts"
if [ ! -f .env.production ]; then
  echo "❌ Missing .env.production"
  exit 1
fi

if [ ! -d .next ]; then
  echo "ℹ️  No .next build artifacts detected, running npm run build"
  npm run build >/dev/null
fi

echo ""
echo "========================================="
echo "✅ Pre-deployment checks complete"
echo "========================================="
