# Mailu Rollback Guide

**Purpose:** Safe rollback procedures if changes break Mailu service health.

---

## 🔄 Quick Rollback (Git-based)

### If compose file is in git:

```bash
cd /home/comzis/inlock-infra

# Check current status
git status

# Rollback compose file
git checkout -- compose/mailu.yml

# Restart services
docker compose -f compose/mailu.yml down
docker compose -f compose/mailu.yml up -d

# Verify
docker compose -f compose/mailu.yml ps
```

---

## 🔄 Manual Rollback (If not using git)

### Step 1: Backup Current State

```bash
cd /home/comzis/inlock-infra

# Backup current compose file
cp compose/mailu.yml compose/mailu.yml.backup-$(date +%Y%m%d-%H%M%S)
```

### Step 2: Identify Changes to Revert

#### Revert Admin Service (if changed)

**File:** `compose/mailu.yml` (lines ~299-305)

**If you added:**
```yaml
cap_add:
  - NET_BIND_SERVICE
  - CHOWN
  - SETGID
  - SETUID
```

**Revert to:**
```yaml
cap_drop:
  - ALL
```

**Note:** This will restore the original permission error, but allows rollback if other issues occur.

#### Revert Front Service (if changed)

**File:** `compose/mailu.yml` (lines ~87-88)

**If you added command wrapper:**
```yaml
command:
  - /bin/sh
  - -c
  - |
    mkdir -p /var/lib/nginx/logs /var/lib/nginx/modules
    /start.py
```

**Revert to:** (remove command section, use default)

**Or if you changed tmpfs to volume:**
- Remove volume mount for `/var/lib/nginx`
- Restore tmpfs entry: `- /var/lib/nginx`

#### Revert Redis Service (if changed)

**File:** `compose/mailu.yml` (lines ~327-331)

**If you added:**
```yaml
cap_add:
  - CHOWN
  - SETGID
  - SETUID
```

**Revert to:**
```yaml
cap_drop:
  - ALL
```

---

### Step 3: Apply Rollback

```bash
# Edit compose file manually or use backup
# Then restart services
docker compose -f compose/mailu.yml down
docker compose -f compose/mailu.yml up -d
```

### Step 4: Verify Rollback

```bash
# Check service status
docker compose -f compose/mailu.yml ps

# Check logs for expected errors (original issues may return)
docker logs compose-mailu-admin-1 --tail 20
docker logs compose-mailu-front-1 --tail 20
```

---

## ⚠️ Rollback Scenarios

### Scenario 1: Admin Service Fails After Capability Change

**Symptoms:**
- Container crashes
- New permission errors
- Service won't start

**Rollback:**
1. Revert `cap_add` back to `cap_drop: ALL` in admin service
2. Restart: `docker compose -f compose/mailu.yml restart mailu-admin`

**Investigation:**
- Check logs for specific capability needed
- May need different capabilities than expected

---

### Scenario 2: Front Service Fails After Command Change

**Symptoms:**
- Nginx won't start
- Command not found errors
- Service in restart loop

**Rollback:**
1. Remove command wrapper, restore default
2. Restart: `docker compose -f compose/mailu.yml restart mailu-front`

**Alternative:**
- If using volume approach, revert to tmpfs and restore original tmpfs configuration

---

### Scenario 3: Redis Service Fails After Capability Change

**Symptoms:**
- Redis won't start
- User switching errors return

**Rollback:**
1. Revert to `cap_drop: ALL`
2. Restart: `docker compose -f compose/mailu.yml restart mailu-redis`

**Note:** Redis was working with current config, so this is unlikely.

---

## 🛡️ Safe Rollback Strategy

### Before Making Changes

1. **Create backup:**
   ```bash
   cp compose/mailu.yml compose/mailu.yml.backup-$(date +%Y%m%d-%H%M%S)
   ```

2. **Document current state:**
   ```bash
   docker compose -f compose/mailu.yml ps > mailu-state-before.txt
   docker compose -f compose/mailu.yml config > mailu-config-before.txt
   ```

3. **Test changes in isolated environment** (if possible)

### During Changes

1. **Make incremental changes:**
   - Change one service at a time
   - Test after each change
   - Don't change all services simultaneously

2. **Monitor immediately after change:**
   ```bash
   docker compose -f compose/mailu.yml ps
   docker logs compose-mailu-{admin,front,redis}-1 --tail 20
   ```

### After Changes

1. **Verify all services healthy**
2. **Test functionality** (see `MAILU-TEST-PLAN.md`)
3. **If issues occur, rollback immediately**

---

## 📋 Rollback Checklist

```
[ ] Backup created: compose/mailu.yml.backup-*
[ ] Current state documented
[ ] Changes identified and isolated
[ ] Rollback steps planned
[ ] Services stopped gracefully
[ ] Changes reverted
[ ] Services restarted
[ ] Health verified
[ ] Functionality tested
```

---

## 🔍 Rollback Verification

### After Rollback, Verify:

1. **Services start:**
   ```bash
   docker compose -f compose/mailu.yml ps
   ```

2. **No new errors:**
   ```bash
   docker logs compose-mailu-admin-1 --tail 20
   docker logs compose-mailu-front-1 --tail 20
   docker logs compose-mailu-redis-1 --tail 20
   ```

3. **Expected errors return** (original issues may be back, but this confirms rollback worked)

4. **Data intact:**
   ```bash
   docker volume ls | grep mailu
   # Volumes should still exist and be accessible
   ```

---

## 🚨 Emergency Rollback (Complete Service Stop)

If services are in critical failure state:

```bash
# Stop all Mailu services
docker compose -f compose/mailu.yml down

# Restore from backup
cp compose/mailu.yml.backup-* compose/mailu.yml

# Start services
docker compose -f compose/mailu.yml up -d

# Monitor
docker compose -f compose/mailu.yml ps
docker compose -f compose/mailu.yml logs -f
```

---

## 📝 Rollback Log Template

```
=== Mailu Rollback Log ===
Date: [YYYY-MM-DD HH:MM]
Reason: [Why rollback was needed]

Changes Made:
- [List changes that were rolled back]

Rollback Steps:
1. [Step 1]
2. [Step 2]
...

Verification:
- [ ] Services stopped
- [ ] Changes reverted
- [ ] Services restarted
- [ ] Health verified

Result: ✅ SUCCESS / ❌ FAILED

Notes:
[Any observations or issues]
```

---

**Important:** Rollback restores previous configuration, which may have the original issues. Rollback is for stability, not for fixing the root cause.

