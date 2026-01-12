#!/usr/bin/env bash
set -euo pipefail

# Usage: DOCKER_IMAGE=youruser/streamart-ai-secure-mvp:<tag> DEPLOY_DIR=/opt/streamart-ai-secure-mvp ./scripts/deploy/remote-deploy.sh

DEPLOY_DIR="${DEPLOY_DIR:-/opt/streamart-ai-secure-mvp}"

echo "Changing to deploy directory: ${DEPLOY_DIR}"
cd "${DEPLOY_DIR}"

if [ ! -f .env ]; then
  echo "Missing .env in ${DEPLOY_DIR}; aborting." >&2
  exit 1
fi

if [ -n "${DOCKER_IMAGE:-}" ]; then
  export DOCKER_IMAGE
  echo "Using DOCKER_IMAGE=${DOCKER_IMAGE}"
fi

echo "Pulling images..."
docker compose pull web

echo "Deploying..."
docker compose up -d

echo "Pruning old images..."
docker image prune -f >/dev/null

echo "Done."
