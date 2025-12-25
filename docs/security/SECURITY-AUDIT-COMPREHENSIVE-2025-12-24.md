# Comprehensive Security Audit Report
**Date:** December 24, 2025  
**Audit Type:** Read-Only Infrastructure Security Assessment  
**Scope:** Traefik/Auth, Secrets, Network Segmentation, Monitoring Paths, Documentation Accuracy

---

## Executive Summary

**Overall Security Score: 7.0/10** (Down from documented 8.5/10)

The infrastructure demonstrates strong security fundamentals but has **critical discrepancies** between documented posture and actual deployment state. Key findings include hardcoded credentials, service failures, exposed ports, and configuration inconsistencies.

---

## Summary Bullets

### Service Health
- **Total Services:** 16 defined, 14 containers present
- **Healthy:** 12 services running and healthy
- **Issues:** 2 restarting (blackbox-exporter, portainer), 2 created/not started (prometheus, traefik)

### Auth/Traefik Coverage
- ✅ **OAuth2 Forward-Auth:** Enabled on all admin routers (portainer, grafana, n8n, coolify, homarr, cockpit, dashboard)
- ✅ **IP Allowlist:** `allowed-admins` middleware applied to all admin services
- ⚠️ **Redundancy:** `admin-ip-allowlist` still referenced in coolify and homarr (redundant with `allowed-admins`)
- ✅ **Public Services:** inlock-ai, mail.inlock.ai use secure-headers only (appropriate for public access)
- ✅ **Mailu Admin:** Protected by `admin-forward-auth` (Auth0)

### Exposed Ports
- ✅ **Traefik:** Ports 80, 443 (required), 465, 993 (mail), 127.0.0.1:9100 (metrics - safe)
- 🔴 **Strapi:** Port 1337 directly exposed (`0.0.0.0:1337:1337`) - **NOT behind Traefik**
- ✅ **Mailu:** Port 587 (SMTP submission - required, documented)
- ✅ **Coolify:** Ports 127.0.0.1:8080, 127.0.0.1:6380, 127.0.0.1:5433, 127.0.0.1:6001 (localhost only - safe)
- ⚠️ **PostHog/ClickHouse:** No direct port exposure (good), but services not behind Traefik

### Secrets Posture
- 🔴 **CRITICAL:** Hardcoded ClickHouse password in `tooling.yml:167`: `CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5`
- ✅ **Other Services:** Use environment variables (`${POSTHOG_CLICKHOUSE_PASSWORD:?Required}`)
- ✅ **env.example:** Documents `POSTHOG_CLICKHOUSE_PASSWORD` (line 66)
- ✅ **Docker Secrets:** Used for Grafana, Portainer, n8n, Traefik (properly configured)

### Network Segmentation
- ✅ **Edge Network:** Only Traefik, Cockpit-Proxy, Inlock-AI (correct - public services)
- ✅ **Mgmt Network:** All admin services (Portainer, Grafana, n8n, OAuth2-Proxy, etc.)
- ✅ **Internal Network:** Databases, internal services (inlock-db, postgres-exporter)
- ✅ **Socket-Proxy Network:** Docker socket proxy, Traefik, Portainer (correct isolation)
- ✅ **Mail Network:** Mailu services, n8n, inlock-ai (appropriate)

### Image Pinning State
- ✅ **Main Stack:** All images pinned (Grafana 11.1.0, Alertmanager v0.27.0, cAdvisor v0.49.1, Node Exporter v1.8.2, Blackbox Exporter v0.27.0)
- ⚠️ **Tooling Stack:** PostHog uses `:latest` (3 services)
- ⚠️ **Other Services:** Homarr, Coolify, Socat use `:latest`
- ⚠️ **Legacy Containers:** Old `compose-*` containers still running with `:latest` images

