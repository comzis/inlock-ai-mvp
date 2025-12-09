# Inlock AI Deployment Guide - inlock.ai

## Overview

This guide covers deploying the Inlock AI application to `inlock.ai` using Positive SSL certificates and the existing Traefik infrastructure.

**Domain:** `inlock.ai` and `www.inlock.ai`  
**SSL:** Positive SSL (already installed)  
**App Location:** `/opt/inlock-ai-secure-mvp`  
**Port:** 3040  
**Database:** PostgreSQL (separate instance)

---

## Pre-Deployment Checklist

Before starting, ensure:

- [ ] Positive SSL certificate is installed and valid
- [ ] Project code is in `/opt/inlock-ai-secure-mvp`
- [ ] You have backup of current homepage service (if needed)
- [ ] Database credentials prepared
- [ ] Environment variables documented

---

## Step 1: Verify Positive SSL Certificate

Check that Positive SSL certificate is installed and valid:

```bash
# Check certificate details
openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -subject -issuer -dates

# Verify certificate is accessible to Traefik
ls -la /home/comzis/apps/secrets-real/positive-ssl.*
```

**Expected output:**
- Certificate subject: `CN = inlock.ai`
- Certificate should be valid (not expired)
- Files should have `600` permissions

---

## Step 2: Set Up Database

The app needs a PostgreSQL database. We'll create a separate database instance for the app.

### 2.1 Create Database Compose File

Create `/home/comzis/inlock-infra/compose/inlock-db.yml`:

```yaml
x-default-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

x-hardening: &hardening
  security_opt:
    - no-new-privileges:true

x-resource-hints: &resource-hints
  deploy:
    resources:
      limits:
        memory: 512m
      reservations:
        memory: 128m

services:
  inlock-db:
    image: postgres@sha256:a5074487380d4e686036ce61ed6f2d363939ae9a0c40123d1a9e3bb3a5f344b4
    restart: always
    env_file:
      - ../.env
    environment:
      - POSTGRES_DB=${INLOCK_DB_NAME:-inlock}
      - POSTGRES_USER=${INLOCK_DB_USER:-inlock}
      - POSTGRES_PASSWORD=${INLOCK_DB_PASSWORD:-$(cat /home/comzis/apps/secrets-real/inlock-db-password 2>/dev/null | tr -d '\n\r' || echo '')}
    volumes:
      - inlock_db_data:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${INLOCK_DB_USER:-inlock} -d ${INLOCK_DB_NAME:-inlock}"]
      interval: 30s
      timeout: 5s
      retries: 5
    tmpfs:
      - /tmp
      - /var/run/postgresql
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
      - DAC_OVERRIDE
    security_opt:
      - no-new-privileges:false
    <<: [*default-logging, *resource-hints]

networks:
  internal:
    external: true
    name: internal

volumes:
  inlock_db_data:
```

### 2.2 Generate Database Password

```bash
# Generate a strong password
openssl rand -base64 32 | tr -d '\n' > /home/comzis/apps/secrets-real/inlock-db-password
chmod 600 /home/comzis/apps/secrets-real/inlock-db-password
chown comzis:comzis /home/comzis/apps/secrets-real/inlock-db-password

# Show password (you'll need this for DATABASE_URL)
cat /home/comzis/apps/secrets-real/inlock-db-password
```

### 2.3 Add Database to Stack

Edit `/home/comzis/inlock-infra/compose/stack.yml` and add the database service import at the top:

```yaml
include:
  - compose/inlock-db.yml
```

---

## Step 3: Build Docker Image

### 3.1 Navigate to App Directory

```bash
cd /opt/inlock-ai-secure-mvp
```

### 3.2 Build the Image

```bash
# Build the Docker image
docker build -t inlock-ai:latest .

# Verify image was created
docker images | grep inlock-ai
```

**Note:** The build may take several minutes as it installs dependencies and builds the Next.js app.

---

## Step 4: Create Environment File

### 4.1 Generate Session Secret

