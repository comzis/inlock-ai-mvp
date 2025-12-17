# OAuth2-Proxy Redirect Loop Fix

**Date:** December 11, 2025  
**Issue:** "Too many redirects" error when accessing protected services

## Problem

After adding `auth-root-redirect` middleware to redirect root path `/` to `/oauth2/start`, a redirect loop occurred:
1. User accesses protected service (e.g., Coolify, Grafana)
2. Traefik forwardAuth checks authentication
3. OAuth2-Proxy redirects to Auth0
4. Auth0 redirects back to `/oauth2/callback`
5. Callback processes but then redirects again, creating a loop

## Root Cause

The `auth-root-redirect` middleware was interfering with the OAuth2 callback flow. While the regex should only match root path, it was causing issues with the authentication flow.

## Solution

**Removed `auth-root-redirect` middleware** from OAuth2-Proxy router:
- Root path `/` will return 404 (expected behavior)
- OAuth2 endpoints (`/oauth2/*`) work correctly
- Callback flow no longer loops

## Current Configuration

**OAuth2-Proxy Router:**
```yaml
oauth2-proxy:
  rule: Host(`auth.inlock.ai`)
  middlewares:
    - secure-headers
    - mgmt-ratelimit
  # No auth-root-redirect - causes redirect loops
  # No allowed-admins - OAuth2-Proxy handles auth
```

## Expected Behavior

- ✅ Root path `/` returns 404 (acceptable - not meant for direct access)
- ✅ `/oauth2/auth_or_start` works for forwardAuth
- ✅ `/oauth2/callback` processes Auth0 callbacks correctly
- ✅ `/oauth2/start` redirects to Auth0 login
- ✅ Authentication flow completes without loops

## Verification

**Test authentication flow:**
1. Visit `https://deploy.inlock.ai` (or any protected service)
2. Should redirect to Auth0 login (no loop)
3. After login, redirects back to service
4. Access granted

**Test OAuth2 endpoints:**
```bash
# Should redirect to Auth0 (no loop)
curl -k -L https://auth.inlock.ai/oauth2/start

# Callback should process (not loop)
curl -k -I https://auth.inlock.ai/oauth2/callback
```

---

**Last Updated:** December 11, 2025  
**Status:** Fixed - Redirect loop resolved
