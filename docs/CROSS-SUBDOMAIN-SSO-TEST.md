# Cross-Subdomain SSO Test Procedure

**Date:** 2025-12-13  
**Purpose:** Verify seamless SSO across all `*.inlock.ai` subdomains  
**Priority:** 🔴 Critical for production readiness

---

## Prerequisites

### Configuration Verified

- ✅ Single OAuth2-Proxy instance (`auth.inlock.ai`)
- ✅ Cookie domain: `.inlock.ai` (shared across subdomains)
- ✅ Cookie SameSite: `None` (allows cross-site)
- ✅ Cookie Secure: `true` (HTTPS only)
- ✅ Shared cookie secret: Configured in `.env` as `OAUTH2_PROXY_COOKIE_SECRET`
- ✅ All subdomains whitelisted:
  - `auth.inlock.ai`
  - `portainer.inlock.ai`
  - `grafana.inlock.ai`
  - `n8n.inlock.ai`
  - `dashboard.inlock.ai`
  - `deploy.inlock.ai`
  - `traefik.inlock.ai`
  - `cockpit.inlock.ai`
- ✅ Auth0 Web Origin: `https://auth.inlock.ai`
- ✅ Traefik forward-auth configured with Cookie header passing

---

## Test Procedure

### Step 1: Clear Browser State

**Chrome/Edge:**
1. Open DevTools (F12)
2. Application tab → Cookies
3. Delete all cookies for `*.inlock.ai` domain
4. Clear browser cache (Ctrl+Shift+Delete)

**Firefox:**
1. Open DevTools (F12)
2. Storage tab → Cookies
3. Delete all `*.inlock.ai` cookies
4. Clear cache

---

### Step 2: Initial Authentication

1. **Navigate to first subdomain:**
   ```
   https://grafana.inlock.ai
   ```

2. **Expected behavior:**
   - Redirected to Auth0 login page
   - Complete authentication
   - Redirected back to Grafana
   - Cookie `inlock_session` set for `.inlock.ai` domain

3. **Verify cookie:**
   - Open DevTools → Application/Storage → Cookies
   - Check `*.inlock.ai` domain
   - Should see `inlock_session` cookie
   - Cookie attributes:
     - Domain: `.inlock.ai` ✅
     - Path: `/` ✅
     - Secure: Yes ✅
     - SameSite: None ✅

---

### Step 3: Cross-Subdomain SSO Test

**Test Sequence (perform in order):**

1. **Without closing browser, navigate to:**
   ```
   https://portainer.inlock.ai
   ```
   
   **Expected:** ✅ Immediate access, NO authentication prompt

2. **Navigate to:**
   ```
   https://n8n.inlock.ai
   ```
   
   **Expected:** ✅ Immediate access, NO authentication prompt

3. **Navigate to:**
   ```
   https://dashboard.inlock.ai
   ```
   
   **Expected:** ✅ Immediate access, NO authentication prompt

4. **Navigate to:**
   ```
   https://traefik.inlock.ai
   ```
   
   **Expected:** ✅ Immediate access (with basic auth), NO OAuth prompt

5. **Navigate to:**
   ```
   https://deploy.inlock.ai
   ```
   
   **Expected:** ✅ Immediate access, NO authentication prompt

---

### Step 4: Logout and Re-Auth Test

1. **Logout from any service:**
   - Click logout button (or navigate to `/oauth2/sign_out`)

2. **Expected:**
   - Redirected to logout URL
   - Cookie cleared
   - Session terminated

3. **Navigate to a different subdomain:**
   ```
   https://grafana.inlock.ai
   ```
   
   **Expected:** ✅ Prompted for authentication again (expected behavior after logout)

4. **Authenticate again**

5. **Navigate to another subdomain:**
   ```
   https://portainer.inlock.ai
   ```
   
   **Expected:** ✅ No re-authentication (SSO working)

---

### Step 5: Cookie Domain Verification

**Manual Check:**

1. Open DevTools → Application → Cookies
2. Expand `.inlock.ai` domain
3. Verify cookie:
   ```
   Name: inlock_session
   Domain: .inlock.ai
   Path: /
   Expires: [future date]
   Size: [non-zero]
   HttpOnly: [yes/no - either is acceptable]
   Secure: Yes
   SameSite: None
   ```

---

## Expected Test Results

### ✅ Success Criteria

- [x] First authentication prompts user for login
- [x] Subsequent subdomain visits do NOT prompt for login
- [x] Cookie is visible in browser for `.inlock.ai` domain
- [x] Cookie has correct attributes (Secure, SameSite=None)
- [x] Logout clears cookie and session
- [x] Re-authentication works after logout

### ❌ Failure Indicators

- **Re-prompted on each subdomain:** Cookie domain or SameSite incorrect
- **CORS errors:** Web Origin not configured in Auth0
- **Cookie not visible:** Cookie domain mismatch or browser blocking
- **Infinite redirect loop:** Traefik forward-auth misconfigured
- **401 Unauthorized:** OAuth2-Proxy not receiving cookie

---

## Logging During Test

**Terminal 1: OAuth2-Proxy logs**
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env logs -f oauth2-proxy
```

**Terminal 2: Traefik logs**
```bash
docker compose -f compose/stack.yml --env-file .env logs -f traefik
```

**Watch for:**
- `[AuthSuccess]` messages when SSO works
- `No valid authentication` messages when re-prompting (expected only on first auth)
- Cookie-related errors

---

## Troubleshooting

### Issue: Re-prompted on Every Subdomain

**Check:**
1. Cookie domain is `.inlock.ai` (not specific subdomain)
2. Cookie SameSite is `None`
3. Cookie Secure is `true`
4. Browser allows third-party cookies (required for SameSite=None)

**Fix:**
```yaml
# In compose/stack.yml
OAUTH2_PROXY_COOKIE_DOMAIN=.inlock.ai
OAUTH2_PROXY_COOKIE_SAMESITE=none
OAUTH2_PROXY_COOKIE_SECURE=true
```

---

### Issue: Cookie Not Visible in DevTools

**Possible causes:**
- Cookie domain mismatch
- Cookie path issue
- Browser blocking third-party cookies
- HTTPS required but accessing HTTP

**Fix:**
- Ensure all services use HTTPS
- Check browser settings (allow third-party cookies for testing)
- Verify cookie domain in OAuth2-Proxy logs

---

### Issue: CORS Errors

**Check:**
- Auth0 Dashboard → Applications → `inlock-admin` → Settings
- Allowed Web Origins: `https://auth.inlock.ai`
- No trailing slash

---

## Test Results Template

```
Date: [YYYY-MM-DD]
Tester: [Name]
Browser: [Chrome/Firefox/Edge] [Version]

Test 1: Initial Auth
- Subdomain: grafana.inlock.ai
- Result: ✅/❌
- Notes: [any issues]

Test 2: Cross-Subdomain SSO
- Subdomains tested: [list]
- Result: ✅/❌
- Notes: [any re-prompts]

Test 3: Cookie Verification
- Cookie present: ✅/❌
- Domain: [actual]
- SameSite: [actual]
- Secure: [actual]

Test 4: Logout/Re-Auth
- Result: ✅/❌
- Notes: [behavior]

Overall: ✅ PASS / ❌ FAIL
```

---

**Last Updated:** 2025-12-13  
**Status:** Ready for testing

