# Security Audit Report - December 24, 2025

**Audit Date:** December 24, 2025  
**Auditor:** Infrastructure Security Review  
**Scope:** Deployed stack security posture, access controls, configuration compliance  
**Method:** Read-only inspection of running containers, networks, configurations

---

## Executive Summary

**Current Security Score: 7.5/10** (Down from documented 8.5/10)

The infrastructure shows strong security fundamentals with container hardening and network segmentation properly implemented. However, **critical discrepancies** were found between documented security posture and actual deployment state, including:

- 🔴 **CRITICAL**: Hardcoded credential still present in `tooling.yml`
- 🔴 **CRITICAL**: Service failures (Portainer, Blackbox Exporter) indicating configuration issues
- 🟡 **HIGH**: Legacy containers running with unpinned `:latest` images
- 🟡 **MEDIUM**: Redundant middleware references in routing configuration
- 🟢 **LOW**: Minor documentation drift

---

## Detailed Findings

### 🔴 CRITICAL Issues

#### 1. Hardcoded Credential Still Present

**Location:** `compose/services/tooling.yml:167`  
**Service:** `posthog_worker`  
**Issue:** ClickHouse password still hardcoded: `CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5`

**Impact:** 
- Credential exposed in source code
- Inconsistent with other PostHog services (web, plugins use env var)
- Security risk if repository is compromised

**Expected State:** Should use `${POSTHOG_CLICKHOUSE_PASSWORD:?Required}` like other services

**Recommendation:** 
```yaml
# Line 167 - Change from:
- CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5
# To:
- CLICKHOUSE_PASSWORD=${POSTHOG_CLICKHOUSE_PASSWORD:?Required}
```

---

#### 2. Service Failures - Configuration Issues

**Services Affected:**
- `services-portainer-1`: Restarting - Store timeout errors
- `services-blackbox-exporter-1`: Restarting - Config file path issue

**Portainer Issue:**
```
FTL failed opening store | error=timeout
INF encryption key file not present | filename=/run/secrets/portainer
```

**Blackbox Exporter Issue:**
```
ERROR Error loading config err="error parsing config file: yaml: input error: read /etc/blackbox/blackbox.yml: is a directory"
```

**Root Cause:**
- Blackbox exporter config path points to directory instead of file
- Portainer volume mount or secret configuration issue

**Impact:**
- Services not functioning correctly
- Monitoring gaps (blackbox exporter)
- Container management unavailable (portainer)

**Recommendation:**
1. Fix blackbox exporter config path in `stack.yml`
2. Verify Portainer volume mounts and secrets
3. Check for duplicate/conflicting container definitions

---

### 🟡 HIGH Priority Issues

#### 3. Legacy Containers with Unpinned Images

**Finding:** Old `compose-*` containers still running with `:latest` tags

**Containers:**
- `compose-grafana-1`: `grafana/grafana:latest` (should be `11.1.0`)
- `compose-alertmanager-1`: `prom/alertmanager:latest` (should be `v0.27.0`)
- `compose-cadvisor-1`: `gcr.io/cadvisor/cadvisor:latest` (should be `v0.49.1`)
- `compose-blackbox-exporter-1`: `prom/blackbox-exporter:latest` (should be `v0.27.0`)
- `compose-node-exporter-1`: `prom/node-exporter:latest` (should be `v1.8.2`)

**Impact:**
- Unpredictable updates
- Potential security vulnerabilities from outdated images
- Inconsistency between compose files and running containers
- Resource waste (duplicate containers)

**Recommendation:**
1. Stop and remove old `compose-*` containers
2. Verify only `services-*` containers are running
3. Document cleanup procedure

---

#### 4. Redundant Middleware in Routing

**Location:** `traefik/dynamic/routers.yml`  
**Services:** Coolify, Homarr

**Issue:** Both `admin-ip-allowlist` and `allowed-admins` middlewares are applied

**Current Configuration:**
```yaml
coolify:
  middlewares:
    - coolify-headers
    - admin-ip-allowlist  # Redundant
    - admin-forward-auth
    - allowed-admins      # More specific
    - mgmt-ratelimit
```

**Impact:**
- Redundant IP filtering (both allowlists are checked)
- Potential confusion in middleware chain
- `admin-ip-allowlist` is very broad (all private networks)

