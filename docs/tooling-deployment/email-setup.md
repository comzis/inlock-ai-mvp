# Email Server Deployment Guide

Mailcow is the production mail stack for Inlock AI and is deployed outside this repo at `/home/comzis/mailcow`.

## Quick Start

```bash
cd /home/comzis/mailcow
docker compose up -d
```

## Full Setup Guide

See `docs/deployment/MAILCOW-DEPLOYMENT.md` for:
- DNS records (MX/SPF/DKIM/DMARC)
- Mailbox provisioning
- Validation commands
- Ongoing maintenance
