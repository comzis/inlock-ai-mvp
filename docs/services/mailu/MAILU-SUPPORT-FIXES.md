# Mailu Support Fixes - Background Support Swarm

**Date:** 2025-12-13  
**Target Services:** mailu-front, mailu-admin, mailu-redis  
**Goal:** Front/admin/redis healthy; contact form mail flow works

---

## 🎯 Executive Summary

**Issues Identified:**
1. **Admin:** Missing `SETGID` capability (needed for `os.setgroups([])`) - has `cap_drop: ALL`
2. **Front:** Nginx log directory and module paths not accessible in tmpfs
3. **Redis:** Currently working (capabilities correct in runtime)

**Status:** Ready-to-apply fixes provided below.

---

## 🔧 Issue 1: Admin - Permission Errors

### Symptoms
```
PermissionError: [Errno 1] Operation not permitted
os.setgroups([])
chown: /dkim: Operation not permitted
```

### Root Cause
Container has `cap_drop: ALL` (line 300) but needs:
- `SETGID` - for `os.setgroups([])`
- `CHOWN` - for `chown /dkim` and `/data`
- `SETUID` - for user switching

### Fix

**File:** `compose/mailu.yml` (lines 299-305)

**Current:**
```yaml
cap_drop:
  - ALL
# user: "1000:1000"  # Removed - Mailu needs root to write config files at startup
security_opt:
  - no-new-privileges:false  # Override hardening - Mailu needs to read secrets and write configs
```

**Replace with:**
```yaml
# Do NOT use cap_drop: ALL - admin needs SETGID, SETUID, CHOWN
cap_add:
  - NET_BIND_SERVICE  # For binding to ports
  - CHOWN             # For chown operations on /dkim, /data
  - SETGID            # For os.setgroups([])
  - SETUID            # For user switching
# user: "1000:1000"  # Removed - Mailu needs root to write config files at startup
security_opt:
  - no-new-privileges:false  # Override hardening - Mailu needs to read secrets and write configs
```

---

## 🔧 Issue 2: Front (Nginx) - Log and Module Paths

### Symptoms
```
nginx: [alert] could not open error log file: open() "/var/lib/nginx/logs/error.log" failed (2: No such file or directory)
dlopen() "/var/lib/nginx/modules/ngx_mail_module.so" failed (Error loading shared library ...: No such file or directory)
```

### Root Cause
- tmpfs `/var/lib/nginx` is mounted but directory structure doesn't exist at startup
- Nginx tries to write logs before directory creation
- Module loading fails because path doesn't exist

### Fix Options

#### Option A: Pre-create directories (Recommended)

**File:** `compose/mailu.yml` (lines 52-101)

**Add init container or modify command:**
```yaml
mailu-front:
  # ... existing config ...
  command:
    - /bin/sh
    - -c
    - |
      mkdir -p /var/lib/nginx/logs /var/lib/nginx/modules
      /start.py
  # ... rest of config ...
```

#### Option B: Use volume for persistent logs (Alternative)

**File:** `compose/mailu.yml`

**Add volume:**
```yaml
volumes:
  # ... existing volumes ...
  mailu_front_logs:

# In mailu-front service:
volumes:
  - mailu_mail_data:/mail
  - mailu_dkim_data:/dkim
  - mailu_front_logs:/var/lib/nginx  # Instead of tmpfs
```

**Remove from tmpfs:**
```yaml
tmpfs:
  - /tmp
  - /var/run
  # Remove: - /var/lib/nginx  # Use volume instead
```

**Recommendation:** Use Option A (pre-create directories) - simpler and keeps logs ephemeral.

---

## 🔧 Issue 3: Redis - User Switching (Already Fixed)

### Status
✅ **Currently working** - container has correct capabilities:
- `CapAdd: [CAP_CHOWN, CAP_SETGID, CAP_SETUID]`
- `CapDrop: null` (no cap_drop in runtime)

### Note
The compose file shows `cap_drop: ALL` (line 327), but runtime inspection shows `CapDrop: null`, meaning capabilities were already added. However, to ensure consistency:

**File:** `compose/mailu.yml` (lines 327-331)

**Current:**
```yaml
cap_drop:
  - ALL
# No user override - let container run as root and switch to redis user internally
security_opt:
  - no-new-privileges:false  # Allow user switching
```

**Replace with (for consistency):**
```yaml
# Do NOT use cap_drop: ALL - redis needs SETUID/SETGID to switch to redis user
cap_add:
  - CHOWN
  - SETGID
  - SETUID
# No user override - let container run as root and switch to redis user internally
security_opt:
  - no-new-privileges:false  # Allow user switching
```

---

## 📋 Complete Fix Checklist

### Step 1: Apply Admin Fix
- [ ] Edit `compose/mailu.yml` line 300
- [ ] Remove `cap_drop: ALL`
- [ ] Add `cap_add: [NET_BIND_SERVICE, CHOWN, SETGID, SETUID]`
- [ ] Save file

### Step 2: Apply Front Fix
- [ ] Edit `compose/mailu.yml` line 87 (command section)
- [ ] Add directory creation before `/start.py`
- [ ] OR use volume approach (Option B)
- [ ] Save file

### Step 3: Apply Redis Fix (Optional - already working)
- [ ] Edit `compose/mailu.yml` line 327
- [ ] Remove `cap_drop: ALL`
- [ ] Add `cap_add: [CHOWN, SETGID, SETUID]`
- [ ] Save file

### Step 4: Restart Services
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/mailu.yml down
docker compose -f compose/mailu.yml up -d
```

### Step 5: Verify
```bash
# Check admin
docker logs compose-mailu-admin-1 --tail 20

# Check front
docker logs compose-mailu-front-1 --tail 20

# Check redis
docker logs compose-mailu-redis-1 --tail 20

# Check health
docker compose -f compose/mailu.yml ps
```

---

## 🔍 Expected Outputs After Fix

### Admin (Success)
```
[No PermissionError messages]
[No chown permission errors]
[Service starts successfully]
```

### Front (Success)
```
[No "could not open error log file" messages]
[No "dlopen() failed" messages]
[nginx starts successfully]
[Health check passes]
```

### Redis (Success - Already Working)
```
* Redis is starting oO0OoO0OoO0Oo
* Server initialized
* Ready to accept connections
```

---

## 🧪 Testing

See `MAILU-TEST-PLAN.md` for complete testing procedures.

Quick health check:
```bash
# All services should show "healthy"
docker compose -f compose/mailu.yml ps | grep mailu

# Admin health
curl -f http://localhost/admin/health || echo "Admin not accessible"

# Front health
curl -f http://localhost/health || echo "Front not accessible"

# Redis health
docker exec compose-mailu-redis-1 redis-cli ping
# Expected: PONG
```

---

## ⚠️ Risk Assessment

**Risk Level:** LOW

- Changes are minimal (capability adjustments)
- No data volume changes
- Easy rollback (git revert or manual edit)

**Rollback:** See `MAILU-ROLLBACK.md`

---

**Next:** See `MAILU-ENV-SECRETS-CHECKLIST.md` for environment variable validation.