**Recommendation:**
- Remove `admin-ip-allowlist` from coolify and homarr routers
- Keep only `allowed-admins` (more specific, secure)

---

### 🟢 MEDIUM Priority Issues

#### 5. Network Segmentation - Minor Deviation

**Finding:** `services-inlock-ai-1` is on `edge` network (expected for public service)

**Status:** ✅ **CORRECT** - Inlock AI is a public-facing service, should be on edge network

**Edge Network Containers:**
- `compose-cockpit-proxy-1` ✅
- `compose-traefik-1` ✅
- `services-cockpit-proxy-1` ✅
- `services-inlock-ai-1` ✅

**Assessment:** Network segmentation is correct. Only public-facing services on edge network.

---

#### 6. Container Security Configuration

**Audit Results:**

| Service | User | CapDrop | ReadOnly | NoNewPrivs | Status |
|---------|------|---------|----------|------------|--------|
| alertmanager | nobody | ❌ None | ❌ false | ✅ true | ⚠️ Missing cap_drop |
| inlock-ai | 1001:1001 | ✅ ALL | ❌ false | ✅ true | ✅ Good |
| inlock-db | (default) | ✅ ALL | ❌ false | ❌ false | ⚠️ Missing no-new-privs |
| portainer | 1000:1000 | ✅ ALL | ❌ false | ✅ true | ✅ Good |
| oauth2-proxy | 65532 | ❌ None | ✅ true | ✅ true | ⚠️ Missing cap_drop |
| grafana | 472 | ✅ ALL | ❌ false | ✅ true | ✅ Good |
| postgres-exporter | 1000:1000 | ❌ None | ✅ true | ✅ true | ⚠️ Missing cap_drop |
| loki | 10001 | ✅ ALL | ❌ false | ✅ true | ✅ Good |
| node-exporter | nobody | ✅ ALL | ✅ true | ✅ true | ✅ Excellent |
| blackbox-exporter | (default) | ✅ ALL | ✅ true | ✅ true | ✅ Excellent |
| cadvisor | (default) | ❌ None | ✅ true | ✅ true | ⚠️ Missing cap_drop |

**Issues:**
- Alertmanager: Missing `cap_drop: ALL`
- Inlock-DB: Missing `no-new-privileges: true`
- OAuth2-Proxy: Missing `cap_drop: ALL`
- Postgres-Exporter: Missing `cap_drop: ALL`
- cAdvisor: Missing `cap_drop: ALL`

**Recommendation:** Update compose files to enforce consistent hardening.

---

### 🟢 LOW Priority Issues

#### 7. OAuth2-Proxy Endpoint Status

**Finding:** `/oauth2/start` returns HTTP 302 (redirect) - **This is CORRECT behavior**

**Previous Concern:** Documentation mentioned 404, but actual behavior is correct redirect to Auth0

**Status:** ✅ **NO ACTION NEEDED** - OAuth2-Proxy is functioning correctly

---

#### 8. Image Version Consistency

**Compose Files vs Running Containers:**

| Service | Compose File | Running (services-*) | Legacy (compose-*) | Status |
|---------|-------------|----------------------|-------------------|--------|
| Grafana | 11.1.0 | ✅ 11.1.0 | ❌ latest | ⚠️ Legacy running |
| Alertmanager | v0.27.0 | ✅ v0.27.0 | ❌ latest | ⚠️ Legacy running |
| cAdvisor | v0.49.1 | ✅ v0.49.1 | ❌ latest | ⚠️ Legacy running |
| Node Exporter | v1.8.2 | ✅ v1.8.2 | ❌ latest | ⚠️ Legacy running |
| Blackbox | v0.27.0 | ✅ v0.27.0 | ❌ latest | ⚠️ Legacy running |

**Assessment:** New `services-*` containers are using correct pinned versions. Legacy `compose-*` containers need cleanup.

---

## Security Score Breakdown