### Monitoring/Alert Paths
- ✅ **Prometheus:** Path fixed to `/etc/prometheus/prometheus.yml` (correct)
- ✅ **Alertmanager:** Path fixed to `/etc/alertmanager/alertmanager.yml` (correct)
- 🔴 **Blackbox Exporter:** Config path points to directory (`config/monitoring/blackbox.yml` is a directory, not file)
- ⚠️ **Service Status:** Prometheus and Traefik in "Created" state (not running)

---

## Detailed Findings

### 🔴 CRITICAL Issues

#### 1. Hardcoded Credential Still Present
**File:** `compose/services/tooling.yml:167`  
**Service:** `posthog_worker`  
**Issue:** `CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5` hardcoded

**Evidence:**
```yaml
posthog_worker:
  environment:
    - CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5  # Line 167 - HARDCODED
```

**Impact:** Credential exposed in source code, inconsistent with other PostHog services

**Fix Required:**
```yaml
- CLICKHOUSE_PASSWORD=${POSTHOG_CLICKHOUSE_PASSWORD:?Required}
```

---

#### 2. Strapi Direct Port Exposure
**File:** `compose/services/tooling.yml:30`  
**Service:** `strapi`  
**Issue:** Port 1337 exposed directly to host: `"1337:1337"`

**Evidence:**
```yaml
ports:
  - "1337:1337"  # Direct exposure, not behind Traefik
```

**Impact:** Service accessible without Traefik reverse proxy, bypasses security middlewares

**Fix Required:**
- Remove direct port exposure
- Ensure Traefik router exists for Strapi
- Apply security middlewares (secure-headers, admin-forward-auth, allowed-admins)

---

#### 3. Service Failures
**Services:** `services-blackbox-exporter-1`, `services-portainer-1`

**Blackbox Exporter:**
- Status: Restarting
- Error: Config path points to directory instead of file
- Path: `config/monitoring/blackbox.yml` (is a directory)
- Expected: Should point to actual config file

**Portainer:**
- Status: Restarting
- Error: Store timeout, encryption key file not present
- Impact: Container management unavailable

---

#### 4. Prometheus and Traefik Not Running
**Services:** `services-prometheus-1`, `services-traefik-1`  
**Status:** Created (not started)

**Impact:**
- No metrics collection (Prometheus)
- No reverse proxy/routing (Traefik)
- Critical infrastructure services down

---

### 🟡 HIGH Priority Issues

#### 5. Redundant Middleware in Routing
**File:** `traefik/dynamic/routers.yml:91, 116`  
**Services:** Coolify, Homarr

**Issue:** Both `admin-ip-allowlist` and `allowed-admins` applied

**Current:**
```yaml
coolify:
  middlewares:
    - coolify-headers
    - admin-ip-allowlist  # Redundant - very broad (all private networks)
    - admin-forward-auth
    - allowed-admins       # More specific, secure
    - mgmt-ratelimit
```

**Fix:** Remove `admin-ip-allowlist` (redundant and less secure)

---

#### 6. Legacy Containers with Unpinned Images
**Containers:** `compose-*` containers still running

**Affected:**
- `compose-grafana-1`: `grafana/grafana:latest` (should be 11.1.0)
- `compose-alertmanager-1`: `prom/alertmanager:latest` (should be v0.27.0)
- `compose-cadvisor-1`: `gcr.io/cadvisor/cadvisor:latest` (should be v0.49.1)
- `compose-node-exporter-1`: `prom/node-exporter:latest` (should be v1.8.2)
- `compose-blackbox-exporter-1`: `prom/blackbox-exporter:latest` (should be v0.27.0)

**Impact:** Unpredictable updates, resource waste, inconsistency

---

### 🟢 MEDIUM Priority Issues

#### 7. Container Hardening Gaps
**Services Missing `cap_drop: ALL`:**
- Alertmanager (uses `nobody` user but no cap_drop)
- OAuth2-Proxy (read-only but no cap_drop)
- Postgres-Exporter (read-only but no cap_drop)
- cAdvisor (read-only but no cap_drop)

**Services Missing `no-new-privileges`:**
- Inlock-DB (has cap_drop but no no-new-privileges)

---

