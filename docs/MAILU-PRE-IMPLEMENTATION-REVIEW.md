# Mailu Email Stack - Pre-Implementation Review

**Date:** December 11, 2025  
**Reviewer:** DevOps Expert  
**Status:** Pre-Implementation Review Complete

---

## Executive Summary

This document reviews the existing Mailu email stack configuration (`compose/mailu.yml`) against the TODO requirements and existing infrastructure patterns. The review identifies what's already complete, what needs improvement, and what's missing before deployment.

---

## Current State Analysis

### ✅ What's Already Complete

1. **Compose File Structure** (`compose/mailu.yml`)
   - ✅ All core services defined (front, postfix, imap, rspamd, admin, redis, postgres)
   - ✅ Networks configured (mail, mgmt, internal)
   - ✅ Secrets management via Docker secrets
   - ✅ Volumes defined for all persistent data
   - ✅ Security hardening applied (no-new-privileges, read-only, tmpfs, cap_drop)
   - ✅ Healthchecks configured for all services
   - ✅ Compose file validates successfully

2. **Traefik Configuration**
   - ✅ HTTP routers configured for admin UI and webmail
   - ✅ OAuth2 forward-auth middleware applied to admin UI
   - ✅ Service definition added to `services.yml`
   - ✅ IP allowlists configured

3. **Secrets Management**
   - ✅ Secret files created in `/home/comzis/apps/secrets-real/`
   - ✅ Example files provided for documentation

---

## Issues Identified

### 🔴 Critical Issues

1. **Image Pinning Missing**
   - **Issue:** Mailu images use tags (`mailu/*:2.0`) instead of SHA256 digests
   - **Risk:** Images can change unexpectedly, breaking deployments
   - **Requirement:** TODO item requires "pinned to digests"
   - **Action:** Need to fetch and pin all Mailu images to SHA256 digests
   - **Files:** `compose/mailu.yml` (lines 53, 98, 150, 198, 238, 283)

2. **Mailu Environment Variables May Be Incorrect**
   - **Issue:** Using `SECRET_KEY_FILE`, `DB_PW_FILE`, `ADMIN_PW_FILE` - need to verify these match Mailu's actual environment variable names
   - **Risk:** Services may not start if variable names are wrong
   - **Action:** Verify against Mailu documentation or test startup
   - **Reference:** Mailu typically uses `SECRET_KEY`, `DB_PASSWORD`, `ADMIN_PASSWORD` (not `_FILE` variants)

### 🟡 Medium Priority Issues

3. **Backup Script Documentation Only**
   - **Issue:** Backup script mentions Mailu volumes in comments but doesn't explicitly list them
   - **Current:** Comment says "Includes volumes for: ... mailu"
   - **Requirement:** TODO requires explicit backup of Mailu volumes
   - **Action:** Update backup script to explicitly include Mailu volumes
   - **File:** `scripts/backup-volumes.sh`

4. **Prometheus Monitoring Missing**
   - **Issue:** No Prometheus scrape configs for Mailu services
   - **Requirement:** TODO requires Prometheus exporters and dashboards
   - **Action:** Add scrape configs for Rspamd metrics and blackbox checks for mail ports
   - **File:** `compose/prometheus/prometheus.yml`

5. **DNS Automation Script Missing**
   - **Issue:** No script to automate DNS record creation (MX/SPF/DKIM/DMARC)
   - **Requirement:** TODO requires "Cloudflare automation scripts"
   - **Action:** Create script to provision DNS records via Cloudflare API
   - **File:** `scripts/setup-mailu-dns.sh` (new)

### 🟢 Low Priority / Nice to Have

6. **Redis Read-Only Filesystem**
   - **Issue:** Redis container has `read_only: true` but needs to write AOF (append-only file)
   - **Current:** Has volume mount for `/data` which should allow writes
   - **Status:** Likely OK, but should verify Redis can write to volume

7. **Postgres Security Exception**
   - **Issue:** Postgres has `no-new-privileges:false` (line 337)
   - **Reason:** Postgres requires this for proper operation
   - **Status:** Acceptable exception, documented

---

## Required Changes

### 1. Pin Images to SHA256 Digests

**Action:** Fetch current SHA256 digests for all Mailu images and update compose file.

**Images to pin:**
- `mailu/nginx:2.0`
- `mailu/postfix:2.0`
- `mailu/dovecot:2.0`
- `mailu/rspamd:2.0`
- `mailu/admin:2.0`
- `redis:7-alpine` (already using tag, should pin)

**Command to fetch digests:**
```bash
docker pull mailu/nginx:2.0
docker inspect mailu/nginx:2.0 | grep -i sha256
# Repeat for each image
```

### 2. Verify Mailu Environment Variables

**Action:** Check Mailu documentation or test container startup to verify environment variable names.

**Potential fixes:**
- If Mailu expects `SECRET_KEY` instead of `SECRET_KEY_FILE`, we may need to read secret file and pass as env var
- Or use Mailu's secret file support if available

### 3. Update Backup Script

**File:** `scripts/backup-volumes.sh`

**Current:** Generic volume backup (all volumes in `/var/lib/docker/volumes`)

**Required:** Explicitly document Mailu volumes:
- `mailu_mail_data`
- `mailu_dkim_data` (critical - contains private keys)
- `mailu_rspamd_data`
- `mailu_redis_data`
- `mailu_postgres_data`

