# INLOCK.AI Infrastructure User Guide

## Table of Contents
1. [Overview](#overview)
2. [Services & Access](#services--access)
3. [Security Features](#security-features)
4. [TLS/SSL Certificates](#tlsssl-certificates)
5. [Network Architecture](#network-architecture)
6. [Monitoring & Metrics](#monitoring--metrics)
7. [Backup & Maintenance](#backup--maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Firewall Management](#firewall-management)

---

## Overview

The INLOCK.AI infrastructure is a hardened, GitOps-ready Docker Compose stack running on a single server. It provides:

- **Reverse Proxy**: Traefik for routing and TLS termination
- **Container Management**: Portainer for Docker management
- **Workflow Automation**: n8n for automation workflows
- **Database**: PostgreSQL for n8n data storage
- **Monitoring**: cAdvisor for container metrics
- **Homepage**: Static website for the main domain

All services are secured with:
- IP allowlisting (Tailscale VPN required for admin services)
- Authentication (Basic Auth or Forward Auth)
- Rate limiting
- Secure headers (HSTS, CSP, etc.)
- TLS/SSL encryption

---

## Services & Access

### 1. Homepage (`inlock.ai` / `www.inlock.ai`)

**URL**: https://inlock.ai  
**Access**: Public (no authentication required)

**Features**:
- Static website served via Nginx
- Public access (no restrictions)
- HTTPS with PositiveSSL certificate
- HTTP to HTTPS redirect

**How to Access**:
```
https://inlock.ai
https://www.inlock.ai
```

---

### 2. Traefik Dashboard (`traefik.inlock.ai`)

**URL**: https://traefik.inlock.ai  
**Access**: **RESTRICTED** - Requires:
- Tailscale VPN connection (IP allowlist)
- Basic Authentication (username/password)

**Features**:
- Traefik reverse proxy dashboard
- View routers, services, and middlewares
- Monitor HTTP/HTTPS traffic
- View TLS certificate status
- Access logs and metrics

**Security**:
- ✅ IP Allowlist (Tailscale IPs only)
- ✅ Basic Authentication
- ✅ Rate Limiting (50 req/min avg, 100 burst)
- ✅ Secure Headers (HSTS, CSP, etc.)
- ✅ Let's Encrypt TLS certificate

**How to Access**:
1. Connect to Tailscale VPN
2. Navigate to: https://traefik.inlock.ai
3. Enter Basic Auth credentials (stored in Docker secrets)

**Allowed IPs**:
- `100.83.222.69/32` (Admin device 1)
- `100.96.110.8/32` (Admin device 2)

---

### 3. Portainer (`portainer.inlock.ai`)

**URL**: https://portainer.inlock.ai  
**Access**: **RESTRICTED** - Requires:
- Tailscale VPN connection (IP allowlist)
- Forward Authentication (via auth service)
- Portainer admin password

**Features**:
- Docker container management
- Container logs and console access
- Image management
- Network and volume management
- Stack deployment
- User management

**Security**:
- ✅ IP Allowlist (Tailscale IPs only)
- ✅ Forward Authentication
- ✅ Rate Limiting (50 req/min avg, 100 burst)
- ✅ Secure Headers
- ✅ Let's Encrypt TLS certificate

**How to Access**:
1. Connect to Tailscale VPN
2. Navigate to: https://portainer.inlock.ai
3. Complete forward authentication
4. Enter Portainer admin password

**Allowed IPs**:
- `100.83.222.69/32` (Admin device 1)
- `100.96.110.8/32` (Admin device 2)

---

### 4. n8n Workflow Automation (`n8n.inlock.ai`)

**URL**: https://n8n.inlock.ai  
**Access**: **RESTRICTED** - Requires:
- Tailscale VPN connection (IP allowlist)
- n8n user account (created on first access)

**Features**:
- Workflow automation and orchestration
- 400+ integrations (APIs, databases, services)
- Visual workflow editor
- Webhook support
- Scheduled workflows (cron)
- Data transformation and processing
- PostgreSQL database backend

**Security**:
- ✅ IP Allowlist (Tailscale IPs only)
- ✅ Rate Limiting (50 req/min avg, 100 burst)
- ✅ Secure Headers
- ✅ Let's Encrypt TLS certificate
- ✅ Encrypted credentials storage

**How to Access**:
1. Connect to Tailscale VPN
2. Navigate to: https://n8n.inlock.ai
3. Create your first user account (on first access)
4. Start building workflows

**Allowed IPs**:
- `100.83.222.69/32` (Admin device 1)
- `100.96.110.8/32` (Admin device 2)

**Database**:
- PostgreSQL 16 (internal network only)
- Data stored in Docker volume: `postgres_data`

---

### 5. cAdvisor (`localhost:8080`)

**URL**: http://localhost:8080 (internal only)  
**Access**: **LOCALHOST ONLY** - No external access

**Features**:
- Container resource usage monitoring
- CPU, memory, network, and filesystem metrics
- Per-container statistics
- Historical data
- Prometheus metrics endpoint

**Security**:
- ✅ No external access (localhost only)
- ✅ Internal network only

**How to Access**:
```bash
# From the server
curl http://localhost:8080
```

---

## Security Features

### IP Allowlisting

Admin services (Traefik, Portainer, n8n) are protected by IP allowlists. Only Tailscale VPN IPs can access these services.

**Current Allowed IPs**:
- `100.83.222.69/32` - Admin device 1 (Tailscale)
- `100.96.110.8/32` - Admin device 2 (Tailscale)

**To Add/Remove IPs**:
1. Edit `traefik/dynamic/middlewares.yml`
2. Update the `allowed-admins` middleware
3. Restart Traefik: `docker compose -f compose/stack.yml restart traefik`

### Authentication

**Traefik Dashboard**:
- Basic Authentication (htpasswd)
- Credentials stored in Docker secrets: `traefik-basicauth`

**Portainer**:
- Forward Authentication via `https://auth.inlock.ai/check`
- Additional Portainer admin password required

**n8n**:
- User accounts managed within n8n
- First user becomes admin

### Rate Limiting

All admin services have rate limiting enabled:
- **Average**: 50 requests per minute
- **Burst**: 100 requests

This prevents brute force attacks and DDoS.

### Secure Headers

All services include security headers:
- **HSTS**: Strict Transport Security (2 years)
- **Content-Type No-Sniff**: Prevents MIME sniffing
- **Frame Deny**: Prevents clickjacking
- **Referrer Policy**: Controls referrer information
- **Permissions Policy**: Restricts browser features

### Network Segmentation

Services are isolated into separate Docker networks:
- **`edge`**: Public-facing services (Traefik, homepage, n8n)
- **`mgmt`**: Management services (Traefik, Portainer)
- **`internal`**: Internal services (PostgreSQL, n8n)
- **`socket-proxy`**: Docker socket proxy network

---

## TLS/SSL Certificates

### Certificate Strategy

**Apex Domain (`inlock.ai`)**:
- **Certificate**: PositiveSSL (commercial)
- **Type**: Self-signed (temporary, until PositiveSSL key is found)
- **Location**: Docker secrets (`positive_ssl_cert`, `positive_ssl_key`)
- **Valid Until**: Dec 5, 2035 (self-signed)

**Subdomains** (`*.inlock.ai`):
- **Certificate**: Let's Encrypt (automatic)
- **Challenge**: DNS-01 (Cloudflare)
- **Auto-renewal**: Enabled
- **Valid For**: 90 days (auto-renewed)

### Current Certificates

✅ **Active Certificates**:
- `traefik.inlock.ai` - Let's Encrypt
- `portainer.inlock.ai` - Let's Encrypt
- `n8n.inlock.ai` - Let's Encrypt
- `inlock.ai` - Self-signed (PositiveSSL pending)

### Certificate Management

**Let's Encrypt**:
- Automatically renewed by Traefik
- Stored in: `/etc/traefik/acme/acme.json` (Docker volume)
- Cloudflare DNS challenge configured

**PositiveSSL**:
- Manual installation required
- Certificate and key stored in Docker secrets
- Update secrets when renewing

---

## Network Architecture

### Docker Networks

```
┌─────────────────────────────────────────┐
│           edge Network                  │
│  ┌──────────┐  ┌──────────┐  ┌──────┐  │
│  │ Traefik  │  │ Homepage │  │  n8n │  │
│  └──────────┘  └──────────┘  └──────┘  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          mgmt Network                    │
│  ┌──────────┐  ┌──────────┐            │
│  │ Traefik  │  │ Portainer │            │
│  └──────────┘  └──────────┘            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         internal Network                 │
│  ┌──────────┐  ┌──────────┐            │
│  │ Postgres │  │   n8n     │            │
│  └──────────┘  └──────────┘            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│       socket-proxy Network               │
│  ┌──────────┐  ┌──────────┐              │
│  │ Traefik  │  │ Socket   │              │
│  │          │  │  Proxy   │              │
│  └──────────┘  └──────────┘              │
└─────────────────────────────────────────┘
```

### Port Mapping

**Public Ports**:
- `80` → Traefik (HTTP, redirects to HTTPS)
- `443` → Traefik (HTTPS)

**Internal Ports** (not exposed):
- `2375` → Docker Socket Proxy
- `5432` → PostgreSQL
- `5678` → n8n
- `8080` → cAdvisor
- `9000` → Portainer

---

## Monitoring & Metrics

### Traefik Metrics

**Prometheus Endpoint**: http://localhost:9100/metrics

**Available Metrics**:
- HTTP request counts
- Response times
- TLS certificate status
- Router and service health
- Entry point statistics

**Access**:
```bash
# From server
curl http://localhost:9100/metrics
```

### cAdvisor

**URL**: http://localhost:8080

**Features**:
- Container CPU usage
- Memory consumption
- Network I/O
- Filesystem usage
- Historical metrics

### Service Health Checks

All services have health checks configured:
- **Traefik**: `traefik healthcheck`
- **PostgreSQL**: `pg_isready`
- **n8n**: `wget http://localhost:5678/healthz`
- **Docker Socket Proxy**: `wget http://localhost:2375/_ping`
- **cAdvisor**: Built-in health endpoint

**Check Status**:
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps
```

---

## Backup & Maintenance

### Volume Backups

**Volumes to Backup**:
- `postgres_data` - PostgreSQL database
- `n8n_data` - n8n workflows and data
- `traefik_acme` - Let's Encrypt certificates
- `portainer_data` - Portainer data

**Backup Script**:
```bash
./scripts/backup-volumes.sh
```

**Restore Script**:
```bash
./scripts/restore-volumes.sh
```

### Database Backups

PostgreSQL database can be backed up separately:
```bash
docker exec compose-postgres-1 pg_dump -U n8n n8n > backup.sql
```

### Certificate Backups

**Let's Encrypt Certificates**:
- Stored in Docker volume: `traefik_acme`
- Backup the volume or `acme.json` file

**PositiveSSL Certificates**:
- Stored in Docker secrets
- Backup secret files: `secrets/positive-ssl.crt`, `secrets/positive-ssl.key`

### Maintenance Commands

**View Logs**:
```bash
# All services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs

# Specific service
docker compose -f compose/stack.yml --env-file .env logs traefik
```

**Restart Services**:
```bash
# All services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env restart

# Specific service
docker compose -f compose/stack.yml --env-file .env restart traefik
```

**Update Services**:
```bash
./scripts/update-infra.sh
```

---

## Troubleshooting

### Cannot Access Admin Services

**Problem**: Getting 403 Forbidden when accessing Traefik/Portainer/n8n

**Solutions**:
1. ✅ Ensure you're connected to Tailscale VPN
2. ✅ Verify your Tailscale IP is in the allowlist
3. ✅ Check `traefik/dynamic/middlewares.yml` for allowed IPs
4. ✅ Restart Traefik after updating allowlist

### Certificate Errors

**Problem**: Browser shows certificate warning

**Solutions**:
1. ✅ For subdomains: Wait for Let's Encrypt certificate generation (may take a few minutes)
2. ✅ Check Traefik logs: `docker logs compose-traefik-1 | grep -i acme`
3. ✅ Verify Cloudflare API token is configured in `.env`
4. ✅ For apex domain: Self-signed certificate is expected until PositiveSSL is installed

### Service Not Starting

**Problem**: Container keeps restarting

**Solutions**:
1. ✅ Check logs: `docker logs <container-name>`
2. ✅ Verify health check: `docker ps`
3. ✅ Check resource limits: `docker stats`
4. ✅ Verify secrets are configured: `ls -la /home/comzis/apps/secrets/`

### Portainer Permission Errors

**Problem**: Portainer shows "permission denied" errors

**Solution**:
```bash
sudo ./scripts/fix-portainer.sh
```

### n8n Database Connection Issues

**Problem**: n8n cannot connect to PostgreSQL

**Solutions**:
1. ✅ Verify PostgreSQL is running: `docker ps | grep postgres`
2. ✅ Check database credentials in `.env`
3. ✅ Verify secrets are mounted: `docker exec compose-n8n-1 ls -la /run/secrets/`
4. ✅ Check network connectivity: `docker exec compose-n8n-1 ping postgres`

---

## Quick Reference

### Service URLs

| Service | URL | Access |
|---------|-----|--------|
| Homepage | https://inlock.ai | Public |
| Traefik Dashboard | https://traefik.inlock.ai | Tailscale + Auth |
| Portainer | https://portainer.inlock.ai | Tailscale + Auth |
| n8n | https://n8n.inlock.ai | Tailscale |

### Common Commands

```bash
# Navigate to infrastructure directory
cd /home/comzis/inlock-infra

# View all services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs -f

# Restart all services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env restart

# Validate configuration
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config

# Test stack
./scripts/test-stack.sh
```

### Support

For issues or questions:
1. Check logs: `docker logs <service-name>`
2. Review documentation in `docs/`
3. Check security review: `.cursor/commands/security-review.md`
4. Run test scripts: `./scripts/test-stack.sh`

---

## Firewall Management

### Overview

The infrastructure uses UFW (Uncomplicated Firewall) for host-level network security. The firewall is configured to deny all incoming traffic by default and only allows explicitly permitted ports.

### Current Configuration

**Default Policies**:
- Incoming: DENY (default deny all)
- Outgoing: ALLOW
- Routed: ALLOW

**Allowed Ports**:
- UDP 41641 - Tailscale VPN
- TCP 22 - SSH
- TCP 80 - HTTP (Traefik)
- TCP 443 - HTTPS (Traefik)

### Management Methods

**1. Management Script (Recommended for quick changes)**:
```bash
# View status
sudo ./scripts/manage-firewall.sh status

# Allow a port
sudo ./scripts/manage-firewall.sh allow 8080

# Remove a port
sudo ./scripts/manage-firewall.sh deny 8080

# List all rules
sudo ./scripts/manage-firewall.sh list

# View logs
sudo ./scripts/manage-firewall.sh logs

# Create audit backup
sudo ./scripts/manage-firewall.sh audit
```

**2. Ansible Playbook (Recommended for production)**:
```bash
# Edit ansible/roles/hardening/tasks/main.yml
# Then run:
ansible-playbook playbooks/hardening.yml
```

**3. Manual Script (Full reset)**:
```bash
sudo ./scripts/apply-firewall-manual.sh
```

**4. Direct UFW Commands (Emergency only)**:
```bash
sudo ufw status verbose
sudo ufw allow <port>/tcp comment 'Description'
sudo ufw delete <rule_number>
```

### Adding New Rules

**For a new service**:
1. Plan the change (port, protocol, access restrictions)
2. Update Ansible playbook (`ansible/roles/hardening/tasks/main.yml`)
3. Test in staging (if available)
4. Apply to production: `ansible-playbook playbooks/hardening.yml`
5. Verify: `sudo ./scripts/manage-firewall.sh status`
6. Document in `docs/FIREWALL-STATUS.md`

**Quick addition** (for testing):
```bash
sudo ./scripts/manage-firewall.sh allow <port>
```

### Best Practices

- ✅ Use Ansible for production changes (version controlled)
- ✅ Document all changes in Git
- ✅ Test changes before applying
- ✅ Audit firewall rules monthly
- ✅ Use principle of least privilege (only allow what's needed)
- ✅ Monitor firewall logs regularly

### Documentation

- **Firewall Management Guide**: `docs/FIREWALL-MANAGEMENT.md` (complete guide)
- **Firewall Status**: `docs/FIREWALL-STATUS.md` (current status)
- **Network Security**: `docs/network-security.md` (security overview)

---

**Last Updated**: December 8, 2025  
**Infrastructure Version**: GitOps-ready hardened stack  
**Maintainer**: INLOCK.AI Infrastructure Team