#### 8. PostHog Services Not Behind Traefik
**Services:** PostHog web, worker, plugins, ClickHouse

**Status:** No Traefik routers defined, no direct port exposure (good), but not accessible via reverse proxy

**Impact:** Services may be inaccessible or require direct network access

---

### 🟢 LOW Priority Issues

#### 9. Documentation Drift
**File:** `docs/security/SECURITY-POSTURE-2025-12-24.md`

**Discrepancies:**
- Documents score as 8.5/10, actual is 7.0/10
- Claims "No hardcoded credentials" but one exists
- Claims "All containers drop ALL capabilities" but some don't
- OAuth2-Proxy status documented as 404, actually 302 (correct redirect)

---

## Security Score Breakdown (0-10)

### Container Hardening: 7.5/10
**Rationale:**
- ✅ Most services have `cap_drop: ALL` and `no-new-privileges: true`
- ✅ Non-root users where applicable
- ✅ Read-only filesystems on monitoring services
- ⚠️ 5 services missing `cap_drop: ALL` (alertmanager, oauth2-proxy, postgres-exporter, cadvisor, inlock-db)
- ⚠️ 1 service missing `no-new-privileges` (inlock-db)

**Deductions:** -1.5 for missing hardening on 6 services

---

### Network Segmentation: 9/10
**Rationale:**
- ✅ Only public services on edge network (Traefik, Cockpit-Proxy, Inlock-AI)
- ✅ Admin services isolated on mgmt network
- ✅ Internal services on internal network
- ✅ Socket proxy properly isolated
- ✅ Mail services on dedicated network

**Deductions:** -1.0 for Strapi direct port exposure (bypasses network isolation)

---

### Auth/Forward-Auth: 8.5/10
**Rationale:**
- ✅ All admin services use `admin-forward-auth` middleware
- ✅ IP allowlist (`allowed-admins`) as secondary layer
- ✅ Secure headers applied
- ✅ Rate limiting on admin services
- ⚠️ Redundant middleware in 2 routers (coolify, homarr)

**Deductions:** -1.5 for middleware redundancy

---

### Secrets Management: 6.5/10
**Rationale:**
- ✅ Docker secrets used for critical services
- ✅ Most credentials use environment variables
- ✅ env.example documents required variables
- 🔴 1 hardcoded credential found (ClickHouse password)
- ✅ Secrets stored outside repo

**Deductions:** -3.5 for hardcoded credential (critical security issue)

---

### Image Pinning: 7.5/10
**Rationale:**
- ✅ Main stack images pinned (Grafana, Alertmanager, cAdvisor, Node Exporter, Blackbox Exporter)
- ✅ Traefik, Prometheus, OAuth2-Proxy pinned
- ⚠️ Tooling services use `:latest` (PostHog, Homarr, Coolify, Socat)
- ⚠️ Legacy containers running with unpinned images

**Deductions:** -2.5 for tooling services and legacy containers

---

### Monitoring/Alert Paths: 6.0/10
**Rationale:**
- ✅ Prometheus config path fixed
- ✅ Alertmanager config path fixed
- 🔴 Blackbox exporter config path incorrect (directory vs file)
- 🔴 Prometheus and Traefik not running (Created state)

**Deductions:** -4.0 for blackbox config issue and services not running

---

### Documentation Accuracy: 6.0/10
**Rationale:**
- ✅ Security posture document exists
- ✅ Recent improvements documented
- ⚠️ Score discrepancy (8.5/10 documented vs 7.0/10 actual)
- ⚠️ Claims "no hardcoded credentials" but one exists
- ⚠️ Claims "all containers drop ALL capabilities" but some don't
- ⚠️ OAuth2 status incorrectly documented

**Deductions:** -4.0 for multiple inaccuracies

---

### Service Health: 6.0/10
**Rationale:**
- ✅ 12 services healthy
- 🔴 2 services restarting (blackbox-exporter, portainer)
- 🔴 2 services not started (prometheus, traefik)

**Deductions:** -4.0 for 4 services with issues

