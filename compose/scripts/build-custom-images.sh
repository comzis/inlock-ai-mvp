#!/bin/bash
set -e

echo "========================================="
echo "Building Custom Mailu Images"
echo "========================================="

cd "$(dirname "$0")/.."

# Build custom admin image with SSO patch
echo ""
echo "Building mailu-admin-patched:2.0..."
docker build -t mailu-admin-patched:2.0 \
  -f docker/mailu-admin/Dockerfile \
  docker/mailu-admin/

if [ $? -eq 0 ]; then
  echo "✓ Admin image built successfully"
else
  echo "✗ Admin image build failed"
  exit 1
fi

# Build custom webmail image with symlinks
echo ""
echo "Building mailu-webmail-custom:2.0..."
docker build -t mailu-webmail-custom:2.0 \
  -f docker/mailu-webmail/Dockerfile \
  docker/mailu-webmail/

if [ $? -eq 0 ]; then
  echo "✓ Webmail image built successfully"
else
  echo "✗ Webmail image build failed"
  exit 1
fi

echo ""
echo "========================================="
echo "Custom Images Built Successfully!"
echo "========================================="
docker images | grep -E "mailu-(admin|webmail)" | head -5
