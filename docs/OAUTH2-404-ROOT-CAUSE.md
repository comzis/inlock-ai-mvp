# OAuth2-Proxy 404 After Login - Root Cause Analysis

**Date:** December 11, 2025  
**Issue:** 404 error after successful Auth0 authentication

## Root Cause

After successful authentication:
1. ✅ User authenticates with Auth0
2. ✅ OAuth2-Proxy processes callback successfully
3. ❌ OAuth2-Proxy redirects to `/` (root path) → 404

**The Problem:**
- State parameter contains `:/` (colon slash) instead of original URL
- State format: `base64encoded:/` instead of `base64encoded:https://deploy.inlock.ai/`
- OAuth2-Proxy redirects based on state → redirects to `/` → 404

## Why State Contains `:/`

When Traefik's forwardAuth calls `/oauth2/auth_or_start`:
- OAuth2-Proxy creates state parameter
- Should extract original URL from `X-Forwarded-Uri` header
- But it's only getting `:/` instead of full URL
- This happens because forwardAuth doesn't pass the original URL correctly

## Current Configuration

**Traefik forwardAuth:**
- Endpoint: `https://auth.inlock.ai/oauth2/auth_or_start`
- Headers forwarded: `X-Forwarded-Uri`, `X-Forwarded-Host`, etc.
- Response headers: `X-Auth-Request-Redirect`

**OAuth2-Proxy:**
- Upstream: `static://202`
- Reverse proxy: Enabled
- Headers: Configured to read forwarded headers

## Solutions Attempted

1. ✅ Changed upstream to `static://202` (prevents content serving)
2. ✅ Added redirect middleware (catches root path redirects)
3. ✅ Configured forwarded headers in Traefik
4. ✅ Enabled reverse proxy mode in OAuth2-Proxy
5. ⚠️ Still redirecting to `/` after callback

## Next Steps

**Option 1: Fix State Parameter (Proper Fix)**
- Ensure OAuth2-Proxy extracts original URL from headers when creating state
- May require OAuth2-Proxy configuration changes or version update

**Option 2: Catch Root Redirects (Workaround)**
- Configure Traefik to catch redirects to `auth.inlock.ai/` and redirect to `deploy.inlock.ai`
- Already attempted but not working as expected

**Option 3: Use Different Endpoint**
- Try using `/oauth2/auth` for forwardAuth checks (returns 401 if not authenticated)
- Traefik can then redirect to `/oauth2/start` for login
- More complex but might work better

**Option 4: Temporary Workaround**
- Disable authentication for Coolify temporarily
- Access Coolify directly without OAuth2-Proxy
- Fix authentication later

## Recommendation

Try **Option 3** or temporarily disable authentication for Coolify to restore access, then fix the state parameter issue properly.

---

**Last Updated:** December 11, 2025  
**Status:** Root cause identified - State parameter issue
