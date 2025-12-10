# Secret Management & Rotation

## Overview

This document defines the lifecycle management for all secrets used in the Inlock infrastructure.

## Secret Inventory

### Cloudflare
- **Type:** API Token
- **Location:** `.env` → `CLOUDFLARE_API_TOKEN`
- **Rotation Cadence:** Annually or if compromised
- **Last Rotated:** [Update after rotation]
- **Access:** Cloudflare Dashboard → My Profile → API Tokens

### Traefik Basic Auth
- **Type:** HTTP Basic Auth (htpasswd)
- **Location:** Docker secret → `traefik-basicauth`
- **Rotation Cadence:** Quarterly
- **Last Rotated:** [Update after rotation]
- **Access:** `scripts/update-traefik-auth.sh` or manual htpasswd update

### Database Credentials
- **Type:** Postgres username/password
- **Location:** `.env.production` → `DATABASE_URL`
- **Rotation Cadence:** Quarterly
- **Last Rotated:** [Update after rotation]
- **Access:** `/opt/inlock-ai-secure-mvp/.env.production`

### SSL Certificates
- **Type:** Positive SSL Certificate & Key
- **Location:** Docker secrets → `positive_ssl_cert`, `positive_ssl_key`
- **Rotation Cadence:** Annually (cert expires)
- **Last Rotated:** [Update after rotation]
- **Access:** Cert provider portal

### Application Secrets
- **Type:** NextAuth secret, encryption keys, API keys
- **Location:** `.env.production`
- **Rotation Cadence:** Monthly
- **Last Rotated:** [Update after rotation]
- **Access:** `/opt/inlock-ai-secure-mvp/.env.production`

## Rotation Procedures

### Cloudflare API Token

1. **Create new token:**
   ```bash
   # Via Cloudflare Dashboard:
   # My Profile → API Tokens → Create Token
   # Permissions: Zone → DNS → Edit, Zone → Zone → Read
   ```

2. **Update `.env`:**
   ```bash
   cd /home/comzis/inlock-infra
   # Edit .env: CLOUDFLARE_API_TOKEN=new_token_here
   ```

3. **Verify:**
   ```bash
   ./scripts/verify-cloudflare-proxy.sh
   ```

4. **Revoke old token:**
   - Cloudflare Dashboard → API Tokens → Revoke old token

### Traefik Basic Auth

1. **Generate new password:**
   ```bash
   htpasswd -nb admin new_password_here | base64
   ```

2. **Update secret:**
   ```bash
   cd /home/comzis/inlock-infra
   echo -n "$HASHED_PASSWORD" | docker secret create traefik-basicauth -
   ```

3. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d traefik
   ```

4. **Update documentation:**
   - Update password in secure password manager
   - Update rotation date in this doc

### Database Credentials

1. **Generate new password:**
   ```bash
   openssl rand -base64 32
   ```

2. **Update database:**
   ```sql
   ALTER USER inlock_user WITH PASSWORD 'new_password';
   ```

3. **Update `.env.production`:**
   ```bash
   # Update DATABASE_URL in /opt/inlock-ai-secure-mvp/.env.production
   ```

4. **Restart application:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
   ```

### SSL Certificates

1. **Order renewal** (before expiry)
   - Contact certificate provider
   - Complete domain validation

2. **Download new certificate and key:**
   ```bash
   # Save to secure location
   ```

3. **Update Docker secrets:**
   ```bash
   # Remove old secrets
   docker secret rm positive_ssl_cert positive_ssl_key
   
   # Create new secrets
   cat new_cert.crt | docker secret create positive_ssl_cert -
   cat new_key.key | docker secret create positive_ssl_key -
   ```

4. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d traefik
   ```

5. **Verify:**
   ```bash
   openssl s_client -connect inlock.ai:443 -servername inlock.ai < /dev/null 2>/dev/null | openssl x509 -noout -dates
   ```

### Application Secrets

1. **Generate new secrets:**
   ```bash
   # NextAuth secret
   openssl rand -base64 32
   
   # Encryption keys
   openssl rand -hex 32
   ```

2. **Update `.env.production`:**
   ```bash
   # Edit /opt/inlock-ai-secure-mvp/.env.production
   # Update NEXTAUTH_SECRET, ENCRYPTION_KEY, etc.
   ```

3. **Restart application:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
   ```

4. **Verify:**
   - Test authentication flows
   - Check application logs

## Rotation Checklist

Add to `scripts/deploy-manual.sh` pre-deployment check:

- [ ] Cloudflare API token valid (not expired)
- [ ] SSL certificate valid (expiry > 30 days)
- [ ] Database credentials rotated in last 90 days
- [ ] Application secrets rotated in last 30 days
- [ ] Traefik basic auth rotated in last 90 days

## Secret Storage Security

### Current State
- Secrets stored in plain text files (`.env`, `.env.production`)
- Docker secrets used for some credentials
- Files in `/home/comzis/apps/secrets-real`

### Recommended Improvements

#### Option 1: SOPS (Secrets Operations)

**Install:**
```bash
# Download SOPS from https://github.com/getsops/sops/releases
# Or via package manager
```

**Setup:**
1. Generate GPG key or use AWS KMS / Azure Key Vault
2. Encrypt `.env` files with SOPS
3. Update deployment scripts to decrypt before use

**Usage:**
```bash
# Encrypt
sops -e -i .env

# Decrypt for use
sops -d .env > .env.decrypted
```

#### Option 2: Docker Secrets with Automated Rotation

**Enhancement:**
- Generate secrets at deploy time from secure vault
- Use `docker secret create` with expiration dates
- Automate rotation via cron + scripts

#### Option 3: HashiCorp Vault (Enterprise)

**Setup:**
- Deploy Vault in secure network
- Use AppRole authentication
- Fetch secrets at container startup
- Secrets never stored on disk

### Migration Plan

1. **Phase 1 (Immediate):**
   - Document all secret locations
   - Implement rotation cadence
   - Add verification scripts

2. **Phase 2 (Next Quarter):**
   - Migrate to SOPS for `.env` files
   - Move secrets to encrypted storage
   - Update deployment scripts

3. **Phase 3 (Future):**
   - Evaluate Vault integration
   - Implement automated rotation
   - Add secret scanning in CI

## Audit & Compliance

### Secret Age Monitoring

Run monthly audit:
```bash
./scripts/audit-secrets.sh
```

Checks:
- Secret file modification dates
- Certificate expiry dates
- Credential age vs. rotation cadence

### Access Logging

- Log all secret access (who, when, what)
- Monitor for unauthorized access
- Alert on suspicious patterns

### Compliance Notes

- **GDPR:** Ensure secrets handling complies with data protection
- **SOC 2:** Document secret management procedures
- **PCI DSS:** If handling payment data, use FIPS 140-2 validated encryption

---

**Last Updated:** December 10, 2025  
**Next Review:** January 10, 2026  
**Related:** `docs/CLOUDFLARE-IP-ALLOWLIST.md`, `scripts/deploy-manual.sh`
