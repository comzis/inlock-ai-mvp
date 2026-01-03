# Subdomain Authentication Matrix

**Date:** 2025-12-29  
**Status:** Current Configuration

---

## Summary

**No, authentication does NOT apply to all subdomains.** Different subdomains have different authentication requirements based on their purpose.

---

## Authentication Status by Subdomain

### 🔒 **Protected with Auth0 (admin-forward-auth middleware)**

These subdomains require Auth0 authentication via OAuth2-Proxy before access:

| Subdomain | Service | Authentication | Notes |
|-----------|---------|----------------|-------|
| `traefik.inlock.ai` | Traefik Dashboard | ✅ Auth0 | Only `/dashboard` path |
| `portainer.inlock.ai` | Portainer | ✅ Auth0 | Container management |
| `n8n.inlock.ai` | n8n | ✅ Auth0 | Workflow automation |
| `grafana.inlock.ai` | Grafana | ✅ Auth0 | Monitoring dashboards |
| `deploy.inlock.ai` | Coolify | ✅ Auth0 | Deployment platform |
| `dashboard.inlock.ai` | Homarr | ✅ Auth0 | Dashboard aggregator |
| `cockpit.inlock.ai` | Cockpit | ✅ Auth0 | Server management |

**All of these:**
- Use `admin-forward-auth` middleware
- Redirect unauthenticated users to Auth0 login
- Are publicly accessible via DNS but require authentication
- Use HTTPS/TLS encryption
- Have rate limiting (except n8n)

---

### 🌐 **Public (No Auth0 authentication)**

These subdomains are publicly accessible without Auth0 authentication:

| Subdomain | Service | Authentication | Notes |
|-----------|---------|----------------|-------|
| `inlock.ai` / `www.inlock.ai` | Inlock AI App | ✅ NextAuth.js | App-level authentication (not Traefik) |
| `mail.inlock.ai` | Mailcow | ❌ None | Email server (has its own login) |
| `auth.inlock.ai` | OAuth2-Proxy | ❌ None | Auth callback endpoint (no auth needed) |

**Details:**

1. **`inlock.ai` / `www.inlock.ai`** (Main App)
   - **Public:** Yes, anyone can access
   - **Authentication:** Uses NextAuth.js at application level
   - **Middleware:** Only `secure-headers` (no `admin-forward-auth`)
   - **Purpose:** Production web application
   - **Note:** Users authenticate within the app, not via Traefik

2. **`mail.inlock.ai`** (Mailcow)
   - **Public:** Yes, anyone can access
   - **Authentication:** Mailcow's own login system
   - **Middleware:** Only `secure-headers` (no `admin-forward-auth`)
   - **Purpose:** Email server web interface
   - **Note:** Mailcow handles its own authentication

3. **`auth.inlock.ai`** (OAuth2-Proxy)
   - **Public:** Yes, for OAuth callbacks
   - **Authentication:** N/A (this IS the authentication service)
   - **Middleware:** `secure-headers` and redirects
   - **Purpose:** OAuth2 callback endpoint
   - **Note:** This is where Auth0 redirects after login

---

## Configuration Details

### Admin Services (Protected)

All admin services use this middleware stack:
```yaml
middlewares:
  - secure-headers          # Security headers
  - admin-forward-auth      # Auth0 authentication (REQUIRED)
  - mgmt-ratelimit          # Rate limiting (most services)
```

### Public Services

Public services use minimal middleware:
```yaml
middlewares:
  - secure-headers          # Security headers only
  # No admin-forward-auth
```

---

## Security Implications

### ✅ **Secure:**
- All admin services require Auth0 authentication
- All traffic is encrypted (HTTPS/TLS)
- Rate limiting on most admin services
- Security headers applied to all services

### ⚠️ **Considerations:**
- `mail.inlock.ai` is public (relies on Mailcow's authentication)
- `inlock.ai` is public but has app-level authentication
- `auth.inlock.ai` must be public (OAuth callback endpoint)

---

## Adding New Services

### For Admin Services (Protected):
```yaml
new-admin-service:
  entryPoints:
    - websecure
  rule: Host(`new-service.inlock.ai`)
  middlewares:
    - secure-headers
    - admin-forward-auth      # REQUIRED
    - mgmt-ratelimit
  service: new-service
  tls:
    certResolver: le-dns
```

### For Public Services:
```yaml
new-public-service:
  entryPoints:
    - websecure
  rule: Host(`new-service.inlock.ai`)
  middlewares:
    - secure-headers          # Only security headers
  service: new-service
  tls:
    certResolver: le-dns
```

---

## Quick Reference

**Protected Subdomains (7):**
- `traefik.inlock.ai`
- `portainer.inlock.ai`
- `n8n.inlock.ai`
- `grafana.inlock.ai`
- `deploy.inlock.ai`
- `dashboard.inlock.ai`
- `cockpit.inlock.ai`

**Public Subdomains (3):**
- `inlock.ai` / `www.inlock.ai` (app-level auth)
- `mail.inlock.ai` (Mailcow auth)
- `auth.inlock.ai` (OAuth callback)

---

**Last Updated:** 2025-12-29











