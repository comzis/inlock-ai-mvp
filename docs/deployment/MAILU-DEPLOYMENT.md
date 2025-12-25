# Mailu Email Server Deployment Guide

**Date:** December 25, 2025  
**Purpose:** Guide for deploying Mailu email server with proper environment configuration

---

## Overview

Mailu provides a full-featured email server with:
- **SMTP/IMAP**: Email server functionality
- **Webmail**: Roundcube web interface
- **Admin Panel**: Email account management
- **Security**: SPF, DKIM, DMARC, spam filtering

**Deployment Type:** Standalone (not included in main stack.yml)

---

## Prerequisites

- Docker and Docker Compose installed
- Domain `mail.inlock.ai` pointing to server
- Ports 25, 465, 587 (SMTP) and 143, 993 (IMAP) open (firewall-restricted)
- Docker secrets configured

---

## Environment Variables

### Required Variables

Mailu requires the following environment variables in `compose/.env`:

```bash
# Domain configuration
DOMAIN=inlock.ai
EMAIL=admin@inlock.ai

# Mailu Database Password (REQUIRED)
# This is used in SQLALCHEMY_DATABASE_URI for all Mailu services
# Store actual password in /home/comzis/apps/secrets-real/mailu-db-password
MAILU_DB_PASSWORD=<password-from-secret-file>
```

### Optional Variables

```bash
# Postmaster email (defaults to 'admin')
POSTMASTER=admin

# Hostnames (defaults to mail.${DOMAIN})
HOSTNAMES=mail.inlock.ai

# TLS Configuration
# Options: notls, letsencrypt, mail-letsencrypt, cert
TLS_FLAVOR=mail-letsencrypt

# Mail Network Subnet (for mail network)
# Note: This is informational - the actual mail network subnet is configured
# separately. The mail network is external and uses 172.30.0.0/16 by default.
# This variable is used in Mailu services but doesn't control the network CIDR.
SUBNET=172.30.0.0/16
```

### Important: SUBNET Variable vs Network CIDR

**Key Distinction:**
- The `SUBNET` environment variable in `compose/.env` is used by Mailu services internally
- The actual Docker network CIDR for the `mail` network is configured separately when creating the network
- The `mail` network is **external** (created outside of compose) and uses `172.30.0.0/16` by default
- The `SUBNET` env var in `compose/.env` can differ from the actual network CIDR without issues

**Example:**
```bash
# compose/.env might have:
SUBNET=172.24.0.0/16

# But the actual mail network was created with:
docker network create --subnet=172.30.0.0/16 mail

# This is fine - Mailu services will work correctly
```

---

## Secrets Configuration

Mailu requires three secrets stored in `/home/comzis/apps/secrets-real/`:

1. **mailu-secret-key**: Session encryption key (32+ characters)
2. **mailu-admin-password**: Admin UI password
3. **mailu-db-password**: PostgreSQL database password

**Verify secrets exist:**
```bash
for secret in mailu-secret-key mailu-admin-password mailu-db-password; do
  if [ -s "/home/comzis/apps/secrets-real/$secret" ]; then
    echo "✅ $secret: OK"
  else
    echo "❌ $secret: MISSING"
  fi
done
```

---

## Network Configuration

### Mail Network

The `mail` network is **external** and must be created before deploying Mailu:

```bash
# Create mail network (if not exists)
docker network create --subnet=172.30.0.0/16 mail 2>/dev/null || true

# Verify network exists
docker network ls | grep mail
```

**Note:** The network subnet (172.30.0.0/16) is configured at network creation time, not via environment variables.

---

## Deployment Steps

### Step 1: Verify Environment File

Ensure `compose/.env` has all required Mailu variables:

```bash
cd /home/comzis/inlock
grep -E "MAILU_DB_PASSWORD|POSTMASTER|DOMAIN" compose/.env
```

### Step 2: Verify Secrets

```bash
# Check all Mailu secrets exist
ls -la /home/comzis/apps/secrets-real/mailu-*
```

### Step 3: Validate Configuration

```bash
cd /home/comzis/inlock
docker compose -f compose/services/mailu.yml --env-file compose/.env config
```

### Step 4: Deploy Mailu

```bash
cd /home/comzis/inlock
docker compose -f compose/services/mailu.yml --env-file compose/.env up -d
```

**Alternative:** If using a separate env file (e.g., `.env.mailu`):

```bash
docker compose -f compose/services/mailu.yml --env-file .env.mailu up -d
```

### Step 5: Verify Deployment

```bash
# Check service status
docker compose -f compose/services/mailu.yml --env-file compose/.env ps

# Check logs
docker compose -f compose/services/mailu.yml --env-file compose/.env logs -f
```

**Expected services:**
- `services-mailu-front-1` (nginx/frontend)
- `services-mailu-postfix-1` (SMTP)
- `services-mailu-imap-1` (IMAP)
- `services-mailu-admin-1` (admin UI)
- `services-mailu-webmail-1` (webmail)
- `services-mailu-rspamd-1` (spam filter)
- `services-mailu-redis-1` (cache)
- `services-mailu-postgres-1` (database)

---

## Post-Deployment

### Access Points

- **Webmail**: `https://mail.inlock.ai/webmail/`
- **Admin UI**: `https://mail.inlock.ai/admin` (requires Auth0 auth)
- **SMTP**: `mail.inlock.ai:587` (STARTTLS) or `:465` (SSL)
- **IMAP**: `mail.inlock.ai:993` (SSL) or `:143` (STARTTLS)

### Create First User

See `docs/guides/MAILU-ACCESS-GUIDE.md` for creating the first email account.

---

## Troubleshooting

### Missing MAILU_DB_PASSWORD

**Error:** `The "MAILU_DB_PASSWORD" variable is not set`

**Fix:**
```bash
# Add to compose/.env
echo "MAILU_DB_PASSWORD=$(cat /home/comzis/apps/secrets-real/mailu-db-password)" >> compose/.env
```

### Network Issues

**Error:** `network mail was found but has incorrect label`

**Fix:**
```bash
# Ensure mail network is external in mailu.yml
# Then recreate if needed:
docker network rm mail
docker network create --subnet=172.30.0.0/16 mail
```

### Service Won't Start

**Check logs:**
```bash
docker compose -f compose/services/mailu.yml --env-file compose/.env logs <service-name>
```

**Common issues:**
- Missing secrets
- Network not created
- Port conflicts (check if ports 25, 465, 587, 143, 993 are in use)

---

## Reference

- **Main Compose File**: `compose/services/mailu.yml`
- **Environment Template**: `env.example` (see Mailu section)
- **Access Guide**: `docs/guides/MAILU-ACCESS-GUIDE.md`
- **Mailu Documentation**: https://mailu.io/2.0/

---

**Last Updated:** December 25, 2025

