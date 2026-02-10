#!/bin/bash
# Service Configuration Health Check Script
# Verifies critical service configurations are correct

set -e

DOMAIN="inlock.ai"
PROJECT_DIR="/home/comzis/projects/inlock-ai-mvp"

echo "========================================="
echo "Service Configuration Health Check"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/compose/services/coolify.yml" ]; then
    echo "❌ Error: Cannot find project directory"
    echo "   Expected: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "=== Coolify Configuration Check ==="
echo ""

# Check Coolify environment variables
if docker compose -f compose/services/coolify.yml ps coolify | grep -q "Up"; then
    echo "✅ Coolify container is running"
    
    APP_URL=$(docker compose -f compose/services/coolify.yml exec -T coolify env | grep "^APP_URL=" | cut -d'=' -f2-)
    if [ "$APP_URL" = "https://deploy.inlock.ai" ]; then
        echo "✅ APP_URL is correct: $APP_URL"
    else
        echo "❌ APP_URL is incorrect: $APP_URL (expected: https://deploy.inlock.ai)"
    fi
    
    DB_PASSWORD=$(docker compose -f compose/services/coolify.yml exec -T coolify env | grep "^DB_PASSWORD=" | cut -d'=' -f2-)
    if [ -n "$DB_PASSWORD" ]; then
        echo "✅ DB_PASSWORD is set"
    else
        echo "❌ DB_PASSWORD is not set"
    fi
    
    TRUSTED_PROXIES=$(docker compose -f compose/services/coolify.yml exec -T coolify env | grep "^TRUSTED_PROXIES=" | cut -d'=' -f2-)
    if [ "$TRUSTED_PROXIES" = "*" ]; then
        echo "✅ TRUSTED_PROXIES is correct: $TRUSTED_PROXIES"
    else
        echo "❌ TRUSTED_PROXIES is incorrect: $TRUSTED_PROXIES (expected: *)"
    fi
    
    # Test database connection
    if docker compose -f compose/services/coolify.yml exec -T coolify sh -c 'php artisan migrate:status' 2>&1 | head -1 | grep -q "Migration"; then
        echo "✅ Database connection working"
    else
        echo "❌ Database connection failed"
    fi
else
    echo "❌ Coolify container is not running"
fi

echo ""
echo "=== Grafana Configuration Check ==="
echo ""

# Check Grafana environment variables
if docker compose -f compose/services/stack.yml ps grafana | grep -q "Up"; then
    echo "✅ Grafana container is running"
    
    GF_DOMAIN=$(docker compose -f compose/services/stack.yml exec -T grafana env | grep "^GF_SERVER_DOMAIN=" | cut -d'=' -f2-)
    if [ "$GF_DOMAIN" = "grafana.inlock.ai" ]; then
        echo "✅ GF_SERVER_DOMAIN is correct: $GF_DOMAIN"
    elif [ -z "$GF_DOMAIN" ] || [ "$GF_DOMAIN" = "grafana." ]; then
        echo "❌ GF_SERVER_DOMAIN is empty or incorrect: '$GF_DOMAIN' (expected: grafana.inlock.ai)"
    else
        echo "⚠️  GF_SERVER_DOMAIN is: $GF_DOMAIN (expected: grafana.inlock.ai)"
    fi
    
    GF_ROOT_URL=$(docker compose -f compose/services/stack.yml exec -T grafana env | grep "^GF_SERVER_ROOT_URL=" | cut -d'=' -f2-)
    if [ "$GF_ROOT_URL" = "https://grafana.inlock.ai" ]; then
        echo "✅ GF_SERVER_ROOT_URL is correct: $GF_ROOT_URL"
    elif [ -z "$GF_ROOT_URL" ] || [ "$GF_ROOT_URL" = "https://grafana." ]; then
        echo "❌ GF_SERVER_ROOT_URL is empty or incorrect: '$GF_ROOT_URL' (expected: https://grafana.inlock.ai)"
    else
        echo "⚠️  GF_SERVER_ROOT_URL is: $GF_ROOT_URL (expected: https://grafana.inlock.ai)"
    fi
