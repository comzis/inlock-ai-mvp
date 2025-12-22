#!/bin/bash
# Fetch secrets from Vault and create Docker secrets or update env files
# Usage: ./scripts/fetch-vault-secrets.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "========================================="
echo "Fetching Secrets from Vault"
echo "========================================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
  echo "❌ ERROR: .env file not found"
  exit 1
fi

# Load Vault configuration from .env
source .env

# Set Vault address (default to localhost)
export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"

# Authenticate with Vault
if [ -n "$VAULT_ROOT_TOKEN" ]; then
  echo "🔐 Authenticating with root token (dev mode)..."
  export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
elif [ -n "$VAULT_ROLE_ID" ] && [ -n "$VAULT_SECRET_ID" ]; then
  echo "🔐 Authenticating with AppRole..."
  export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="$VAULT_ROLE_ID" \
    secret_id="$VAULT_SECRET_ID" 2>/dev/null)
  
  if [ -z "$VAULT_TOKEN" ]; then
    echo "❌ ERROR: AppRole authentication failed"
    exit 1
  fi
else
  echo "❌ ERROR: No Vault authentication method configured"
  echo "   Set either VAULT_ROOT_TOKEN or VAULT_ROLE_ID + VAULT_SECRET_ID in .env"
  exit 1
fi

# Check Vault connection
if ! vault status &>/dev/null; then
  echo "❌ ERROR: Cannot connect to Vault at $VAULT_ADDR"
  echo "   Check that Vault is running and accessible"
  exit 1
fi

echo "✅ Connected to Vault"
echo ""

# Fetch secrets
echo "📥 Fetching secrets..."

# Auth0 secrets
if vault kv get secret/inlock/production &>/dev/null; then
  echo "  → Fetching Auth0 secrets..."
  
  # Fetch all production secrets
  TEMP_FILE=$(mktemp)
  vault kv get -format=json secret/inlock/production > "$TEMP_FILE" 2>/dev/null
  
  # Update .env with non-secret values (client IDs)
  AUTH0_ADMIN_CLIENT_ID=$(jq -r '.data.data.AUTH0_ADMIN_CLIENT_ID // empty' "$TEMP_FILE")
  if [ -n "$AUTH0_ADMIN_CLIENT_ID" ]; then
    # Update .env file (preserve other lines)
    if grep -q "^AUTH0_ADMIN_CLIENT_ID=" .env; then
      sed -i "s|^AUTH0_ADMIN_CLIENT_ID=.*|AUTH0_ADMIN_CLIENT_ID=$AUTH0_ADMIN_CLIENT_ID|" .env
    else
      echo "AUTH0_ADMIN_CLIENT_ID=$AUTH0_ADMIN_CLIENT_ID" >> .env
    fi
  fi
  
  # Create Docker secret for client secret
  AUTH0_ADMIN_CLIENT_SECRET=$(jq -r '.data.data.AUTH0_ADMIN_CLIENT_SECRET // empty' "$TEMP_FILE")
  if [ -n "$AUTH0_ADMIN_CLIENT_SECRET" ]; then
    echo "$AUTH0_ADMIN_CLIENT_SECRET" | \
      docker secret create auth0-admin-secret - 2>/dev/null || \
      (docker secret rm auth0-admin-secret 2>/dev/null && \
       echo "$AUTH0_ADMIN_CLIENT_SECRET" | docker secret create auth0-admin-secret -)
    echo "  ✅ Created Docker secret: auth0-admin-secret"
  fi
  
  # OAuth2 cookie secret
  OAUTH2_COOKIE_SECRET=$(jq -r '.data.data.OAUTH2_COOKIE_SECRET // empty' "$TEMP_FILE")
  if [ -n "$OAUTH2_COOKIE_SECRET" ]; then
    if grep -q "^OAUTH2_COOKIE_SECRET=" .env; then
      sed -i "s|^OAUTH2_COOKIE_SECRET=.*|OAUTH2_COOKIE_SECRET=$OAUTH2_COOKIE_SECRET|" .env
    else
      echo "OAUTH2_COOKIE_SECRET=$OAUTH2_COOKIE_SECRET" >> .env
    fi
  fi
  
  rm -f "$TEMP_FILE"
else
  echo "  ⚠️  Secret path 'secret/inlock/production' not found"
fi

# SSL certificates
if vault kv get secret/inlock/ssl &>/dev/null; then
  echo "  → Fetching SSL certificates..."
  
  # Fetch SSL cert
  CERT=$(vault kv get -format=json secret/inlock/ssl | jq -r '.data.data.POSITIVE_SSL_CERT // empty')
  if [ -n "$CERT" ]; then
    echo "$CERT" | \
      docker secret create positive_ssl_cert - 2>/dev/null || \
      (docker secret rm positive_ssl_cert 2>/dev/null && \
       echo "$CERT" | docker secret create positive_ssl_cert -)
    echo "  ✅ Created Docker secret: positive_ssl_cert"
  fi
  
  # Fetch SSL key
  KEY=$(vault kv get -format=json secret/inlock/ssl | jq -r '.data.data.POSITIVE_SSL_KEY // empty')
  if [ -n "$KEY" ]; then
    echo "$KEY" | \
      docker secret create positive_ssl_key - 2>/dev/null || \
      (docker secret rm positive_ssl_key 2>/dev/null && \
       echo "$KEY" | docker secret create positive_ssl_key -)
    echo "  ✅ Created Docker secret: positive_ssl_key"
  fi
else
  echo "  ⚠️  Secret path 'secret/inlock/ssl' not found"
fi

# Database credentials
if vault kv get secret/inlock/database &>/dev/null; then
  echo "  → Fetching database credentials..."
  
  # Note: Database URL should be stored in application .env.production, not here
  # This script just validates that secrets exist
  echo "  ✅ Database secrets found (update application .env.production manually)"
else
  echo "  ⚠️  Secret path 'secret/inlock/database' not found"
fi

echo ""
echo "========================================="
echo "✅ Secrets fetched successfully"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Update /opt/inlock-ai-secure-mvp/.env.production with Auth0 web app credentials"
echo "2. Restart services: docker compose -f compose/stack.yml --env-file .env up -d"
echo ""

