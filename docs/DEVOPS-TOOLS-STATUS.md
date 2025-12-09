# DevOps Tools Status & Quick Fixes

**Last Updated:** 2025-12-08

## Service Status Overview

| Service | URL | Access Control | Status | Issues |
|---------|-----|----------------|--------|--------|
| Traefik Dashboard | `https://traefik.inlock.ai/dashboard/` | ✅ IP Allowlist + Auth | ✅ Working | None |
| Portainer | `https://portainer.inlock.ai` | ✅ IP Allowlist | ✅ Healthy | Fixed 2025-12-08 |
| n8n | `https://n8n.inlock.ai` | ✅ IP Allowlist | ✅ Healthy | Fixed 2025-12-08 |
| Cockpit | `https://cockpit.inlock.ai` | ✅ IP Allowlist | ✅ Working | Added 2025-12-08 |
| Homepage | `https://inlock.ai` | ❌ Public | ✅ Working | None |

---

## 1. Traefik Dashboard

**Status:** ✅ **WORKING**

**Access:**
- URL: `https://traefik.inlock.ai/dashboard/`
- Authentication: Basic Auth (username/password)
- IP Restriction: Tailscale IPs only (100.83.222.69, 100.96.110.8)
- Expected Response: 401 (auth required) or 200 (after auth)

**Credentials:**
- File: `secrets/traefik-dashboard-users.htpasswd`
- Format: Apache htpasswd (MD5 or bcrypt)

**Quick Test:**
```bash
curl -k -I https://traefik.inlock.ai/dashboard/
# Expected: HTTP/2 401
```

**No Issues** ✅

---

## 2. Portainer

**Status:** ✅ **HEALTHY** (Fixed 2025-12-08)

**Access:**
- URL: `https://portainer.inlock.ai`
- IP Restriction: Tailscale IPs only
- Expected Response: 200 (if IP allowed) or 403 (if blocked)

**Current Issues:**
- Container shows "unhealthy" status
- May be due to healthcheck configuration
- Service is running and accessible

**Quick Fix:**
```bash
# Fix data directory ownership
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
sudo chmod 755 /home/comzis/apps/traefik/portainer_data

# Restart Portainer
docker compose -f compose/stack.yml --env-file .env restart portainer

# Check logs
docker compose -f compose/stack.yml --env-file .env logs portainer

# Check health
docker compose -f compose/stack.yml --env-file .env ps portainer
```

**Previous Issues (Resolved):**
- ✅ Docker socket proxy permissions fixed
- ✅ Data directory permissions fixed (2025-12-08: chown 1000:1000, chmod 755)
- ✅ Router configuration fixed

**Fix Applied (2025-12-08):**
```bash
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
sudo chmod 755 /home/comzis/apps/traefik/portainer_data
docker compose -f compose/stack.yml --env-file .env restart portainer
```

**Access Control:** ✅ Working (403 for non-allowed IPs)

---

## 3. n8n

**Status:** ✅ **HEALTHY** (Fixed 2025-12-08)

**Access:**
- URL: `https://n8n.inlock.ai`
- IP Restriction: Tailscale IPs only
- Expected Response: 200 (if IP allowed and service healthy) or 403 (if blocked)

**Current Status:**
- ✅ Database connection working
- ✅ Service is healthy
- ✅ All errors resolved

**Fix Applied (2025-12-08):**
- Database password verified and matched
- Connection tested: ✅ Working
- Service restarted and health recovered

**Previous Issues (Resolved):**
- ✅ Database connection errors fixed
- ✅ Password authentication resolved

**Quick Fix (if needed):**
```bash
# 1. Check Postgres is running
docker compose -f compose/postgres.yml --env-file .env ps postgres

# 2. Test database connection
docker compose -f compose/postgres.yml --env-file .env exec postgres psql -U n8n -d n8n -c "SELECT 1;"

# 3. Check database credentials in .env
grep N8N_DB .env

# 4. Check n8n database password secret
cat /home/comzis/apps/secrets/n8n-db-password

# 5. Check n8n logs
docker compose -f compose/n8n.yml --env-file .env logs n8n

# 6. Restart n8n
docker compose -f compose/n8n.yml --env-file .env restart n8n

# 7. Wait for service to start
docker compose -f compose/n8n.yml --env-file .env logs -f n8n
```

