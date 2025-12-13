# Auth0 Redirect Loop Fix - Safari Cookie Issue

**Date:** 2025-12-13  
**Issue:** Redirect loop after successful authentication  
**Symptom:** "Too many redirects" error in Safari after Auth0 login  
**Root Cause:** Cookie not being recognized after callback redirect

---

## Problem Analysis

From logs, the flow is:
1. ✅ User authenticates with Auth0 - SUCCESS
2. ✅ OAuth2-Proxy receives callback - SUCCESS  
3. ✅ Session created: `[AuthSuccess] Authenticated via OAuth2`
4. ✅ Redirect sent to service (e.g., `portainer.inlock.ai`)
5. ❌ Next request: `[oauthproxy.go:1017] No valid authentication in request`
6. ❌ Loop continues: redirect → callback → redirect → ...

**Issue:** The `inlock_session` cookie is not being sent or recognized by OAuth2-Proxy when Traefik forwards the auth check.

---

## Potential Causes

### 1. Safari Third-Party Cookie Blocking
Safari blocks third-party cookies by default, and `SameSite=None` cookies are considered third-party in cross-site redirects.

### 2. Cookie Domain Mismatch
Cookie set for `.inlock.ai` but request coming from specific subdomain may not match.

### 3. Traefik Forward-Auth Cookie Passing
Traefik forward-auth middleware may not be passing cookies correctly.

### 4. Cookie Path Issues
Cookie path may not match the request path.

---

## Solutions to Try

### Solution 1: Verify Cookie Settings (Already Configured)
Current settings are correct:
- `--cookie-domain=.inlock.ai` ✅
- `--cookie-samesite=none` ✅  
- `OAUTH2_PROXY_COOKIE_SECURE=true` ✅

### Solution 2: Check Traefik Forward-Auth Headers
Traefik forward-auth needs to pass cookies to OAuth2-Proxy.

**Check:** `traefik/dynamic/middlewares.yml` - `admin-forward-auth` middleware

Current config looks correct with `trustForwardHeader: true`.

### Solution 3: Enable Cookie Chunking (If Cookie Too Large)
If cookie is too large, it might be rejected. OAuth2-Proxy v7.6.0 should handle this automatically.

### Solution 4: Test in Different Browser
Safari has stricter cookie policies. Test in Chrome/Firefox to isolate Safari-specific issue.

### Solution 5: Check OAuth2-Proxy Logs for Cookie Issues
```bash
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 | grep -i cookie
```

### Solution 6: Verify Cookie is Actually Set
Check browser Developer Tools → Application → Cookies after authentication attempt.

---

## Immediate Actions

### Step 1: Check Cookie in Browser
1. Open Developer Tools → Application → Cookies
2. Look for `inlock_session` cookie after authentication attempt
3. Check:
   - Is cookie present? YES / NO
   - Domain: `.inlock.ai`?
   - Secure: true?
   - SameSite: None?

### Step 2: Test in Chrome/Firefox
Safari has stricter cookie policies. Test in Chrome to see if issue is Safari-specific.

### Step 3: Check OAuth2-Proxy Cookie Logging
Enable verbose logging to see cookie details.

---

## Debugging Steps

### Check if Cookie is Being Set

```bash
# After authentication attempt, check if cookie appears in logs
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 200 | grep -iE "cookie|set-cookie"
```

### Check Traefik Headers

```bash
# Check what headers Traefik is sending to OAuth2-Proxy
docker compose -f compose/stack.yml --env-file .env logs traefik --tail 100 | grep -iE "oauth2|auth|cookie"
```

### Manual Cookie Check

1. After authentication callback (before redirect loop starts)
2. Check browser: Developer Tools → Network tab
3. Find the callback request: `/oauth2/callback?code=...`
4. Check Response Headers for `Set-Cookie`
5. Verify cookie is being set

---

## Potential Fix: Cookie Chunking

If cookie is too large, enable chunking in OAuth2-Proxy:

```yaml
# In compose/stack.yml
environment:
  - OAUTH2_PROXY_COOKIE_CHUNK_SIZE=4000
```

**Note:** This may not be the issue, but worth trying.

---

## Potential Fix: Adjust Cookie SameSite (Not Recommended)

Changing `SameSite=None` to `lax` would break cross-site redirects. Current setting is correct.

---

## Potential Fix: Ensure Cookie Domain Matches Request

The cookie domain `.inlock.ai` should work for all subdomains. Verify this is the case.

---

## Most Likely Fix: Safari Cookie Settings

Safari may be blocking the cookie. Check:

1. **Safari Settings:**
   - Safari → Preferences → Privacy
   - Check "Prevent cross-site tracking" - this may block `SameSite=None` cookies
   - Try disabling temporarily to test

2. **Alternative:** Test in Chrome/Firefox first to confirm it's Safari-specific

---

## Testing After Fix

1. Clear all cookies for `*.inlock.ai`
2. Visit protected service
3. Complete authentication
4. Verify:
   - Cookie is set in browser
   - Service loads without redirect loop
   - No "too many redirects" error

---

## Status

**Current Issue:** Redirect loop - cookie not recognized after authentication  
**Priority:** 🔴 Critical  
**Next Steps:** 
1. Check browser cookie settings
2. Test in Chrome/Firefox
3. Verify cookie is being set in browser
4. Check OAuth2-Proxy logs for cookie issues

