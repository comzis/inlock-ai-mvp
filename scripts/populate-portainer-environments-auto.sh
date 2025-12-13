#!/usr/bin/env bash
# Auto-populate Portainer Environments (Non-interactive)
#
# This version reads password from secret file if available
# Usage: ./scripts/populate-portainer-environments-auto.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

PORTAINER_URL="${PORTAINER_URL:-https://portainer.inlock.ai}"
ADMIN_USER="${ADMIN_USER:-admin}"

# Try to read password from secret file
SECRET_FILE="/home/comzis/apps/secrets-real/portainer-admin-password"
if [ -f "$SECRET_FILE" ]; then
    ADMIN_PASS=$(cat "$SECRET_FILE" | head -1 | tr -d '\n' | tr -d '\r')
    echo "Using password from secret file"
else
    echo "❌ Error: Password secret file not found at $SECRET_FILE"
    echo "Please create it first:"
    echo "  echo 'your-password' > $SECRET_FILE"
    exit 1
fi

# Call the main script with password
exec "$SCRIPT_DIR/populate-portainer-environments.sh" "$ADMIN_USER" "$ADMIN_PASS"

