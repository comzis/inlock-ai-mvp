# Alert Verification Tests & Trigger Scenarios

**Agent:** Alerting Assistant (Agent 9)  
**Date:** 2025-12-13  
**Purpose:** Verify Prometheus alert rules syntax and create test triggers

---

## Alert Rules Overview

**File:** `compose/prometheus/rules/inlock-ai.yml`  
**Group:** `inlock-ai`  
**OAuth2-Proxy Alerts:** 5 rules configured

### Alert Rules

1. **OAuth2ProxyDown** (Critical)
   - Trigger: `up{job="oauth2-proxy"} == 0` for 1 minute
   - Impact: Authentication completely unavailable

2. **OAuth2ProxyHighErrorRate** (Warning)
   - Trigger: >10% error rate (4xx/5xx) for 5 minutes
   - Impact: Many requests failing

3. **OAuth2ProxyHighAuthFailureRate** (Warning)
   - Trigger: >20% auth failures (401/403) for 5 minutes
   - Impact: Many users unable to authenticate

4. **OAuth2ProxySlowResponseTime** (Warning)
   - Trigger: 95th percentile > 2 seconds for 10 minutes
   - Impact: Poor user experience

5. **OAuth2ProxyNoAuthSuccess** (Critical)
   - Trigger: No successful auths (200) in 10 minutes despite requests
   - Impact: Complete authentication failure

---

## Syntax Validation

### PromQL Syntax Check

```bash
cd /home/comzis/inlock-infra

# Validate Prometheus rules file syntax
docker compose -f compose/stack.yml exec prometheus \
  promtool check rules /etc/prometheus/rules/inlock-ai.yml

# Expected output: SUCCESS: X rules found
```

**Alternative method (if promtool not available in container):**

```bash
# Install promtool locally (if needed)
# wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
# tar xzf prometheus-*.tar.gz
# ./prometheus-*/promtool check rules compose/prometheus/rules/inlock-ai.yml

# Or use Prometheus API
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name == "inlock-ai")'
```

### Label Consistency Check

```bash
# Verify alert labels match routing configuration
grep -A 10 "OAuth2Proxy" compose/prometheus/rules/inlock-ai.yml | grep "labels:"

# Expected labels:
# - severity: critical or warning
# - service: oauth2-proxy
```

**Verify labels in rules:**
- ✅ `severity`: `critical` or `warning`
- ✅ `service`: `oauth2-proxy`

---

## Test Trigger Scenarios

### Test 1: OAuth2ProxyDown Alert

**Objective:** Verify alert triggers when service is down

**Steps:**

1. **Verify service is up:**
   ```bash
   # Check metrics endpoint
   curl -s http://localhost:9090/api/v1/query?query=up{job=\"oauth2-proxy\"} | jq '.data.result[0].value[1]'
   # Expected: "1"
   ```

2. **Stop OAuth2-Proxy:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env stop oauth2-proxy
   ```

3. **Wait for alert (1 minute):**
   ```bash
   sleep 60
   ```

4. **Check alert status:**
   ```bash
   # Via Prometheus API
   curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname == "OAuth2ProxyDown")'
   
   # Or via Alertmanager
   curl -s http://localhost:9093/api/v2/alerts | jq '.[] | select(.labels.alertname == "OAuth2ProxyDown")'
   ```

5. **Expected:**
   - Alert status: `firing`
   - Labels: `severity=critical`, `service=oauth2-proxy`
   - Annotations include summary/description

6. **Restore service:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env start oauth2-proxy
   ```

7. **Verify alert resolves:**
   ```bash
   sleep 60
   curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname == "OAuth2ProxyDown") | .state'
   # Expected: "inactive" or no results
   ```

---

### Test 2: OAuth2ProxyHighErrorRate Alert (Simulated)

**Objective:** Verify alert triggers on high error rate

**Note:** This requires generating errors, which may be difficult to simulate safely.

