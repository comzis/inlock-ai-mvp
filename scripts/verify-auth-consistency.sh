#!/bin/bash
# Verify Auth0 consistency across all admin services
# Ensures all admin services use admin-forward-auth middleware

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "========================================="
echo "Auth0 Stack Consistency Check"
echo "========================================="
echo ""

ROUTERS_FILE="traefik/dynamic/routers.yml"
ERRORS=0

# List of admin services that MUST have admin-forward-auth
ADMIN_SERVICES=(
    "dashboard"
    "portainer"
    "grafana"
    "n8n"
    "coolify"
    "homarr"
)

echo "Checking admin services for admin-forward-auth middleware..."
echo ""

for service in "${ADMIN_SERVICES[@]}"; do
    if grep -A 10 "^    ${service}:" "$ROUTERS_FILE" | grep -q "admin-forward-auth"; then
        echo "✅ ${service}: Has admin-forward-auth"
    else
        echo "❌ ${service}: MISSING admin-forward-auth"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Checking for deprecated auth middlewares..."
echo ""

# Check for deprecated middlewares
if grep -q "dashboard-auth:" "$ROUTERS_FILE" && ! grep -q "# dashboard-auth:" "$ROUTERS_FILE"; then
    echo "⚠️  dashboard-auth still in use (should use admin-forward-auth)"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "portainer-auth:" "$ROUTERS_FILE" && ! grep -q "# portainer-auth:" "$ROUTERS_FILE"; then
    echo "⚠️  portainer-auth still in use (should use admin-forward-auth)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking OAuth2-Proxy configuration..."
echo ""

if docker ps --format '{{.Names}}' | grep -q "oauth2-proxy"; then
    echo "✅ OAuth2-Proxy container is running"
else
    echo "❌ OAuth2-Proxy container is not running"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking NextAuth.js configuration..."
echo ""

if [ -f "/opt/inlock-ai-secure-mvp/app/api/auth/[...nextauth]/route.ts" ]; then
    echo "✅ NextAuth.js route exists"
    
    if grep -q "Auth0Provider" "/opt/inlock-ai-secure-mvp/app/api/auth/[...nextauth]/route.ts"; then
        echo "✅ NextAuth.js configured with Auth0"
    else
        echo "⚠️  NextAuth.js route exists but Auth0Provider not found"
    fi
else
    echo "⚠️  NextAuth.js route not found (may be expected if not deployed)"
fi

echo ""
echo "========================================="

if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! Auth0 stack is consistent."
    echo ""
    echo "All admin services use admin-forward-auth middleware."
    echo "Authentication flows through Auth0 for all services."
    exit 0
else
    echo "❌ Found $ERRORS issue(s) - please review above"
    echo ""
    echo "See docs/AUTH0-STACK-CONSISTENCY.md for guidance"
    exit 1
fi

