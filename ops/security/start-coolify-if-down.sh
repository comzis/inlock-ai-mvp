#!/usr/bin/env bash
# Start Coolify stack if the main Coolify container is not running.
# Use from cron to auto-recover after crashes (e.g. every 15 min or after daily report).
#
# Usage:
#   ./start-coolify-if-down.sh              # use defaults (compose/services/coolify.yml, project "services")
#   ./start-coolify-if-down.sh --dry-run    # only report status, do not start
#
# Requires: docker compose, repo root with .env (or set INLOCK_REPO_ROOT and env file path).
#
# Cron example (every 15 min):
#   */15 * * * * root /home/comzis/inlock/ops/security/start-coolify-if-down.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${INLOCK_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
COMPOSE_FILE="${COOLIFY_COMPOSE_FILE:-$REPO_ROOT/compose/services/coolify.yml}"
PROJECT_NAME="${COOLIFY_PROJECT_NAME:-services}"
ENV_FILE="${COOLIFY_ENV_FILE:-$REPO_ROOT/.env}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "start-coolify-if-down: compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi

cd "$REPO_ROOT"

# Container name is typically ${PROJECT_NAME}-coolify-1
CONTAINER_NAME="${PROJECT_NAME}-coolify-1"
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    # Already running
    exit 0
  fi
fi

# Coolify (or its main container) is not running
if [[ "$DRY_RUN" == true ]]; then
  echo "start-coolify-if-down: $CONTAINER_NAME not running (dry-run, would start)"
  exit 0
fi

if [[ -f "$ENV_FILE" ]]; then
  docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" --env-file "$ENV_FILE" up -d
else
  docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
fi
echo "start-coolify-if-down: started Coolify stack ($PROJECT_NAME)"
