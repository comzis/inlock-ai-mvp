# Alerting Verification Guide - OAuth2-Proxy Alerts

**Date:** 2025-12-13  
**Purpose:** Verify OAuth2-Proxy alert rules are configured and working  
**Configuration:** `compose/prometheus/rules/inlock-ai.yml`

## Overview

Five OAuth2-Proxy alert rules have been added to Prometheus for monitoring authentication health. This guide explains how to verify the alerts are configured correctly and firing appropriately.

## Alert Rules Configured

### 1. OAuth2ProxyDown
- **Severity:** Critical
- **Trigger:** OAuth2-Proxy metrics endpoint down for > 1 minute
- **Impact:** Authentication completely unavailable

### 2. OAuth2ProxyHighErrorRate
- **Severity:** Warning
- **Trigger:** > 10% of requests return 4xx/5xx errors for 5 minutes
- **Impact:** High rate of authentication failures

### 3. OAuth2ProxyHighAuthFailureRate
- **Severity:** Warning
- **Trigger:** > 20% authentication requests fail (401/403) for 5 minutes
- **Impact:** Many users unable to authenticate

### 4. OAuth2ProxySlowResponseTime
- **Severity:** Warning
- **Trigger:** p95 response time > 2 seconds for 10 minutes
- **Impact:** Slow authentication, poor user experience

### 5. OAuth2ProxyNoAuthSuccess
- **Severity:** Critical
- **Trigger:** No successful authentications (200) in 10 minutes despite requests
- **Impact:** Complete authentication failure

## Verification Steps

### Step 1: Verify Prometheus Rules are Loaded

1. Access Prometheus: `http://localhost:9090` (internal)
2. Navigate to: **Alerts** tab
3. Search for: `OAuth2Proxy`
4. Verify all 5 alerts appear in the list

**Expected:** All 5 OAuth2-Proxy alerts visible with their current state (pending/firing)

### Step 2: Check Alert Expressions

For each alert, verify the expression is correct:

#### OAuth2ProxyDown
```promql
up{job="oauth2-proxy"} == 0
```

#### OAuth2ProxyHighErrorRate
```promql
sum(rate(oauth2_proxy_http_request_total{job="oauth2-proxy",code=~"4..|5.."}[5m])) 
/ 
sum(rate(oauth2_proxy_http_request_total{job="oauth2-proxy"}[5m])) 
> 0.1
```

#### OAuth2ProxyHighAuthFailureRate
```promql
sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code=~"401|403"}[5m]))
/
(sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy"}[5m])) + 1)
> 0.2
```

#### OAuth2ProxySlowResponseTime
```promql
histogram_quantile(0.95, sum(rate(oauth2_proxy_http_request_duration_seconds_bucket{job="oauth2-proxy"}[5m])) by (le)) 
> 2
```

#### OAuth2ProxyNoAuthSuccess
```promql
sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code="200"}[10m])) == 0
and
sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy"}[10m])) > 0
```

### Step 3: Verify Alertmanager Configuration

1. Check Alertmanager config: `compose/alertmanager/alertmanager.yml`
2. Verify routes send OAuth2-Proxy alerts to n8n webhook:
   - Route matches: `severity=~"warning|critical"`
   - Receiver: `n8n-webhook`
   - Webhook URL: `http://n8n:5678/webhook/alertmanager`

**Current Configuration:**
```yaml
routes:
  - matchers:
      - severity=~"warning|critical"
    receiver: n8n-webhook
```

All OAuth2-Proxy alerts have `severity: warning` or `severity: critical`, so they will route to n8n webhook.

### Step 4: Test Alert Firing (Optional)

To test alerts, you can temporarily cause conditions:

**⚠️ Warning:** Only test in non-production or with caution

#### Test OAuth2ProxyDown
```bash
# Stop OAuth2-Proxy temporarily
docker compose -f compose/stack.yml --env-file .env stop oauth2-proxy

# Wait 2 minutes, then check Prometheus Alerts tab
# Should see OAuth2ProxyDown in "firing" state

# Restart service
docker compose -f compose/stack.yml --env-file .env start oauth2-proxy
```

