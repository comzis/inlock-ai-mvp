#!/usr/bin/env bash
set -euo pipefail

# Script to rotate secrets and migrate to external location
# Ensures real secrets are outside repo and only .example files remain

SECRETS_DIR="secrets"
EXTERNAL_SECRETS="/home/comzis/apps/secrets-real"
BACKUP_DIR="/home/comzis/apps/secrets-real/backup-$(date +%F-%H%M%S)"

echo "Secret Rotation and Migration Script"
echo "===================================="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "Backup directory: $BACKUP_DIR"

# List of secret files
SECRETS=(
  "positive-ssl.crt"
  "positive-ssl.key"
  "traefik-dashboard-users.htpasswd"
  "portainer-admin-password"
  "n8n-db-password"
  "n8n-encryption-key"
)

echo ""
echo "Step 1: Backing up existing secrets..."
for secret in "${SECRETS[@]}"; do
  if [ -f "$EXTERNAL_SECRETS/$secret" ] && [ -s "$EXTERNAL_SECRETS/$secret" ]; then
    cp "$EXTERNAL_SECRETS/$secret" "$BACKUP_DIR/$secret"
    echo "  ✅ Backed up: $secret"
  else
    echo "  ⚠️  Missing or empty: $secret"
  fi
done

echo ""
echo "Step 2: Creating .example placeholders in repo..."
mkdir -p "$SECRETS_DIR"
for secret in "${SECRETS[@]}"; do
  EXAMPLE_FILE="$SECRETS_DIR/${secret}.example"
  if [ ! -f "$EXAMPLE_FILE" ]; then
    cat > "$EXAMPLE_FILE" <<EOF
# Placeholder for ${secret}
# Copy this file to ${EXTERNAL_SECRETS}/${secret} and fill with real values
# Do NOT commit real secrets to Git
EOF
    echo "  ✅ Created: $EXAMPLE_FILE"
  else
    echo "  ℹ️  Already exists: $EXAMPLE_FILE"
  fi
done

echo ""
echo "Step 3: Verifying external secrets location..."
if [ -d "$EXTERNAL_SECRETS" ]; then
  echo "  ✅ External secrets directory exists: $EXTERNAL_SECRETS"
  for secret in "${SECRETS[@]}"; do
    if [ -f "$EXTERNAL_SECRETS/$secret" ] && [ -s "$EXTERNAL_SECRETS/$secret" ]; then
      echo "  ✅ $secret exists and has content"
    else
      echo "  ⚠️  $secret missing or empty - needs to be populated"
    fi
  done
else
  echo "  ⚠️  External secrets directory not found: $EXTERNAL_SECRETS"
  echo "  Creating directory..."
  mkdir -p "$EXTERNAL_SECRETS"
  chmod 700 "$EXTERNAL_SECRETS"
fi

echo ""
echo "Step 4: Setting permissions..."
chmod 600 "$EXTERNAL_SECRETS"/* 2>/dev/null || true
echo "  ✅ Permissions set to 600"

echo ""
echo "===================================="
echo "Rotation Summary"
echo "===================================="
echo "Backup location: $BACKUP_DIR"
echo "External secrets: $EXTERNAL_SECRETS"
echo ""
echo "Next steps:"
echo "1. Review backed up secrets in: $BACKUP_DIR"
echo "2. Update secrets in: $EXTERNAL_SECRETS"
echo "3. Rotate any credentials that were previously committed"
echo "4. Verify compose files reference external paths"
echo "5. Test deployment with new secrets"

