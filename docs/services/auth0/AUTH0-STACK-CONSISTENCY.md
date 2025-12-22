# Auth0 Stack Consistency Guide

**Date:** December 10, 2025  
**Principle:** Auth0 as single source of truth for all authentication

---

## 🎯 Core Principles

1. **Auth0 Everywhere** - All authentication flows through Auth0
2. **Traefik Forward-Auth** - All admin services use `admin-forward-auth` middleware
3. **Role-Driven Access** - Roles injected via Auth0 Action, passed as headers
4. **NextAuth for Frontend** - Public app uses NextAuth.js with Auth0
5. **Centralized Logging** - All auth events logged in Auth0

---

## 📋 Service Authentication Matrix

| Service | Domain | Auth Method | Middleware | Roles Header |
|---------|-------|-------------|------------|--------------|
| **Traefik Dashboard** | `traefik.inlock.ai` | OAuth2-Proxy | `admin-forward-auth` | `X-Auth-Request-Groups` |
| **Portainer** | `portainer.inlock.ai` | OAuth2-Proxy | `admin-forward-auth` | `X-Auth-Request-Groups` |
| **Grafana** | `grafana.inlock.ai` | OAuth2-Proxy | `admin-forward-auth` | `X-Auth-Request-Groups` |
| **n8n** | `n8n.inlock.ai` | OAuth2-Proxy | `admin-forward-auth` | `X-Auth-Request-Groups` |
| **Inlock AI App** | `inlock.ai` | NextAuth.js | N/A (app-level) | `session.user.roles` |
| **OAuth2-Proxy** | `auth.inlock.ai` | N/A (callback) | `secure-headers` | N/A |

---

## 🔧 Adding New Admin Services

### Step 1: Add Service to Docker Compose

```yaml
services:
  new-service:
    image: new-service:latest
    networks:
      - mgmt
      - edge
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.new-service.rule=Host(`new-service.inlock.ai`)"
      - "traefik.http.routers.new-service.entrypoints=websecure"
      - "traefik.http.routers.new-service.middlewares=secure-headers@file,admin-forward-auth@file,allowed-admins@file,mgmt-ratelimit@file"
      - "traefik.http.routers.new-service.tls.certresolver=le-dns"
      - "traefik.http.services.new-service.loadbalancer.server.port=8080"
```

### Step 2: Add Router to `traefik/dynamic/routers.yml`

```yaml
new-service:
  entryPoints:
    - websecure
  rule: Host(`new-service.inlock.ai`)
  middlewares:
    - secure-headers
    - admin-forward-auth  # ✅ Always use this for admin services
    - allowed-admins
    - mgmt-ratelimit
  service: new-service
  tls:
    certResolver: le-dns
```

### Step 3: Add Service Definition to `traefik/dynamic/services.yml`

```yaml
new-service:
  loadBalancer:
    servers:
      - url: http://new-service:8080
```

### Step 4: Verify Auth0 Configuration

- Ensure callback URL is configured: `https://auth.inlock.ai/oauth2/callback`
- Test authentication flow
- Verify roles are passed in headers

---

## 🔐 Role-Based Access Control

### Auth0 Action (Required)

**Location:** Auth0 Dashboard → Actions → Flows → Login

**Code:**
```javascript
exports.onExecutePostLogin = async (event, api) => {
  const namespace = 'https://inlock.ai';
  
  if (event.authorization) {
    // Inject roles into ID token for NextAuth.js
    api.idToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
    
    // Also available in access token if needed
    api.accessToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
  }
};
```

### Using Roles in Services

**OAuth2-Proxy (Admin Services):**
- Roles passed as `X-Auth-Request-Groups` header
- Service can check header for authorization

**NextAuth.js (Frontend):**
- Roles available in `session.user.roles`
- Use for UI rendering and API authorization

**Example Authorization Check:**
```typescript
// In Next.js app
import { useSession } from "next-auth/react";

function AdminPanel() {
  const { data: session } = useSession();
  
  if (!session?.user?.roles?.includes('admin')) {
    return <div>Access Denied</div>;
  }
  
  return <div>Admin Content</div>;
}
```

