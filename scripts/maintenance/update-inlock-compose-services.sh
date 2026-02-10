#!/bin/bash
#
# Update selected Inlock Docker Compose services (pinned versions)
#
# Usage:
#   ./scripts/maintenance/update-inlock-compose-services.sh --dry-run
#   ./scripts/maintenance/update-inlock-compose-services.sh
#
# Notes:
# - Uses compose/services/stack.yml (Compose v2 include-based stack).
# - Pulls updated images, then applies with `up -d`.
# - Does not modify tags automatically; update tags in repo first.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/compose/services/stack.yml"
ENV_FILE="$PROJECT_ROOT/.env"

DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--dry-run]" >&2
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed/available" >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose (v2) is required" >&2
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "ERROR: missing compose file: $COMPOSE_FILE" >&2
  exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: missing env file: $ENV_FILE" >&2
  exit 1
fi

echo "=== Inlock Compose Update ==="
echo "Compose: $COMPOSE_FILE"
echo "Env:     $ENV_FILE"
echo ""

echo "Validating compose config..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config >/dev/null
echo "✓ Config OK"
echo ""

echo "Services with updated pins in repo:"
echo "  - oauth2-proxy"
echo "  - alertmanager"
echo "  - cadvisor"
echo "  - loki"
echo "  - promtail"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: would run:"
  echo "  docker compose -f \"$COMPOSE_FILE\" --env-file \"$ENV_FILE\" pull"
  echo "  docker compose -f \"$COMPOSE_FILE\" --env-file \"$ENV_FILE\" up -d"
  exit 0
fi

echo "Pulling images..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
echo ""

echo "Applying updates (up -d)..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
echo ""

echo "Status:"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" | head -n 30
echo ""

echo "Done."
