#!/bin/bash
set -e

# Read password from secret file as root (before Postgres drops privileges)
# Docker secrets are only readable by root
if [ -f /run/secrets/n8n-db-password ] && [ "$(id -u)" = "0" ]; then
  POSTGRES_PASSWORD=$(cat /run/secrets/n8n-db-password | tr -d '\n\r')
  export POSTGRES_PASSWORD
  # CRITICAL: Unset POSTGRES_PASSWORD_FILE so Postgres entrypoint doesn't try to read it
  unset POSTGRES_PASSWORD_FILE
  # Also remove it from environment if it was set
  export -n POSTGRES_PASSWORD_FILE 2>/dev/null || true
fi

# Execute original Postgres entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"
