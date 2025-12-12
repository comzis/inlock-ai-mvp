# Adding a New Admin Service - Quick Guide

**Date:** December 10, 2025  
**Pattern:** Auth0 + OAuth2-Proxy + Traefik Forward-Auth

---

## 🚀 Quick Start Checklist

When adding a new admin service, follow this checklist:

- [ ] Add service to `compose/stack.yml`
- [ ] Add router to `traefik/dynamic/routers.yml` with `admin-forward-auth`
- [ ] Add service definition to `traefik/dynamic/services.yml`
- [ ] Run `./scripts/verify-auth-consistency.sh` to verify
- [ ] Test authentication flow
- [ ] Update this checklist if needed

---

## 📝 Step-by-Step

### 1. Add Service to Docker Compose

```yaml
# In compose/stack.yml
services:
  new-service:
    image: new-service:latest
    restart: always
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
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    <<: [*hardening, *default-logging, *resource-hints]
```

**Key points:**
- Always use `admin-forward-auth@file` middleware
- Include `allowed-admins@file` for IP restrictions
- Include `mgmt-ratelimit@file` for rate limiting
- Use `secure-headers@file` for security headers

### 2. Add Router Configuration

```yaml
# In traefik/dynamic/routers.yml
new-service:
  entryPoints:
    - websecure
  rule: Host(`new-service.inlock.ai`)
  middlewares:
    - secure-headers
    - admin-forward-auth  # ✅ REQUIRED for admin services
    - allowed-admins
    - mgmt-ratelimit
  service: new-service
  tls:
    certResolver: le-dns
```

**Key points:**
- `admin-forward-auth` is **required** for all admin services
- Order matters: security → auth → access control → rate limit
- The middleware uses `https://auth.inlock.ai/oauth2/auth` (public endpoint) so oauth2-proxy can redirect the browser to Auth0

### 3. Add Service Definition

```yaml
# In traefik/dynamic/services.yml
new-service:
  loadBalancer:
    servers:
      - url: http://new-service:8080
```

---

## ✅ Verification

### Automated Check

```bash
cd /home/comzis/inlock-infra
./scripts/verify-auth-consistency.sh
```

### Manual Verification

1. **Check configuration:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env config
   ```

2. **Reload Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d traefik
   ```

3. **Test authentication:**
   ```bash
   # Visit https://new-service.inlock.ai
   # Should redirect to Auth0 login
   ```

4. **Monitor logs:**
   ```bash
   ./scripts/test-auth-flow.sh all
   ```

---

## 🔐 Auth0 Configuration

### Required Settings

1. **Callback URL:** Already configured as `https://auth.inlock.ai/oauth2/callback`
2. **Allowed Logout URLs:** Add `https://new-service.inlock.ai` (no trailing slash) to the comma-separated list in Auth0
3. **Roles:** Assign roles in Auth0 if role-based access is needed

### Role-Based Access

If your service needs role-based access:

1. **Create roles in Auth0:**
   - Auth0 Dashboard → User Management → Roles
   - Create roles (e.g., `new-service-admin`, `new-service-viewer`)

2. **Assign roles to users:**
   - User Management → Users → Select user → Roles tab

3. **Roles are passed as headers:**
   - Available as `X-Auth-Request-Groups` header
   - Service can check this header for authorization

---

## 📊 Example: Adding pgAdmin

```yaml
# compose/stack.yml
pgadmin:
  image: dpage/pgadmin4:8.3
  restart: always
  env_file:
    - ../.env
  networks:
    - mgmt
    - edge
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.pgadmin.rule=Host(`dbadmin.inlock.ai`)"
    - "traefik.http.routers.pgadmin.entrypoints=websecure"
    - "traefik.http.routers.pgadmin.middlewares=secure-headers@file,admin-forward-auth@file,allowed-admins@file,mgmt-ratelimit@file"
    - "traefik.http.routers.pgadmin.tls.certresolver=le-dns"
    - "traefik.http.services.pgadmin.loadbalancer.server.port=80"
  <<: [*hardening, *default-logging, *resource-hints]
```

```yaml
# traefik/dynamic/routers.yml
pgadmin:
  entryPoints:
    - websecure
  rule: Host(`dbadmin.inlock.ai`)
  middlewares:
    - secure-headers
    - admin-forward-auth
    - allowed-admins
    - mgmt-ratelimit
  service: pgadmin
  tls:
    certResolver: le-dns
```

```yaml
# traefik/dynamic/services.yml
pgadmin:
  loadBalancer:
    servers:
      - url: http://pgadmin:80
```

---

## 🚫 Common Mistakes

1. **Missing `admin-forward-auth`** - Service will be accessible without Auth0
2. **Wrong middleware order** - Auth should come before rate limiting
3. **Missing `allowed-admins`** - Service accessible from any IP
4. **Not running verification script** - Miss consistency issues
5. **Forgetting to reload Traefik** - Changes won't take effect

---

## 📚 Related Documentation

- **[Auth0 Stack Consistency](AUTH0-STACK-CONSISTENCY.md)** - Complete Auth0 integration guide
- **[Auth0 Testing Guide](AUTH0-TESTING-GUIDE.md)** - Manual testing procedures
- **[Traefik Configuration](../traefik/)** - Traefik config files

---

**Quick Command Reference:**

```bash
# Verify consistency
./scripts/verify-auth-consistency.sh

# Monitor auth flows
./scripts/test-auth-flow.sh all

# Reload Traefik
docker compose -f compose/stack.yml --env-file .env up -d traefik

# Check logs
docker logs compose-oauth2-proxy-1 --tail 50
docker logs compose-traefik-1 --tail 50
```

---

**Last Updated:** December 10, 2025

