#!/bin/bash
set -e

echo "========================================="
echo "Deploying Mailu with Custom Images"
echo "========================================="

cd "$(dirname "$0")/.."

# Stop existing containers
echo ""
echo "Stopping existing Mailu containers..."
docker compose -f mailu.yml down

# Build custom images
echo ""
./scripts/build-custom-images.sh

# Start services with custom images
echo ""
echo "Starting Mailu services..."
docker compose -f mailu.yml up -d

# Wait for services to be healthy
echo ""
echo "Waiting for services to be healthy..."
sleep 30

# Check service status
echo ""
echo "========================================="
echo "Service Status"
echo "========================================="
docker compose -f mailu.yml ps

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Test webmail access: https://mail.inlock.ai/webmail/"
echo "2. Verify SSO redirect works (no 404)"
echo "3. Test email sending/receiving"
