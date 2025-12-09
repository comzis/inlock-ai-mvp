#!/usr/bin/env bash
set -uo pipefail

# Comprehensive stack test script
# Tests all components: config, services, networks, access control, secrets

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ENV_FILE=".env"
[ ! -f "$ENV_FILE" ] && ENV_FILE="env.example"

echo "=========================================="
echo "INLOCK.AI Stack Test Suite"
echo "=========================================="
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# Function to safely increment counters
inc_pass() { PASSED=$((PASSED + 1)); }
inc_fail() { FAILED=$((FAILED + 1)); }
inc_warn() { WARNINGS=$((WARNINGS + 1)); }

# Test 1: Compose validation
echo "TEST 1: Docker Compose Configuration"
echo "-----------------------------------"
if docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config > /dev/null 2>&1; then
  echo "✅ PASS: Compose config is valid"
  inc_pass
else
  echo "❌ FAIL: Compose config validation failed"
  inc_fail
fi
echo ""

# Test 2: Networks
echo "TEST 2: Docker Networks"
echo "---------------------"
NETWORKS=("edge" "mgmt" "internal" "socket-proxy")
for net in "${NETWORKS[@]}"; do
  if docker network inspect "$net" > /dev/null 2>&1; then
    echo "  ✅ $net: EXISTS"
    inc_pass
  else
    echo "  ❌ $net: MISSING"
    inc_fail
  fi
done
echo ""

# Test 3: Allowlist
echo "TEST 3: IP Allowlist Configuration"
echo "----------------------------------"
if grep -q "100.83.222.69/32\|100.96.110.8/32" traefik/dynamic/middlewares.yml; then
  echo "✅ PASS: Allowlist configured"
  grep -A 3 "allowed-admins:" traefik/dynamic/middlewares.yml | grep "100\." | sed 's/^/  /'
  inc_pass
else
  echo "❌ FAIL: Allowlist not configured"
  inc_fail
fi
echo ""

# Test 4: Services
echo "TEST 4: Service Status"
echo "---------------------"
SERVICES=("traefik" "postgres" "n8n" "homepage" "portainer" "docker-socket-proxy" "cadvisor")
for svc in "${SERVICES[@]}"; do
  CONTAINER="compose-${svc}-1"
  if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
    STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
    HEALTH=$(docker inspect "$CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
    if [ "$STATUS" = "running" ]; then
      if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "no-healthcheck" ]; then
        echo "  ✅ $svc: $STATUS ($HEALTH)"
        inc_pass
      else
        echo "  ⚠️  $svc: $STATUS ($HEALTH)"
        inc_warn
      fi
    else
      echo "  ❌ $svc: $STATUS"
      inc_fail
    fi
  else
    echo "  ❌ $svc: NOT RUNNING"
    inc_fail
  fi
done
echo ""

# Test 5: Traefik connectivity
echo "TEST 5: Traefik Connectivity"
echo "---------------------------"
if docker ps | grep -q "compose-traefik"; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: traefik.inlock.ai" http://localhost 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]; then
    echo "✅ PASS: Traefik responding (HTTP $HTTP_CODE)"
    inc_pass
  else
    echo "⚠️  WARN: Traefik returned HTTP $HTTP_CODE"
    inc_warn
  fi
  
  if netstat -tln 2>/dev/null | grep -q ":80\|:443" || ss -tln 2>/dev/null | grep -q ":80\|:443"; then
    echo "✅ PASS: Traefik ports listening"
    inc_pass
  else
    echo "❌ FAIL: Traefik ports not listening"
    inc_fail
  fi
else
  echo "❌ FAIL: Traefik container not running"
  inc_fail
fi
echo ""

# Test 6: Secrets
echo "TEST 6: Secrets Configuration"
echo "---------------------------"
SECRETS_DIR="/home/comzis/apps/secrets"
SECRETS=("positive-ssl.crt" "positive-ssl.key" "traefik-dashboard-users.htpasswd" "portainer-admin-password" "n8n-db-password" "n8n-encryption-key")
if [ -d "$SECRETS_DIR" ]; then
  for secret in "${SECRETS[@]}"; do
    if [ -f "$SECRETS_DIR/$secret" ]; then
      if [ -s "$SECRETS_DIR/$secret" ]; then
        echo "  ✅ $secret: EXISTS (has content)"
        inc_pass
      else
        echo "  ⚠️  $secret: EXISTS (empty)"
        inc_warn
      fi
    else
      echo "  ❌ $secret: MISSING"
      inc_fail
    fi
  done
else
  echo "❌ FAIL: Secrets directory not found"
  inc_fail
fi
echo ""

# Test 7: Firewall
echo "TEST 7: Firewall Status"
echo "---------------------"
if command -v ufw &> /dev/null; then
  UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1 || echo "not enabled")
  if echo "$UFW_STATUS" | grep -q "active\|enabled"; then
    echo "✅ PASS: Firewall active"
    inc_pass
  else
    echo "⚠️  WARN: Firewall not active (run: sudo ./scripts/apply-firewall-manual.sh)"
    inc_warn
  fi
else
  echo "⚠️  WARN: UFW not installed"
  inc_warn
fi
echo ""

# Test 8: Config files
echo "TEST 8: Configuration Files"
echo "-------------------------"
CONFIG_FILES=(
  "traefik/traefik.yml"
  "traefik/dynamic/middlewares.yml"
  "traefik/dynamic/routers.yml"
  "traefik/dynamic/services.yml"
  "traefik/dynamic/tls.yml"
)
for file in "${CONFIG_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file: EXISTS"
    inc_pass
  else
    echo "  ❌ $file: MISSING"
    inc_fail
  fi
done
echo ""

# Summary
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "✅ Passed: $PASSED"
echo "⚠️  Warnings: $WARNINGS"
echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
  if [ $WARNINGS -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
  else
    echo "✅ Core tests passed with warnings"
    exit 0
  fi
else
  echo "❌ Some tests failed - review output above"
  exit 1
fi

