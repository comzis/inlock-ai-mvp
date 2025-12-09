# Secret Management

## Overview

All sensitive credentials, certificates, and keys are stored **outside** the Git repository in `/home/comzis/apps/secrets/`. Only `.example` placeholder files are committed to Git.

## Secret Storage Location

**Production secrets location:** `/home/comzis/apps/secrets/`

This directory is:
- Outside the Git repository
- Excluded from Git via `.gitignore`
- Protected with restrictive permissions (600 for files, 700 for directory)
- Not backed up to Git or public repositories

## Required Secrets

### 1. PositiveSSL Certificate (`positive-ssl.crt`, `positive-ssl.key`)

**Purpose:** TLS certificate for apex domain `inlock.ai`

**Installation:**
```bash
# Copy certificate
cp /path/to/inlock_ai.crt /home/comzis/apps/secrets/positive-ssl.crt

# Copy private key
cp /path/to/inlock_ai.key /home/comzis/apps/secrets/positive-ssl.key

# Set permissions
chmod 600 /home/comzis/apps/secrets/positive-ssl.crt
chmod 600 /home/comzis/apps/secrets/positive-ssl.key
```

**Verification:**
```bash
# Verify key matches certificate
openssl x509 -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.crt | openssl md5
openssl rsa -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.key | openssl md5
# Both should output the same hash
```

### 2. Traefik Dashboard Authentication (`traefik-dashboard-users.htpasswd`)

**Purpose:** Basic authentication for Traefik dashboard at `traefik.inlock.ai`

**Generation:**
```bash
# Generate bcrypt hash (preferred)
htpasswd -nbB admin YOUR_PASSWORD > /home/comzis/apps/secrets/traefik-dashboard-users.htpasswd

# Or Apache MD5 format (also works with Traefik)
htpasswd -nbm admin YOUR_PASSWORD > /home/comzis/apps/secrets/traefik-dashboard-users.htpasswd

# Set permissions
chmod 600 /home/comzis/apps/secrets/traefik-dashboard-users.htpasswd
```

**Format:** `username:hashed_password` (one per line)

### 3. Portainer Admin Password (`portainer-admin-password`)

**Purpose:** Initial admin password for Portainer (set on first access if not using file)

**Installation:**
```bash
echo "YOUR_SECURE_PASSWORD" > /home/comzis/apps/secrets/portainer-admin-password
chmod 600 /home/comzis/apps/secrets/portainer-admin-password
```

**Note:** Portainer can also prompt for password on first access. The file is optional.

### 4. n8n Database Password (`n8n-db-password`)

**Purpose:** PostgreSQL password for n8n database user

**Installation:**
```bash
echo "YOUR_SECURE_PASSWORD" > /home/comzis/apps/secrets/n8n-db-password
chmod 600 /home/comzis/apps/secrets/n8n-db-password
```

**Important:** This password must match the PostgreSQL user password. To reset:
```bash
# Read password from secret
N8N_PASSWORD=$(cat /home/comzis/apps/secrets/n8n-db-password | tr -d '\n\r')

# Reset in Postgres
docker compose -f compose/postgres.yml --env-file .env exec -T postgres \
  psql -U n8n -d n8n -c "ALTER USER n8n WITH PASSWORD '$N8N_PASSWORD';"
```

### 5. n8n Encryption Key (`n8n-encryption-key`)

**Purpose:** Encryption key for n8n workflow data (32+ characters)

**Generation:**
```bash
# Generate random 32-character key
openssl rand -base64 32 > /home/comzis/apps/secrets/n8n-encryption-key
chmod 600 /home/comzis/apps/secrets/n8n-encryption-key
```

**Important:** 
- Must be at least 32 characters
- Keep this key secure - losing it means encrypted workflow data cannot be decrypted
- Do not change this key after workflows are created (data will be lost)

## Secret Rotation

### Rotating Passwords

1. **Update secret file:**
   ```bash
   echo "NEW_PASSWORD" > /home/comzis/apps/secrets/SECRET_NAME
   chmod 600 /home/comzis/apps/secrets/SECRET_NAME
   ```

2. **Update service configuration:**
   - For database passwords: Update both secret file and database user
   - For application passwords: Restart the service

3. **Restart affected services:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart SERVICE_NAME
   ```

### Rotating SSL Certificates

1. **Backup current certificate:**
   ```bash
   cp /home/comzis/apps/secrets/positive-ssl.crt /home/comzis/apps/secrets/positive-ssl.crt.backup-$(date +%Y%m%d)
   cp /home/comzis/apps/secrets/positive-ssl.key /home/comzis/apps/secrets/positive-ssl.key.backup-$(date +%Y%m%d)
   ```

2. **Install new certificate:**
   ```bash
   cp /path/to/new_cert.crt /home/comzis/apps/secrets/positive-ssl.crt
   cp /path/to/new_key.key /home/comzis/apps/secrets/positive-ssl.key
   chmod 600 /home/comzis/apps/secrets/positive-ssl.*
   ```

3. **Verify key matches certificate:**
   ```bash
   openssl x509 -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.crt | openssl md5
   openssl rsa -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.key | openssl md5
   ```

4. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

## Security Best Practices

1. **File Permissions:**
   - All secret files: `600` (read/write owner only)
   - Secret directory: `700` (owner access only)

2. **Backup Strategy:**
   - Do NOT backup secrets to Git
   - Use encrypted backups (GPG, SOPS, or Vault)
   - Store backups in secure, separate location

3. **Access Control:**
   - Limit access to `/home/comzis/apps/secrets/` to root and service owner only
   - Use `sudo` for secret management operations
   - Audit secret access logs regularly

4. **Rotation Schedule:**
   - Passwords: Every 90 days (or per security policy)
   - SSL Certificates: Before expiration (typically 1 year)
   - Encryption Keys: Only when compromised (data loss risk)

## Future: SOPS/Vault Integration

For enhanced security, consider migrating to:
- **SOPS (Secrets OPerationS):** Encrypted secrets in Git with age/age-key encryption
- **HashiCorp Vault:** Centralized secret management with dynamic secrets
- **Cloud Provider Secrets Manager:** AWS Secrets Manager, Azure Key Vault, etc.

Migration steps:
1. Install SOPS/Vault client
2. Encrypt existing secrets
3. Update compose files to use SOPS/Vault provider
4. Document new secret management workflow

## Troubleshooting

### Service Cannot Read Secret

**Error:** `permission denied` or `file not found`

**Fix:**
```bash
# Check file exists
ls -la /home/comzis/apps/secrets/SECRET_NAME

# Check permissions
chmod 600 /home/comzis/apps/secrets/SECRET_NAME

# Check compose file references correct path
grep -r "SECRET_NAME" compose/
```

### Secret File Contains Placeholder

**Error:** Service fails with authentication/certificate errors

**Fix:**
1. Verify secret file contains real data (not placeholder)
2. Check file size (placeholders are usually < 200 bytes)
3. Reinstall secret following installation instructions above

### Database Password Mismatch

**Error:** `password authentication failed for user`

**Fix:**
```bash
# Reset password in database to match secret file
N8N_PASSWORD=$(cat /home/comzis/apps/secrets/n8n-db-password | tr -d '\n\r')
docker compose -f compose/postgres.yml --env-file .env exec -T postgres \
  psql -U n8n -d n8n -c "ALTER USER n8n WITH PASSWORD '$N8N_PASSWORD';"
```

## References

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Traefik Basic Auth](https://doc.traefik.io/traefik/middlewares/http/basicauth/)
- [n8n Security](https://docs.n8n.io/security/)
- [Portainer Security](https://docs.portainer.io/start/install/server/security)



