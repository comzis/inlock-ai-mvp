# Secrets Directory

**⚠️ IMPORTANT: This directory contains only `.example` placeholder files.**

**Real secrets are stored in:** `/home/comzis/apps/secrets-real/` (outside this repository)

## Purpose

This directory contains example/placeholder files to document:
- What secrets are required
- Where they should be stored
- How to generate/install them

## Files

- `positive-ssl.crt.example` - PositiveSSL certificate for inlock.ai
- `positive-ssl.key.example` - Private key for PositiveSSL certificate
- `traefik-dashboard-users.htpasswd.example` - Traefik dashboard basic auth
- `portainer-admin-password.example` - Portainer admin password
- `n8n-db-password.example` - n8n PostgreSQL password
- `n8n-encryption-key.example` - n8n encryption key

## Installation

See [docs/SECRET-MANAGEMENT.md](../docs/SECRET-MANAGEMENT.md) for detailed instructions on:
- Installing each secret
- Setting correct permissions
- Rotating secrets
- Troubleshooting

## Security

- **Never commit real secrets to Git**
- All real secrets are in `/home/comzis/apps/secrets-real/` (excluded from Git)
- Secret files have `600` permissions (owner read/write only)
- Secret directory has `700` permissions (owner access only)

## Quick Reference

```bash
# Check if secrets are installed
ls -la /home/comzis/apps/secrets-real/

# Verify permissions
ls -l /home/comzis/apps/secrets-real/* | grep -v "^total"

# Set correct permissions
chmod 600 /home/comzis/apps/secrets-real/*
chmod 700 /home/comzis/apps/secrets-real/
```
