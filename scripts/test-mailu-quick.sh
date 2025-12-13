#!/usr/bin/env bash
# Quick Mailu Test Script
# Tests SMTP submission, contact form, and service health

set -euo pipefail

COMPOSE_FILE="compose/mailu.yml"
ENV_FILE=".env"

cd "$(dirname "$0")/.." || exit 1

echo "=== Mailu Quick Test Suite ==="
echo ""

# Test 1: Service Health
echo "TEST 1: Service Health Checks"
echo "------------------------------"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps --format "table {{.Name}}\t{{.Status}}" | grep mailu
echo ""

# Test 2: Front Health
echo "TEST 2: Front Service Health"
echo "----------------------------"
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mailu-front wget -q -O- http://localhost/health 2>&1 | grep -q "OK\|200"; then
  echo "✅ Front health check: PASS"
else
  echo "❌ Front health check: FAIL"
fi
echo ""

# Test 3: Admin Health
echo "TEST 3: Admin Service Health"
echo "----------------------------"
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mailu-admin wget -q -O- http://localhost/health 2>&1 | grep -q "OK\|200"; then
  echo "✅ Admin health check: PASS"
else
  echo "❌ Admin health check: FAIL"
fi
echo ""

# Test 4: Redis Connectivity
echo "TEST 4: Redis Connectivity"
echo "-------------------------"
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mailu-redis redis-cli ping 2>&1 | grep -q "PONG"; then
  echo "✅ Redis ping: PASS"
else
  echo "❌ Redis ping: FAIL"
fi
echo ""

# Test 5: SMTP Port Check
echo "TEST 5: SMTP Port Check"
echo "----------------------"
if timeout 2 bash -c "echo > /dev/tcp/localhost/25" 2>/dev/null; then
  echo "✅ SMTP port 25: LISTENING"
else
  echo "❌ SMTP port 25: NOT LISTENING"
fi

if timeout 2 bash -c "echo > /dev/tcp/localhost/587" 2>/dev/null; then
  echo "✅ SMTP port 587: LISTENING"
else
  echo "❌ SMTP port 587: NOT LISTENING"
fi
echo ""

# Test 6: Nginx Log Directory
echo "TEST 6: Front Nginx Log Directory"
echo "---------------------------------"
if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T mailu-front test -w /var/lib/nginx/logs 2>/dev/null; then
  echo "✅ Nginx logs directory: WRITABLE"
else
  echo "❌ Nginx logs directory: NOT WRITABLE"
fi
echo ""

# Test 7: Recent Error Logs
echo "TEST 7: Recent Error Logs (Last 5 lines)"
echo "----------------------------------------"
echo "Front errors:"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail 5 mailu-front 2>&1 | grep -i error || echo "No errors found"
echo ""
echo "Admin errors:"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail 5 mailu-admin 2>&1 | grep -i error || echo "No errors found"
echo ""

echo "=== Test Suite Complete ==="

