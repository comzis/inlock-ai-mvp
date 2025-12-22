# Inlock AI Deployment Preparation Guide

## Overview

This guide prepares the Inlock AI deployment to replace the current homepage service at `inlock.ai`. The app will use Positive SSL and be accessible directly on the main domain.

**Key Features:**
- ✅ All configuration files prepared
- ✅ Positive SSL certificate ready
- ✅ Production route configured (`inlock.ai`)
- ✅ Replaces current homepage service
- ✅ Uses Positive SSL certificate

---

## Quick Preparation

Run the automated preparation script:

```bash
cd /home/comzis/inlock-infra
./scripts/prepare-inlock-deployment.sh
```

This script will:
1. Generate database password
2. Generate session secret
3. Create environment file
4. Verify Positive SSL certificate
5. Verify all configuration files

---

## Manual Preparation Steps

If you prefer to do it manually:

### Step 1: Generate Database Password

```bash
openssl rand -base64 32 | tr -d '\n' > /home/comzis/apps/secrets-real/inlock-db-password
chmod 600 /home/comzis/apps/secrets-real/inlock-db-password
chown comzis:comzis /home/comzis/apps/secrets-real/inlock-db-password
```

### Step 2: Generate Session Secret

```bash
AUTH_SECRET=$(openssl rand -base64 32)
echo $AUTH_SECRET  # Save this for the environment file
```

### Step 3: Create Environment File

Create `/opt/inlock-ai-secure-mvp/.env.production`:

```bash
cat > /opt/inlock-ai-secure-mvp/.env.production << EOF
DATABASE_URL=postgresql://inlock:$(cat /home/comzis/apps/secrets-real/inlock-db-password)@inlock-db:5432/inlock?sslmode=disable
AUTH_SESSION_SECRET=${AUTH_SECRET}
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
EOF

chmod 600 /opt/inlock-ai-secure-mvp/.env.production
```

### Step 4: Verify Positive SSL Certificate

```bash
# Check certificate exists
ls -la /home/comzis/apps/secrets-real/positive-ssl.*

# Verify certificate details
openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -subject -issuer -dates

# Verify certificate matches key
openssl x509 -noout -modulus -in /home/comzis/apps/secrets-real/positive-ssl.crt | openssl md5
openssl rsa -noout -modulus -in /home/comzis/apps/secrets-real/positive-ssl.key | openssl md5
# These should match!
```

---

## Configuration Files Status

### ✅ Already Prepared

1. **Database Configuration**: `compose/inlock-db.yml`
   - PostgreSQL service
   - Uses internal network
   - Health checks configured

2. **Application Configuration**: `compose/inlock-ai.yml`
   - Docker service definition
   - Health checks configured
   - Security hardening applied

3. **Traefik Service**: `traefik/dynamic/services.yml`
   - Service endpoint configured
   - Points to `inlock-ai:3040`

4. **Traefik Router (Production)**: `traefik/dynamic/routers.yml`
   - `inlock-ai` router configured
   - Routes `inlock.ai` and `www.inlock.ai` to the app
   - Uses Positive SSL (`options: default`)
   - Public access (secure-headers middleware only)

5. **TLS Configuration**: `traefik/dynamic/tls.yml`
   - Positive SSL certificate configured
   - Certificate stored in Docker secrets

### 📝 Files to Update

1. **Stack Configuration**: `compose/stack.yml`
   - Add database include
   - Add application include

---

## Deployment Steps (When Ready)

### 1. Update stack.yml

Edit `/home/comzis/inlock-infra/compose/stack.yml` and add includes after line 10:

```yaml
include:
  - compose/inlock-db.yml
  - compose/inlock-ai.yml
```

### 2. Build Docker Image

```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
```

### 3. Start Database

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-db

# Wait for database to be healthy
docker compose -f compose/stack.yml ps inlock-db
```

### 4. Start Application

```bash
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

### 5. Restart Traefik

```bash
docker compose -f compose/stack.yml --env-file .env restart traefik
```

### 6. Test Production Route

```bash
# Test the main domain
curl -I https://inlock.ai

# Should return 200 OK
# SSL certificate should be Positive SSL
```