#### Test Alert Resolution
1. Cause alert to fire (using method above)
2. Wait for alert condition to clear
3. Verify alert returns to "pending" or disappears
4. Check Alertmanager shows "resolved" state

### Step 5: Verify Alertmanager Integration

1. Access Alertmanager: `http://localhost:9093` (internal)
2. Navigate to: **Alerts** tab
3. Verify OAuth2-Proxy alerts appear when firing
4. Check alert annotations and labels are correct

### Step 6: Verify Webhook Delivery (If n8n Configured)

1. Access n8n: `https://n8n.inlock.ai`
2. Check webhook endpoint: `/webhook/alertmanager`
3. Verify alerts are received when firing
4. Check alert payload structure

## Expected Behavior

### Normal Operation
- All alerts in **pending** state
- No alerts firing
- Alertmanager shows no active alerts

### During Issues
- Relevant alerts move to **firing** state
- Alertmanager receives and routes alerts
- Alerts sent to configured receiver (n8n webhook)
- Alert annotations contain useful information

## Troubleshooting

### Issue: Alerts Not Appearing in Prometheus

**Possible Causes:**
- Prometheus not loading rule file
- Rule file syntax error
- Prometheus not scraping OAuth2-Proxy

**Solution:**
1. Check Prometheus logs:
   ```bash
   docker compose -f compose/prometheus.yml --env-file .env logs prometheus --tail 50 | grep -i "error\|rule"
   ```

2. Verify rule file syntax:
   ```bash
   promtool check rules compose/prometheus/rules/inlock-ai.yml
   ```

3. Reload Prometheus configuration:
   ```bash
   docker compose -f compose/prometheus.yml --env-file .env restart prometheus
   ```

### Issue: Alerts Firing When Service is Healthy

**Possible Causes:**
- Alert thresholds too sensitive
- Prometheus query returning incorrect data
- Metrics labels mismatch

**Solution:**
1. Verify metrics are correct:
   ```bash
   # Check if metrics exist
   curl http://localhost:9090/api/v1/query?query=up{job="oauth2-proxy"}
   ```

2. Adjust alert thresholds if needed (edit rule file)

3. Verify metric names match OAuth2-Proxy exporter

### Issue: Alerts Not Reaching Alertmanager

**Possible Causes:**
- Prometheus not configured to send to Alertmanager
- Alertmanager not reachable
- Route configuration incorrect

**Solution:**
1. Check Prometheus config:
   ```yaml
   alerting:
     alertmanagers:
       - static_configs:
           - targets:
               - alertmanager:9093
   ```

2. Verify Alertmanager is running:
   ```bash
   docker compose -f compose/prometheus.yml --env-file .env ps alertmanager
   ```

3. Check Alertmanager logs:
   ```bash
   docker compose -f compose/prometheus.yml --env-file .env logs alertmanager --tail 50
   ```

## Alert Metrics Reference

### Key Metrics Used
- `up{job="oauth2-proxy"}` - Service availability
- `oauth2_proxy_http_request_total` - Total HTTP requests by code
- `oauth2_proxy_authz_request_total` - Authorization requests by code
- `oauth2_proxy_http_request_duration_seconds_bucket` - Request duration histogram

### Metric Labels
- `job="oauth2-proxy"` - Identifies OAuth2-Proxy metrics
- `code` - HTTP status code (200, 401, 403, 4xx, 5xx)

## Next Steps

After verifying alerts:

1. **Monitor:** Watch alerts in Prometheus/Alertmanager
2. **Tune:** Adjust thresholds based on normal operation patterns
3. **Document:** Note any threshold changes
4. **Integrate:** Configure additional notification channels if needed (Slack, email, etc.)

## Related Documentation

- `AUTH0-FIX-STATUS.md` - Overall Auth0 integration status
- `compose/prometheus/rules/inlock-ai.yml` - Alert rules configuration
- `compose/alertmanager/alertmanager.yml` - Alertmanager routing config

