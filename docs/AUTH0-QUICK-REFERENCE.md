# Auth0 Configuration - Quick Reference

## Application URLs Summary

### inlock-admin (Regular Web App)

**Purpose:** OAuth2-Proxy authentication for admin services (Traefik, Portainer, Grafana, n8n)

**Allowed Callback URLs:**
```
https://auth.inlock.ai/oauth2/callback
```

**Allowed Logout URLs:**
```
https://auth.inlock.ai/oauth2/callback
https://traefik.inlock.ai/
```

**Why:** The oauth2-proxy service listens at `auth.inlock.ai` and handles the OAuth2 flow. After Auth0 authenticates the user, it redirects to this callback URL, and oauth2-proxy then forwards the user to the admin service they were trying to access (e.g., `traefik.inlock.ai`, `portainer.inlock.ai`).

---

### inlock-web (Single Page App)

**Purpose:** NextAuth.js authentication for the Next.js frontend

**Allowed Callback URLs:**
```
https://inlock.ai/api/auth/callback/auth0
http://localhost:3040/api/auth/callback/auth0
```

**Allowed Logout URLs:**
```
https://inlock.ai
http://localhost:3040
```

**Allowed Web Origins:**
```
https://inlock.ai
http://localhost:3040
```

**Why:** NextAuth.js uses the `/api/auth/callback/auth0` endpoint to handle the OAuth2 callback. After Auth0 authenticates, it redirects here, and NextAuth.js completes the session setup.

---

## Environment Variables Checklist

### Infrastructure (`/home/comzis/inlock-infra/.env`)

```bash
# Auth0 Configuration
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_ISSUER=https://your-tenant.auth0.com
AUTH0_ADMIN_CLIENT_ID=from-inlock-admin-app
AUTH0_ADMIN_CLIENT_SECRET=from-inlock-admin-app

# OAuth2-Proxy
OAUTH2_COOKIE_SECRET=$(openssl rand -hex 32)

# Vault
VAULT_ADDR=http://vault:8200
VAULT_TOKEN=dev-root-token  # or use AppRole for production
```

### Application (`/opt/inlock-ai-secure-mvp/.env.production`)

```bash
# Auth0 for NextAuth.js
AUTH0_WEB_CLIENT_ID=from-inlock-web-app
AUTH0_WEB_CLIENT_SECRET=from-inlock-web-app
AUTH0_ISSUER=https://your-tenant.auth0.com/

# NextAuth.js
NEXTAUTH_SECRET=$(openssl rand -hex 32)
NEXTAUTH_URL=https://inlock.ai
```

---

## Quick Setup Steps

1. **Create Auth0 Applications**
   - `inlock-admin` → Regular Web App → Callback: `https://auth.inlock.ai/oauth2/callback`
   - `inlock-web` → Single Page App → Callback: `https://inlock.ai/api/auth/callback/auth0`

2. **Configure Environment Variables**
   - Copy values from Auth0 Dashboard to `.env` files

3. **Install NextAuth.js**
   ```bash
   cd /opt/inlock-ai-secure-mvp
   npm install next-auth
   ```

4. **Deploy Services**
   ```bash
   cd /home/comzis/inlock-infra
   ./scripts/deploy-manual.sh
   ```

5. **Test**
   - Admin: Visit `https://traefik.inlock.ai` → Should redirect to Auth0
   - Frontend: Visit `https://inlock.ai/auth/signin` → Should show Auth0 login

---

## Troubleshooting

**Issue:** "Redirect URI mismatch" error
- **Fix:** Verify callback URLs in Auth0 Dashboard match exactly (including trailing slashes)

**Issue:** OAuth2-Proxy not redirecting
- **Check:** `OAUTH2_PROXY_REDIRECT_URL` in compose/stack.yml matches Auth0 callback URL
- **Check:** `auth.inlock.ai` DNS record points to your server

**Issue:** NextAuth.js callback failing
- **Check:** `NEXTAUTH_URL` matches your domain exactly
- **Check:** Callback URL in Auth0 matches `/api/auth/callback/auth0`

---

**Last Updated:** December 10, 2025  
**Related:** `docs/AUTH0-NEXTAUTH-SETUP.md`

