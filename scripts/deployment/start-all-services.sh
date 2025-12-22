#!/bin/bash
# Start all required Docker services
# Run: ./scripts/start-all-services.sh

set -euo pipefail

cd /home/comzis/inlock-infra

echo "=== Starting All Docker Services ==="
echo ""

# 1. Check current status
echo "1. Checking current container status..."
STOPPED=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | grep -E "compose-|inlock-" || true)
if [ -n "$STOPPED" ]; then
    echo "   Found stopped containers:"
    echo "$STOPPED" | sed 's/^/     - /'
else
    echo "   ✓ No stopped containers found"
fi
echo ""

# 2. Start main stack
echo "2. Starting main stack (stack.yml)..."
docker compose -f compose/stack.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
echo "   ✓ Main stack started"
echo ""

# 3. Start n8n
echo "3. Starting n8n..."
if docker compose -f compose/n8n.yml --env-file .env ps n8n 2>&1 | grep -q "Stopped\|Exited"; then
    docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
    echo "   ✓ n8n started"
else
    echo "   ✓ n8n already running"
fi
echo ""

# 4. Start other services
echo "4. Starting other services..."

# Check and start Coolify
if [ -f compose/coolify.yml ]; then
    if docker compose -f compose/coolify.yml --env-file .env ps 2>&1 | grep -q "Stopped\|Exited"; then
        docker compose -f compose/coolify.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
        echo "   ✓ Coolify started"
    else
        echo "   ✓ Coolify already running"
    fi
fi

# Check and start Homarr
if [ -f compose/homarr.yml ]; then
    if docker compose -f compose/homarr.yml --env-file .env ps 2>&1 | grep -q "Stopped\|Exited"; then
        docker compose -f compose/homarr.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
        echo "   ✓ Homarr started"
    else
        echo "   ✓ Homarr already running"
    fi
fi

# Check and start OAuth2 Proxy
if [ -f compose/oauth2-proxy.yml ]; then
    if docker compose -f compose/oauth2-proxy.yml --env-file .env ps 2>&1 | grep -q "Stopped\|Exited"; then
        docker compose -f compose/oauth2-proxy.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
        echo "   ✓ OAuth2 Proxy started"
    else
        echo "   ✓ OAuth2 Proxy already running"
    fi
fi

# Check and start Vault
if [ -f compose/vault.yml ]; then
    if docker compose -f compose/vault.yml --env-file .env ps 2>&1 | grep -q "Stopped\|Exited"; then
        docker compose -f compose/vault.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
        echo "   ✓ Vault started"
    else
        echo "   ✓ Vault already running"
    fi
fi

# Check and start Postgres (if separate)
if [ -f compose/postgres.yml ]; then
    if docker compose -f compose/postgres.yml --env-file .env ps 2>&1 | grep -q "Stopped\|Exited"; then
        docker compose -f compose/postgres.yml --env-file .env up -d 2>&1 | grep -E "(Creating|Starting|Started|Up)" || true
        echo "   ✓ Postgres started"
    else
        echo "   ✓ Postgres already running"
    fi
fi

echo ""

# 5. Wait for services to initialize
echo "5. Waiting for services to initialize..."
sleep 10
echo "   ✓ Wait complete"
echo ""

# 6. Check final status
echo "6. Final status check..."
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | head -20
echo ""

STILL_STOPPED=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | grep -E "compose-|inlock-" || true)
if [ -n "$STILL_STOPPED" ]; then
    echo "⚠️  Still stopped (may be intentional):"
    echo "$STILL_STOPPED" | sed 's/^/     - /'
    echo ""
fi

# 7. Health check
echo "7. Health check..."
HEALTHY=$(docker ps --filter "health=healthy" --format "{{.Names}}" | wc -l)
TOTAL=$(docker ps --format "{{.Names}}" | wc -l)
echo "   Healthy: $HEALTHY / $TOTAL containers"
echo ""

echo "=== Summary ==="
echo ""
echo "All required services have been started."
echo ""
echo "To check individual service status:"
echo "  docker compose -f compose/<service>.yml --env-file .env ps"
echo ""
echo "To view logs:"
echo "  docker compose -f compose/<service>.yml --env-file .env logs -f"
echo ""

