# Critical Security Fixes Required

**Current Score: 6/10**  
**Target Score: 10/10**

## Issues Identified

### 1. 🔴 CRITICAL: Docker Socket Exposure
**Status**: ✅ FIXED (removed direct mount, using socket-proxy)

**Issue**: Traefik was mounting `/var/run/docker.sock` directly, giving full Docker control.

**Fix Applied**:
- Removed direct socket mount from Traefik
- Traefik now uses `DOCKER_HOST=tcp://docker-socket-proxy:2375`
- Socket proxy limits Docker API access

**Action Required**: Restart Traefik to apply changes

---

### 2. 🔴 CRITICAL: Ingress Auth Gaps
**Status**: ⚠️ NEEDS FIX

**Issue**: All admin routers rely only on IP allowlist, no OAuth2/SSO/MFA.

**Current State**:
- `portainer-auth` middleware exists but unused
- All admin services (Traefik, Portainer, Grafana, n8n, Coolify, Homarr, Cockpit) only use `allowed-admins` IP middleware
- Anyone on allowed IP can access without additional auth

**Fix Required**:
```yaml
# In traefik/dynamic/routers.yml
# Add portainer-auth middleware to all admin routers:

portainer:
  middlewares:
    - secure-headers
    - portainer-auth  # ADD THIS
    - allowed-admins
    - mgmt-ratelimit

grafana:
  middlewares:
    - secure-headers
    - portainer-auth  # ADD THIS
    - allowed-admins
    - mgmt-ratelimit

n8n:
  middlewares:
    - n8n-headers
    - portainer-auth  # ADD THIS
    - allowed-admins

# ... same for coolify, homarr, cockpit, dashboard
```

**Prerequisites**:
- OAuth2-Proxy must be running and accessible at `https://auth.inlock.ai/check`
- Verify OAuth2-Proxy configuration

---

### 3. 🟡 HIGH: Network Segmentation
**Status**: ⚠️ NEEDS FIX

**Issue**: Admin services attached to public `edge` network, increasing attack surface.

**Current State**:
- `compose-n8n-1`: edge network
- `compose-grafana-1`: edge network
- `compose-portainer-1`: edge network
- `compose-coolify-1`: edge network
- `compose-homarr-1`: edge network

**Fix Required**:
Remove `edge` network from admin services, keep only:
- `mgmt` network (for Traefik access)
- `internal` network (for database access where needed)

**Example Fix**:
```yaml
# In compose/stack.yml or respective compose files
grafana:
  networks:
    - mgmt  # Remove 'edge'
    - internal  # Keep if needed for DB access

portainer:
  networks:
    - mgmt  # Remove 'edge'
```

**Note**: Traefik should be the ONLY service on `edge` network. All other services access via Traefik.

---

### 4. 🟡 HIGH: n8n Stability & Secrets
**Status**: ✅ VERIFIED (no errors in logs)

**Issue**: Encryption key mismatches and proxy trust errors.

**Current State**:
- `N8N_ENCRYPTION_KEY_FILE` configured
- `N8N_TRUSTED_PROXIES` set to `loopback,linklocal,uniquelocal`
- No errors in recent logs

**Action**: Monitor for encryption key issues. If they recur:
1. Verify encryption key secret file exists and is correct
2. Ensure key is consistent across restarts
3. Check `N8N_TRUSTED_PROXIES` matches actual proxy setup

---

### 5. 🟡 MEDIUM: SSH & fail2ban
**Status**: ⚠️ PARTIAL

**Issue**: Password authentication enabled, fail2ban status unclear.

**Current State**:
- fail2ban process is running (PID 3808527)
- Cannot verify SSH config without sudo
- Previous review indicated password auth was enabled