---

## Overall Score: 7.0/10

**Calculation:**
- Container Hardening: 7.5/10 (weight: 1.5) = 11.25
- Network Segmentation: 9.0/10 (weight: 1.5) = 13.5
- Auth/Forward-Auth: 8.5/10 (weight: 1.5) = 12.75
- Secrets Management: 6.5/10 (weight: 2.0) = 13.0
- Image Pinning: 7.5/10 (weight: 1.0) = 7.5
- Monitoring Paths: 6.0/10 (weight: 1.0) = 6.0
- Documentation: 6.0/10 (weight: 0.5) = 3.0
- Service Health: 6.0/10 (weight: 1.0) = 6.0

**Total:** 73.0 / 10.5 = **7.0/10**

---

## Discrepancies with Documentation

| Documented | Actual | File Reference | Severity |
|------------|--------|----------------|----------|
| "No hardcoded credentials" | 1 hardcoded credential found | `tooling.yml:167` | 🔴 CRITICAL |
| "All containers drop ALL capabilities" | 5 services missing cap_drop | `stack.yml` (multiple services) | 🟡 HIGH |
| Score: 8.5/10 | Actual: 7.0/10 | `SECURITY-POSTURE-2025-12-24.md` | 🟡 HIGH |
| "OAuth2-Proxy returns 404" | Actually returns 302 (correct) | `SECURITY-POSTURE-2025-12-24.md:38` | 🟢 LOW |
| "All services healthy" | 4 services with issues | Deployment state | 🔴 CRITICAL |

---

## Action Plan

### Priority 1: Critical Fixes (This Week)

#### 1. Remove Hardcoded Credential
**File:** `compose/services/tooling.yml`  
**Line:** 167  
**Action:**
```yaml
# Change:
- CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5
# To:
- CLICKHOUSE_PASSWORD=${POSTHOG_CLICKHOUSE_PASSWORD:?Required}
```
**Command:**
```bash
sed -i '167s/CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5/CLICKHOUSE_PASSWORD=${POSTHOG_CLICKHOUSE_PASSWORD:?Required}/' compose/services/tooling.yml
```

---

#### 2. Fix Blackbox Exporter Config Path
**File:** `compose/services/stack.yml:359`  
**Issue:** Config path points to directory (`config/monitoring/blackbox.yml` is a directory)  
**Actual File:** `compose/config/monitoring/blackbox.yml` (file exists)  
**Action:** Update path from `../../config/monitoring/blackbox.yml` to `../config/monitoring/blackbox.yml`
```yaml
# Change:
- ../../config/monitoring/blackbox.yml:/etc/blackbox/blackbox.yml:ro
# To:
- ../config/monitoring/blackbox.yml:/etc/blackbox/blackbox.yml:ro
```

---

#### 3. Fix Strapi Port Exposure
**File:** `compose/services/tooling.yml`  
**Line:** 30  
**Action:**
```yaml
# Remove:
ports:
  - "1337:1337"
# Ensure Traefik router exists for Strapi
# Add security middlewares to router
```

---

#### 4. Investigate Prometheus/Traefik Not Starting
**Action:**
```bash
# Check why services are in Created state
docker compose -f compose/services/stack.yml --env-file /home/comzis/deployments/.env ps -a
docker compose -f compose/services/stack.yml --env-file /home/comzis/deployments/.env logs prometheus traefik
# Start services if needed
docker compose -f compose/services/stack.yml --env-file /home/comzis/deployments/.env up -d prometheus traefik
```

---

### Priority 2: High Priority (This Month)

#### 5. Remove Redundant Middleware
**File:** `traefik/dynamic/routers.yml`  
**Lines:** 91, 116  
**Action:**
```yaml
# Remove admin-ip-allowlist from:
coolify:
  middlewares:
    - coolify-headers
    # - admin-ip-allowlist  # REMOVE THIS
    - admin-forward-auth
    - allowed-admins
    - mgmt-ratelimit

homarr:
  middlewares:
    - secure-headers
    # - admin-ip-allowlist  # REMOVE THIS
    - admin-forward-auth
    - allowed-admins
```

