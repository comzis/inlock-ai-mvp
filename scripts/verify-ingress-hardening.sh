#!/bin/bash
# Verify all admin routers use consistent hardened middlewares

set -e

echo "=========================================="
echo "INGRESS HARDENING VERIFICATION"
echo "=========================================="
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTERS_FILE="$REPO_DIR/traefik/dynamic/routers.yml"

# Required middlewares for admin services
REQUIRED_MIDDLEWARES=("secure-headers" "allowed-admins" "mgmt-ratelimit")

# Admin services (excluding dashboard which has additional auth)
ADMIN_SERVICES=("portainer" "n8n" "cockpit" "grafana")

echo "Checking admin router middleware consistency..."
echo ""

ERRORS=0

for service in "${ADMIN_SERVICES[@]}"; do
    echo "Checking $service router..."
    
    # Check if router exists
    if ! grep -q "^    $service:" "$ROUTERS_FILE"; then
        echo "  ❌ Router not found: $service"
        ((ERRORS++))
        continue
    fi
    
    # Check for required middlewares
    for middleware in "${REQUIRED_MIDDLEWARES[@]}"; do
        if ! grep -A 10 "^    $service:" "$ROUTERS_FILE" | grep -q "        - $middleware"; then
            echo "  ❌ Missing middleware: $middleware"
            ((ERRORS++))
        fi
    done
    
    # Check for TLS
    if ! grep -A 10 "^    $service:" "$ROUTERS_FILE" | grep -q "tls:"; then
        echo "  ⚠️  No TLS configured (should use certResolver)"
    fi
    
    echo "  ✅ $service router configured correctly"
done

echo ""
echo "Checking dashboard router (has additional auth)..."
if grep -A 10 "^    dashboard:" "$ROUTERS_FILE" | grep -q "dashboard-auth"; then
    echo "  ✅ Dashboard has authentication"
else
    echo "  ❌ Dashboard missing authentication"
    ((ERRORS++))
fi

echo ""
echo "Checking IP allowlist configuration..."
if grep -q "allowed-admins:" "$REPO_DIR/traefik/dynamic/middlewares.yml"; then
    IP_COUNT=$(grep -A 15 "allowed-admins:" "$REPO_DIR/traefik/dynamic/middlewares.yml" | grep -c "sourceRange:" || echo "0")
    if [ "$IP_COUNT" -gt 0 ]; then
        echo "  ✅ IP allowlist configured"
        echo "  IPs in allowlist:"
        grep -A 15 "allowed-admins:" "$REPO_DIR/traefik/dynamic/middlewares.yml" | grep "          -" | sed 's/          -/    /'
    else
        echo "  ⚠️  IP allowlist empty"
    fi
else
    echo "  ❌ IP allowlist middleware not found"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "=========================================="
    echo "✅ ALL CHECKS PASSED"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "❌ FOUND $ERRORS ISSUE(S)"
    echo "=========================================="
    exit 1
fi
