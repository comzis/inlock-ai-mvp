# OAuth2-Proxy 404 After Login - Final Fix

**Date:** December 11, 2025  
**Issue:** 404 error after successful Auth0 authentication

## Problem

After successful authentication with Auth0:
1. User authenticates successfully ✅
2. OAuth2-Proxy processes callback ✅
3. OAuth2-Proxy redirects to `/` (root path) ❌
4. Root path returns 404 ❌

## Root Cause

The state parameter in OAuth2 flow contains `:/` (root path) instead of the original service URL (e.g., `https://deploy.inlock.ai/`). This happens because:

1. When Traefik's forwardAuth calls `/oauth2/auth_or_start`, OAuth2-Proxy creates a state parameter
2. The state should contain the original URL, but it's only getting `:/`
3. After callback, OAuth2-Proxy redirects based on state → redirects to `/` → 404

## Current Configuration

**Traefik forwardAuth:**
- Endpoint: `https://auth.inlock.ai/oauth2/auth_or_start`
- Headers forwarded: `X-Forwarded-Uri`, `X-Forwarded-Host`, etc.
- Response headers: `X-Auth-Request-Redirect`

**OAuth2-Proxy:**
- Upstream: `static://202`
- Reverse proxy mode: Enabled
- Headers: Configured to read forwarded headers

## Solution Options

### Option 1: Clear Browser Cookies and Retry (Quick Test)
The 404 might be from a stale state parameter. Clear cookies for `auth.inlock.ai` and `*.inlock.ai`, then try again.

### Option 2: Configure Default Redirect (Current)
Added `OAUTH2_PROXY_SIGNOUT_REDIRECT=https://deploy.inlock.ai` as a fallback.

### Option 3: Fix State Parameter (Proper Fix)
The state parameter needs to contain the original URL. This requires OAuth2-Proxy to extract it from `X-Forwarded-Uri` header when creating the state.

**Check if headers are being passed:**
```bash
# Check OAuth2-Proxy logs for forwarded headers
docker logs compose-oauth2-proxy-1 | grep -i "forwarded"
```

## Testing

1. **Clear browser cookies** for `auth.inlock.ai` and `*.inlock.ai`
2. **Visit** `https://deploy.inlock.ai`
3. **Authenticate** with Auth0
4. **After callback**, should redirect to `deploy.inlock.ai` (not 404)

## Expected Behavior

- ✅ Redirects to Auth0 login
- ✅ After login, redirects back to original service
- ✅ No 404 errors
- ✅ Access granted

## If Still Getting 404

The issue might be that OAuth2-Proxy isn't extracting the original URL from headers. Check:

1. **OAuth2-Proxy logs** - see what URL is in the state parameter
2. **Browser network tab** - see where the redirect goes after callback
3. **Clear all cookies** - stale state might cause issues

---

**Last Updated:** December 11, 2025  
**Status:** Configuration updated - testing needed
