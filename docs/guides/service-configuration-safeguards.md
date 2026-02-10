# Service Configuration Safeguards

## 🚨 CRITICAL: Service Configuration Protection

### Overview
Service misconfiguration can cause application failures, authentication issues, and database connection problems. This document defines mandatory safeguards for service configurations.

---

## Pre-Task Mandatory Checks

### 1. Coolify Configuration Protection

**CRITICAL RULE:** Coolify requires specific database and environment configurations to function.

#### Configuration Details:
- **Database Password:**
  - Environment variable: `POSTGRES_PASSWORD` or default: `ee7a8e171c075626d63b3cb7292b0cba9e4e71b83c9a3fff`
  - Location: `compose/services/coolify.yml` → `DB_PASSWORD=${POSTGRES_PASSWORD:-ee7a8e171c075626d63b3cb7292b0cba9e4e71b83c9a3fff}`
  - **NEVER remove the default fallback password**

- **Application URL:**
  - Must be: `APP_URL=https://deploy.inlock.ai`
  - Location: `compose/services/coolify.yml`
  - **NEVER change to localhost or http**

- **Trusted Proxy Configuration:**
  - Required: `TRUSTED_PROXIES=*`
  - Required: `FORWARDED_HEADERS=X-Forwarded-For,X-Forwarded-Host,X-Forwarded-Proto,X-Forwarded-Port`
  - Location: `compose/services/coolify.yml`
  - **NEVER remove these - required for Traefik reverse proxy**

- **Database Connection:**
  - Host: `coolify-postgres`
  - Port: `5432`
  - Database: `coolify`
  - Username: `coolify`
  - Password: Must match PostgreSQL container password

#### Verification Commands:
```bash
# Verify database connection
docker compose -f compose/services/coolify.yml exec coolify sh -c 'php artisan migrate:status' 2>&1 | head -5

# Verify environment variables
docker compose -f compose/services/coolify.yml exec coolify env | grep -E "APP_URL|DB_PASSWORD|TRUSTED_PROXIES"

# Verify PostgreSQL password matches
docker compose -f compose/services/coolify.yml exec coolify-postgres psql -U coolify -d coolify -c "SELECT 1;" 2>&1
```

### 2. Grafana Configuration Protection

**CRITICAL RULE:** Grafana domain configuration must be hardcoded, not using environment variables.

#### Configuration Details:
- **Server Domain:**
  - Must be: `GF_SERVER_DOMAIN=grafana.inlock.ai`
  - Location: `compose/services/stack.yml`
  - **NEVER use `${DOMAIN}` variable - it may be empty**

- **Root URL:**
  - Must be: `GF_SERVER_ROOT_URL=https://grafana.inlock.ai`
  - Location: `compose/services/stack.yml`
  - **NEVER use `${DOMAIN}` variable - it may be empty**

#### Verification Commands:
```bash
# Verify Grafana environment variables
docker compose -f compose/services/stack.yml exec grafana env | grep -E "GF_SERVER"

# Verify Grafana is accessible
curl -I https://grafana.inlock.ai 2>&1 | head -5
```

### 3. Database Password Synchronization

**CRITICAL RULE:** Database passwords must match between:
- PostgreSQL container environment (`POSTGRES_PASSWORD`)
- Application connection string (`DB_PASSWORD`)

#### Configuration Details:
- **PostgreSQL Container:**
  - File: `compose/services/coolify.yml`
  - Variable: `POSTGRES_PASSWORD=${POSTGRES_PASSWORD}`
  - Default: Must have fallback in application config

- **Application Connection:**
  - File: `compose/services/coolify.yml`
  - Variable: `DB_PASSWORD=${POSTGRES_PASSWORD:-ee7a8e171c075626d63b3cb7292b0cba9e4e71b83c9a3fff}`
  - **NEVER remove the default fallback**

#### Verification:
```bash
# Check PostgreSQL password
docker compose -f compose/services/coolify.yml exec coolify-postgres env | grep POSTGRES_PASSWORD

# Check application password
docker compose -f compose/services/coolify.yml exec coolify env | grep DB_PASSWORD

# Test connection
docker compose -f compose/services/coolify.yml exec coolify-postgres psql -U coolify -d coolify -c "SELECT 1;" 2>&1
```

---

## Task-Specific Safeguards

### When Modifying Coolify Configuration

1. **Backup current configuration:**
   ```bash
   cp compose/services/coolify.yml compose/services/coolify.yml.backup
   ```

2. **Verify database password is preserved:**
   - Check `DB_PASSWORD` has default fallback
   - Check `POSTGRES_PASSWORD` is set correctly

3. **Verify proxy configuration is preserved:**
   - Check `TRUSTED_PROXIES=*` exists
   - Check `FORWARDED_HEADERS` includes required headers
   - Check `APP_URL` is `https://deploy.inlock.ai`

4. **After changes, verify:**
   - Database connection works
   - Application starts successfully
   - HTTPS redirects work correctly

### When Modifying Grafana Configuration

1. **Backup current configuration:**
   ```bash
   cp compose/services/stack.yml compose/services/stack.yml.backup
   ```

