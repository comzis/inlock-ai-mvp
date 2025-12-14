# Mailu Mail Server Status

**Date:** 2025-12-13  
**Status:** ⚠️ **CONFIGURED BUT NOT RUNNING**

---

## Current Status

### ❌ Services Not Running
**No Mailu containers are currently running.**

**Expected Services:**
- `mailu-postgres` - Database
- `mailu-redis` - Cache/Queue
- `mailu-rspamd` - Spam filtering
- `mailu-admin` - Admin interface
- `mailu-front` - Web frontend (nginx)
- `mailu-imap` - IMAP server
- `mailu-postfix` - SMTP server

### ✅ Configuration Ready
- **Compose File:** `compose/mailu.yml` exists and is valid
- **Secrets:** All required secrets exist:
  - ✅ `mailu-secret-key` (32 bytes)
  - ✅ `mailu-admin-password` (33 bytes)
  - ✅ `mailu-db-password` (33 bytes)
- **Traefik Routes:** Configured for `mail.inlock.ai`
  - Admin UI: `https://mail.inlock.ai/admin` (OAuth2 protected)
  - Webmail: `https://mail.inlock.ai` (public with rate limiting)

### ⚠️ Current Behavior
- **mail.inlock.ai:** Returns HTTP 502 (Bad Gateway)
  - Traefik is routing to `mailu-front` service
  - Service is not running, so connection fails
- **mail.inlock.ai/admin:** Redirects to Auth0 (correct behavior when service is running)

---

## To Start Mailu

### Start All Services
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/mailu.yml --env-file .env up -d
```

### Check Status
```bash
docker compose -f compose/mailu.yml ps
```

### View Logs
```bash
docker compose -f compose/mailu.yml logs -f
```

### Check Specific Service
```bash
docker compose -f compose/mailu.yml logs mailu-front
docker compose -f compose/mailu.yml logs mailu-admin
```

---

## Services Overview

### mailu-postgres
- **Purpose:** Mailu database
- **Port:** 5432 (internal)
- **Volume:** `mailu_postgres_data`

### mailu-redis
- **Purpose:** Cache and queue management
- **Port:** 6379 (internal)
- **Volume:** `mailu_redis_data`

### mailu-rspamd
- **Purpose:** Spam filtering and antivirus
- **Port:** 11334 (internal)
- **Volume:** `mailu_rspamd_data`

### mailu-admin
- **Purpose:** Admin interface backend
- **Port:** 80 (internal)
- **Access:** Via `mailu-front` (nginx)

### mailu-front
- **Purpose:** Web frontend (nginx reverse proxy)
- **Port:** 80 (internal)
- **Access:** Via Traefik at `mail.inlock.ai`
- **Routes:**
  - `/admin` → `mailu-admin` (OAuth2 protected)
  - `/` → Webmail (public)

### mailu-imap
- **Purpose:** IMAP server
- **Ports:** 143 (IMAP), 993 (IMAPS)
- **Volume:** `mailu_mail_data`

### mailu-postfix
- **Purpose:** SMTP server
- **Ports:** 25 (SMTP), 465 (SMTPS), 587 (Submission)
- **Volume:** `mailu_mail_data`

---

## Network Configuration

### Networks
- **mail:** Internal Mailu network (bridge)
- **internal:** Shared internal network
- **mgmt:** Management network (for Traefik access)

### Traefik Integration
- Routes configured in `traefik/dynamic/routers.yml`
- Services configured in `traefik/dynamic/services.yml`
- OAuth2 middleware applied to `/admin` route

---

## DNS Requirements

### Required DNS Records
- **MX Record:** `inlock.ai` → `mail.inlock.ai` (priority 10)
- **A Record:** `mail.inlock.ai` → Server IP
- **SPF Record:** `v=spf1 mx ~all`
- **DMARC Record:** `_dmarc.inlock.ai` → `v=DMARC1; p=none; rua=mailto:admin@inlock.ai`

### DNS Setup Script
```bash
./scripts/setup-mailu-dns.sh
```

---

## Access Guide

### Admin Interface
1. Navigate to: `https://mail.inlock.ai/admin`
2. Authenticate via Auth0 (OAuth2)
3. Enter Mailu admin password (from secret file)
4. Access admin interface

### Webmail
1. Navigate to: `https://mail.inlock.ai`
2. Login with email credentials
3. Access webmail interface

### Mailu Admin Password
```bash
cat /home/comzis/apps/secrets-real/mailu-admin-password
```

---

## Troubleshooting

### Service Won't Start
1. Check logs: `docker compose -f compose/mailu.yml logs`
2. Verify secrets exist: `ls -la /home/comzis/apps/secrets-real/mailu-*`
3. Check network: `docker network ls | grep mail`
4. Verify volumes: `docker volume ls | grep mailu`

### 502 Bad Gateway
- **Cause:** `mailu-front` service not running
- **Fix:** Start Mailu services: `docker compose -f compose/mailu.yml up -d`

### Database Connection Issues
- Check `mailu-postgres` is running
- Verify `mailu-db-password` secret exists
- Check logs: `docker compose -f compose/mailu.yml logs mailu-postgres`

### OAuth2 Redirect Issues
- Verify Auth0 callback URL includes `https://mail.inlock.ai/admin`
- Check OAuth2-Proxy is running
- Verify Traefik middleware configuration

---

## Security Notes

✅ **Hardened Configuration:**
- All containers run with `no-new-privileges`
- Resource limits configured
- Network isolation (mail network)
- Secrets management via Docker secrets
- OAuth2 protection for admin interface

✅ **Best Practices:**
- Image pinning to SHA256 digests
- Secrets stored securely
- Admin interface protected by OAuth2
- Rate limiting on webmail

---

## Next Steps

1. **Start Mailu Services:**
   ```bash
   docker compose -f compose/mailu.yml --env-file .env up -d
   ```

2. **Verify Services:**
   ```bash
   docker compose -f compose/mailu.yml ps
   ```

3. **Check Logs:**
   ```bash
   docker compose -f compose/mailu.yml logs -f
   ```

4. **Test Access:**
   - Webmail: `https://mail.inlock.ai`
   - Admin: `https://mail.inlock.ai/admin`

5. **Verify DNS:**
   - Run DNS setup script if not already done
   - Verify MX, SPF, DMARC records

---

## Summary

**Status:** ⚠️ **Not Running - Ready to Start**

- ✅ Configuration complete
- ✅ Secrets present
- ✅ Traefik routes configured
- ❌ Services not started

**Action Required:** Start Mailu services with:
```bash
docker compose -f compose/mailu.yml --env-file .env up -d
```

---

**Last Updated:** 2025-12-13  
**Status:** Ready to Start

