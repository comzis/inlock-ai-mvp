# Email Server Deployment Guide

Deploy **Mailu** full-featured email server for Inlock AI.

## Overview

Mailu provides:
- **SMTP/IMAP**: Full email server functionality
- **Webmail**: Roundcube web interface at `mail.inlock.ai`
- **Admin Panel**: Email account management
- **Security**: SPF, DKIM, DMARC, spam filtering

## Prerequisites

- Docker and Docker Compose installed
- Domain `mail.inlock.ai` pointing to server
- Ports 25, 465, 587 (SMTP) and 143, 993 (IMAP) open
- Docker secrets configured (recommended)

## DNS Configuration

Before deployment, configure these DNS records:

```dns
# MX Record
@           IN MX 10 mail.inlock.ai.

# A Record
mail        IN A     <your-server-ip>

# SPF Record
@           IN TXT   "v=spf1 mx ~all"

# DMARC Record
_dmarc      IN TXT   "v=DMARC1; p=quarantine; rua=mailto:admin@inlock.ai"

# DKIM Record (generate after first deployment)
# Will be created: dkim._domainkey IN TXT "v=DKIM1; k=rsa; p=..."
```

## Deployment Steps

### 1. Set Up Docker Secrets

Create secret files (recommended for production):

```bash
# Generate secure keys
openssl rand -hex 32 > /home/comzis/apps/secrets-real/mailu-secret-key
openssl rand -base64 24 > /home/comzis/apps/secrets-real/mailu-admin-password
openssl rand -base64 24 > /home/comzis/apps/secrets-real/mailu-db-password

# Secure the files
chmod 600 /home/comzis/apps/secrets-real/mailu-*
```

### 2. Environment Configuration

Copy the template:

```bash
cp infrastructure/env-templates/mailu.env.template .env.mailu
```

Edit `.env.mailu`:

```env
DOMAIN=inlock.ai
POSTMASTER=admin
```

### 3. Create Required Networks

```bash
docker network create mail || true
docker network create traefik_public || true
docker network create internal || true
docker network create mgmt || true
```

### 4. Deploy Mailu

```bash
docker compose -f infrastructure/docker-compose/email.yml up -d
```

### 5. Verify Deployment

**Check services:**
```bash
docker compose -f infrastructure/docker-compose/email.yml ps
```

**Access webmail:**
Visit `https://mail.inlock.ai` and log in with:
- Username: `admin@inlock.ai`
- Password: (from `/home/comzis/apps/secrets-real/mailu-admin-password`)

### 6. Configure DKIM

Retrieve DKIM public key:

```bash
docker exec mailu-admin cat /dkim/inlock.ai.dkim.key
```

Add the output as a TXT record:
```dns
dkim._domainkey IN TXT "v=DKIM1; k=rsa; p=<your-public-key>"
```

## Security Hardening

The Mailu stack includes several security features:

- **Read-only filesystems** where possible
- **Capability dropping** to minimum required
- **No new privileges** security option
- **Tmpfs** for temporary files
- **Health checks** for all services
- **Docker secrets** for sensitive data

## Firewall Configuration

Allow these ports:

```bash
# SMTP
ufw allow 25/tcp
ufw allow 465/tcp
ufw allow 587/tcp

# IMAP
ufw allow 143/tcp
ufw allow 993/tcp
```

## Testing Email Delivery

### Send Test Email

```bash
# From within the server
echo "Test email body" | mail -s "Test Subject" recipient@example.com
```

### Check Mail Queue

```bash
docker exec mailu-postfix postqueue -p
```

### View Logs

```bash
# All services
docker compose -f infrastructure/docker-compose/email.yml logs -f

# Specific service
docker logs mailu-postfix
docker logs mailu-imap
docker logs mailu-rspamd
```

## Troubleshooting

### Mail not sending

1. Check SMTP logs: `docker logs mailu-postfix`
2. Verify DNS records are propagated
3. Check if port 25 is blocked by ISP
4. Verify SPF/DKIM/DMARC records

### Webmail not accessible

1. Check Traefik labels in compose file
2. Verify SSL certificate generation
3. Check front service: `docker logs mailu-front`

### Database connection errors

1. Check secrets are mounted correctly
2. Verify PostgreSQL is running: `docker logs mailu-postgres`
3. Check network connectivity between services

## Maintenance

### Backup Email Data

```bash
docker run --rm \
  -v mailu_mail_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mailu-mail-backup.tar.gz /data

docker run --rm \
  -v mailu_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mailu-db-backup.tar.gz /data
```

### Update Mailu

```bash
docker compose -f infrastructure/docker-compose/email.yml pull
docker compose -f infrastructure/docker-compose/email.yml up -d
```

### Add New Email Account

Access admin panel at `https://mail.inlock.ai/admin` and create users.

## Resources

- [Mailu Documentation](https://mailu.io/master/)
- [MX Toolbox (DNS Testing)](https://mxtoolbox.com/)
- [Mail Tester (Spam Score)](https://www.mail-tester.com/)
