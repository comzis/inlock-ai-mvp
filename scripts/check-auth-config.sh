#!/bin/bash
# Verify Auth0 configuration is correct
# Usage: ./scripts/check-auth-config.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "========================================="
echo "Auth0 Configuration Check"
echo "========================================="
echo ""

# Check .env file
if [ ! -f ".env" ]; then
  echo "❌ .env file not found"
  exit 1
fi

echo "📋 Environment Variables:"
echo ""

# Check OAuth2-Proxy variables
echo "OAuth2-Proxy (Admin Auth):"
AUTH0_ISSUER=$(grep "^AUTH0_ISSUER=" .env | cut -d'=' -f2 || echo "")
AUTH0_ADMIN_CLIENT_ID=$(grep "^AUTH0_ADMIN_CLIENT_ID=" .env | cut -d'=' -f2 || echo "")
OAUTH2_COOKIE_SECRET=$(grep "^OAUTH2_COOKIE_SECRET=" .env | cut -d'=' -f2 || echo "")

if [ -n "$AUTH0_ISSUER" ]; then
  echo "  ✅ AUTH0_ISSUER: ${AUTH0_ISSUER:0:30}..."
else
  echo "  ❌ AUTH0_ISSUER: Missing"
fi

if [ -n "$AUTH0_ADMIN_CLIENT_ID" ]; then
  echo "  ✅ AUTH0_ADMIN_CLIENT_ID: ${AUTH0_ADMIN_CLIENT_ID:0:20}..."
else
  echo "  ❌ AUTH0_ADMIN_CLIENT_ID: Missing"
fi

if [ -n "$OAUTH2_COOKIE_SECRET" ]; then
  COOKIE_LEN=${#OAUTH2_COOKIE_SECRET}
  if [ "$COOKIE_LEN" -eq 32 ] || [ "$COOKIE_LEN" -eq 64 ]; then
    echo "  ✅ OAUTH2_COOKIE_SECRET: Set (${COOKIE_LEN} chars)"
  else
    echo "  ⚠️  OAUTH2_COOKIE_SECRET: Length ${COOKIE_LEN} (should be 32 or 64)"
  fi
else
  echo "  ❌ OAUTH2_COOKIE_SECRET: Missing"
fi

echo ""

# Check application .env.production
echo "NextAuth.js (Frontend Auth):"
if [ -f "/opt/inlock-ai-secure-mvp/.env.production" ]; then
  AUTH0_WEB_CLIENT_ID=$(grep "^AUTH0_WEB_CLIENT_ID=" /opt/inlock-ai-secure-mvp/.env.production | cut -d'=' -f2 || echo "")
  AUTH0_WEB_SECRET=$(grep "^AUTH0_WEB_CLIENT_SECRET=" /opt/inlock-ai-secure-mvp/.env.production | cut -d'=' -f2 || echo "")
  NEXTAUTH_SECRET=$(grep "^NEXTAUTH_SECRET=" /opt/inlock-ai-secure-mvp/.env.production | cut -d'=' -f2 || echo "")
  NEXTAUTH_URL=$(grep "^NEXTAUTH_URL=" /opt/inlock-ai-secure-mvp/.env.production | cut -d'=' -f2 || echo "")
  
  if [ -n "$AUTH0_WEB_CLIENT_ID" ]; then
    echo "  ✅ AUTH0_WEB_CLIENT_ID: ${AUTH0_WEB_CLIENT_ID:0:20}..."
  else
    echo "  ❌ AUTH0_WEB_CLIENT_ID: Missing"
  fi
  
  if [ -n "$AUTH0_WEB_SECRET" ]; then
    echo "  ✅ AUTH0_WEB_CLIENT_SECRET: Set"
  else
    echo "  ❌ AUTH0_WEB_CLIENT_SECRET: Missing"
  fi
  
  if [ -n "$NEXTAUTH_SECRET" ]; then
    echo "  ✅ NEXTAUTH_SECRET: Set"
  else
    echo "  ❌ NEXTAUTH_SECRET: Missing"
  fi
  
  if [ -n "$NEXTAUTH_URL" ]; then
    echo "  ✅ NEXTAUTH_URL: $NEXTAUTH_URL"
  else
    echo "  ❌ NEXTAUTH_URL: Missing"
  fi
else
  echo "  ⚠️  .env.production not found at /opt/inlock-ai-secure-mvp/.env.production"
fi

echo ""

# Check services
echo "📦 Service Status:"
docker compose -f compose/stack.yml --env-file .env ps oauth2-proxy inlock-ai traefik --format "  {{.Name}}: {{.Status}}" 2>&1 | tail -3

echo ""

# Check callback URLs
echo "🔗 Callback URLs (verify in Auth0 Dashboard):"
echo "  inlock-admin: https://auth.inlock.ai/oauth2/callback"
echo "  inlock-web: https://inlock.ai/api/auth/callback/auth0"
echo ""

# Check OAuth2-Proxy redirect URL
OAUTH2_REDIRECT=$(grep "OAUTH2_PROXY_REDIRECT_URL" compose/stack.yml | head -1 | sed 's/.*=//' | tr -d '"' | tr -d "'")
echo "📋 OAuth2-Proxy Redirect URL (from compose):"
echo "  $OAUTH2_REDIRECT"
echo ""

echo "========================================="
echo "✅ Configuration check complete"
echo "========================================="