else
    echo "❌ Grafana container is not running"
fi

echo ""
echo "=== Database Password Synchronization Check ==="
echo ""

# Check PostgreSQL password
POSTGRES_PW=$(docker compose -f compose/services/coolify.yml exec -T coolify-postgres env 2>/dev/null | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2- || echo "")
APP_PW=$(docker compose -f compose/services/coolify.yml exec -T coolify env 2>/dev/null | grep "^DB_PASSWORD=" | cut -d'=' -f2- || echo "")

if [ -n "$POSTGRES_PW" ] && [ -n "$APP_PW" ]; then
    if [ "$POSTGRES_PW" = "$APP_PW" ]; then
        echo "✅ Database passwords match"
    else
        echo "⚠️  Database passwords differ (may be intentional if using defaults)"
    fi
else
    echo "⚠️  Could not verify password synchronization"
fi

# Test database connection
if docker compose -f compose/services/coolify.yml exec -T coolify-postgres psql -U coolify -d coolify -c "SELECT 1;" 2>&1 | grep -q "1 row"; then
    echo "✅ PostgreSQL connection working"
else
    echo "❌ PostgreSQL connection failed"
fi

echo ""
echo "=== Service Accessibility Check ==="
echo ""

# Check Coolify
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://deploy.inlock.ai" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "000" ]; then
    echo "❌ deploy.inlock.ai: Cannot connect"
elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "✅ deploy.inlock.ai: Accessible (HTTP $HTTP_CODE)"
else
    echo "⚠️  deploy.inlock.ai: Returns HTTP $HTTP_CODE"
fi

# Check Grafana
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://grafana.inlock.ai" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "000" ]; then
    echo "❌ grafana.inlock.ai: Cannot connect"
elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "✅ grafana.inlock.ai: Accessible (HTTP $HTTP_CODE)"
else
    echo "⚠️  grafana.inlock.ai: Returns HTTP $HTTP_CODE"
fi

echo ""
echo "=== Configuration File Check ==="
echo ""

# Check Coolify config has required values
if grep -q "DB_PASSWORD=\${POSTGRES_PASSWORD:-ee7a8e171c075626d63b3cb7292b0cba9e4e71b83c9a3fff}" compose/services/coolify.yml; then
    echo "✅ Coolify: DB_PASSWORD has default fallback"
else
    echo "❌ Coolify: DB_PASSWORD missing default fallback"
fi

if grep -q "APP_URL=https://deploy.inlock.ai" compose/services/coolify.yml; then
    echo "✅ Coolify: APP_URL is correct"
else
    echo "❌ Coolify: APP_URL is incorrect"
fi

if grep -q "TRUSTED_PROXIES=\*" compose/services/coolify.yml; then
    echo "✅ Coolify: TRUSTED_PROXIES is set"
else
    echo "❌ Coolify: TRUSTED_PROXIES is missing"
fi

# Check Grafana config has hardcoded domains
if grep -q "GF_SERVER_DOMAIN=grafana.inlock.ai" compose/services/stack.yml; then
    echo "✅ Grafana: GF_SERVER_DOMAIN is hardcoded correctly"
elif grep -q "GF_SERVER_DOMAIN=grafana.\${DOMAIN}" compose/services/stack.yml; then
    echo "❌ Grafana: GF_SERVER_DOMAIN uses \${DOMAIN} variable (should be hardcoded)"
else
    echo "⚠️  Grafana: GF_SERVER_DOMAIN configuration not found"
fi

if grep -q "GF_SERVER_ROOT_URL=https://grafana.inlock.ai" compose/services/stack.yml; then
    echo "✅ Grafana: GF_SERVER_ROOT_URL is hardcoded correctly"
elif grep -q "GF_SERVER_ROOT_URL=https://grafana.\${DOMAIN}" compose/services/stack.yml; then
    echo "❌ Grafana: GF_SERVER_ROOT_URL uses \${DOMAIN} variable (should be hardcoded)"
else
    echo "⚠️  Grafana: GF_SERVER_ROOT_URL configuration not found"
fi

echo ""
echo "========================================="
echo "Health Check Complete"
echo "========================================="
