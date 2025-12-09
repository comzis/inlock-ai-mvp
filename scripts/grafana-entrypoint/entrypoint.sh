#!/bin/sh
set -e

# Read password from secret file (accessible as root)
if [ -f /run/secrets/grafana_admin_password ]; then
  PASSWORD=$(cat /run/secrets/grafana_admin_password | tr -d '\n\r')
  export GF_SECURITY_ADMIN_PASSWORD="$PASSWORD"
  echo "✅ Password read from secret file"
else
  echo "⚠️  Secret file not found, using default password"
fi

# Execute original Grafana entrypoint
# Grafana's /run.sh handles user switching internally
echo "Starting Grafana..."
exec /run.sh "$@"