**Alternative: Lower threshold temporarily for testing:**

```bash
# Backup original rule
cp compose/prometheus/rules/inlock-ai.yml compose/prometheus/rules/inlock-ai.yml.backup

# Temporarily lower threshold to 0.01 (1%) for testing
sed -i 's/> 0.1/> 0.01/' compose/prometheus/rules/inlock-ai.yml

# Reload Prometheus
docker compose -f compose/stack.yml --env-file .env exec prometheus \
  kill -HUP 1

# Wait for reload
sleep 10

# Generate some errors (be careful!)
# Example: Send requests to invalid endpoints
for i in {1..100}; do
  curl -s https://auth.inlock.ai/invalid-endpoint > /dev/null 2>&1
done

# Check alert
sleep 60
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname == "OAuth2ProxyHighErrorRate")'

# Restore original threshold
cp compose/prometheus/rules/inlock-ai.yml.backup compose/prometheus/rules/inlock-ai.yml
docker compose -f compose/stack.yml --env-file .env exec prometheus kill -HUP 1
```

**Expected:**
- Alert fires when error rate exceeds threshold
- Resolves when error rate drops below threshold

---

### Test 3: Manual Alert Query Test

**Objective:** Verify alert queries return expected results

```bash
# Test each alert expression manually

# 1. OAuth2ProxyDown
curl -s 'http://localhost:9090/api/v1/query?query=up{job="oauth2-proxy"}' | jq '.data.result'

# 2. OAuth2ProxyHighErrorRate
curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(oauth2_proxy_http_request_total{job="oauth2-proxy",code=~"4..|5.."}[5m])) / sum(rate(oauth2_proxy_http_request_total{job="oauth2-proxy"}[5m]))' | jq '.data.result'

# 3. OAuth2ProxyHighAuthFailureRate
curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code=~"401|403"}[5m])) / (sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy"}[5m])) + 1)' | jq '.data.result'

# 4. OAuth2ProxySlowResponseTime
curl -s 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(oauth2_proxy_http_request_duration_seconds_bucket{job="oauth2-proxy"}[5m])) by (le))' | jq '.data.result'

# 5. OAuth2ProxyNoAuthSuccess
curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy",code="200"}[10m])) == 0 and sum(rate(oauth2_proxy_authz_request_total{job="oauth2-proxy"}[10m])) > 0' | jq '.data.result'
```

**Expected:**
- All queries return valid results (may be empty arrays if conditions not met)
- No query errors
- Results match expected format

---

## Alertmanager Integration Verification

### Check Alert Routing

**File:** `compose/prometheus/alertmanager.yml` (if exists)

```bash
# Check Alertmanager configuration
docker compose -f compose/stack.yml exec alertmanager cat /etc/alertmanager/alertmanager.yml | grep -A 20 "oauth2"

# Or check via API
curl -s http://localhost:9093/api/v2/status | jq '.config'
```

**Expected routing:**
- OAuth2-Proxy alerts route to appropriate channel (e.g., n8n webhook)
- Critical alerts have higher priority
- Warning alerts route separately

### Test Alert Notification

**Note:** This depends on Alertmanager configuration. Adjust based on your setup.

```bash
# Check if alerts are being sent to Alertmanager
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | select(.labels.service == "oauth2-proxy")'

# Check Alertmanager silence status
curl -s http://localhost:9093/api/v2/silences | jq '.[] | select(.matchers[].value == "oauth2-proxy")'
```

---

## Validation Checklist

### Rule Syntax
- [ ] Prometheus rules file syntax valid
- [ ] All PromQL expressions valid
- [ ] No syntax errors in promtool check

### Label Consistency
- [ ] All alerts have `severity` label (critical/warning)
- [ ] All alerts have `service=oauth2-proxy` label
- [ ] Labels match routing configuration

