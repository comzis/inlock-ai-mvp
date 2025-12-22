#!/bin/bash
# Get Docker container logs without requiring sudo
# Falls back to SSH or Portainer API
#
# Usage: ./scripts/docker-logs.sh <container-name> [tail-lines]

set -e

CONTAINER_NAME="$1"
TAIL_LINES="${2:-50}"

if [ -z "$CONTAINER_NAME" ]; then
  echo "Usage: $0 <container-name> [tail-lines]"
  exit 1
fi

# Try direct Docker access
if command -v docker &> /dev/null && docker ps &> /dev/null; then
  docker logs --tail "$TAIL_LINES" "$CONTAINER_NAME" 2>&1
  exit 0
fi

# Fallback: Try Portainer API
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -f ".env" ]; then
  PORTAINER_URL=$(grep "^PORTAINER_URL=" .env | cut -d'=' -f2 | tr -d '"' || echo "")
  PORTAINER_API_KEY=$(grep "^PORTAINER_API_KEY=" .env | cut -d'=' -f2 | tr -d '"' || echo "")
  
  if [ -n "$PORTAINER_URL" ] && [ -n "$PORTAINER_API_KEY" ]; then
    # Get container ID
    CONTAINER_ID=$(curl -s -H "X-API-Key: $PORTAINER_API_KEY" \
      "$PORTAINER_URL/api/endpoints/1/docker/containers/json" \
      | jq -r ".[] | select(.Names[] | contains(\"$CONTAINER_NAME\")) | .Id" | head -1)
    
    if [ -n "$CONTAINER_ID" ]; then
      curl -s -H "X-API-Key: $PORTAINER_API_KEY" \
        "$PORTAINER_URL/api/endpoints/1/docker/containers/$CONTAINER_ID/logs?stdout=1&stderr=1&tail=$TAIL_LINES"
      exit 0
    fi
  fi
fi

# Last resort
echo "⚠️  Cannot access Docker logs directly"
echo "Options:"
echo "1. SSH: ssh user@host 'docker logs --tail $TAIL_LINES $CONTAINER_NAME'"
echo "2. Portainer UI: https://portainer.inlock.ai → Containers → $CONTAINER_NAME → Logs"
exit 1

