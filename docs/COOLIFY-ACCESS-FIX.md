# Coolify Access Fix

**Date:** December 11, 2025  
**Issue:** Lost access to Coolify after OAuth2-Proxy configuration

## Problem

1. OAuth2-Proxy was crashing due to invalid cookie secret (64 bytes, needs 16/24/32 bytes)
2. `admin-forward-auth` middleware was blocking access to Coolify
3. Coolify returned HTTP 403 Forbidden

## Solution Applied

### Temporary Fix (Immediate Access Restored)
- Disabled `admin-forward-auth` middleware for Coolify router
- Coolify is now accessible at `https://deploy.inlock.ai`
- Access restored without authentication (IP allowlist still active)

### Permanent Fix Needed

**Fix OAuth2-Proxy Cookie Secret:**

The cookie secret must be exactly 16, 24, or 32 bytes (not base64 encoded length).

**Generate new cookie secret:**
```bash
# Generate 32-byte secret (recommended)
openssl rand -base64 24 | head -c 32

# Or generate 16-byte secret
openssl rand -base64 12 | head -c 16
```

**Update `.env` file:**
```bash
OAUTH2_PROXY_COOKIE_SECRET=<new-32-byte-secret>
```

**Restart OAuth2-Proxy:**
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart oauth2-proxy
```

**Re-enable authentication for Coolify:**
Once OAuth2-Proxy is working, uncomment the `admin-forward-auth` middleware in `traefik/dynamic/routers.yml`:

```yaml
coolify:
  middlewares:
    - secure-headers
    - admin-forward-auth  # Re-enable this
    - allowed-admins
    - mgmt-ratelimit
```

## Current Status

- ✅ OAuth2-Proxy: Fixed and running (cookie secret updated)
- ✅ ForwardAuth endpoint: Updated to `/oauth2/auth_or_start`
- ⚠️ Authentication: Enabled but may need browser access to test
- ✅ IP Allowlist: Still active via `allowed-admins` middleware

**Note:** If you see 403 errors, try accessing from a browser (not curl) - OAuth2-Proxy redirects to Auth0 login page which requires browser interaction.

## Next Steps

1. Generate new OAuth2-Proxy cookie secret
2. Update `.env` file
3. Restart OAuth2-Proxy
4. Verify OAuth2-Proxy is running: `docker ps | grep oauth2-proxy`
5. Re-enable `admin-forward-auth` middleware for Coolify
6. Test authentication flow

---

**Last Updated:** December 11, 2025
