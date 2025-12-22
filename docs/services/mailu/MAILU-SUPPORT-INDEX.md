# Mailu Support Index - Quick Reference

**Background Support Swarm Deliverables for Primary Mailu Strike Team**

---

## 🚀 Quick Start

**Start here:** `MAILU-HANDOFF-SUMMARY.md` - Executive summary and quick start guide

---

## 📚 Documentation Structure

### 1. **Handoff & Summary**
- **`MAILU-HANDOFF-SUMMARY.md`** ⭐ **START HERE**
  - Executive summary
  - Issues identified
  - Quick start guide
  - Success criteria

---

### 2. **Fix Documentation**
- **`MAILU-SUPPORT-FIXES.md`**
  - Detailed issue analysis
  - Root cause identification
  - Step-by-step fixes
  - Verification steps

- **`MAILU-COMPOSE-FIXES.yml`**
  - Copy-paste ready code snippets
  - Exact line numbers
  - Multiple fix options

---

### 3. **Configuration Validation**
- **`MAILU-ENV-SECRETS-CHECKLIST.md`**
  - Environment variable validation
  - Secrets validation
  - Validation scripts
  - Common issues

---

### 4. **Testing**
- **`MAILU-TEST-PLAN.md`**
  - Health check procedures
  - SMTP submission tests
  - Contact form flow verification
  - Test results template

---

### 5. **Safety & Rollback**
- **`MAILU-ROLLBACK.md`**
  - Rollback procedures
  - Scenario-specific rollbacks
  - Safe rollback strategy
  - Emergency rollback

---

## 🎯 Issues & Fixes Quick Reference

### Issue 1: Admin Permission Errors ❌ CRITICAL

**Symptom:** `PermissionError: [Errno 1] Operation not permitted`

**Fix:** Remove `cap_drop: ALL`, add `cap_add: [SETGID, SETUID, CHOWN, NET_BIND_SERVICE]`

**See:** `MAILU-SUPPORT-FIXES.md` - Issue 1

---

### Issue 2: Front Nginx Log/Module Errors ❌ CRITICAL

**Symptom:** `could not open error log file`, `dlopen() failed`

**Fix:** Pre-create directories in command or use volume instead of tmpfs

**See:** `MAILU-SUPPORT-FIXES.md` - Issue 2

---

### Issue 3: Redis User Switching ✅ WORKING

**Status:** Already working, fix optional for consistency

**See:** `MAILU-SUPPORT-FIXES.md` - Issue 3

---

## 🔧 Quick Fix Commands

### Apply All Fixes

```bash
cd /home/comzis/inlock-infra

# 1. Review fixes
cat docs/MAILU-SUPPORT-FIXES.md

# 2. Apply fixes (edit compose/mailu.yml)
# See docs/MAILU-COMPOSE-FIXES.yml for snippets

# 3. Restart services
docker compose -f compose/mailu.yml down
docker compose -f compose/mailu.yml up -d

# 4. Verify
docker compose -f compose/mailu.yml ps
docker logs compose-mailu-admin-1 --tail 20
docker logs compose-mailu-front-1 --tail 20
```

---

## 🧪 Quick Test Commands

```bash
# Health check
docker compose -f compose/mailu.yml ps

# Validate secrets
./scripts/validate-mailu-secrets.sh

# Test SMTP
telnet localhost 25

# Test contact form (manual)
# Navigate to web interface and submit form
```

**Full test plan:** See `MAILU-TEST-PLAN.md`

---

## 📋 Checklists

### Pre-Fix Checklist
- [ ] Review `MAILU-HANDOFF-SUMMARY.md`
- [ ] Backup compose file: `cp compose/mailu.yml compose/mailu.yml.backup`
- [ ] Review current logs: `docker logs compose-mailu-{admin,front,redis}-1`
- [ ] Validate secrets: `./scripts/validate-mailu-secrets.sh`

### Post-Fix Checklist
- [ ] Services healthy: `docker compose -f compose/mailu.yml ps`
- [ ] No permission errors in logs
- [ ] SMTP tests pass
- [ ] Contact form delivers email

---

## 🚨 Emergency Procedures

### If Fix Breaks Services

1. **Stop services:**
   ```bash
   docker compose -f compose/mailu.yml down
   ```

2. **Rollback:**
   ```bash
   # If using git:
   git checkout -- compose/mailu.yml
   
   # If manual backup:
   cp compose/mailu.yml.backup-* compose/mailu.yml
   ```

3. **Restart:**
   ```bash
   docker compose -f compose/mailu.yml up -d
   ```

**Full rollback guide:** See `MAILU-ROLLBACK.md`

---

## 📊 Status Dashboard

| Service | Current Status | Fix Required | Priority |
|---------|---------------|--------------|----------|
| **Admin** | ❌ Restarting | Add capabilities | 🔴 CRITICAL |
| **Front** | ❌ Restarting | Fix nginx paths | 🔴 CRITICAL |
| **Redis** | ✅ Working | Optional fix | 🟡 LOW |

---

## 🎓 Key Learnings

1. **cap_drop: ALL conflicts with privilege dropping** - Cannot use when services need SETUID/SETGID
2. **tmpfs requires initialization** - Directories must exist before services use them
3. **Minimal capabilities required** - Only add what's needed, keep security posture

---

## 📞 Support Flow

```
1. Issue identified → Check logs
2. Review MAILU-SUPPORT-FIXES.md → Apply fix
3. Test → Follow MAILU-TEST-PLAN.md
4. If issue → Check MAILU-ROLLBACK.md
5. Verify → Use MAILU-ENV-SECRETS-CHECKLIST.md
```

---

## 📁 Files Reference

```
docs/
├── MAILU-HANDOFF-SUMMARY.md         ⭐ Start here
├── MAILU-SUPPORT-FIXES.md           Fix details
├── MAILU-COMPOSE-FIXES.yml          Code snippets
├── MAILU-ENV-SECRETS-CHECKLIST.md   Validation
├── MAILU-TEST-PLAN.md               Testing
├── MAILU-ROLLBACK.md                Safety
└── MAILU-SUPPORT-INDEX.md           This file

scripts/
└── validate-mailu-secrets.sh        Validation script
```

---

**Last Updated:** 2025-12-13  
**Status:** ✅ Ready for primary team  
**Estimated Fix Time:** 45 minutes