**Fix Required**:
```bash
# Option 1: Disable password auth (recommended)
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Option 2: Ensure fail2ban is monitoring SSH
sudo fail2ban-client status sshd
# If not active:
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

---

### 6. 🟡 MEDIUM: Grafana Dashboard Provisioning
**Status**: ⚠️ NEEDS FIX

**Issue**: Dashboards not auto-loading due to stale volume metadata.

**Current State**:
- Dashboard JSON files exist in `grafana/dashboards/`
- Grafana volume may have conflicting UIDs
- `/var/lib/grafana/dashboards/` directory doesn't exist in container

**Fix Options**:

**Option A: Reset Grafana Volume** (loses custom dashboards)
```bash
docker compose -f compose/stack.yml --env-file .env stop grafana
docker volume rm compose_grafana_data
docker compose -f compose/stack.yml --env-file .env up -d grafana
```

**Option B: Manual Import** (preserves data)
1. Access Grafana UI
2. Import dashboards manually via UI
3. Fix UID conflicts if they occur

**Option C: Fix Provisioning** (recommended)
1. Check Grafana provisioning config
2. Verify dashboard UIDs are unique
3. Ensure provisioning directory is mounted correctly

---

### 7. 🟡 MEDIUM: Alert Delivery
**Status**: ⚠️ NEEDS VERIFICATION

**Issue**: Alertmanager forwards to n8n webhook, but no confirmed workflow exists.

**Current State**:
- Alertmanager configured: `http://n8n:5678/webhook/alertmanager`
- Need to verify n8n workflow exists and processes alerts

**Fix Required**:
1. Log into n8n
2. Verify webhook workflow exists at `/webhook/alertmanager`
3. Test with a test alert
4. Configure workflow to send to Slack/Email/PagerDuty

**If workflow doesn't exist**:
- Create n8n workflow with webhook trigger
- Add alert processing logic
- Configure notification channels

---

### 8. 🟢 LOW: Documentation Drift
**Status**: ⚠️ NEEDS UPDATE

**Issue**: Documentation mentions security features that aren't effectively in place.

**Fix Required**:
1. Update `CURRENT-SECURITY-STATUS.md` with actual state
2. Update `SECURITY-REVIEW-2025-12-11.md` with corrected score (6/10)
3. Document actual fail2ban status
4. Document actual network segmentation
5. Remove references to features that aren't working

---

## Implementation Priority

### Immediate (Before Next Review)
1. ✅ Remove Docker socket mount (DONE)
2. ⚠️ Enable OAuth2 on admin routers
3. ⚠️ Fix network segmentation
4. ⚠️ Verify SSH/fail2ban configuration

### Short Term (This Week)
5. ⚠️ Fix Grafana dashboard provisioning
6. ⚠️ Verify and fix alert delivery
7. ⚠️ Update documentation

### Long Term (Ongoing)
8. Monitor n8n stability
9. Regular security audits
10. Keep dependencies updated

---

## Quick Fix Commands

### Restart Traefik (apply socket-proxy fix)
```bash
docker compose -f compose/stack.yml --env-file .env restart traefik
```

### Verify OAuth2-Proxy
```bash
curl -k https://auth.inlock.ai/check
```

### Check Network Isolation
```bash
docker network inspect edge --format '{{range .Containers}}{{.Name}} {{end}}'
# Should only show: traefik, inlock-ai (public services)
```

### Verify fail2ban
```bash
sudo fail2ban-client status sshd
```

---

## Expected Score After Fixes

| Issue | Current | After Fix | Impact |
|-------|---------|-----------|--------|
| Docker Socket | 0/10 | 10/10 | +1.0 |
| Ingress Auth | 3/10 | 10/10 | +0.7 |
| Network Seg | 5/10 | 10/10 | +0.5 |
| SSH/fail2ban | 5/10 | 10/10 | +0.5 |
| Grafana | 7/10 | 10/10 | +0.3 |
| Alerts | 5/10 | 10/10 | +0.5 |
| **TOTAL** | **6/10** | **10/10** | **+4.0** |

---

**Last Updated**: December 11, 2025  
**Next Review**: After implementing critical fixes

