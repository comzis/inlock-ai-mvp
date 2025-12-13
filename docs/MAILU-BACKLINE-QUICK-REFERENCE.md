# Mailu Backline Quick Reference - Front/Admin/Redis Issues

**Date:** 2025-12-13  
**Purpose:** Quick troubleshooting snippets and fixes for Mailu support swarm  
**Status:** 🔄 Active Support

---

## 🚨 Critical Issues Checklist

### mailu-front (Restarting)
- [ ] Check nginx logs write permissions
- [ ] Verify tmpfs mounts (`/var/lib/nginx`)
- [ ] Confirm module load capabilities
- [ ] Test nginx config generation

### mailu-admin (Restarting)
- [ ] Verify setgroups capability
- [ ] Check admin startup logs
- [ ] Confirm DB/Redis connectivity
- [ ] Verify secret file access

### mailu-redis (Starting)
- [ ] Check volume permissions (`/data`)
- [ ] Verify user switch capabilities
- [ ] Confirm appendonly file writes

---

## ⚡ Quick Fixes

### Front Service: Nginx Logs & Modules

**Issue:** Cannot write to `/var/lib/nginx/logs` or load modules

**Fix 1: Add tmpfs for nginx logs**
```yaml
# In compose/mailu.yml - mailu-front service
tmpfs:
  - /tmp
  - /var/run
  - /var/lib/nginx  # ✅ Already added
```

**Fix 2: Minimal capabilities (if Fix 1 insufficient)**
```yaml
# Remove cap_drop: ALL or ensure these caps exist:
cap_add:
  - NET_BIND_SERVICE
  - CHOWN
  - SETGID
  - SETUID
  - DAC_OVERRIDE  # For file access
security_opt:
  - no-new-privileges:false  # ✅ Already set
```

**One-liner permission fix:**
```bash
# Not needed if tmpfs is mounted, but if using volume:
docker exec compose-mailu-front-1 chown -R nginx:nginx /var/lib/nginx
```

**Verify:**
```bash
docker compose -f compose/mailu.yml exec mailu-front ls -la /var/lib/nginx
# Should show writable directory
```

---

### Admin Service: Setgroups & Startup

**Issue:** Admin fails to start, needs setgroups capability

**Fix 1: Ensure setgroups allowed**
```yaml
# In compose/mailu.yml - mailu-admin service
# ✅ Already has: security_opt: no-new-privileges:false
# ✅ Already has: cap_add includes SETGID, SETUID

# If still failing, ensure no cap_drop: ALL:
# Remove this line if present:
# cap_drop: ALL
```

**Fix 2: Check startup logs pattern**
```bash
docker compose -f compose/mailu.yml logs mailu-admin | grep -iE "error|fail|permission|setgroups"
```

**Expected startup log pattern:**
```
[INFO] Starting Mailu admin
[INFO] Database connection: OK
[INFO] Redis connection: OK
```

**Failure pattern:**
```
[ERROR] Permission denied
[ERROR] setgroups: Operation not permitted
[ERROR] Cannot write to /tmp
```

---

### Redis Service: User Switch & Volume

**Issue:** Redis cannot switch to redis user or write to `/data`

**Fix 1: Minimal capabilities for user switch**
```yaml
# In compose/mailu.yml - mailu-redis service
# ✅ Already has:
cap_add:
  - SETGID
  - SETUID
  - CHOWN
security_opt:
  - no-new-privileges:false  # ✅ Already set
```

**Fix 2: Volume permissions (if using named volume)**
```bash
# One-liner fix:
docker compose -f compose/mailu.yml exec mailu-redis chown -R redis:redis /data

# Or recreate volume:
docker volume rm mailu_redis_data
docker compose -f compose/mailu.yml up -d mailu-redis
```

**Verify:**
```bash
docker compose -f compose/mailu.yml exec mailu-redis ls -la /data
# Should show redis:redis ownership
```

---

## 🔧 Compose Snippets (Ready to Use)