| Component | Documented | Actual | Discrepancy |
|-----------|------------|--------|-------------|
| Container Hardening | 9/10 | 7.5/10 | ⚠️ Some services missing cap_drop |
| Network Segmentation | 9/10 | 9/10 | ✅ Correct |
| Authentication | 8.5/10 | 8.5/10 | ✅ Correct |
| Secrets Management | 9/10 | 7/10 | 🔴 Hardcoded credential found |
| Image Security | 8/10 | 7/10 | ⚠️ Legacy containers with :latest |
| Service Health | N/A | 6/10 | 🔴 2 services failing |
| **Overall** | **8.5/10** | **7.5/10** | **-1.0 point** |

---

## Discrepancies Summary

### Critical Discrepancies

1. **Hardcoded Credential:** Documented as "removed" but still present in `tooling.yml:167`
2. **Service Failures:** Portainer and Blackbox Exporter not functioning
3. **Legacy Containers:** Old `compose-*` containers still running with unpinned images

### Medium Discrepancies

4. **Container Hardening:** Some services missing `cap_drop: ALL` or `no-new-privileges`
5. **Middleware Redundancy:** `admin-ip-allowlist` still referenced in routers

### Minor Discrepancies

6. **Documentation:** OAuth2-Proxy status incorrectly documented as 404 (actually 302 - correct)

---

## Recommended Actions

### Immediate (This Week)

1. **Fix Hardcoded Credential** 🔴
   ```bash
   # Update compose/services/tooling.yml line 167
   # Change: CLICKHOUSE_PASSWORD=dbbKUiRTs8knEbH5
   # To: CLICKHOUSE_PASSWORD=${POSTHOG_CLICKHOUSE_PASSWORD:?Required}
   ```

2. **Fix Blackbox Exporter Config Path** 🔴
   ```bash
   # Verify config path in stack.yml
   # Ensure it points to file, not directory
   ```

3. **Fix Portainer Configuration** 🔴
   ```bash
   # Check volume mounts and secrets
   # Verify /run/secrets/portainer exists
   ```

4. **Clean Up Legacy Containers** 🟡
   ```bash
   # Stop and remove old compose-* containers
   docker ps -a --filter "name=compose-" --format "{{.Names}}" | xargs docker rm -f
   ```

### Short Term (This Month)

5. **Complete Container Hardening** 🟡
   - Add `cap_drop: ALL` to alertmanager, oauth2-proxy, postgres-exporter, cadvisor
   - Add `no-new-privileges: true` to inlock-db

6. **Remove Redundant Middleware** 🟡
   - Remove `admin-ip-allowlist` from coolify and homarr routers

7. **Update Documentation** 🟢
   - Correct OAuth2-Proxy status (302 is correct, not 404)
   - Update security posture score to reflect actual state (7.5/10)

### Ongoing

8. **Regular Audits**
   - Monthly security posture reviews
   - Automated checks for hardcoded credentials
   - Container health monitoring

---

## Verification Commands

### Check for Hardcoded Credentials
```bash
grep -r "PASSWORD=" compose/services/*.yml | grep -v "\${" | grep -v "#"
grep -r "SECRET=" compose/services/*.yml | grep -v "\${" | grep -v "#"
```

### Check Container Health
```bash
docker ps --format "{{.Names}}\t{{.Status}}" | grep -E "(Restarting|Unhealthy|Error)"
```

### Check Legacy Containers
```bash
docker ps -a --filter "name=compose-" --format "{{.Names}}\t{{.Image}}"
```

### Verify Network Isolation
```bash
docker network inspect edge --format '{{range .Containers}}{{.Name}} {{end}}'
# Should only show: traefik, cockpit-proxy, inlock-ai
```

### Check Image Versions
```bash
docker ps --format "{{.Names}}\t{{.Image}}" | grep -E "(grafana|alertmanager|cadvisor)"
```

---

## Conclusion

The infrastructure maintains a **strong security foundation** with proper network segmentation, authentication controls, and most containers properly hardened. However, **critical issues** were identified that reduce the actual security score from the documented 8.5/10 to **7.5/10**.

**Priority Actions:**
1. Remove remaining hardcoded credential (CRITICAL)
2. Fix failing services (CRITICAL)
3. Clean up legacy containers (HIGH)
4. Complete container hardening (MEDIUM)

Once these issues are addressed, the security score should return to **8.5/10** or higher.

---

**Audit Completed:** December 24, 2025  
**Next Audit:** January 24, 2026  
**Auditor:** Infrastructure Security Review



