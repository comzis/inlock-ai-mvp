# Auth0 Command Reference

**Quick reference for common Auth0/OAuth2-Proxy commands**

---

## Service Management

### Start/Stop/Restart

```bash
# Restart OAuth2-Proxy
docker compose -f compose/stack.yml --env-file .env restart oauth2-proxy

# Stop
docker compose -f compose/stack.yml --env-file .env stop oauth2-proxy

# Start
docker compose -f compose/stack.yml --env-file .env start oauth2-proxy

# Recreate (applies config changes)
docker compose -f compose/stack.yml --env-file .env up -d --force-recreate oauth2-proxy
```

### Status Check

```bash
# Service status
docker compose -f compose/stack.yml ps oauth2-proxy

# Health check
curl -I http://oauth2-proxy:4180/ping

# Container details
docker inspect compose-oauth2-proxy-1
```

---

## Logs

### View Logs

```bash
# Last 50 lines
docker compose -f compose/stack.yml logs --tail 50 oauth2-proxy

# Follow logs
docker compose -f compose/stack.yml logs -f oauth2-proxy

# Last 100 lines, filter errors
docker compose -f compose/stack.yml logs --tail 100 oauth2-proxy | grep -i error

# Last 100 lines, filter auth
docker compose -f compose/stack.yml logs --tail 100 oauth2-proxy | grep -i auth
```

### Search Logs

```bash
# Find CSRF errors
docker compose -f compose/stack.yml logs oauth2-proxy | grep -i csrf

# Find authentication failures
docker compose -f compose/stack.yml logs oauth2-proxy | grep -E "401|403"

# Find PKCE warnings
docker compose -f compose/stack.yml logs oauth2-proxy | grep -i pkce

# Find rate limits
docker compose -f compose/stack.yml logs oauth2-proxy | grep -i "rate.*limit"
```

---

## Configuration Verification

### Check Command Arguments

```bash
# All arguments
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}'

# PKCE
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}' | grep code-challenge

# Cookie settings
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}' | grep -E "cookie|samesite"

# Whitelist domains
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}' | grep whitelist
```

### Check Environment Variables

```bash
# All Auth0/OAuth2 vars
docker exec compose-oauth2-proxy-1 env | grep -E "AUTH0|OAUTH2"

# Specific variable
docker exec compose-oauth2-proxy-1 env | grep AUTH0_ISSUER

# Cookie secret (first 10 chars)
docker exec compose-oauth2-proxy-1 env | grep COOKIE_SECRET | cut -c1-20
```

### Check Configuration Files

```bash
# OAuth2-Proxy service config
grep -A 60 "oauth2-proxy:" compose/stack.yml

# Traefik forward-auth middleware
grep -A 20 "admin-forward-auth:" traefik/dynamic/middlewares.yml

# Prometheus scraping
grep -A 8 "oauth2-proxy" compose/prometheus/prometheus.yml
```

---

## Testing

### Scripts

```bash
# Full diagnostic
./scripts/diagnose-auth0-issue.sh

# Config check
./scripts/check-auth-config.sh

# API test (requires M2M credentials)
./scripts/test-auth0-api-examples.sh

# Quick API test
./scripts/test-auth0-api.sh

# Monitor status
./scripts/monitor-auth0-status.sh

# Auth flow debug
./scripts/debug-auth-flow.sh
```

### Manual Tests

```bash
# Test callback endpoint (should return 403 without OAuth params)
curl -I https://auth.inlock.ai/oauth2/callback

# Test health endpoint
curl http://oauth2-proxy:4180/ping

# Test metrics endpoint
curl http://oauth2-proxy:44180/metrics | head -20
```

---

## Metrics & Monitoring

### Prometheus Queries

```bash
# Service up/down
curl -s 'http://localhost:9090/api/v1/query?query=up{job="oauth2-proxy"}' | jq

# Request rate
curl -s 'http://localhost:9090/api/v1/query?query=rate(oauth2_proxy_http_request_total{job="oauth2-proxy"}[5m])' | jq

# Error rate
curl -s 'http://localhost:9090/api/v1/query?query=rate(oauth2_proxy_http_request_total{job="oauth2-proxy",code=~"4..|5.."}[5m])' | jq

# Auth success rate
curl -s 'http://localhost:9090/api/v1/query?query=rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code="200"}[5m])' | jq

# Auth failure rate
curl -s 'http://localhost:9090/api/v1/query?query=rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code=~"401|403"}[5m])' | jq
```

### Direct Metrics

```bash
# All metrics
curl -s http://oauth2-proxy:44180/metrics

# Filter specific metric
curl -s http://oauth2-proxy:44180/metrics | grep oauth2_proxy_http_request_total

# Count metrics
curl -s http://oauth2-proxy:44180/metrics | wc -l
```

### Alert Check

```bash
# All alerts
curl -s http://localhost:9093/api/v2/alerts | jq

# OAuth2-Proxy alerts
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | select(.labels.service=="oauth2-proxy")'

# Prometheus rules
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name=="inlock-ai") | .rules[] | select(.name | startswith("OAuth2"))'
```

---

## Management API (if configured)

### Get Token

```bash
source .env

TOKEN_RESPONSE=$(curl -s -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"https://${AUTH0_DOMAIN}/api/v2/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
echo "$ACCESS_TOKEN"
```

### Get Application

```bash
curl -s -X GET "https://${AUTH0_DOMAIN}/api/v2/applications/${AUTH0_ADMIN_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq '.'
```

### Check Callback URLs

```bash
APP_RESPONSE=$(curl -s -X GET "https://${AUTH0_DOMAIN}/api/v2/applications/${AUTH0_ADMIN_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "$APP_RESPONSE" | jq '.callbacks'
echo "$APP_RESPONSE" | jq '.allowed_logout_urls'
echo "$APP_RESPONSE" | jq '.allowed_origins'
```

---

## Troubleshooting

### Common Issues

```bash
# Service won't start
docker compose -f compose/stack.yml logs oauth2-proxy | tail -50

# Check environment file
cat .env | grep -E "AUTH0|OAUTH2"

# Check network connectivity
docker exec compose-oauth2-proxy-1 ping -c 3 comzis.eu.auth0.com

# Check DNS resolution
docker exec compose-oauth2-proxy-1 nslookup comzis.eu.auth0.com
```

### Reset Service

```bash
# Stop and remove
docker compose -f compose/stack.yml stop oauth2-proxy
docker compose -f compose/stack.yml rm -f oauth2-proxy

# Recreate
docker compose -f compose/stack.yml --env-file .env up -d oauth2-proxy

# Verify
docker compose -f compose/stack.yml ps oauth2-proxy
```

---

## Network Debugging

```bash
# Check container network
docker network inspect compose_mgmt_default | jq '.[0].Containers[] | select(.Name | contains("oauth2-proxy"))'

# Test internal connectivity
docker exec compose-oauth2-proxy-1 wget -qO- http://localhost:4180/ping

# Test external connectivity (Auth0)
docker exec compose-oauth2-proxy-1 wget -qO- https://comzis.eu.auth0.com/.well-known/openid-configuration
```

---

**Last Updated:** 2025-12-13

