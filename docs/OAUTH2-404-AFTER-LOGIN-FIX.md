# OAuth2-Proxy 404 After Login Fix

**Date:** December 11, 2025  
**Issue:** 404 error after successful Auth0 login

## Problem

After successfully authenticating with Auth0, users are redirected to `auth.inlock.ai/` which returns 404.

## Root Cause

OAuth2-Proxy was configured with `OAUTH2_PROXY_UPSTREAMS=file:///dev/null`, which means:
- No upstream service to serve content
- After callback, OAuth2-Proxy doesn't know where to redirect
- If state parameter points to root `/`, it redirects there → 404

## Solution

**Changed upstream to `static://202`:**
- Returns HTTP 202 (Accepted) status after authentication
- OAuth2-Proxy uses the state parameter to redirect to original service
- `SET_XAUTHREQUEST_REDIRECT=true` ensures proper redirect handling

**Configuration changes:**
```yaml
- OAUTH2_PROXY_UPSTREAMS=static://202  # Changed from file:///dev/null
- OAUTH2_PROXY_SET_XAUTHREQUEST_REDIRECT=true  # Added
- OAUTH2_PROXY_WHITELIST_DOMAIN=.inlock.ai  # Added
```

## How It Works Now

1. User accesses protected service (e.g., `deploy.inlock.ai`)
2. Traefik forwardAuth calls `/oauth2/auth_or_start`
3. OAuth2-Proxy redirects to Auth0 with state containing original URL
4. User authenticates with Auth0
5. Auth0 redirects to `/oauth2/callback` with code and state
6. OAuth2-Proxy processes callback and redirects back to original service (from state)
7. User can now access the protected service

## Expected Behavior

- ✅ After login, redirects back to original service (not `auth.inlock.ai/`)
- ✅ No 404 errors
- ✅ Authentication cookie set correctly
- ✅ Access granted to protected services

## Verification

**Test the flow:**
1. Visit `https://deploy.inlock.ai` (or any protected service)
2. Should redirect to Auth0 login
3. After login, should redirect back to `deploy.inlock.ai` (not 404)
4. Access granted

---

**Last Updated:** December 11, 2025  
**Status:** Fixed - Upstream changed to static://202
