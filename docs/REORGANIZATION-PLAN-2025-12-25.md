# Project Reorganization Plan
**Date:** 2025-12-25  
**Status:** In Progress

## Overview
This document tracks the reorganization of the project to fully comply with `.cursorrules` and fix critical issues.

## Critical Issues to Fix

### ✅ Completed
1. [x] Create missing `.cursorrules-security` file

### 🔄 In Progress
2. [ ] Review and commit uncommitted changes (Mailu cleanup)
3. [ ] Fix broken compose include path (`../config/monitoring/logging.yml`)

### 📋 Pending
4. [ ] Reorganize documentation files into proper subdirectories
5. [ ] Resolve duplicate files (case differences)
6. [ ] Update `docs/index.md`
7. [ ] Create structure validation script

---

## Step 1: Fix Critical Compose Issue

**Issue:** `compose/services/stack.yml` line 18 includes `../config/monitoring/logging.yml` which doesn't exist.

**Action:** 
- Check if logging.yml should be in `compose/services/` instead
- Or if it should be created in `config/monitoring/`
- Fix the include path

---

## Step 2: Commit Mailu Cleanup

**Status:** Many Mailu files are deleted (good cleanup)

**Action:**
- Review deleted files
- Commit the cleanup with proper message
- Ensure no broken references remain

---

## Step 3: Documentation Reorganization

### Files to Move from `docs/` root:

#### → `docs/security/`
- `ACCESS-CONTROL-VALIDATION.md`
- `CLOUDFLARE-IP-ALLOWLIST.md`
- `PORT-RESTRICTION-SUMMARY.md`

#### → `docs/guides/`
- `ADDING-NEW-SERVICE.md`
- `AUTOMATION-SCRIPTS.md`
- `CREDENTIALS-RECOVERY.md`
- `INLOCK-AI-QUICK-START.md`
- `INLOCK-CONTENT-MANAGEMENT.md`
- `NODE-JS-DOCKER-ONLY.md`
- `ORPHAN-CONTAINER-CLEANUP.md`
- `QUICK-ACTION-CHECKLIST.md`
- `RUN-DIAGNOSTICS.md`
- `SECRET-MANAGEMENT.md`
- `SERVER-UPDATE-SCHEDULE.md`
- `WEBSITE-LAUNCH-CHECKLIST.md`
- `WORKFLOW-BEST-PRACTICES.md`

#### → `docs/reports/`
- `DEVELOPMENT-STATUS-UPDATE.md`
- `DEVOPS-TOOLS-STATUS.md`
- `EXECUTION-REPORT-2025-12-13.md`
- `EXEC-COMMS-STATUS.md`
- `FEATURE-TEST-RESULTS.md`
- `FINAL-DEPLOYMENT-STATUS.md`
- `FINAL-REVIEW-SUMMARY.md`
- `QUICK-ACTION-STATUS.md`
- `VERIFICATION-REPORT.md`
- `VERIFICATION-SUMMARY.md`
- `SWARM-*.md` (all files)

#### → `docs/architecture/`
- `SERVER-STRUCTURE-ANALYSIS.md`
- `infra.md` (or keep in root if it's the main overview)

#### → `docs/services/`
- `PORTAINER-ACCESS.md` → `docs/services/portainer/`
- `PORTAINER-PASSWORD-RECOVERY.md` → `docs/services/portainer/`
- `COCKPIT-*.md` → `docs/services/cockpit/` (create directory)

#### → `docs/reports/incidents/`
- `STRIKE-TEAM-*.md` files

#### → `docs/reference/`
- `cloudflare-token-fix.md` (or `docs/guides/` if it's a guide)

#### Keep in root (main docs):
- `index.md` (main entry point)
- `monitoring.md` (or move to `docs/services/monitoring/`)

---

## Step 4: Resolve Duplicates

**Check for:**
- `access-control-validation.md` vs `ACCESS-CONTROL-VALIDATION.md`
- Any other case differences

**Action:** Standardize on one naming convention (prefer UPPERCASE for consistency)

---

## Step 5: Update Documentation Index

Update `docs/index.md` to reflect:
- New organization structure
- All major documentation categories
- Quick links to important guides

---

## Step 6: Create Validation Script

Create `scripts/validate-structure.sh` to:
- Check required directories exist
- Verify compose file structure
- Check for common issues
- Validate against `.cursorrules`

---

## Execution Order

1. ✅ Fix compose include path (critical)
2. ✅ Commit Mailu cleanup
3. ✅ Reorganize documentation (use git mv to preserve history)
4. ✅ Update docs/index.md
5. ✅ Create validation script
6. ✅ Final verification

---

*Last Updated: 2025-12-25*


