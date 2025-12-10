# Auth0 Authentication Flow - Quick Reference

**Date:** December 10, 2025

---

## 🚫 Don't Do This

**❌ Do NOT visit `https://auth.inlock.ai/` directly**

This endpoint returns a 403 Forbidden error - **this is expected behavior**. The `auth.inlock.ai` subdomain is only for Traefik's internal forwardAuth checks and OAuth callbacks, not for direct browser access.

---

## ✅ Correct Authentication Flow

### Step-by-Step Process

1. **Visit the admin service you want to access:**
   - `https://traefik.inlock.ai/dashboard/`
   - `https://grafana.inlock.ai/`
   - `https://n8n.inlock.ai/`
   - `https://portainer.inlock.ai/`
   - etc.

2. **Traefik intercepts the request:**
   - Traefik's `admin-forward-auth` middleware checks authentication
   - Makes internal request to: `https://auth.inlock.ai/oauth2/auth_or_start`

3. **OAuth2-Proxy responds:**
   - If unauthenticated: Returns 302 redirect to Auth0 Universal Login
   - Browser is redirected to Auth0 login page

4. **User authenticates:**
   - Sign in with `streamartmedia@gmail.com` (or your Auth0 account)
   - Auth0 handles the authentication (Google/Apple/Passkey/MFA)

5. **Auth0 callback:**
   - Auth0 redirects to: `https://auth.inlock.ai/oauth2/callback`
   - OAuth2-Proxy validates the token and sets authentication cookie

6. **Redirect back:**
   - OAuth2-Proxy redirects browser back to original admin service
   - User is now authenticated and can access the service

---

## 🔄 Visual Flow

```
Browser → https://traefik.inlock.ai/dashboard/
    ↓
Traefik forwardAuth → https://auth.inlock.ai/oauth2/auth_or_start (internal)
    ↓
OAuth2-Proxy → 302 Redirect → Auth0 Universal Login
    ↓
User authenticates → Auth0
    ↓
Auth0 → https://auth.inlock.ai/oauth2/callback
    ↓
OAuth2-Proxy sets cookie → 302 Redirect → https://traefik.inlock.ai/dashboard/
    ↓
User accesses Traefik dashboard (authenticated)
```

---

## 🎯 Key Points

1. **Never visit `auth.inlock.ai` directly** - it's an internal endpoint
2. **Always start at the admin service** you want to access
3. **The redirect flow is automatic** - just follow the browser redirects
4. **After first login, cookies persist** - you won't need to re-authenticate until the cookie expires

---

## 🔍 Troubleshooting

### If you see "Unauthorized" or 401:
- Check if the forwardAuth endpoint is correct: `/oauth2/auth_or_start`
- Verify oauth2-proxy is running and healthy
- Check Traefik logs for forwardAuth errors

### If you see "403 Forbidden" on `auth.inlock.ai`:
- ✅ **This is normal** - the endpoint is internal only
- Start your authentication from an admin service instead

### If callback fails (CSRF errors):
- Verify cookie settings: `SameSite=none`, `Secure=true`
- Check that `OAUTH2_PROXY_INSECURE_OIDC_ALLOW_UNVERIFIED_EMAIL=true` is set
- Ensure callback URL matches Auth0 application settings

### If authentication works but access is still denied:
- Check IP allowlist in `allowed-admins` middleware
- Verify your IP is in the allowed list
- Check if you need to use Tailscale VPN

---

## 📋 Admin Service URLs

All of these use the same authentication flow:

| Service | URL | Notes |
|---------|-----|-------|
| **Traefik Dashboard** | `https://traefik.inlock.ai/dashboard/` | Main entry point |
| **Portainer** | `https://portainer.inlock.ai/` | Container management |
| **Grafana** | `https://grafana.inlock.ai/` | Monitoring dashboards |
| **n8n** | `https://n8n.inlock.ai/` | Workflow automation |
| **Coolify** | `https://deploy.inlock.ai/` | Deployment platform |
| **Homarr** | `https://dashboard.inlock.ai/` | Dashboard aggregator |

---

**Last Updated:** December 10, 2025  
**Related:** `docs/AUTH0-STACK-CONSISTENCY.md`, `docs/AUTH0-TESTING-GUIDE.md`

