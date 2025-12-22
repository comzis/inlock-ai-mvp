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
REQUIRED_MIDDLEWARES=("allowed-admins" "mgmt-ratelimit" "admin-forward-auth")

# Admin services (excluding dashboard which has additional auth)
ADMIN_SERVICES=("portainer" "n8n" "cockpit" "grafana" "coolify")

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
        if [ "$service" == "n8n" ] && [ "$middleware" == "mgmt-ratelimit" ]; then
            continue
        fi
        if ! grep -A 10 "^    $service:" "$ROUTERS_FILE" | grep -q "        - $middleware"; then
            echo "  ❌ Missing middleware: $middleware"
            ((ERRORS++))
        fi
    done

    # Check header-hardening middleware (n8n/cockpit use custom variants)
    HEADER_MIDDLEWARE="secure-headers"
    case "$service" in
        n8n)
            HEADER_MIDDLEWARE="n8n-headers"
            ;;
        cockpit)
            HEADER_MIDDLEWARE="cockpit-headers"
            ;;
    esac

    if ! grep -A 10 "^    $service:" "$ROUTERS_FILE" | grep -q "        - $HEADER_MIDDLEWARE"; then
        echo "  ❌ Missing middleware: $HEADER_MIDDLEWARE"
        ((ERRORS++))
    fi
    
    # Check for TLS
    if ! grep -A 10 "^    $service:" "$ROUTERS_FILE" | grep -q "tls:"; then
        echo "  ⚠️  No TLS configured (should use certResolver)"
    fi
    
    echo "  ✅ $service router configured correctly"
done

echo ""
echo "Checking dashboard router (has additional auth)..."
if grep -A 10 "^    dashboard:" "$ROUTERS_FILE" | grep -q "admin-forward-auth"; then
    echo "  ✅ Dashboard protected via admin-forward-auth"
else
    echo "  ❌ Dashboard missing admin-forward-auth"
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
