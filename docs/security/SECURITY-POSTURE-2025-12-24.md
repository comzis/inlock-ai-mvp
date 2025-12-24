# Security Posture Report

**Date:** December 24, 2025  
**Overall Score:** 8.5/10  
**Status:** Production ready - All critical issues resolved. inlock-ai rebuilt from trusted source.

---

## Executive Summary

The Inlock AI infrastructure maintains a strong security posture with solid network segmentation and authentication controls. All admin services are protected by OAuth2 forward-auth via Auth0, IP allowlisting, and rate limiting. Recent improvements include removal of all hardcoded credentials, image version pinning, blackbox exporter path fix, cleanup of all legacy `compose-*` containers, DB password rotation with secret management, and **inlock-ai image rebuilt from trusted source** (malicious script removed). Optional container hardening improvements remain for some services.

---

## ✅ Security Strengths

### 1. Container Hardening (8/10)
- ✅ Most containers drop ALL capabilities (`cap_drop: ALL`)
- ✅ `no-new-privileges: true` enforced on the majority of services
- ✅ Non-root users (1000:1000, 1001:1001) where applicable
- ✅ Read-only filesystems on monitoring services
- ✅ Resource limits configured
- ✅ Health checks on services (blackbox now correctly mounted; inlock-ai health still red)
- ⚠️ Remaining targets: cap_drop for alertmanager, oauth2-proxy, postgres-exporter, cadvisor; `no-new-privileges` for inlock-db

### 2. Network Segmentation (9/10)
- ✅ Only Traefik and Cockpit-Proxy on public `edge` network
- ✅ Admin services isolated on `mgmt` network
- ✅ Internal services on `internal` network
- ✅ Docker socket proxy in place (no direct socket mounts)
- ✅ Mail services on dedicated `mail` network

### 3. Authentication & Authorization (8.5/10)
- ✅ OAuth2 forward-auth enabled on all admin routers
- ✅ Auth0 integration via OAuth2-Proxy
- ✅ IP allowlist middleware as secondary layer
- ✅ Secure headers middleware applied
- ✅ Rate limiting on admin services (50 req/min, 100 burst)
- ⚠️ OAuth2-Proxy `/check` endpoint returns 404 (needs verification)

### 4. Secrets Management (9/10)
- ✅ Docker secrets used (not environment variables)
- ✅ Secrets stored outside repo (`/home/comzis/apps/secrets-real/`)
- ✅ Inlock DB password rotated and moved to secrets file (`/home/comzis/apps/secrets-real/inlock-db-password`)
- ✅ Environment variable templates in `env.example`
- ✅ inlock-ai image rebuilt from trusted source (malicious script removed, image ID: 152076b99ff9)

### 5. Image Security (8.5/10)
- ✅ Most images pinned to specific versions
- ✅ inlock-ai rebuilt from trusted source (Dockerfile at `/opt/inlock-ai-secure-mvp/Dockerfile`)
- ✅ Traefik: v3.6.4
- ✅ Prometheus: v3.8.0
- ✅ Grafana: 11.1.0
- ✅ Alertmanager: v0.27.0
- ⚠️ Some tooling services still use `:latest` (PostHog, Homarr, Coolify)

---

## ⚠️ Areas for Improvement

### 1. OAuth2-Proxy Verification (Medium Priority)
**Issue:** `/oauth2/start` returns 302 redirect (correct); continue to spot-check forward-auth on admin services.  
**Impact:** None observed; keep periodic verification.

### 2. Image Version Pinning (Low Priority)
**Issue:** Some tooling services use `:latest` tags  
**Impact:** Potential for unexpected updates  
**Action Required:**
- Pin PostHog images to specific version
- Pin Homarr, Coolify, Socat to specific versions
- Document update process

### 3. Tooling Stack Security (Medium Priority)
**Issue:** Strapi exposes port 1337 directly  
**Impact:** Service not behind Traefik reverse proxy  
**Action Required:**
- Move Strapi behind Traefik
- Remove direct port exposure
- Apply same security middlewares as other admin services

### 4. Documentation Consolidation (Low Priority)
**Issue:** Multiple security status documents with conflicting scores  
**Impact:** Confusion about actual security state  
**Action Required:**
- Archive outdated security review documents
- Maintain single source of truth (this document)
- Update references in other docs

---

## Security Configuration Details

### Admin Services Protection

All admin services use the following middleware chain:
1. **secure-headers** - HSTS, CSP, frame options, etc.
2. **admin-forward-auth** - OAuth2/Auth0 authentication
3. **allowed-admins** - IP allowlist (Tailscale + approved IPs)
4. **mgmt-ratelimit** - Rate limiting (50 req/min, 100 burst)

**Protected Services:**
- Traefik Dashboard (`traefik.inlock.ai`)
- Portainer (`portainer.inlock.ai`)
- Grafana (`grafana.inlock.ai`)
- n8n (`n8n.inlock.ai`)
- Coolify (`deploy.inlock.ai`)
- Homarr (`dashboard.inlock.ai`)
- Cockpit (`cockpit.inlock.ai`)

### Network Architecture

```
Public Internet
    ↓
Traefik (edge network)
    ↓
OAuth2-Proxy (mgmt network)
    ↓
Admin Services (mgmt network only)
```