**Note:** Current script backs up all volumes, so Mailu volumes are already included. Just need to document explicitly.

### 4. Add Prometheus Monitoring

**File:** `compose/prometheus/prometheus.yml`

**Add:**
- Scrape config for Rspamd metrics (port 11334)
- Blackbox exporter checks for SMTP ports (25, 465, 587)
- Blackbox exporter checks for IMAP ports (143, 993)

### 5. Create DNS Automation Script

**File:** `scripts/setup-mailu-dns.sh` (new)

**Functionality:**
- Create MX record: `inlock.ai` → `mail.inlock.ai` (priority 10)
- Create A/AAAA records: `mail.inlock.ai` → Server IP
- Create SPF TXT record: `v=spf1 mx a:mail.inlock.ai ~all`
- Create DMARC TXT record: `v=DMARC1; p=quarantine; rua=mailto:admin@inlock.ai`
- Extract DKIM key from Mailu and create TXT record (after Mailu is running)

**Dependencies:**
- Cloudflare API token (already in `.env` as `CLOUDFLARE_API_TOKEN`)
- `curl` or `jq` for API calls

---

## Configuration Review

### Network Configuration ✅
- **mail network:** Isolated for Mailu services
- **mgmt network:** For Traefik access to frontend/admin
- **internal network:** For database access
- **No edge network:** Correct - mail protocols exposed directly

### Security Hardening ✅
- **no-new-privileges:** Applied to all services (except postgres, which requires it)
- **read_only:** Applied where possible
- **tmpfs:** Used for temporary files
- **cap_drop:** ALL capabilities dropped, minimal cap_add
- **user:** Non-root (1000:1000)

### Port Exposure ✅
- **SMTP:** 25, 465, 587 (exposed directly, firewall-restricted)
- **IMAP:** 143, 993 (exposed directly, firewall-restricted)
- **HTTP:** Via Traefik on mgmt network

### Secrets Management ✅
- All secrets via Docker secrets
- Files in `/home/comzis/apps/secrets-real/`
- Proper file permissions (600)

---

## Testing Checklist

### Pre-Deployment
- [x] Compose file validates
- [ ] Verify port availability (25, 465, 587, 143, 993)
- [ ] Check Mailu environment variable names
- [ ] Pin images to digests
- [ ] Create DNS automation script

### Deployment
- [ ] Start Mailu services
- [ ] Verify all services healthy
- [ ] Check logs for errors
- [ ] Verify Traefik routing works
- [ ] Test admin UI access (should redirect to Auth0)
- [ ] Test webmail access

### Post-Deployment
- [ ] Configure DNS records (MX, A, SPF, DKIM, DMARC)
- [ ] Test SMTP connection
- [ ] Test IMAP connection
- [ ] Verify DKIM key generation
- [ ] Test email sending/receiving
- [ ] Verify backup includes Mailu volumes
- [ ] Verify Prometheus scrapes Mailu metrics

---

## Risk Assessment

### High Risk
1. **Mailu Environment Variables**
   - **Risk:** Services may not start if variable names are incorrect
   - **Mitigation:** Test startup, check Mailu logs, verify against documentation

2. **Port Conflicts**
   - **Risk:** Ports 25, 465, 587, 143, 993 may be in use
   - **Mitigation:** Check port availability before deployment

### Medium Risk
1. **Image Pinning**
   - **Risk:** Using tags instead of digests means images can change
   - **Mitigation:** Pin to digests before production deployment

2. **DNS Configuration**
   - **Risk:** Incorrect DNS records will break email delivery
   - **Mitigation:** Test DNS records before enabling mail sending

### Low Risk
1. **Backup Script**
   - **Risk:** Mailu volumes already backed up, just need documentation
   - **Mitigation:** Explicitly document volumes in backup script

---

## Recommendations

### Before Implementation
1. **Verify Mailu Environment Variables**
   - Check Mailu 2.0 documentation for correct variable names
   - Test with a single service first if unsure

2. **Pin Images to Digests**
   - Fetch current digests for all Mailu images
   - Update compose file before deployment

3. **Create DNS Script**
   - Build and test DNS automation script
   - Verify Cloudflare API token has DNS edit permissions

### During Implementation
1. **Deploy in Stages**
   - Start with services only (no port exposure)
   - Verify services start correctly
   - Then expose ports and configure Traefik
   - Finally configure DNS

2. **Monitor Closely**
   - Watch logs during startup
   - Verify healthchecks pass
   - Test each service individually

### After Implementation
1. **Verify Email Functionality**
   - Test sending email
   - Test receiving email
   - Verify DKIM signing works
   - Check spam scores

2. **Monitor and Alert**
   - Set up Prometheus alerts for mail queue size
   - Monitor delivery rates
   - Track spam detection rates

---

## Approval Status

**Review Status:** ⚠️ **Needs Changes Before Deployment**

**Required Actions:**
1. Pin Mailu images to SHA256 digests
2. Verify Mailu environment variable names
3. Create DNS automation script
4. Update backup script documentation
5. Add Prometheus monitoring configs

**Estimated Time:** 2-3 hours

**Next Steps:**
1. Address critical issues (image pinning, env vars)
2. Create missing scripts (DNS automation)
3. Update monitoring (Prometheus configs)
4. Final review and approval
5. Deploy and test

---

**Last Updated:** December 11, 2025
