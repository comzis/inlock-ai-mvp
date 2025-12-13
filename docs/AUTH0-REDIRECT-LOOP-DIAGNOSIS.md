# Auth0 Redirect Loop - Diagnosis & Fix

**Date:** 2025-12-13  
**Issue:** Redirect loop after successful Auth0 authentication  
**Error:** "Too many redirects occurred" (Safari)  
**Status:** 🔴 **CRITICAL - FIXING**

---

## Problem Observed

User sees redirect loop when accessing protected services after Auth0 login:
- Authentication with Auth0 succeeds ✅
- OAuth2-Proxy receives callback and creates session ✅
- Redirect back to service (e.g., `portainer.inlock.ai`) ✅
- **BUT:** Next request shows "No valid authentication" ❌
- Loop continues: redirect → auth → callback → redirect → ...

---

## Root Cause Identified

**Issue:** Traefik forward-auth middleware not passing `Cookie` header to OAuth2-Proxy.

When Traefik checks authentication via forward-auth:
- It sends request headers to OAuth2-Proxy
- OAuth2-Proxy needs the `Cookie` header to read `inlock_session` cookie
- **The `Cookie` header was missing from `authRequestHeaders`**

---

## Fix Applied

### Configuration Change

**File:** `traefik/dynamic/middlewares.yml`

**Added to `admin-forward-auth` middleware:**
```yaml
authRequestHeaders:
  - X-Forwarded-Method
  - X-Forwarded-Proto
  - X-Forwarded-Host
  - X-Forwarded-Uri
  - X-Forwarded-For
  - X-Real-Ip
  - Cookie  # ← ADDED THIS LINE
```

### Restart Traefik

```bash
docker compose -f compose/stack.yml --env-file .env restart traefik
```

---

## Verification Steps

### Step 1: Wait for Traefik to Reload
- Give Traefik 10-15 seconds to reload configuration
- Check Traefik logs: `docker compose -f compose/stack.yml --env-file .env logs traefik --tail 20`

### Step 2: Clear Browser State
1. Clear all cookies for `*.inlock.ai`
2. Clear cookies for `auth.inlock.ai`
3. Clear browser cache (optional)

### Step 3: Test Authentication Flow
1. Visit: `https://portainer.inlock.ai` (or any protected service)
2. Should redirect to Auth0 login
3. Complete login
4. **Expected:** Should redirect back and grant access (no loop)
5. **Check:** Service loads successfully

### Step 4: Verify Cookie Recognition
1. After successful authentication, check OAuth2-Proxy logs:
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 50
   ```
2. Should see authentication success without immediate "No valid authentication" message

---

## Expected Behavior After Fix

**Before Fix:**
```
1. User → portainer.inlock.ai
2. Traefik → forward-auth → OAuth2-Proxy (no Cookie header)
3. OAuth2-Proxy: "No auth" → redirect to Auth0
4. Auth0 login → callback → session created
5. Redirect to portainer.inlock.ai
6. Traefik → forward-auth → OAuth2-Proxy (no Cookie header) ← PROBLEM
7. Loop continues...
```

**After Fix:**
```
1. User → portainer.inlock.ai
2. Traefik → forward-auth → OAuth2-Proxy (WITH Cookie header)
3. OAuth2-Proxy: "No auth" → redirect to Auth0
4. Auth0 login → callback → session created → Cookie set
5. Redirect to portainer.inlock.ai
6. Traefik → forward-auth → OAuth2-Proxy (WITH Cookie header) ✅
7. OAuth2-Proxy: "Auth valid" → allow request
8. Service loads ✅
```

---

## Additional Checks

### If Fix Doesn't Work

1. **Verify Cookie is Set in Browser:**
   - Developer Tools → Application → Cookies
   - Check for `inlock_session` cookie
   - Verify domain is `.inlock.ai`

2. **Check Safari Cookie Settings:**
   - Safari → Preferences → Privacy
   - If "Prevent cross-site tracking" is ON, try disabling temporarily
   - Safari blocks `SameSite=None` cookies by default

3. **Test in Chrome/Firefox:**
   - To isolate Safari-specific cookie blocking
   - Chrome/Firefox handle `SameSite=None` cookies better

4. **Check OAuth2-Proxy Logs:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 | grep -iE "cookie|auth|redirect"
   ```

---

## Files Modified

- ✅ `traefik/dynamic/middlewares.yml` - Added `Cookie` to `authRequestHeaders`

---

## Next Steps After Fix

1. ✅ Test authentication flow
2. ✅ Verify no redirect loop
3. ✅ Test cross-service access
4. ✅ Document results in `AUTH0-BROWSER-TEST-RESULTS.md`
5. ✅ Update `AUTH0-FIX-STATUS.md` with fix

---

**Fix Applied:** 2025-12-13  
**Status:** ⏳ Testing required  
**Priority:** 🔴 Critical

