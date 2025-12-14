# Consolidated TODO Analysis & Action Plan

## Summary

Only one TODO file exists: `/home/comzis/TODO_old.md` (dated Dec 11, 2025)

This contains infrastructure hardening and operational tasks. Many items overlap with work we just completed.

---

## 📊 Status Breakdown

### ✅ **Completed (Since Dec 11)**

#### 1. **Mailu Email Stack** - 100% DONE
- ✅ Created `compose/mailu.yml` with all core services
- ✅ Fixed Rspamd/Dovecot crashes
- ✅ Resolved subnet mismatches
- ✅ Enabled contact form email delivery
- ✅ Comprehensive documentation in `docs/reports/mailu/`

**Evidence:** 
- Merged commit: `c8fde05` - Mailu fixes
- 40+ Mailu documentation files
- Scripts: `setup-mailu-dns.sh`, `test-mailu-quick.sh`, `validate-mailu-secrets.sh`

#### 2. **Project Organization** - 100% DONE
- ✅ Cleaned scattered status reports (69 files organized)
- ✅ Consolidated server directories
- ✅ GitHub repo as single source of truth
- ✅ Removed duplicates (`inlock-infra`, `inlock-tooling`)

**Evidence:**
- Root directory: 40+ files → 3 files (95% cleaner)
- All reports in `docs/reports/` by topic
- Unified deployment workflow

#### 3. **Infrastructure Fixes** - PARTIALLY DONE
- ✅ Traefik Docker backend API version fixed
- ✅ Postgres exporter reading secrets correctly
- ✅ Coolify Traefik service updated

---

## 🔴 **Critical Priority (Do First)**

### 1. Security & Authentication
**Status:** 🔴 BLOCKING

**Missing pieces:**
- [ ] OAuth2-Proxy deployment incomplete (Auth0 client wiring)
- [ ] Most admin services lack Auth0 SSO
- [ ] Relying on IP allowlists alone (not secure)
- [ ] Docker socket directly exposed to Traefik

**Impact:** HIGH - Services are exposed without proper authentication

**Effort:** 2-3 days

**Action Required:**
1. Finish Auth0 client configuration
2. Deploy OAuth2-Proxy fully
3. Apply forward-auth middleware to ALL admin routers

### 2. n8n Crash Loop
**Status:** 🔴 BROKEN

**Issue:**
- [ ] Encryption key mismatch
- [ ] Missing `N8N_TRUSTED_PROXIES` configuration
- [ ] Service crash-looping

**Impact:** HIGH - Automation workflows down

**Effort:** 1-2 hours

**Action Required:**
1. Fix encryption key in `.env`
2. Add `N8N_TRUSTED_PROXIES=traefik`
3. Restart service

---

## 🟡 **High Priority (Do Soon)**

### 3. Container Hardening
**Status:** 🟡 PLANNED

**Remaining services:**
- [ ] NetBox
- [ ] Netdata  
- [ ] RPort
- [ ] GoAccess

**Hardening needed:**
- Read-only filesystems
- `no-new-privileges` flag
- Secrets via Docker secrets
- Drop unnecessary capabilities

**Impact:** MEDIUM - Security posture

**Effort:** 1 day

### 4. Network Security
**Status:** 🟡 PLANNED

**Tasks:**
- [ ] Remove direct Docker socket from Traefik
- [ ] Use socket-proxy only
- [ ] Remove admin service attachments to `edge` network
- [ ] Traefik as single ingress

**Impact:** MEDIUM - Attack surface reduction

**Effort:** 4-6 hours

### 5. IP Allowlist Normalization
**Status:** 🟡 INCONSISTENT

**Tasks:**
- [ ] Centralize IP allowlist configuration
- [ ] Apply consistently across all Traefik middlewares
- [ ] Sync with firewall rules
- [ ] Automate allowlist updates

**Impact:** MEDIUM - Security consistency

**Effort:** 1 day

---

## 🟢 **Medium Priority (Schedule)**

### 6. Secret Management
**Status:** 🟢 PLANNED

**Tasks:**
- [ ] Integrate `sops` + `age`
- [ ] Encrypt `.env` files in Git
- [ ] Create decrypt helper scripts
- [ ] Document secret rotation

**Impact:** MEDIUM - Long-term security

