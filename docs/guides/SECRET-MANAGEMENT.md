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

## Rotation Log (update after every change)

| Secret / Token                    | Location                                         | Cadence        | Last Rotated | Next Due      | Notes                                  |
|-----------------------------------|--------------------------------------------------|----------------|--------------|---------------|----------------------------------------|
| Cloudflare API Token              | `/home/comzis/inlock-infra/.env` (`CLOUDFLARE_API_TOKEN`) | Annually       | yyyy-mm-dd   | yyyy-mm-dd    | Scoped DNS-edit token                  |
| Traefik basic auth (htpasswd)     | `/home/comzis/apps/secrets-real/traefik-dashboard-users.htpasswd` | Quarterly      | yyyy-mm-dd   | yyyy-mm-dd    | Admin dashboard protection             |
| Portainer admin password          | `/home/comzis/apps/secrets-real/portainer-admin-password` | Quarterly      | yyyy-mm-dd   | yyyy-mm-dd    |                                        |
| Grafana admin password            | `/home/comzis/apps/secrets-real/grafana-admin-password` | Quarterly      | yyyy-mm-dd   | yyyy-mm-dd    |                                        |
| n8n DB password                   | `/home/comzis/apps/secrets-real/n8n-db-password` | Quarterly      | yyyy-mm-dd   | yyyy-mm-dd    |                                        |
| n8n encryption key                | `/home/comzis/apps/secrets-real/n8n-encryption-key` | Semi-annual    | yyyy-mm-dd   | yyyy-mm-dd    | Rotates with DB when feasible          |
| Inlock DB password                | `/home/comzis/apps/secrets-real/inlock-db-password` | Quarterly      | yyyy-mm-dd   | yyyy-mm-dd    |                                        |
| PositiveSSL certificate & key     | `/home/comzis/apps/secrets-real/positive-ssl.{crt,key}` | Annual/expiry  | yyyy-mm-dd   | expiry date   | Renew if <30 days remaining            |
| App secrets (NextAuth, etc.)      | `/opt/inlock-ai-secure-mvp/.env.production`      | Monthly        | yyyy-mm-dd   | yyyy-mm-dd    | Includes NEXTAUTH_SECRET, OAuth creds  |
| Auth0 admin/management client sec | `/home/comzis/inlock-infra/.env` and `/opt/inlock-ai-secure-mvp/.env.production` | Semi-annual    | yyyy-mm-dd   | yyyy-mm-dd    | Rotate with M2M secret lifecycle       |

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

## Automated Audit

- Run `./scripts/security/audit-secrets-age.sh` to flag overdue secrets by file mtime and SSL expiry.
- Update the rotation log table above after each change.
- Exit code is non-zero if any item is missing or past due; use in CI or cron.

### Checksums (tamper detection)

- Generate checksum manifest:
  ```bash
  SECRETS_DIR=/home/comzis/apps/secrets-real \
  ./scripts/security/generate-secrets-checksums.sh
  ```
- Store `secrets.sha256` in a secure location; compare against a known-good copy to detect unexpected changes:
  ```bash
  cd /home/comzis/apps/secrets-real
  sha256sum -c secrets.sha256
  ```

### Automation (recommended)

- **Cron (monthly):**
  ```cron
  # Run audit with live env file
  0 3 1 * * cd /home/comzis/.cursor/worktrees/inlock-ai__Workspace___SSH__inlock_/uwe && ENV_FILE=/home/comzis/inlock/.env ./scripts/security/audit-secrets-age.sh >> /var/log/inlock-secrets-audit.log
  # After authorized rotations, regenerate checksums and archive off-host
  5 3 1 * * cd /home/comzis/.cursor/worktrees/inlock-ai__Workspace___SSH__inlock_/uwe && SECRETS_DIR=/home/comzis/apps/secrets-real ./scripts/security/generate-secrets-checksums.sh >> /var/log/inlock-secrets-audit.log
  ```
  - Alert on non-zero exit for the audit job.
  - Store `secrets.sha256` securely off-host and compare against the known-good copy when investigating.

- **CI guardrail:**
  - Add a CI job to run `scripts/security/audit-secrets-age.sh` (with mocked paths or secrets provided in CI).
  - Add secret scanning (gitleaks/trufflehog) to fail on committed secrets.

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
