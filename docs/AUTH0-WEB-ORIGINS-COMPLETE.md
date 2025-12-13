# Auth0 Web Origins Configuration - Complete Guide

**Date:** 2025-12-13  
**Purpose:** Ensure all subdomains are configured in Auth0 for silent auth and cross-subdomain SSO  
**Priority:** 🔴 Critical for cross-subdomain SSO

---

## Required Auth0 Configuration

### Allowed Web Origins (CORS)

**Purpose:** Enables silent authentication and prevents CORS errors when OAuth2-Proxy makes requests to Auth0.

**Location:** Auth0 Dashboard → Applications → `inlock-admin` → Settings → Allowed Web Origins (CORS)

**Required Configuration:**
```
https://auth.inlock.ai
```

**Status:** ✅ Currently configured (verified 2025-12-13)

---

## Allowed Callback URLs

**Purpose:** Where Auth0 redirects after authentication.

**Required:**
```
https://auth.inlock.ai/oauth2/callback
```

**Status:** ✅ Verified and configured (2025-12-13)

---

## Allowed Logout URLs

**Purpose:** Where users can be redirected after logout.

**Required:**
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

**Status:** ✅ Configured (2025-12-13)

---

## Why Single Web Origin is Sufficient

**Important:** Only ONE web origin is needed: `https://auth.inlock.ai`

**Reason:**
- OAuth2-Proxy runs on `auth.inlock.ai`
- All authentication requests go through OAuth2-Proxy
- Other subdomains (portainer, grafana, n8n, etc.) don't directly call Auth0
- They use OAuth2-Proxy's forward-auth mechanism

**How It Works:**
1. User accesses `portainer.inlock.ai`
2. Traefik forwards auth check to `auth.inlock.ai` (OAuth2-Proxy)
3. OAuth2-Proxy checks with Auth0 (using web origin `https://auth.inlock.ai`)
4. Cookie is set for `.inlock.ai` domain (works for all subdomains)
5. User accesses other subdomains without re-authentication

---

## Verification Steps

### Step 1: Verify Current Configuration

1. Go to: https://manage.auth0.com/
2. Navigate: Applications → Applications → `inlock-admin`
3. Check Settings section:
   - **Allowed Web Origins:** Should contain `https://auth.inlock.ai`
   - **Allowed Callback URLs:** Should contain `https://auth.inlock.ai/oauth2/callback`
   - **Allowed Logout URLs:** Should contain all service URLs

### Step 2: Test Silent Auth

1. Clear browser cookies for `*.inlock.ai`
2. Visit: `https://grafana.inlock.ai`
3. Complete authentication
4. Visit: `https://portainer.inlock.ai` (different subdomain)
5. **Expected:** No re-authentication prompt (silent SSO)

---

## Current Status

- ✅ **Callback URL:** Verified and present
- ✅ **Web Origin:** Configured (`https://auth.inlock.ai`)
- ✅ **Logout URLs:** Configured (all 8 services)

**Note:** Only `auth.inlock.ai` needs to be in Web Origins. Other subdomains don't need to be listed because they don't directly communicate with Auth0 - they use OAuth2-Proxy as an intermediary.

---

## Troubleshooting

### Issue: Silent Auth Not Working

**Symptoms:**
- User prompted for login on every subdomain
- Cookie not recognized across subdomains

**Check:**
1. Cookie domain is `.inlock.ai` (not specific subdomain)
2. Cookie SameSite is `None`
3. Cookie Secure is `true`
4. Web Origin includes `https://auth.inlock.ai`

### Issue: CORS Errors

**Symptoms:**
- Browser console shows CORS errors
- Authentication fails with CORS messages

**Solution:**
- Ensure `https://auth.inlock.ai` is in Allowed Web Origins
- No trailing slash in web origin URL

---

**Last Verified:** 2025-12-13  
**Status:** ✅ Configured correctly for cross-subdomain SSO

