# Mailu Email Stack - Implementation Complete

**Date:** December 11, 2025  
**Status:** ✅ All Recommendations Implemented  
**Reviewer:** DevOps Expert

---

## ✅ Completed Tasks

### 1. Image Pinning to SHA256 Digests ✅

**Status:** Complete  
**Files Modified:** `compose/mailu.yml`

All Mailu images have been updated to use:
- Correct image registry: `ghcr.io/mailu/*` (GitHub Container Registry)
- SHA256 digests for all images

**Images Updated:**
- `ghcr.io/mailu/nginx@sha256:1f4aa7762c0e4758cdb8c44a64b8f868a9ffea975089de38d29517390fd0d91b`
- `ghcr.io/mailu/postfix@sha256:5f92276dc5af71e130847fb43d6e4519b2c7f6c38b926b36374c63df8d52674f`
- `ghcr.io/mailu/dovecot@sha256:d089c32e3118479191ae17c3b973f014f1bdc0ebd5db192d1e4f7e41425803c5`
- `ghcr.io/mailu/rspamd@sha256:b37566e625c696f2922dd9fa6218160c6422cd4dc93762afc254843c12649ae4`
- `ghcr.io/mailu/admin@sha256:97bc9dc7259c485fcf20bf86809b17e3aee1b236662c2ebee1f2d6c825801400`
- `redis@sha256:ee64a64eaab618d88051c3ade8f6352d11531fcf79d9a4818b9b183d8c1d18ba`

**Verification:**
- ✅ Compose file validates successfully
- ✅ All images use digest format

### 2. Environment Variables Verification ✅

**Status:** Verified  
**Source:** Mailu 2.0 Documentation

Confirmed that Mailu 2.0 supports:
- `SECRET_KEY_FILE` - Path to file containing secret key
- `DB_PW_FILE` - Path to file containing database password
- `ADMIN_PW_FILE` - Path to file containing admin password

**Current Configuration:** ✅ Correct - no changes needed

### 3. DNS Automation Script ✅

**Status:** Complete  
**File Created:** `scripts/setup-mailu-dns.sh`

**Features:**
- Automates creation of MX, A/AAAA, SPF, and DMARC records via Cloudflare API
- Interactive prompts for server IP addresses
- Creates or updates existing DNS records
- Provides instructions for DKIM key setup (manual step after Mailu deployment)
- Uses `CLOUDFLARE_API_TOKEN` from `.env` file

**DNS Records Created:**
- A record: `mail.inlock.ai` → Server IPv4
- AAAA record: `mail.inlock.ai` → Server IPv6 (optional)
- MX record: `inlock.ai` → `mail.inlock.ai` (priority 10)
- SPF TXT record: `v=spf1 mx a:mail.inlock.ai ~all`
- DMARC TXT record: `_dmarc.inlock.ai` with quarantine policy

**Usage:**
```bash
cd /home/comzis/inlock-infra
./scripts/setup-mailu-dns.sh
```

### 4. Backup Script Documentation ✅

**Status:** Complete  
**File Modified:** `scripts/backup-volumes.sh`

**Changes:**
- Added explicit documentation of Mailu volumes
- Clearly marked `mailu_dkim_data` as CRITICAL (contains private keys)
- Listed all 5 Mailu volumes with descriptions

**Mailu Volumes Documented:**
- `mailu_mail_data`: Mail storage and user data
- `mailu_dkim_data`: DKIM private keys (CRITICAL)
- `mailu_rspamd_data`: Spam filter data and statistics
- `mailu_redis_data`: Cache and session storage
- `mailu_postgres_data`: Mailu database

**Note:** The backup script already backs up all Docker volumes, so Mailu volumes are included. Documentation now makes this explicit.

### 5. Prometheus Monitoring ✅

**Status:** Complete  
**File Modified:** `compose/prometheus/prometheus.yml`

**Added Scrape Configs:**

1. **Rspamd Metrics** (`mailu-rspamd` job)
   - Scrapes Rspamd metrics endpoint on port 11334
   - Provides spam filtering statistics

2. **SMTP Port Monitoring** (`blackbox-mailu-smtp` job)
   - Monitors SMTP ports: 25, 465, 587
   - Uses TCP connect probes via blackbox exporter

3. **IMAP Port Monitoring** (`blackbox-mailu-imap` job)
   - Monitors IMAP ports: 143, 993
   - Uses TCP connect probes via blackbox exporter