**Note:** `inlock.ai` is publicly accessible with security headers applied.

---

## Testing Production Deployment

Once deployed, test the production route:

1. **Access URL**: `https://inlock.ai`
2. **Public Access**: Accessible to everyone (with security headers)
3. **SSL**: Uses Positive SSL certificate
4. **Features**: Full application functionality

Verify:
- ✅ Homepage loads
- ✅ SSL certificate is valid (Positive SSL)
- ✅ Authentication works
- ✅ Database connectivity
- ✅ All features functional
- ✅ Both `inlock.ai` and `www.inlock.ai` work

---

## Configuration Status

The production router is already configured in `traefik/dynamic/routers.yml`. The homepage router has been commented out, so when you deploy, `inlock.ai` will automatically route to the Inlock AI app.

**Current Configuration:**
- ✅ `inlock-ai` router active (routes `inlock.ai` and `www.inlock.ai`)
- ✅ Homepage router commented out
- ✅ Uses Positive SSL certificate
- ✅ Security headers applied

**No additional router changes needed** - just deploy and restart Traefik!

---

## Current Routing Status

| Domain | Route | Status |
|--------|-------|--------|
| `inlock.ai` | Inlock AI app | 🟡 Ready (needs deployment) |
| `www.inlock.ai` | Inlock AI app | 🟡 Ready (needs deployment) |
| Homepage service | Commented out | ⏸️ Will be replaced |

---

## Rollback Plan

If something goes wrong:

### Quick Rollback

1. **Stop services**:
   ```bash
   docker compose -f compose/stack.yml stop inlock-ai inlock-db
   ```

2. **Restore homepage router** in `traefik/dynamic/routers.yml`

3. **Restart Traefik**:
   ```bash
   docker compose -f compose/stack.yml restart traefik
   ```

### Complete Removal

If you need to completely remove:

1. Stop and remove containers:
   ```bash
   docker compose -f compose/stack.yml stop inlock-ai inlock-db
   docker compose -f compose/stack.yml rm -f inlock-ai inlock-db
   ```

2. Remove from stack.yml includes

3. Remove router from routers.yml

4. Remove service from services.yml

---

## Security Notes

1. ✅ **Positive SSL**: Certificate already configured for `inlock.ai` domain
2. ✅ **Public Access**: Route is publicly accessible (no IP restrictions)
3. ✅ **Security Headers**: Applied via Traefik middleware (HSTS, CSP, etc.)
4. ✅ **Network Isolation**: Services on internal network
5. ✅ **Secrets Management**: Passwords stored securely

---

## DNS Configuration

DNS should already be configured for `inlock.ai`:

- `inlock.ai` → `156.67.29.52` (A record)
- `www.inlock.ai` → `156.67.29.52` (A record)
- Proxy: Can be ON or OFF (no IP restrictions on public route)

---

## Troubleshooting

### Route Not Accessible

1. Check DNS: `dig +short inlock.ai`
2. Check router exists: `grep "inlock-ai:" traefik/dynamic/routers.yml`
3. Check service exists: `grep "inlock-ai:" traefik/dynamic/services.yml`
4. Check Traefik logs: `docker logs compose-traefik-1 --tail 50`
5. Verify service is running: `docker compose ps inlock-ai`

### SSL Certificate Issues

1. Verify certificate: `openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -text`
2. Check TLS config: `cat traefik/dynamic/tls.yml`
3. Verify certificate matches domain: Certificate should be for `inlock.ai` (works for subdomains)

### Database Connection Errors

1. Check database is running: `docker compose ps inlock-db`
2. Verify DATABASE_URL in `.env.production`
3. Check network connectivity: `docker exec compose-inlock-ai-1 ping inlock-db`

---

## Next Steps After Preparation

1. ✅ Review all configuration files
2. ✅ Verify Positive SSL certificate
3. ✅ Test staging deployment
4. ✅ Verify application functionality
5. ✅ Plan production cutover
6. ✅ Execute production deployment

---

**Last Updated**: 2025-12-09  
**Status**: Ready for staging deployment  
**Production Status**: Not activated (homepage unchanged)