```bash
# Generate AUTH_SESSION_SECRET
openssl rand -base64 32
```

Save this value for the environment file.

### 4.2 Create Environment File

Create `/opt/inlock-ai-secure-mvp/.env.production`:

```bash
# Database
DATABASE_URL=postgresql://inlock:<PASSWORD>@inlock-db:5432/inlock?sslmode=disable

# Auth
AUTH_SESSION_SECRET=<generated-secret-from-step-4.1>

# Environment
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1

# Optional: AI Provider Keys
# GOOGLE_AI_API_KEY=your-key-here
# OPENAI_API_KEY=your-key-here
# ANTHROPIC_API_KEY=your-key-here

# Optional: Redis for Rate Limiting
# UPSTASH_REDIS_REST_URL=your-url
# UPSTASH_REDIS_REST_TOKEN=your-token

# Optional: Sentry
# SENTRY_DSN=your-dsn
# SENTRY_ORG=your-org
# SENTRY_PROJECT=your-project
```

Replace:
- `<PASSWORD>` with the password from step 2.2
- `<generated-secret-from-step-4.1>` with the generated secret

### 4.3 Set Proper Permissions

```bash
chmod 600 /opt/inlock-ai-secure-mvp/.env.production
```

---

## Step 5: Add Service to Stack

Edit `/home/comzis/inlock-infra/compose/stack.yml` and add the Inlock AI service:

```yaml
  inlock-ai:
    image: inlock-ai:latest
    restart: always
    env_file:
      - /opt/inlock-ai-secure-mvp/.env.production
    networks:
      - edge
      - internal
    depends_on:
      inlock-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3040/api/readiness"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    cap_drop:
      - ALL
    user: "1001:1001"
    <<: [*hardening, *default-logging, *resource-hints]
```

Add this service definition after the `grafana` service (around line 242).

---

## Step 6: Configure Traefik Routing

### 6.1 Update Router Configuration

Edit `/home/comzis/inlock-infra/traefik/dynamic/routers.yml` and update the `homepage` router to point to Inlock AI:

```yaml
    homepage:
      entryPoints:
        - websecure
      rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
      middlewares:
        - secure-headers
      service: inlock-ai
      tls:
        certResolver: le-tls
```

**Important:** Change `service: homepage` to `service: inlock-ai`

### 6.2 Add Service Definition

Edit `/home/comzis/inlock-infra/traefik/dynamic/services.yml` and add:

```yaml
    inlock-ai:
      loadBalancer:
        servers:
          - url: http://inlock-ai:3040
```

---

## Step 7: Update TLS Configuration (Use Positive SSL)

Edit `/home/comzis/inlock-infra/traefik/dynamic/routers.yml` to use Positive SSL for the apex domain:

```yaml
    homepage:
      entryPoints:
        - websecure
      rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
      middlewares:
        - secure-headers
      service: inlock-ai
      tls:
        options: default
```

The `tls.options: default` uses the Positive SSL certificate defined in `tls.yml` (already configured).

---

## Step 8: Deploy Services

### 8.1 Start Database

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-db
```

Wait for database to be healthy:
```bash
docker compose -f compose/stack.yml ps inlock-db
```

### 8.2 Start Inlock AI Service

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

### 8.3 Restart Traefik (to pick up new routing)

```bash
docker compose -f compose/stack.yml --env-file .env restart traefik
```

---

## Step 9: Verify Deployment

### 9.1 Check Service Status

```bash
# Check all services are running
docker compose -f compose/stack.yml ps

# Check Inlock AI logs
docker logs compose-inlock-ai-1 --tail 50

# Check database connection
docker logs compose-inlock-db-1 --tail 20
```

### 9.2 Test HTTPS Access

```bash
# Test from server
curl -I https://inlock.ai

# Check SSL certificate
openssl s_client -connect inlock.ai:443 -servername inlock.ai </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates

# Test health endpoint
curl https://inlock.ai/api/readiness
```

### 9.3 Verify Database Migration

Check logs for successful migration:
```bash
docker logs compose-inlock-ai-1 | grep -i "migrate\|migration"
```

### 9.4 Test Application Features

1. Visit `https://inlock.ai` - homepage should load
2. Visit `https://inlock.ai/auth/register` - registration page
3. Visit `https://inlock.ai/api/providers` - should return JSON

---

## Step 10: Cloudflare DNS (if not already configured)

Ensure DNS records exist in Cloudflare:

- `inlock.ai` → `156.67.29.52` (A record, Proxy: OFF or ON based on preference)
- `www.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF or ON)

**Note:** If using Cloudflare Proxy (orange cloud), Traefik IP allowlist won't work for real client IPs. For public-facing app, this is usually fine.

---

## Rollback Plan

If something goes wrong, you can quickly rollback:

### Quick Rollback

1. **Stop Inlock AI service:**
   ```bash
   docker compose -f compose/stack.yml stop inlock-ai
   ```

2. **Restore homepage router:**
   Edit `/home/comzis/inlock-infra/traefik/dynamic/routers.yml`:
   ```yaml
   homepage:
     entryPoints:
       - websecure
     rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
     middlewares:
       - secure-headers
     service: homepage  # Change back to homepage
     tls:
       certResolver: le-tls
   ```

3. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml restart traefik
   ```

---

## Troubleshooting

### Service Won't Start

1. Check logs: `docker logs compose-inlock-ai-1`
2. Verify environment file exists and has correct permissions
3. Check database is accessible: `docker exec -it compose-inlock-db-1 psql -U inlock -d inlock`

### Database Connection Errors

1. Verify `DATABASE_URL` in `.env.production` is correct
2. Check database is healthy: `docker compose -f compose/stack.yml ps inlock-db`
3. Verify network connectivity: `docker exec -it compose-inlock-ai-1 ping inlock-db`

### SSL Certificate Issues

1. Verify certificate is valid: `openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -dates`
2. Check Traefik logs: `docker logs compose-traefik-1 | grep -i cert`
3. Verify TLS configuration in `traefik/dynamic/tls.yml`

### 502 Bad Gateway

1. Check Inlock AI is running: `docker ps | grep inlock`
2. Check health endpoint: `docker exec compose-inlock-ai-1 wget -qO- http://localhost:3040/api/readiness`
3. Verify Traefik service definition points to correct port

### Build Errors

1. Check Node.js version (requires 20+)
2. Verify all dependencies in `package.json`
3. Check build logs for specific errors

---

## Maintenance

### Update Application

```bash
cd /opt/inlock-ai-secure-mvp
git pull  # or update code
docker build -t inlock-ai:latest .
docker compose -f /home/comzis/inlock-infra/compose/stack.yml --env-file /home/comzis/inlock-infra/.env up -d inlock-ai
```

### Database Backup

```bash
# Backup database
docker exec compose-inlock-db-1 pg_dump -U inlock inlock > /backups/inlock-$(date +%Y%m%d).sql

# Restore database
cat /backups/inlock-20251209.sql | docker exec -i compose-inlock-db-1 psql -U inlock inlock
```

### View Logs

```bash
# Application logs
docker logs compose-inlock-ai-1 --tail 100 -f

# Database logs
docker logs compose-inlock-db-1 --tail 100 -f
```

---

## Security Considerations

1. ✅ **HTTPS Only** - Traefik enforces HTTPS redirect
2. ✅ **Security Headers** - Middleware applied via Traefik
3. ✅ **Non-root User** - Container runs as user 1001
4. ✅ **Secrets Management** - Database password stored securely
5. ✅ **Network Isolation** - Services on internal network
6. ✅ **Health Checks** - Automatic container restart on failure

---

## Next Steps

After successful deployment:

1. Monitor application logs for errors
2. Set up backup automation for database
3. Configure monitoring/alerts (if using Grafana/Prometheus)
4. Review and rotate secrets periodically
5. Set up CI/CD pipeline for automated deployments

---

**Last Updated:** 2025-12-09  
**Status:** Ready for deployment