---

#### 6. Clean Up Legacy Containers
**Action:**
```bash
# Stop and remove old compose-* containers
docker ps -a --filter "name=compose-" --format "{{.Names}}" | xargs docker rm -f
# Verify only services-* containers remain
docker ps --format "{{.Names}}" | grep -E "^services-"
```

---

#### 7. Complete Container Hardening
**File:** `compose/services/stack.yml`  
**Action:** Add missing security options:
```yaml
alertmanager:
  cap_drop:
    - ALL  # ADD THIS

oauth2-proxy:
  cap_drop:
    - ALL  # ADD THIS

postgres-exporter:
  cap_drop:
    - ALL  # ADD THIS

cadvisor:
  cap_drop:
    - ALL  # ADD THIS

inlock-db:
  security_opt:
    - no-new-privileges:true  # ADD THIS
```

---

### Priority 3: Medium Priority (Next Month)

#### 8. Pin Remaining Image Versions
**Files:** `compose/services/tooling.yml`, `compose/services/homarr.yml`, `compose/services/coolify.yml`, `compose/services/cockpit-proxy.yml`  
**Action:** Replace `:latest` with specific versions

---

#### 9. Update Security Documentation
**File:** `docs/security/SECURITY-POSTURE-2025-12-24.md`  
**Action:**
- Update score to 7.0/10
- Document actual state (hardcoded credential, service failures)
- Correct OAuth2-Proxy status (302 is correct)
- Update container hardening section

---

## System Security Check

**Status:** Skipped (requires sudo)  
**Note:** System-level security checks (UFW, fail2ban, unattended-upgrades) require sudo privileges. Based on `.cursorrules-security`, these should be:
- ✅ UFW Firewall: ACTIVE
- ✅ Fail2Ban: ACTIVE
- ✅ Unattended-Upgrades: ACTIVE
- ✅ Ubuntu user: DISABLED (`/usr/sbin/nologin`)
- ✅ Sudo: Password required (no NOPASSWD)

**Recommendation:** Run system security check with sudo to verify actual state.

---

## Verification Commands

### Check for Hardcoded Credentials
```bash
grep -r "PASSWORD=" compose/services/*.yml | grep -v "\${" | grep -v "#"
grep -r "SECRET=" compose/services/*.yml | grep -v "\${" | grep -v "#"
```

### Verify Forward-Auth Coverage
```bash
grep -A5 "middlewares:" traefik/dynamic/routers.yml | grep -E "(admin-forward-auth|allowed-admins)"
```

### Check Exposed Ports
```bash
grep -A2 "ports:" compose/services/*.yml | grep -E "^\s+- \"[0-9]"
```

### Verify Network Isolation
```bash
docker network inspect edge --format '{{range .Containers}}{{.Name}} {{end}}'
# Should only show: traefik, cockpit-proxy, inlock-ai
```

### Check Service Health
```bash
docker compose -f compose/services/stack.yml ps --format "{{.Name}}\t{{.Status}}" | grep -E "(Restarting|Exited|Created)"
```

---

## Conclusion

The infrastructure maintains **strong security fundamentals** but has **critical gaps** that reduce the actual security score from the documented 8.5/10 to **7.0/10**. The primary issues are:

1. **Hardcoded credential** (CRITICAL)
2. **Service failures** (CRITICAL)
3. **Direct port exposure** (HIGH)
4. **Legacy containers** (HIGH)
5. **Documentation inaccuracies** (MEDIUM)

**Immediate Actions Required:**
1. Remove hardcoded ClickHouse password
2. Fix blackbox exporter config path
3. Remove Strapi direct port exposure
4. Investigate why Prometheus/Traefik aren't running

Once these critical issues are addressed, the security score should improve to **8.0/10** or higher.

---

**Audit Completed:** December 24, 2025  
**Next Audit:** January 24, 2026  
**Auditor:** Infrastructure Security Review