---

## 🔄 Authentication Flow Patterns

### Pattern 1: Admin Service (OAuth2-Proxy)

```
User → https://service.inlock.ai
  ↓
Traefik → admin-forward-auth middleware
  ↓
Traefik calls https://auth.inlock.ai/oauth2/auth (public endpoint)
  ↓
OAuth2-Proxy sees browser request → /oauth2/auth
  ↓
Not authenticated → OAuth2-Proxy redirects browser to /oauth2/start
  ↓
OAuth2-Proxy → Redirects browser to Auth0 login
  ↓
Auth0 login (Google/Apple/Passkey)
  ↓
Auth0 → https://auth.inlock.ai/oauth2/callback
  ↓
OAuth2-Proxy validates → Sets cookie
  ↓
Redirect to original service
  ↓
Traefik calls https://auth.inlock.ai/oauth2/auth again (now authenticated)
  ↓
OAuth2-Proxy returns 200 with auth headers
  ↓
Service receives X-Auth-Request-Groups header
```

**Important:** The forwardAuth address must use the **public endpoint** (`https://auth.inlock.ai/oauth2/auth`) rather than the internal service URL (`http://oauth2-proxy:4180/oauth2/auth`). This allows oauth2-proxy to see the browser request and redirect it to Auth0. Using the internal URL causes oauth2-proxy to return 401, which Traefik passes through without redirecting the browser.

### Pattern 2: Public App (NextAuth.js)

```
User → https://inlock.ai/auth/signin
  ↓
NextAuth.js → signIn("auth0")
  ↓
Redirect to Auth0 login
  ↓
Auth0 login (Google/Apple/Passkey)
  ↓
Auth0 → https://inlock.ai/api/auth/callback/auth0
  ↓
NextAuth.js creates session
  ↓
Session includes roles from Auth0 token
  ↓
User redirected to app with session
```

---

## ✅ Consistency Checklist

When adding a new service, verify:

- [ ] Service uses `admin-forward-auth` middleware (if admin)
- [ ] Router configured in `traefik/dynamic/routers.yml`
- [ ] Service defined in `traefik/dynamic/services.yml`
- [ ] Auth0 callback URL configured (if using OAuth2-Proxy)
- [ ] Roles assigned in Auth0 (if role-based access needed)
- [ ] Tested authentication flow
- [ ] Verified roles appear in headers/session
- [ ] Added to monitoring scripts
- [ ] Documented in this guide

---

## 📊 Monitoring

### Real-time Monitoring

```bash
# Monitor all auth flows
./scripts/test-auth-flow.sh all

# Monitor specific service
./scripts/test-auth-flow.sh oauth2-proxy
./scripts/test-auth-flow.sh nextauth
```

### Log Checks

```bash
# OAuth2-Proxy logs
docker logs compose-oauth2-proxy-1 --tail 50

# NextAuth.js logs
docker logs compose-inlock-ai-1 --tail 50 | grep -i auth

# Traefik logs
docker logs compose-traefik-1 --tail 50 | grep -i auth
```

---

## 🔒 Security Best Practices

1. **Always use `admin-forward-auth`** for admin services
2. **Never bypass authentication** for admin endpoints
3. **Use role-based checks** in addition to authentication
4. **Monitor Auth0 logs** for suspicious activity
5. **Rotate secrets regularly** (see `docs/SECRET-MANAGEMENT.md`)
6. **Keep Traefik updated** (currently v3.6.4)

---

## 🚀 Quick Reference

### Current Admin Services

All use `admin-forward-auth`:
- ✅ Traefik Dashboard
- ✅ Portainer
- ✅ Grafana
- ✅ n8n

### Public Services

- ✅ Inlock AI App (NextAuth.js)

### Callback URLs

- **OAuth2-Proxy:** `https://auth.inlock.ai/oauth2/callback`
- **NextAuth.js:** `https://inlock.ai/api/auth/callback/auth0`

---

**Last Updated:** December 10, 2025  
**Related:** `docs/AUTH0-NEXTAUTH-SETUP.md`, `docs/AUTH0-TESTING-GUIDE.md`