**Fix Applied (2025-12-08):**
- Database connection tested: ✅ Working
- n8n restarted to reconnect to database
- Check logs for connection status

**Possible Causes:**
1. Database credentials incorrect in `.env`
2. Database not ready when n8n starts (timing issue)
3. Network connectivity issue between n8n and postgres
4. Database user doesn't exist or wrong password

**Access Control:** ✅ Working (403 for non-allowed IPs)

---

## 4. Cockpit

**Status:** ✅ **CONFIGURED AND RUNNING** (Added 2025-12-08)

**Access:**
- URL: `https://cockpit.inlock.ai`
- IP Restriction: Tailscale IPs only
- Expected Response: 200 (if IP allowed) or 403 (if blocked)

**Configuration Added:**
1. ✅ Router definition in `traefik/dynamic/routers.yml`
2. ✅ Service definition in `traefik/dynamic/services.yml`
3. ✅ Docker Compose service in `compose/stack.yml`

**Service Details:**
- Image: `cockpit/ws:latest`
- Port: 9090
- Networks: `mgmt`, `edge`
- Healthcheck: Configured
- Middlewares: `secure-headers`, `allowed-admins`, `mgmt-ratelimit`

**Quick Test:**
```bash
# Check service status
docker compose -f compose/stack.yml --env-file .env ps cockpit

# Check logs
docker compose -f compose/stack.yml --env-file .env logs cockpit

# Test access
curl -I https://cockpit.inlock.ai
```

**Access Control:** ✅ Working (200 for allowed IPs, 403 for blocked IPs)

---

## 5. Homepage (Public)

**Status:** ✅ **WORKING**

**Access:**
- URL: `https://inlock.ai`
- IP Restriction: None (public)
- Expected Response: 200

**Configuration:**
- Router: `homepage`
- Middleware: `secure-headers` only (no IP restriction)
- Certificate: PositiveSSL (default)

**No Issues** ✅

---

## Access Control Summary

### Allowed IPs (Tailscale)
- `100.83.222.69/32` - Device 1 (Server)
- `100.96.110.8/32` - Device 2 (MacBook)

### Also Allowed (Should Remove for Production)
- `2a09:bac3:1e53:2664::3d3:2f/128` - MacBook public IPv6
- `31.10.147.220/32` - MacBook public IPv4
- `172.71.147.142/32` - MacBook public IPv4
- `172.71.146.180/32` - MacBook public IPv4

**Recommendation:** Remove public IPs and require Tailscale-only access for production.

---

## Testing Access Control

### From Tailscale-Connected Host

**Expected:** HTTP 200 (allowed) or 401 (auth required)

```bash
# Run test script
./scripts/test-access-from-tailscale.sh

# Or test manually
curl -I https://portainer.inlock.ai
curl -I https://traefik.inlock.ai/dashboard/
curl -I https://n8n.inlock.ai
```

### From Non-Tailscale IP

**Expected:** HTTP 403 (Forbidden)

```bash
# From public internet
curl -I https://portainer.inlock.ai
# Expected: HTTP/2 403
```

---

## Quick Fixes Summary

### Portainer
```bash
docker compose -f compose/stack.yml --env-file .env restart portainer
```

### n8n
```bash
# Check database
docker compose -f compose/postgres.yml --env-file .env exec postgres psql -U n8n -d n8n -c "SELECT 1;"

# Restart n8n
docker compose -f compose/n8n.yml --env-file .env restart n8n
```

### Cockpit
- Add router/service configuration (see above)
- Or remove DNS record if not needed

---

## Validation

Run validation script:
```bash
./scripts/validate-access-control.sh
```

Full validation report:
- `docs/ACCESS-CONTROL-VALIDATION.md`

---

**Last Updated:** 2025-12-08

