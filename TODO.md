# Inlock AI Infrastructure TODO

*Last Updated: 2024-12-14*

## 🔴 Critical (This Week)

### 1. Fix n8n Crash Loop
- [ ] Update n8n environment variables
  - Add `N8N_TRUSTED_PROXIES=traefik`
  - Fix encryption key mismatch
- [ ] Restart n8n service
- [ ] Verify workflow execution
- **Priority:** URGENT | **Effort:** 1-2 hours

### 2. Complete OAuth2-Proxy + Auth0 SSO
- [ ] Finish Auth0 client configuration
- [ ] Deploy OAuth2-Proxy fully
- [ ] Apply forward-auth middleware to ALL admin services
- [ ] Run verification scripts
- **Priority:** CRITICAL (security) | **Effort:** 2-3 days

## 🟡 High Priority (Next 2 Weeks)

### 3. Docker Socket Hardening
- [ ] Remove direct Docker socket mount from Traefik
- [ ] Configure socket-proxy as only access point
- **Priority:** HIGH | **Effort:** 4-6 hours

### 4. Normalize IP Allowlists
- [ ] Centralize IP allowlist configuration
- [ ] Apply consistently across Traefik middlewares
- **Priority:** HIGH | **Effort:** 1 day

### 5. Container Hardening
- [ ] NetBox, Netdata, RPort, GoAccess
- [ ] Read-only FS, no-new-privileges, Docker secrets
- **Priority:** HIGH | **Effort:** 1 day

## ✅ Recently Completed (Dec 2024)

### Mailu Email Stack (100%)
- ✅ Created compose/mailu.yml, fixed crashes, DKIM/SPF/DMARC

### Project Organization (100%)  
- ✅ Reorganized 69 files, GitHub as source of truth, 95% cleaner

See TODO_archive_2024-12-14.md for full history.