**Effort:** 2 days

### 7. Monitoring Gaps
**Status:** 🟢 PARTIAL

**Missing:**
- [ ] Prometheus configs for new services
- [ ] Dashboards for NetBox, Netdata, etc.
- [ ] Blackbox checks for Mailu ports (25/465/587/993)
- [ ] Coolify-soketi healthcheck resolution

**Impact:** LOW - Visibility

**Effort:** 2-3 days

### 8. Backup Improvements
**Status:** 🟢 OUTDATED

**Tasks:**
- [ ] Update backup scripts for new volumes
- [ ] Include Mailu volumes (mail state, DKIM keys, Rspamd)
- [ ] Add restore validation
- [ ] Test backup/restore flow

**Impact:** MEDIUM - Disaster recovery

**Effort:** 1 day

### 9. SSH Hardening
**Status:** 🟢 PLANNED

**Tasks:**
- [ ] Disable SSH password auth
- [ ] Ensure fail2ban is running
- [ ] Document in security guides
- [ ] Test Tailscale-only SSH

**Impact:** LOW - Already using keys

**Effort:** 2 hours

---

## 🎯 **Recommended 30-Day Roadmap**

### **Week 1: Critical Fixes**
```
Day 1-2: Fix n8n (quick win)
Day 3-5: Complete OAuth2-Proxy + Auth0 SSO
        - Configure Auth0 clients
        - Deploy OAuth2-Proxy
        - Apply to all admin services
        - Run verification scripts
```

### **Week 2: Security Hardening**
```
Day 6-7: Remove Docker socket from Traefik
Day 8-9: Normalize IP allowlists
Day 10-11: Harden NetBox, Netdata, RPort, GoAccess
         - Read-only FS
         - Drop capabilities
         - Add secrets
```

### **Week 3: Infrastructure**
```
Day 12-14: Implement sops + age encryption
Day 15-17: Update backup scripts
          - Add Mailu volumes
          - Test restores
          - Automate
```

### **Week 4: Monitoring & Docs**
```
Day 18-20: Add Prometheus configs
          - New service dashboards
          - Blackbox checks
Day 21-23: Update documentation
          - ADMIN-ACCESS-GUIDE.md
          - infra.md
          - Security guides
Day 24-30: Buffer for testing & fixes
```

---

## 📋 **Quick Wins (Do Today)**

These are high-impact, low-effort tasks:

### 1. ✅ Mark TODO as Complete
```bash
cd /home/comzis
mv TODO_old.md TODO_archive_2024-12-14.md
# Create new TODO.md with remaining tasks
```

### 2. 🔧 Fix n8n (1-2 hours)
```bash
# Update n8n environment
cd /home/comzis/inlock
# Add to compose file or env:
N8N_TRUSTED_PROXIES=traefik
# Fix encryption key
# Restart: docker compose restart n8n
```

### 3. 📝 Run Verification Scripts
```bash
cd /home/comzis/inlock/scripts
./test-access-control.sh
./verify-ingress-hardening.sh
./verify-inlock-deployment.sh
# Review output
```

---

## 💡 **My Recommendations**

### **Immediate Actions:**
1. **Archive old TODO** - Rename to reflect completion date
2. **Create new TODO.md** - With remaining prioritized tasks
3. **Fix n8n** - Unblock automation workflows
4. **Run verification scripts** - Assess current security posture

### **This Week:**
5. **Complete OAuth2 deployment** - Highest security impact
6. **Document what we've completed** - Update guides with new structure

### **Next Steps:**
7. **Create GitHub issues** - Track remaining work systematically
8. **Set up project board** - Visualize progress
9. **Schedule weekly reviews** - Maintain momentum

---

## 🎬 **What Would You Like Me To Do?**

**A. Create Updated TODO.md**
- Archive old file
- Create new prioritized task list
- Add completion tracking

**B. Fix n8n Now**
- Update configuration
- Restart service
- Verify working

**C. Run Security Audit**
- Execute verification scripts
- Generate report
- Identify gaps

**D. Plan OAuth2 Deployment**
- Document Auth0 client setup
- Create deployment guide
- Prepare configuration

**E. All of the Above**
- Complete workflow
- Set you up for success

**Which would you prefer?**
