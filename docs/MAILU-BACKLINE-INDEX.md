# Mailu Backline Support - Index

**Quick navigation for Mailu support swarm**

---

## 📚 Documentation Files

1. **MAILU-BACKLINE-QUICK-REFERENCE.md** ⭐ START HERE
   - Comprehensive troubleshooting guide
   - Configuration snippets
   - Test patterns and log patterns
   - Rollback procedures

2. **MAILU-FIXES-APPLY-NOW.md**
   - Immediate fixes for identified issues
   - Ready-to-apply configuration changes
   - Verification steps

3. **MAILU-ONE-LINERS.md**
   - Quick command reference
   - One-liner fixes for common issues
   - Diagnostic commands

4. **MAILU-BACKLINE-SUMMARY.md**
   - Summary of all deliverables
   - Issues identified and fixed
   - Quick reference links

---

## 🔧 Key Fixes Applied

### Front Service
- ✅ Added `nginx_logs` volume mount
- ✅ Added `DAC_OVERRIDE` capability
- ✅ Removed tmpfs for `/var/lib/nginx`

### Admin Service
- ✅ Removed `cap_drop: ALL`
- ✅ Added `DAC_OVERRIDE` capability
- ✅ Kept `SETGID`, `SETUID`, `CHOWN`

### Redis Service
- ✅ Already configured correctly

---

## 🚀 Quick Start

1. **Review fixes:** `docs/MAILU-FIXES-APPLY-NOW.md`
2. **Apply changes:** Restart services
3. **Run tests:** `./scripts/test-mailu-quick.sh`
4. **Check logs:** Use one-liners from `docs/MAILU-ONE-LINERS.md`

---

## 📋 Common Issues & Solutions

| Issue | Solution | Doc Reference |
|-------|----------|---------------|
| Front: nginx logs error | Use volume mount | MAILU-FIXES-APPLY-NOW.md |
| Front: module not found | Add DAC_OVERRIDE | MAILU-FIXES-APPLY-NOW.md |
| Admin: setgroups error | Remove cap_drop: ALL | MAILU-FIXES-APPLY-NOW.md |
| Admin: chown denied | Remove cap_drop: ALL | MAILU-FIXES-APPLY-NOW.md |

---

**Last Updated:** 2025-12-13