### Front Service - Minimal Security Config
```yaml
mailu-front:
  # ... other config ...
  tmpfs:
    - /tmp
    - /var/run
    - /var/lib/nginx  # ✅ Critical for logs
  cap_add:
    - NET_BIND_SERVICE
    - CHOWN
    - SETGID
    - SETUID
    - DAC_OVERRIDE  # Add if file access issues
  security_opt:
    - no-new-privileges:false  # ✅ Allow privilege dropping
  # NO cap_drop: ALL  # ✅ Don't drop all caps
  # NO read_only: true  # ✅ Disabled (needs write access)
```

### Admin Service - Startup Fix
```yaml
mailu-admin:
  # ... other config ...
  tmpfs:
    - /tmp
    - /var/run
  cap_add:
    - SETGID
    - SETUID
    - CHOWN
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:false  # ✅ Critical for setgroups
  # NO cap_drop: ALL  # ✅ Don't drop all caps if startup fails
  # NO read_only: true  # ✅ Disabled
```

### Redis Service - User Switch Fix
```yaml
mailu-redis:
  # ... other config ...
  tmpfs:
    - /tmp
  volumes:
    - mailu_redis_data:/data
  cap_add:
    - SETGID  # ✅ For user switching
    - SETUID  # ✅ For user switching
    - CHOWN   # ✅ For volume ownership
  security_opt:
    - no-new-privileges:false  # ✅ Allow user switch
  # NO cap_drop: ALL  # ✅ Already removed
  # NO read_only: true  # ✅ Already disabled
```

---

## 📋 Environment/Secret Cheat Sheet

### Critical Mailu Environment Variables

```yaml
# Required - Secret Files
SECRET_KEY_FILE=/run/secrets/mailu-secret-key
DB_PW_FILE=/run/secrets/mailu-db-password
ADMIN_PW_FILE=/run/secrets/mailu-admin-password  # Admin only

# Required - Database
DB_HOST=mailu-postgres
DB_USER=mailu
DB_NAME=mailu

# Required - Redis
REDIS_HOST=mailu-redis
REDIS_PORT=6379

# Required - Domain
DOMAIN=inlock.ai
HOSTNAMES=mail.inlock.ai

# Optional but Important
MESSAGE_SIZE_LIMIT=52428800  # 50MB
POSTMASTER=admin@inlock.ai
LOG_LEVEL=INFO
TLS_FLAVOR=mail-letsencrypt
SUBNET=172.18.0.0/16
TZ=UTC
```

**Verify secrets exist:**
```bash
ls -la /home/comzis/apps/secrets-real/mailu-*
# Should show:
# mailu-secret-key (32 bytes)
# mailu-admin-password (33 bytes)
# mailu-db-password (33 bytes)
```

---

## 🧪 Test Patterns

### Test 1: Service Health Check

```bash
# Front health
docker compose -f compose/mailu.yml exec mailu-front wget -q -O- http://localhost/health

# Admin health
docker compose -f compose/mailu.yml exec mailu-admin wget -q -O- http://localhost/health

# Redis health
docker compose -f compose/mailu.yml exec mailu-redis redis-cli ping
# Expected: PONG
```

### Test 2: SMTP Submission

```bash
# Test SMTP (requires telnet or swaks)
echo -e "EHLO test\nQUIT" | nc mail.inlock.ai 587
# Expected: 220 greeting, 250 EHLO response

# Full test (if swaks installed):
swaks --to admin@inlock.ai --from admin@inlock.ai --server mail.inlock.ai --port 587 -tls
```

### Test 3: Admin API Access

```bash
# Check admin is accessible
curl -k https://mail.inlock.ai/admin/health
# Expected: HTTP 200 or 302 (redirect to auth)
```

### Test 4: Log Write Test

```bash
# Front: Test nginx log write
docker compose -f compose/mailu.yml exec mailu-front touch /var/lib/nginx/logs/test.log
# Should succeed (no permission denied)

# Verify tmpfs mount
docker compose -f compose/mailu.yml exec mailu-front df -h | grep nginx
# Should show tmpfs mounted
```

---

## 📊 Log Patterns

### Success Patterns

