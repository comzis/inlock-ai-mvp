# OAuth2-Proxy 404 Fix

**Date:** December 11, 2025  
**Issue:** 404 error when accessing `auth.inlock.ai` directly

## Problem

Accessing `https://auth.inlock.ai` directly returns "404 page not found".

## Root Cause

OAuth2-Proxy is configured with `OAUTH2_PROXY_UPSTREAMS=file:///dev/null`, which means it has no upstream service to serve content. When accessing the root path `/`, OAuth2-Proxy returns 404 because there's no content to serve.

## Expected Behavior

**This is actually correct behavior!** The `auth.inlock.ai` subdomain is designed for:
- **Internal use**: Traefik's forwardAuth middleware calls it
- **OAuth endpoints**: `/oauth2/auth_or_start`, `/oauth2/callback`, `/oauth2/auth`
- **NOT for direct browser access**: The root path `/` is not meant to be accessed directly

## Solution

### Option 1: Accept the 404 (Recommended)
- The 404 on root path is expected and harmless
- OAuth2-Proxy endpoints (`/oauth2/*`) work correctly
- Traefik forwardAuth uses the correct endpoints
- No action needed

### Option 2: Add Root Path Redirect (If desired)
If you want a friendlier message, you can add a redirect middleware:

```yaml
# In traefik/dynamic/routers.yml
oauth2-proxy:
  middlewares:
    - secure-headers
    - root-redirect  # Redirect / to /oauth2/start
    - mgmt-ratelimit
```

And add middleware:
```yaml
# In traefik/dynamic/middlewares.yml
root-redirect:
  redirectRegex:
    regex: "^https://auth.inlock.ai/$"
    replacement: "https://auth.inlock.ai/oauth2/start"
    permanent: false
```

## Current Status

- ✅ OAuth2-Proxy endpoints working: `/oauth2/auth_or_start`, `/oauth2/callback`
- ✅ Traefik forwardAuth working correctly
- ✅ Authentication flow functional
- ⚠️ Root path `/` returns 404 (expected behavior)

## Verification

**Test OAuth2-Proxy endpoints:**
```bash
# Should return 302 redirect to Auth0
curl -k -I https://auth.inlock.ai/oauth2/auth_or_start

# Should return 302 redirect
curl -k -I https://auth.inlock.ai/oauth2/start
```

**Test authentication flow:**
1. Visit `https://deploy.inlock.ai` (or any protected service)
2. Should redirect to Auth0 login
3. After login, redirects back to service

---

**Last Updated:** December 11, 2025  
**Status:** Working as designed - 404 on root path is expected