2. **Verify domain is hardcoded:**
   - Check `GF_SERVER_DOMAIN=grafana.inlock.ai` (NOT `${DOMAIN}`)
   - Check `GF_SERVER_ROOT_URL=https://grafana.inlock.ai` (NOT `${DOMAIN}`)

3. **After changes, verify:**
   - Grafana container starts
   - Environment variables are correct
   - HTTPS access works

### When Modifying Database Configuration

1. **Backup current configuration:**
   ```bash
   cp compose/services/coolify.yml compose/services/coolify.yml.backup
   ```

2. **Verify password synchronization:**
   - PostgreSQL container password matches application password
   - Default fallback exists in application config

3. **After changes, verify:**
   - PostgreSQL container starts
   - Application can connect to database
   - Migrations run successfully

---

## Protected Configuration Values

**NEVER modify without verification:**

### Coolify (`compose/services/coolify.yml`):
- `DB_PASSWORD=${POSTGRES_PASSWORD:-ee7a8e171c075626d63b3cb7292b0cba9e4e71b83c9a3fff}` - Default fallback password
- `APP_URL=https://deploy.inlock.ai` - Application URL
- `TRUSTED_PROXIES=*` - Trusted proxy configuration
- `FORWARDED_HEADERS=X-Forwarded-For,X-Forwarded-Host,X-Forwarded-Proto,X-Forwarded-Port` - Required headers
- `WEBSERVER_ENABLED=false` - Nginx disabled (Traefik handles reverse proxy)
- `PHP_FPM_LISTEN=0.0.0.0:8080` - PHP-FPM listen address

### Grafana (`compose/services/stack.yml`):
- `GF_SERVER_DOMAIN=grafana.inlock.ai` - Hardcoded domain (NOT `${DOMAIN}`)
- `GF_SERVER_ROOT_URL=https://grafana.inlock.ai` - Hardcoded URL (NOT `${DOMAIN}`)

### PostgreSQL (`compose/services/coolify.yml`):
- `POSTGRES_USER=coolify` - Database user
- `POSTGRES_DB=coolify` - Database name
- `POSTGRES_PASSWORD=${POSTGRES_PASSWORD}` - Password (must match application)

---

## Error Detection

**If you see these errors, STOP and verify configurations:**

### Coolify Errors:
- `password authentication failed for user "coolify"` → Database password mismatch
- `connection to server at "coolify-postgres" failed` → Database connection issue
- `These credentials do not match our records` → User not in database
- Redirects to `localhost:8080` → `APP_URL` or proxy headers misconfigured

### Grafana Errors:
- `GF_SERVER_DOMAIN=grafana.` (empty) → Domain variable not set
- `GF_SERVER_ROOT_URL=https://grafana.` (empty) → Domain variable not set
- Shows "Inlock AI" error page → Domain misconfiguration

### Database Errors:
- `FATAL: password authentication failed` → Password mismatch
- `connection refused` → Database container not running
- `database "coolify" does not exist` → Database not initialized

---

## Post-Change Verification Script

After ANY service configuration change, run:
```bash
#!/bin/bash
# Service configuration health check

echo "=== Coolify Configuration Check ==="
docker compose -f compose/services/coolify.yml exec coolify env | grep -E "APP_URL|DB_PASSWORD|TRUSTED_PROXIES" || echo "❌ Coolify container not running"

echo ""
echo "=== Grafana Configuration Check ==="
docker compose -f compose/services/stack.yml exec grafana env | grep -E "GF_SERVER" || echo "❌ Grafana container not running"

echo ""
echo "=== Database Connection Check ==="
docker compose -f compose/services/coolify.yml exec coolify sh -c 'php artisan migrate:status' 2>&1 | head -3 || echo "❌ Database connection failed"

echo ""
echo "=== Service Accessibility Check ==="
curl -I https://deploy.inlock.ai 2>&1 | grep -E "HTTP|Location" | head -2
curl -I https://grafana.inlock.ai 2>&1 | grep -E "HTTP|Location" | head -2
```

---

## Emergency Rollback

If service configurations break:

1. **Restore from backup:**
   ```bash
   cd /home/comzis/projects/inlock-ai-mvp
   cp compose/services/coolify.yml.backup compose/services/coolify.yml
   cp compose/services/stack.yml.backup compose/services/stack.yml
   ```

2. **Recreate containers:**
   ```bash
   docker compose -f compose/services/coolify.yml up -d --force-recreate coolify
   docker compose -f compose/services/stack.yml up -d --force-recreate grafana
   ```

3. **Verify services:**
   ```bash
   docker compose -f compose/services/coolify.yml exec coolify sh -c 'php artisan migrate:status' 2>&1 | head -3
   curl -I https://deploy.inlock.ai
   curl -I https://grafana.inlock.ai
   ```

---

## Summary Checklist

Before starting ANY service configuration task:

- [ ] Backed up configuration files
- [ ] Verified database password synchronization
- [ ] Verified domain configurations are hardcoded (not using `${DOMAIN}`)
- [ ] Verified proxy configurations are preserved
- [ ] Checked service health before changes

After completing ANY service configuration task:

- [ ] Verified database connections work
- [ ] Verified services start successfully
- [ ] Tested HTTPS access
- [ ] Checked service logs for errors
- [ ] Confirmed environment variables are correct

---

**Remember: Service misconfiguration = Application downtime. Always verify before and after changes.**
