#!/bin/bash
set -e

echo "=========================================="
echo "COMPREHENSIVE STACK TEST"
echo "=========================================="
echo ""

# Test 1: Compose validation
echo "TEST 1: Docker Compose Configuration"
echo "-----------------------------------"
ENV_FILE=".env"
[ ! -f "$ENV_FILE" ] && ENV_FILE="env.example"
if docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config > /dev/null 2>&1; then
  echo "✅ Compose config: VALID"
else
  echo "❌ Compose config: FAILED"
  docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" config 2>&1 | head -10
fi
echo ""

# Test 2: Service status
echo "TEST 2: Service Status"
echo "---------------------"
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file "$ENV_FILE" ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null | grep -E "(NAME|compose-)" || echo "⚠️  Services not running"
echo ""

# Test 3: Network connectivity
echo "TEST 3: Network Connectivity"
echo "---------------------------"
NETWORKS=("edge" "mgmt" "internal" "socket-proxy")
for net in "${NETWORKS[@]}"; do
  if docker network inspect "$net" > /dev/null 2>&1; then
    echo "✅ Network $net: EXISTS"
  else
    echo "❌ Network $net: MISSING"
  fi
done
echo ""

# Test 4: Allowlist configuration
echo "TEST 4: IP Allowlist Configuration"
echo "----------------------------------"
if grep -q "100.83.222.69/32\|100.96.110.8/32" traefik/dynamic/middlewares.yml; then
  echo "✅ Allowlist configured:"
  grep -A 3 "allowed-admins:" traefik/dynamic/middlewares.yml | grep -E "100\.|sourceRange"
else
  echo "❌ Allowlist not configured"
fi
echo ""

# Test 5: Traefik accessibility
echo "TEST 5: Traefik Service"
echo "----------------------"
if docker ps | grep -q "compose-traefik"; then
  TRAEFIK_STATUS=$(docker inspect compose-traefik-1 --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
  echo "Status: $TRAEFIK_STATUS"
  
  # Test HTTP response
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: traefik.inlock.ai" http://localhost 2>/dev/null || echo "000")
  echo "HTTP Response: $HTTP_CODE"
  
  # Check if Traefik is listening
  if netstat -tln 2>/dev/null | grep -q ":80\|:443" || ss -tln 2>/dev/null | grep -q ":80\|:443"; then
    echo "✅ Traefik ports (80/443): LISTENING"
  else
    echo "⚠️  Traefik ports: NOT LISTENING"
  fi
else
  echo "❌ Traefik container not running"
fi
echo ""

# Test 6: Service health
echo "TEST 6: Service Health Checks"
echo "---------------------------"
SERVICES=("traefik" "postgres" "n8n" "homepage" "portainer" "docker-socket-proxy" "cadvisor")
for svc in "${SERVICES[@]}"; do
  CONTAINER="compose-${svc}-1"
  if docker ps --format "{{.Names}}" | grep -q "$CONTAINER"; then
    STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null || echo "unknown")
    HEALTH=$(docker inspect "$CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
    if [ "$STATUS" = "running" ]; then
      echo "✅ $svc: $STATUS ($HEALTH)"
    else
      echo "⚠️  $svc: $STATUS"
    fi
  else
    echo "❌ $svc: NOT RUNNING"
  fi
done
echo ""

# Test 7: Secrets
echo "TEST 7: Secrets Configuration"
echo "---------------------------"
SECRETS_DIR="/home/comzis/apps/secrets"
SECRETS=("positive-ssl.crt" "positive-ssl.key" "traefik-dashboard-users.htpasswd" "portainer-admin-password" "n8n-db-password" "n8n-encryption-key")
if [ -d "$SECRETS_DIR" ]; then
  for secret in "${SECRETS[@]}"; do
    if [ -f "$SECRETS_DIR/$secret" ]; then
      if [ -s "$SECRETS_DIR/$secret" ]; then
        echo "✅ $secret: EXISTS (has content)"
      else
        echo "⚠️  $secret: EXISTS (empty - needs value)"
      fi
    else
      echo "❌ $secret: MISSING"
    fi
  done
else
  echo "❌ Secrets directory not found: $SECRETS_DIR"
fi
echo ""

# Test 8: Firewall
echo "TEST 8: Firewall Status"
echo "---------------------"
if command -v ufw &> /dev/null; then
  UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1 || echo "not enabled")
  echo "UFW: $UFW_STATUS"
  if echo "$UFW_STATUS" | grep -q "active\|enabled"; then
    echo "✅ Firewall: ACTIVE"
  else
    echo "⚠️  Firewall: NOT ACTIVE (run: sudo ./scripts/apply-firewall-manual.sh)"
  fi
else
  echo "⚠️  UFW not installed"
fi
echo ""

# Test 9: Traefik config validation
echo "TEST 9: Traefik Configuration Files"
echo "----------------------------------"
if [ -f "traefik/traefik.yml" ]; then
  echo "✅ Static config: EXISTS"
else
  echo "❌ Static config: MISSING"
fi

if [ -d "traefik/dynamic" ]; then
  DYNAMIC_FILES=("middlewares.yml" "routers.yml" "services.yml" "tls.yml")
  for file in "${DYNAMIC_FILES[@]}"; do
    if [ -f "traefik/dynamic/$file" ]; then
      echo "✅ Dynamic $file: EXISTS"
    else
      echo "⚠️  Dynamic $file: MISSING"
    fi
  done
else
  echo "❌ Dynamic config directory: MISSING"
fi
echo ""

# Test 10: Portainer data directory
echo "TEST 10: Portainer Data Directory"
echo "-------------------------------"
PORTAINER_DATA="/home/comzis/apps/traefik/portainer_data"
if [ -d "$PORTAINER_DATA" ]; then
  PERMS=$(stat -c "%a %U:%G" "$PORTAINER_DATA" 2>/dev/null || echo "unknown")
  echo "Directory: $PORTAINER_DATA"
  echo "Permissions: $PERMS"
  if [ -w "$PORTAINER_DATA" ]; then
    echo "✅ Directory: WRITABLE"
  else
    echo "⚠️  Directory: NOT WRITABLE (may need: sudo chown -R 1000:1000 $PORTAINER_DATA)"
  fi
else
  echo "⚠️  Directory: NOT FOUND"
fi

echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
