#!/usr/bin/env bash
set -euo pipefail

# Script to fix service permissions for homepage and portainer
# Run with appropriate privileges

echo "Fixing service permissions..."
echo ""

# Fix Portainer data directory permissions
PORTAINER_DATA="/home/comzis/apps/traefik/portainer_data"
if [ -d "$PORTAINER_DATA" ]; then
  echo "Fixing Portainer data directory permissions..."
  # Portainer runs as UID 1000
  chown -R 1000:1000 "$PORTAINER_DATA" 2>/dev/null || {
    echo "⚠️  Cannot chown (need sudo): sudo chown -R 1000:1000 $PORTAINER_DATA"
  }
  chmod 755 "$PORTAINER_DATA"
  echo "✅ Portainer data directory permissions updated"
else
  echo "⚠️  Portainer data directory not found: $PORTAINER_DATA"
fi

echo ""
echo "For homepage nginx user issue:"
echo "  The nginx:alpine image uses user 101 by default."
echo "  Options:"
echo "    1. Run nginx as root (remove user restrictions)"
echo "    2. Create custom nginx config overriding user directive"
echo "    3. Use a different nginx base image"
echo ""
echo "Current fix: Remove read_only and run without user restrictions"

