# Auth0 Remediation - Quick Checklist

**For:** Primary Teams  
**Purpose:** Fast verification of critical items  
**Time:** 10-15 minutes

---

## 🔴 Critical (Do First - 5 minutes)

### 1. Auth0 Dashboard Callback URL

- [ ] Go to: https://manage.auth0.com/
- [ ] Navigate: Applications → Applications → `inlock-admin`
- [ ] Verify: **Allowed Callback URLs** contains:
  ```
  https://auth.inlock.ai/oauth2/callback
  ```
- [ ] Verify: **Allowed Logout URLs** contains (all 8):
  ```
  https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
  ```
- [ ] Verify: **Allowed Web Origins** contains:
  ```
  https://auth.inlock.ai
  ```
- [ ] Click: **Save Changes**

**If missing:** Add URLs and save.

---

### 2. Service Health Check

```bash
# Check OAuth2-Proxy is running
docker compose -f compose/stack.yml ps oauth2-proxy

# Check health endpoint
curl -I http://oauth2-proxy:4180/ping

# Check recent logs (no errors)
docker compose -f compose/stack.yml logs --tail 20 oauth2-proxy | grep -i error
```

**Expected:** Service running, health check returns 200, no errors in logs.

---

## 🟡 Important (Do Next - 10 minutes)

### 3. Browser E2E Test

- [ ] Clear browser cookies for `*.inlock.ai`
- [ ] Visit: `https://grafana.inlock.ai`
- [ ] Verify: Redirected to Auth0 login
- [ ] Login: Use valid credentials
- [ ] Verify: Redirected back to Grafana
- [ ] Verify: Access granted (can see Grafana)
- [ ] Check: Browser cookies → `inlock_session` present
- [ ] Check: Cookie attributes → `SameSite=None; Secure`

**If fails:** See troubleshooting section in `AUTH0-SWARM-100-DELIVERABLES.md` Section 9.

---

### 4. Configuration Verification

```bash
# Check PKCE enabled
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}' | grep code-challenge
# Should show: --code-challenge-method=S256

# Check cookie SameSite
docker inspect compose-oauth2-proxy-1 --format '{{range .Args}}{{println .}}{{end}}' | grep samesite
# Should show: --cookie-samesite=none

# Check Prometheus scraping
curl -s 'http://localhost:9090/api/v1/query?query=up{job="oauth2-proxy"}' | jq '.data.result[0].value[1]'
# Should return: "1"
```

**Expected:** All checks pass.

---

## 🟢 Optional (Nice to Have)

### 5. Grafana Dashboard Import

- [ ] Navigate to: `https://grafana.inlock.ai`
- [ ] Go to: Dashboards → Import
- [ ] Upload: `grafana/dashboards/devops/auth0-oauth2.json`
- [ ] Select: Prometheus datasource
- [ ] Click: Import
- [ ] Verify: Dashboard loads with data

---

### 6. Management API Setup (Optional)

```bash
# Run setup script
./scripts/setup-auth0-management-api.sh

# Test connection
./scripts/test-auth0-api.sh
```

**Benefits:** Enables automated Auth0 configuration updates.

---

## Quick Diagnostic Commands

```bash
# Full diagnostic
./scripts/diagnose-auth0-issue.sh

# Config check
./scripts/check-auth-config.sh

# API test (if M2M configured)
./scripts/test-auth0-api-examples.sh

# Monitor status
./scripts/monitor-auth0-status.sh
```

---

## If Something Fails

1. **Check logs:**
   ```bash
   docker compose -f compose/stack.yml logs --tail 50 oauth2-proxy
   ```

2. **Check service status:**
   ```bash
   docker compose -f compose/stack.yml ps oauth2-proxy
   ```

3. **Restart service:**
   ```bash
   docker compose -f compose/stack.yml restart oauth2-proxy
   ```

4. **See troubleshooting:** `AUTH0-SWARM-100-DELIVERABLES.md` Section 9

---

**Last Updated:** 2025-12-13