**Network Isolation:**
- `edge`: Traefik, Cockpit-Proxy (public-facing)
- `mgmt`: All admin services (OAuth2-Proxy, Portainer, Grafana, n8n, etc.)
- `internal`: Databases, internal services
- `mail`: Mailu services
- `socket-proxy`: Docker socket proxy

### Secrets Management

**Secret Files (outside repo):**
- `/home/comzis/apps/secrets-real/traefik-dashboard-users.htpasswd`
- `/home/comzis/apps/secrets-real/positive-ssl.crt`
- `/home/comzis/apps/secrets-real/positive-ssl.key`
- `/home/comzis/apps/secrets-real/portainer-admin-password`
- `/home/comzis/apps/secrets-real/n8n-db-password`
- `/home/comzis/apps/secrets-real/n8n-encryption-key`
- `/home/comzis/apps/secrets-real/grafana-admin-password`
- `/home/comzis/apps/secrets-real/mailu-*` (various Mailu secrets)

**Environment Variables:**
- Templates in `env.example`
- Actual values in `/home/comzis/deployments/.env.*` (not in repo)

---

## Security Score Breakdown

| Component | Score | Notes |
|-----------|-------|-------|
| Container Hardening | 8.0/10 | Most hardened; add cap_drop to alertmanager/oauth2-proxy/postgres-exporter/cadvisor; `no-new-privileges` for inlock-db |
| Network Segmentation | 9.0/10 | Proper isolation (edge/mgmt/internal/socket-proxy) |
| Authentication | 8.5/10 | OAuth2 forward-auth + IP allowlist; `/oauth2/start` 302 OK |
| Secrets Management | 9.0/10 | Hardcoded creds removed; env + secrets in place; inlock DB password rotated to secret file |
| Image Security | 8.0/10 | Pinned core images; review remaining tooling `:latest`; legacy compose-* containers removed; inlock-ai image still needs trusted rebuild |
| Documentation | 7.5/10 | Posture doc aligned; continue consolidation |
| Service Health | 8.0/10 | All services healthy; blackbox fixed; legacy compose-* containers cleaned up |
| **Overall** | **8.0/10** | Production ready with follow-up hardening/cleanup (pending trusted rebuild of inlock-ai) |

---

## Recent Security Improvements

### December 24, 2025
- ✅ Removed hardcoded ClickHouse password from `tooling.yml` (uses `${POSTHOG_CLICKHOUSE_PASSWORD:?Required}`)
- ✅ Rotated ClickHouse password in `/home/comzis/deployments/.env.tooling` and documented in `env.example`
- ✅ Fixed path issues in `stack.yml` (Traefik, Prometheus, Alertmanager, Blackbox exporter config paths)
- ✅ Recreated Blackbox exporter with correct mount
- ✅ Pinned image versions (Grafana, Alertmanager, cAdvisor, Node Exporter, Blackbox Exporter)
- ✅ Verified all admin services use OAuth2 forward-auth
- ✅ Cleaned up legacy `compose-*` containers (traefik/prometheus/n8n removed)
- ✅ Inlock DB password rotated to secret file; compose uses POSTGRES_PASSWORD_FILE; `env.example` and `compose/.env` no longer hold the real secret
- ⚠️ Inlock-ai image showed malicious download (`immunify360firewall.sh`) — image must be rebuilt from trusted source and redeployed

### Previous Improvements
- ✅ Docker socket proxy implementation
- ✅ Network segmentation (removed edge network from admin services)
- ✅ OAuth2 forward-auth on all admin routers
- ✅ Container hardening (cap_drop, no-new-privileges, non-root users)

---

## Next Steps

### Immediate (This Week)
1. Verify OAuth2-Proxy functionality
2. Test forward-auth on all admin services
3. Document any issues found

### Short Term (This Month)
1. Pin remaining image versions (PostHog, Homarr, Coolify)
2. Move Strapi behind Traefik
3. Consolidate security documentation

### Ongoing
1. Regular security reviews (monthly)
2. Dependency updates (Docker images, system packages)
3. Security documentation updates
4. Penetration testing considerations

---

## Verification Commands

### Check OAuth2-Proxy
```bash
docker logs compose-oauth2-proxy-1 --tail 50
curl -v https://auth.inlock.ai/oauth2/start
```

### Verify Network Isolation
```bash
docker network inspect edge --format '{{range .Containers}}{{.Name}} {{end}}'
# Should only show: compose-traefik-1 compose-cockpit-proxy-1
```

### Check Container Security
```bash
docker inspect compose-grafana-1 | jq '.[0].HostConfig.SecurityOpt'
docker inspect compose-grafana-1 | jq '.[0].HostConfig.CapDrop'
docker inspect compose-grafana-1 | jq '.[0].Config.User'
```

### Verify Secrets
```bash
# Check no hardcoded secrets in compose files
grep -r "PASSWORD=" compose/services/*.yml | grep -v "\${"
grep -r "SECRET=" compose/services/*.yml | grep -v "\${"
```

---

## Reference Documents

- **Security Rules:** `.cursorrules-security`
- **Container Hardening:** `docs/security/CONTAINER-HARDENING.md`
- **Ingress Hardening:** `docs/security/INGRESS-HARDENING.md`
- **Network Security:** `docs/network-security.md`
- **Secret Management:** `docs/SECRET-MANAGEMENT.md`

---

**Last Updated:** December 24, 2025  
**Next Review:** January 24, 2026  
**Maintainer:** Infrastructure Team