**Front:**
```
[INFO] Starting Mailu frontend
[INFO] Nginx configuration generated
[INFO] Nginx started
```

**Admin:**
```
[INFO] Starting Mailu admin
[INFO] Database connection: OK
[INFO] Redis connection: OK
[INFO] Admin API ready
```

**Redis:**
```
* Ready to accept connections
* Background saving started
```

### Failure Patterns

**Front:**
```
[ERROR] Cannot write to /var/lib/nginx/logs
[ERROR] nginx: [emerg] module not found
[ERROR] Permission denied: /var/lib/nginx
```

**Admin:**
```
[ERROR] setgroups: Operation not permitted
[ERROR] Cannot connect to database
[ERROR] Permission denied: /tmp
```

**Redis:**
```
* Permission denied: /data/appendonly.aof
* Operation not permitted
```

---

## 🔄 Rollback Safety

### If Health Worsens After Changes

**Rollback Step 1: Revert compose file**
```bash
cd /home/comzis/inlock-infra
git diff compose/mailu.yml  # Review changes
git checkout compose/mailu.yml  # Revert if needed
```

**Rollback Step 2: Restart with old config**
```bash
docker compose -f compose/mailu.yml --env-file .env down
docker compose -f compose/mailu.yml --env-file .env up -d
```

**Rollback Step 3: Check previous working state**
```bash
# Check git history for last working commit
git log --oneline compose/mailu.yml | head -5

# Restore specific version
git checkout <commit-hash> -- compose/mailu.yml
```

### Safe Minimal Config (Baseline)

**If everything breaks, use this minimal config:**
```yaml
# Minimal front config (remove all hardening temporarily)
mailu-front:
  tmpfs: [/tmp, /var/run, /var/lib/nginx]
  security_opt: [no-new-privileges:false]
  # Remove all cap_drop/cap_add temporarily
  # Remove read_only

# Minimal admin config
mailu-admin:
  tmpfs: [/tmp, /var/run]
  security_opt: [no-new-privileges:false]
  # Remove all cap_drop/cap_add temporarily

# Minimal redis config
mailu-redis:
  tmpfs: [/tmp]
  cap_add: [SETGID, SETUID, CHOWN]
  security_opt: [no-new-privileges:false]
```

---

## 🎯 Diagnostic Commands

### One-Liners

```bash
# Check all Mailu services status
docker compose -f compose/mailu.yml ps

# Tail all logs
docker compose -f compose/mailu.yml logs -f

# Check front nginx config
docker compose -f compose/mailu.yml exec mailu-front nginx -t

# Check admin DB connection
docker compose -f compose/mailu.yml exec mailu-admin python -c "from mailu import db; print(db)"

# Check Redis connectivity
docker compose -f compose/mailu.yml exec mailu-admin python -c "import redis; r=redis.Redis('mailu-redis'); print(r.ping())"

# Verify secrets mounted
docker compose -f compose/mailu.yml exec mailu-front ls -la /run/secrets/

# Check volume permissions
docker compose -f compose/mailu.yml exec mailu-redis ls -la /data
```

---

## 📝 Quick Decision Tree

**Front restarting?**
1. Check logs: `docker compose -f compose/mailu.yml logs mailu-front`
2. If "Permission denied" on `/var/lib/nginx` → Ensure tmpfs mount
3. If "module not found" → Add DAC_OVERRIDE capability
4. If "cannot bind" → Check NET_BIND_SERVICE capability

**Admin restarting?**
1. Check logs: `docker compose -f compose/mailu.yml logs mailu-admin`
2. If "setgroups" error → Ensure `no-new-privileges:false`
3. If "DB connection" error → Check postgres is running
4. If "Permission denied" on `/tmp` → Ensure tmpfs mount

**Redis failing?**
1. Check logs: `docker compose -f compose/mailu.yml logs mailu-redis`
2. If "Permission denied" on `/data` → Fix volume permissions
3. If "Operation not permitted" → Ensure SETGID/SETUID capabilities
4. If "appendonly" error → Check volume write access

---

**Last Updated:** 2025-12-13  
**Status:** 🔄 Active Support

