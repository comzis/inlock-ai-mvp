# Auth0 Configuration Fix Required

## Issue
Callback requests from Auth0 are not reaching OAuth2-Proxy server.

## Root Cause
The callback URL `https://auth.inlock.ai/oauth2/callback` must be configured in Auth0 Application Settings.

## Action Required

### Step 1: Verify Auth0 Application Settings

1. Go to: https://manage.auth0.com/
2. Navigate to: **Applications** → **Applications** → Select `inlock-admin`
3. Check the **Allowed Callback URLs** field

### Step 2: Add Callback URL

**Required Callback URL:**
```
https://auth.inlock.ai/oauth2/callback
```

**If the field is empty or doesn't contain this URL:**
1. Add: `https://auth.inlock.ai/oauth2/callback`
2. Click **Save Changes**

### Step 3: Verify Other Settings

**Allowed Logout URLs:** (comma-separated format, no trailing slashes)
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

**Allowed Web Origins:** (Leave empty or add)
```
https://auth.inlock.ai
```

### Step 4: Test

1. Clear browser cookies for `*.inlock.ai`
2. Visit: `https://grafana.inlock.ai` (or any protected service)
3. Should redirect to Auth0 login
4. After login, should redirect back successfully

## Current Server Configuration

✅ **OAuth2-Proxy redirect URL:** `https://auth.inlock.ai/oauth2/callback`  
✅ **PKCE enabled:** S256  
✅ **OIDC Issuer:** `https://comzis.eu.auth0.com/`  
✅ **Callback endpoint accessible:** Returns 403 (expected without OAuth params)

## Evidence

- Redirect URL in OAuth2 request: `redirect_uri=https://auth.inlock.ai/oauth2/callback`
- No callback requests in server logs
- Server configuration is correct

---

**Once Auth0 is configured, authentication should work correctly.**

