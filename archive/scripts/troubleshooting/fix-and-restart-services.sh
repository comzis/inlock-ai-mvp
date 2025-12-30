#!/usr/bin/env bash
set -euo pipefail

# Script to fix service permissions and restart services
# Handles Portainer data directory and service restarts

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Service Fix and Restart"
echo "======================"
echo ""

# Fix Portainer data directory permissions
PORTAINER_DATA="/home/comzis/apps/traefik/portainer_data"

if [ -d "$PORTAINER_DATA" ]; then
  echo "Step 1: Fixing Portainer data directory permissions..."
  
  # Try without sudo first
  if chown -R 1000:1000 "$PORTAINER_DATA" 2>/dev/null; then
    echo "  ✅ Permissions updated"
  else
    echo "  ⚠️  Requires sudo for chown"
    echo "  Run: sudo chown -R 1000:1000 $PORTAINER_DATA"
    echo ""
    read -p "Press Enter after fixing permissions manually, or Ctrl+C to exit..."
  fi
  
  chmod 755 "$PORTAINER_DATA" 2>/dev/null || true
else
  echo "⚠️  Portainer data directory not found: $PORTAINER_DATA"
  echo "  Creating directory..."
  mkdir -p "$PORTAINER_DATA"
  chmod 755 "$PORTAINER_DATA"
  if [ "$EUID" -eq 0 ]; then
    chown -R 1000:1000 "$PORTAINER_DATA"
  else
    echo "  Run: sudo chown -R 1000:1000 $PORTAINER_DATA"
  fi
fi

# Restart Portainer
echo ""
echo "Step 2: Restarting Portainer..."
if [ -f ".env" ]; then
  ENV_FILE=".env"
elif [ -f "env.example" ]; then
  ENV_FILE="env.example"
  echo "  ⚠️  Using env.example (create .env for production)"
else
  echo "  ❌ No .env file found"
  exit 1
fi

docker compose -f compose/stack.yml --env-file "$ENV_FILE" restart portainer

echo ""
echo "Step 3: Checking service status..."
sleep 3
docker compose -f compose/stack.yml --env-file "$ENV_FILE" ps portainer homepage

echo ""
echo "✅ Service fix and restart complete!"
echo ""
echo "If Portainer is still restarting, verify permissions:"
echo "  sudo chown -R 1000:1000 $PORTAINER_DATA"
echo "  docker compose -f compose/stack.yml --env-file $ENV_FILE restart portainer"

