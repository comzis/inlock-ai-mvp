# Grafana Dashboard Import Guide

**Created:** 2025-12-13 01:20 UTC  
**Agent:** Grafana Import Assistant (Agent 8)  
**Purpose:** Step-by-step guide to import auth0-oauth2.json dashboard

---

## Prerequisites

- ✅ Grafana running and accessible
- ✅ Prometheus datasource configured in Grafana
- ✅ OAuth2-Proxy metrics being scraped by Prometheus
- ✅ Dashboard file: `grafana/dashboards/devops/auth0-oauth2.json`

---

## Step 1: Verify Prometheus Datasource

### Check Datasource Configuration
1. Log into Grafana: `https://grafana.inlock.ai`
2. Navigate to: **Configuration** → **Data Sources**
3. Find: **Prometheus** datasource
4. Verify:
   - ✅ URL: `http://prometheus:9090` (internal) or appropriate
   - ✅ Access: Server (default)
   - ✅ Status: Working

### Test Query
1. Click **Explore** in Grafana
2. Select **Prometheus** datasource
3. Run query: `up{job="oauth2-proxy"}`
4. Expected: Should return `1` (service is up)

---

## Step 2: Verify OAuth2-Proxy Metrics

### Check Metrics Availability
1. In Grafana **Explore**, run:
   ```
   oauth2_proxy_http_request_total{job="oauth2-proxy"}
   ```
2. Expected: Should see metrics with labels (code, method, etc.)

### Verify Key Metrics
Run these queries to verify metrics exist:
- `oauth2_proxy_http_request_total` - Request count
- `oauth2_proxy_authz_request_total` - Auth requests
- `oauth2_proxy_http_request_duration_seconds_bucket` - Response times
- `oauth2_proxy_upstream_response_status_code_total` - Upstream responses

---

## Step 3: Import Dashboard

### Method 1: Via Grafana UI (Recommended)

1. **Navigate to Dashboards:**
   - Click **Dashboards** → **Import**

2. **Import Dashboard:**
   - Click **Upload JSON file**
   - Select: `grafana/dashboards/devops/auth0-oauth2.json`
   - Or paste JSON content directly

3. **Configure Import:**
   - **Name:** OAuth2-Proxy Authentication (or keep default)
   - **Folder:** DevOps (or create new folder)
   - **UID:** Leave default or set custom
   - **Prometheus:** Select Prometheus datasource

4. **Review Panels:**
   - Verify all panels load without errors
   - Check datasource is set to Prometheus for all panels

5. **Save Dashboard:**
   - Click **Save**
   - Add tags: `oauth2`, `auth0`, `authentication`, `devops`

### Method 2: Via API (Automated)

```bash
# Get Grafana API key from Grafana UI:
# Configuration → API Keys → New API Key

GRAFANA_URL="https://grafana.inlock.ai"
GRAFANA_API_KEY="your-api-key"
DASHBOARD_FILE="grafana/dashboards/devops/auth0-oauth2.json"

# Import dashboard
curl -X POST \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d @$DASHBOARD_FILE \
  "$GRAFANA_URL/api/dashboards/db"
```

### Method 3: Via Provisioning (Permanent)

1. **Add to Provisioning:**
   - File: `grafana/provisioning/dashboards/inlock-dashboards.yml`
   - Add entry for `auth0-oauth2.json`

2. **Restart Grafana:**
   ```bash
   docker compose -f compose/stack.yml restart grafana
   ```

---

## Step 4: Verify Dashboard Panels

### Expected Panels

1. **Service Status**
   - Panel: OAuth2-Proxy Up/Down
   - Query: `up{job="oauth2-proxy"}`
   - Expected: Green (1) when service is up

2. **Request Rate**
   - Panel: Requests per Second
   - Query: `rate(oauth2_proxy_http_request_total[5m])`
   - Expected: Non-zero during activity

3. **Error Rate**
   - Panel: Error Rate (%)
   - Query: Error requests / Total requests
   - Expected: Low percentage (< 10%)

