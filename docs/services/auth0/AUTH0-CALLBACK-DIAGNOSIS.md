# Auth0 Callback Not Reaching Server - Diagnosis

**Date:** December 12, 2025  
**Issue:** Callback requests from Auth0 are not reaching OAuth2-Proxy

## Evidence

### Confirmed from Logs

1. **Redirect URL is correct:**
   - OAuth2-Proxy redirects to: `https://comzis.eu.auth0.com/authorize?...&redirect_uri=https%3A%2F%2Fauth.inlock.ai%2Foauth2%2Fcallback&...`
   - Decoded: `redirect_uri=https://auth.inlock.ai/oauth2/callback`

2. **PKCE is working:**
   - `code_challenge_method=S256` is present in redirect URL

3. **No callback requests in logs:**
   - OAuth2-Proxy logs show zero `/oauth2/callback` entries
   - Traefik logs show zero `/oauth2/callback` entries
   - Only `/oauth2/auth` requests (returning 202 - auth required)

4. **State parameter issue:**
   - State contains only `:/` instead of full original URL
   - Example: `state=...%3A%2F` decodes to `...:/`

## Root Cause Hypothesis

**Most Likely:** The callback URL `https://auth.inlock.ai/oauth2/callback` is **not configured in Auth0 Application Settings**.

When Auth0 doesn't recognize a callback URL, it:
1. Shows an error to the user
2. Does NOT redirect to the callback URL
3. Callback never reaches our server

## Required Auth0 Configuration

**Application:** `inlock-admin` (Regular Web Application)

**Settings that MUST be configured:**

1. **Allowed Callback URLs:**
   ```
   https://auth.inlock.ai/oauth2/callback
   ```

2. **Allowed Logout URLs:**
   ```
   https://auth.inlock.ai/
   https://traefik.inlock.ai/
   https://portainer.inlock.ai/
   https://grafana.inlock.ai/
   ```

## Verification Steps

1. **Check Auth0 Dashboard:**
   - Go to: https://manage.auth0.com/
   - Navigate to: Applications → `inlock-admin`
   - Check "Allowed Callback URLs" field
   - Verify it contains: `https://auth.inlock.ai/oauth2/callback`

2. **Test Callback URL:**
   ```bash
   # This should return 404 or handle the callback
   curl -I https://auth.inlock.ai/oauth2/callback
   ```

3. **Check OAuth2-Proxy Configuration:**
   ```bash
   cd /home/comzis/inlock-infra
   docker exec compose-oauth2-proxy-1 env | grep OAUTH2_PROXY_REDIRECT_URL
   ```
   Should show: `OAUTH2_PROXY_REDIRECT_URL=https://auth.inlock.ai/oauth2/callback`

## If Callback URL is Correct in Auth0

If the callback URL is correctly configured in Auth0 but callbacks still don't reach the server:

1. **Check Auth0 Logs:**
   - Auth0 Dashboard → Monitoring → Logs
   - Look for failed login attempts or callback rejections

2. **Check Network Connectivity:**
   - Ensure `auth.inlock.ai` is publicly accessible
   - Check DNS resolution
   - Verify SSL certificate is valid

3. **Check for Rate Limiting:**
   - Auth0 may be rate limiting if too many requests

## Current Configuration Status

- ✅ OAuth2-Proxy redirect URL: `https://auth.inlock.ai/oauth2/callback`
- ✅ PKCE enabled: `S256`
- ✅ OIDC Issuer: `https://comzis.eu.auth0.com/`
- ❌ Callbacks not reaching server (configuration issue suspected)

---

**Next Step:** Verify Auth0 Application Settings match the configuration above.