### Query Validity
- [ ] All alert queries return valid results
- [ ] Queries match actual metric names
- [ ] Label selectors match Prometheus job configuration

### Alert Behavior
- [ ] OAuth2ProxyDown fires when service down (1 min)
- [ ] Alerts resolve when conditions no longer met
- [ ] Alert annotations contain useful information

### Integration
- [ ] Prometheus loads rules successfully
- [ ] Alertmanager receives alerts
- [ ] Notifications route correctly (if configured)

---

## Expected Metrics

Verify these metrics exist and are being scraped:

```bash
# List all oauth2_proxy metrics
curl -s http://localhost:9090/api/v1/label/__name__/values | jq '.data[] | select(. | startswith("oauth2_proxy"))'

# Check specific metrics
curl -s 'http://localhost:9090/api/v1/query?query=oauth2_proxy_http_request_total{job="oauth2-proxy"}' | jq '.data.result[0]'
curl -s 'http://localhost:9090/api/v1/query?query=oauth2_proxy_authz_request_total{job="oauth2-proxy"}' | jq '.data.result[0]'
curl -s 'http://localhost:9090/api/v1/query?query=up{job="oauth2-proxy"}' | jq '.data.result[0]'
```

**Required metrics for alerts:**
- ✅ `up{job="oauth2-proxy"}` - Service availability
- ✅ `oauth2_proxy_http_request_total` - HTTP request count
- ✅ `oauth2_proxy_authz_request_total` - Authorization request count
- ✅ `oauth2_proxy_http_request_duration_seconds_bucket` - Response time histogram

---

## Troubleshooting

### Issue: Alert Not Firing When Expected

**Check:**
1. Verify metric exists: `curl -s 'http://localhost:9090/api/v1/query?query=METRIC_NAME'`
2. Check evaluation interval: Alert must meet condition for `for` duration
3. Verify rule is loaded: Check Prometheus UI → Status → Rules

### Issue: PromQL Syntax Error

**Fix:**
- Validate syntax with promtool
- Check for typos in metric names
- Verify label selectors match actual labels

### Issue: Alert Fires but No Notification

**Check:**
- Alertmanager configuration
- Notification channel setup
- Network connectivity between Prometheus and Alertmanager

---

## Test Results Template

```
Alert Verification Date: [YYYY-MM-DD HH:MM UTC]
Verified By: [Name]

SYNTAX VALIDATION:
- Promtool check: [PASS / FAIL]
- Errors: [List any errors]

LABEL VERIFICATION:
- Severity labels: [PASS / FAIL]
- Service labels: [PASS / FAIL]
- Notes: [ ]

QUERY VALIDATION:
- OAuth2ProxyDown query: [VALID / INVALID]
- OAuth2ProxyHighErrorRate query: [VALID / INVALID]
- OAuth2ProxyHighAuthFailureRate query: [VALID / INVALID]
- OAuth2ProxySlowResponseTime query: [VALID / INVALID]
- OAuth2ProxyNoAuthSuccess query: [VALID / INVALID]

ALERT TRIGGER TESTS:
- OAuth2ProxyDown test: [PASS / FAIL / NOT TESTED]
- Error rate test: [PASS / FAIL / NOT TESTED]
- Notes: [ ]

INTEGRATION:
- Prometheus loads rules: [YES / NO]
- Alertmanager receives alerts: [YES / NO]
- Notifications work: [YES / NO / NOT CONFIGURED]

OVERALL RESULT: [PASS / FAIL / PARTIAL]

ISSUES IDENTIFIED:
[List any issues]

BLOCKERS:
[List blockers]

NEXT STEPS:
[Actions required]
```

---

## Handoff Notes

**For Primary Team:**
- [ ] Alert rules syntax validated
- [ ] Queries tested
- [ ] Trigger scenarios documented
- [ ] Integration verified
- [ ] Status documented

**Status:** [READY / NEEDS PRIMARY TEAM ACTION / BLOCKED]