4. **Authentication Success/Failure**
   - Panel: Auth Success vs Failure
   - Query: `oauth2_proxy_authz_request_total{code="200"}` vs `{code=~"401|403"}`
   - Expected: More successes than failures

5. **Response Time**
   - Panel: 95th Percentile Response Time
   - Query: `histogram_quantile(0.95, ...)`
   - Expected: < 2 seconds

6. **Token Operations**
   - Panel: Token Refresh/Revoke operations
   - Query: `oauth2_proxy_token_refresh_total`, etc.
   - Expected: Metrics present if available

---

## Step 5: Panel Sanity Checks

### Check Each Panel

1. **No Data?**
   - Verify Prometheus is scraping: `up{job="oauth2-proxy"}`
   - Check time range (last 1 hour minimum)
   - Verify metric names match OAuth2-Proxy version

2. **Wrong Datasource?**
   - Edit panel → **Query** tab
   - Select **Prometheus** datasource
   - Save panel

3. **Query Errors?**
   - Check PromQL syntax
   - Verify metric names exist in Prometheus
   - Check label names match actual labels

4. **Missing Metrics?**
   - Some metrics may not be available in all OAuth2-Proxy versions
   - Check OAuth2-Proxy version: `v7.6.0`
   - Verify metrics endpoint: `http://oauth2-proxy:44180/metrics`

---

## Step 6: Datasource Requirements

### Required Labels

Dashboard expects these labels:
- `job="oauth2-proxy"` - Job name from Prometheus
- `code` - HTTP status code (200, 401, 403, etc.)
- `method` - HTTP method (GET, POST, etc.)

### Metric Names

Dashboard uses these metrics:
- `oauth2_proxy_http_request_total` - Total HTTP requests
- `oauth2_proxy_authz_request_total` - Authorization requests
- `oauth2_proxy_http_request_duration_seconds_bucket` - Response time histogram
- `oauth2_proxy_upstream_response_status_code_total` - Upstream responses
- `oauth2_proxy_token_refresh_total` - Token refresh operations
- `up{job="oauth2-proxy"}` - Service availability

---

## Troubleshooting

### Dashboard Shows "No Data"

1. **Check Prometheus:**
   ```bash
   # In Grafana Explore, run:
   up{job="oauth2-proxy"}
   ```

2. **Check Metrics Endpoint:**
   ```bash
   # From host (if network allows):
   curl http://oauth2-proxy:44180/metrics | grep oauth2_proxy_http_request_total
   ```

3. **Check Scrape Configuration:**
   - Verify `compose/prometheus/prometheus.yml` has oauth2-proxy job
   - Check Prometheus targets: `http://prometheus:9090/targets`

### Panels Show Errors

1. **Check Query Syntax:**
   - Edit panel → Query tab
   - Verify PromQL is valid
   - Check for typos in metric names

2. **Check Time Range:**
   - Ensure time range includes when metrics were collected
   - Try "Last 1 hour" or "Last 6 hours"

3. **Check Datasource:**
   - Verify Prometheus datasource is selected
   - Test datasource connection

---

## Verification Checklist

- [ ] Prometheus datasource configured and working
- [ ] OAuth2-Proxy metrics visible in Prometheus
- [ ] Dashboard imported successfully
- [ ] All panels load without errors
- [ ] Service status panel shows "Up"
- [ ] Request rate panel shows activity
- [ ] Error rate panel shows data (even if 0%)
- [ ] Authentication panels show success/failure counts
- [ ] Response time panel shows data
- [ ] Dashboard saved and accessible

---

## Next Steps

1. **Monitor Dashboard:**
   - Watch for authentication failures
   - Monitor error rates
   - Track response times

2. **Set Up Alerts:**
   - Use Alertmanager rules from `compose/prometheus/rules/inlock-ai.yml`
   - Configure notification channels in Grafana

3. **Customize Dashboard:**
   - Add additional panels as needed
   - Adjust thresholds and time ranges
   - Add annotations for deployments

---

**Last Updated:** 2025-12-13 01:20 UTC  
**Status:** Ready for Primary Team Use