4. **Webmail/Admin UI Monitoring** (`blackbox-mailu-web` job)
   - Monitors HTTPS endpoints: `https://mail.inlock.ai` and `https://mail.inlock.ai/admin`
   - Uses HTTP 2xx probes via blackbox exporter

**Verification:**
- ✅ Prometheus config validated successfully

---

## 📋 Implementation Summary

### Files Modified
1. `compose/mailu.yml` - Updated images to use GHCR registry and SHA256 digests
2. `scripts/backup-volumes.sh` - Added explicit Mailu volume documentation
3. `compose/prometheus/prometheus.yml` - Added Mailu monitoring scrape configs

### Files Created
1. `scripts/setup-mailu-dns.sh` - DNS automation script (executable)

### Files Verified
1. `compose/mailu.yml` - Validates successfully
2. `compose/prometheus/prometheus.yml` - Validates successfully
3. Environment variables - Confirmed correct for Mailu 2.0

---

## 🧪 Pre-Deployment Checklist

Before deploying Mailu, verify:

- [x] Compose file validates
- [x] Images pinned to digests
- [x] Environment variables verified
- [x] DNS automation script created
- [x] Backup script updated
- [x] Prometheus monitoring added
- [ ] Port availability (25, 465, 587, 143, 993) - **Check before deployment**
- [ ] Secrets files exist and have correct permissions (600)
- [ ] Cloudflare API token has DNS edit permissions

---

## 🚀 Next Steps

### 1. Pre-Deployment Checks
```bash
# Check port availability
sudo netstat -tulpn | grep -E ':(25|465|587|143|993)'

# Verify secrets exist
ls -la /home/comzis/apps/secrets-real/mailu-*

# Verify secrets permissions
stat -c "%a %n" /home/comzis/apps/secrets-real/mailu-*
```

### 2. Deploy Mailu
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/mailu.yml --env-file .env up -d
```

### 3. Verify Services
```bash
# Check service status
docker compose -f compose/mailu.yml ps

# Check logs
docker compose -f compose/mailu.yml logs --tail 50

# Verify healthchecks
docker compose -f compose/mailu.yml ps | grep -E "(healthy|unhealthy)"
```

### 4. Configure DNS
```bash
# Run DNS automation script
./scripts/setup-mailu-dns.sh

# Verify DNS propagation
dig MX inlock.ai
dig A mail.inlock.ai
dig TXT inlock.ai | grep -E "(SPF|DMARC)"
```

### 5. Extract and Configure DKIM
```bash
# After Mailu is running, extract DKIM key
docker exec compose-mailu-admin-1 cat /dkim/inlock.ai.txt

# Add DKIM record to Cloudflare (manual or via script)
# Name: mail._domainkey.inlock.ai
# Content: [paste DKIM public key]
```

### 6. Test Email Functionality
```bash
# Test SMTP connection
telnet mail.inlock.ai 25

# Test IMAP connection
telnet mail.inlock.ai 143

# Test webmail access
curl -I https://mail.inlock.ai

# Test admin UI (should redirect to Auth0)
curl -I https://mail.inlock.ai/admin
```

### 7. Verify Monitoring
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job | contains("mailu"))'

# Verify blackbox probes
curl http://localhost:9090/api/v1/query?query=probe_success | jq '.data.result[] | select(.metric.instance | contains("mail.inlock.ai"))'
```

---

## 📊 Monitoring Dashboard

After deployment, create a Grafana dashboard for Mailu with:
- Rspamd spam detection rates
- Mail queue size
- SMTP/IMAP port connectivity
- Webmail/admin UI availability
- Email delivery success rates

---

## 🔄 Rollback Plan

If issues occur:

1. **Stop Mailu services:**
   ```bash
   docker compose -f compose/mailu.yml down
   ```

2. **Remove DNS records** (if needed):
   - Use Cloudflare dashboard or API
   - Remove MX, A, SPF, DMARC records

3. **Revert Traefik config** (if needed):
   - Remove Mailu routers from `traefik/dynamic/routers.yml`
   - Remove Mailu service from `traefik/dynamic/services.yml`
   - Reload Traefik

4. **Restore volumes** (if corrupted):
   ```bash
   scripts/restore-volumes.sh mailu_mail_data mailu_dkim_data
   ```

---

## ✅ Implementation Status

**All Recommendations:** ✅ **COMPLETE**

- [x] Pin images to SHA256 digests
- [x] Verify environment variables
- [x] Create DNS automation script
- [x] Update backup script documentation
- [x] Add Prometheus monitoring

**Ready for Deployment:** ✅ **YES**

---

**Last Updated:** December 11, 2025
