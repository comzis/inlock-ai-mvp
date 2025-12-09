# Dependency Update Notes

## Current Status

The build shows deprecation warnings for several packages. These are **non-critical** but should be addressed for security and compatibility.

## Warnings Summary

### 1. ESLint 8.57.0 → ESLint 9+

**Current:** `eslint@^8.57.0`  
**Recommended:** `eslint@^9.0.0`

**Impact:** ESLint 8 is deprecated. ESLint 9 has breaking changes:
- New flat config format
- Requires `eslint.config.js` instead of `.eslintrc.json`
- Next.js 15 should support ESLint 9

**Action:** Update ESLint and migrate config format if needed.

### 2. Glob 7.2.3 → Glob 9+

**Current:** Transitive dependency (dependency of another package)  
**Status:** Usually updated automatically when parent packages update

### 3. Inflight 1.0.6

**Current:** Transitive dependency  
**Issue:** Known memory leak, deprecated  
**Resolution:** Update parent packages that use it

### 4. @humanwhocodes/* Packages

**Current:** `@humanwhocodes/object-schema@2.0.3`, `@humanwhocodes/config-array@0.13.0`  
**Recommended:** `@eslint/object-schema`, `@eslint/config-array`  
**Impact:** Part of ESLint ecosystem migration

## Recommended Update Steps

### Option 1: Update ESLint to v9 (Recommended)

1. **Update package.json:**
   ```json
   "eslint": "^9.0.0",
   ```

2. **Update ESLint config** (if needed):
   - ESLint 9 uses flat config format
   - Check if Next.js 15 supports ESLint 9 flat config
   - May need to update `.eslintrc.json` to `eslint.config.js`

3. **Rebuild:**
   ```bash
   docker build -t inlock-ai:latest .
   ```

### Option 2: Stay on ESLint 8 (Safer for now)

If ESLint 9 causes issues with Next.js 15:
- Keep ESLint 8 for now
- Warnings are non-blocking
- Plan migration for next maintenance window

## Current Approach

**Status:** ESLint version updated in package.json to `^9.0.0`

**Next Steps:**
1. Rebuild Docker image to test compatibility
2. If build fails, revert to ESLint 8 and document for future update
3. Check Next.js 15 ESLint 9 compatibility documentation

## Verification

After updating, rebuild and check for warnings:

```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest . 2>&1 | grep -i "warn\|error"
```

## Notes

- These are **warnings**, not errors - build should still succeed
- Transitive dependencies (like `glob`, `inflight`) update automatically when parent packages update
- Next.js 15 should handle ESLint 9, but test thoroughly
- Always test builds and linting after dependency updates

---

**Last Updated:** 2025-12-09  
**Action Taken:** ESLint version updated to ^9.0.0 in package.json

