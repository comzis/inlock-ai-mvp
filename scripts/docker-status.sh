#!/bin/bash
# Get Docker container status without requiring sudo
# Uses Docker API directly or Portainer API if available
#
# Usage: ./scripts/docker-status.sh [service-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -n "$1" ]; then
  SERVICE_NAME="$1"
fi

# Try direct Docker access first
if command -v docker &> /dev/null && docker ps &> /dev/null; then
  echo "📊 Container Status (via Docker):"
  echo ""
  
  if [ -n "$SERVICE_NAME" ]; then
    docker ps --filter "name=$SERVICE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Health}}" || echo "No containers found"
  else
    docker compose -f compose/stack.yml --env-file .env ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>/dev/null || \
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}" | head -20
  fi
  exit 0
fi

# Fallback: Try Portainer API if available
if [ -f ".env" ]; then
  PORTAINER_URL=$(grep "^PORTAINER_URL=" .env | cut -d'=' -f2 | tr -d '"' || echo "")
  PORTAINER_API_KEY=$(grep "^PORTAINER_API_KEY=" .env | cut -d'=' -f2 | tr -d '"' || echo "")
  
  if [ -n "$PORTAINER_URL" ] && [ -n "$PORTAINER_API_KEY" ]; then
    echo "📊 Container Status (via Portainer API):"
    echo ""
    curl -s -H "X-API-Key: $PORTAINER_API_KEY" \
      "$PORTAINER_URL/api/endpoints/1/docker/containers/json" \
      | jq -r '.[] | "\(.Names[0]) - \(.Status)"' || echo "API call failed"
    exit 0
  fi
fi

# Last resort: SSH to management node
echo "⚠️  Cannot access Docker directly"
echo ""
echo "Options:"
echo "1. Add user to docker group: sudo usermod -aG docker $USER"
echo "2. Use SSH to management node: ssh user@mgmt-node 'docker ps'"
echo "3. Use Portainer web UI: https://portainer.inlock.ai"
echo ""
exit 1

