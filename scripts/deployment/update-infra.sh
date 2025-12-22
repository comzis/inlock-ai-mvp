#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f ".env" ]; then
  echo ".env missing; copy env.example and fill real values." >&2
  exit 1
fi

docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env pull
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d

