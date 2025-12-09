# INLOCK.AI Infrastructure

GitOps-ready, hardened Docker Compose infrastructure stack for INLOCK.AI.

## Overview

This repository contains the complete infrastructure configuration for INLOCK.AI, including:

- **Reverse Proxy**: Traefik with TLS termination
- **Container Management**: Portainer
- **Workflow Automation**: n8n
- **Database**: PostgreSQL
- **Monitoring**: cAdvisor
- **Security**: Hardened with IP allowlists, authentication, rate limiting

## Quick Start

```bash
# Clone the repository
git clone <repository-url> inlock-infra
cd inlock-infra

# Copy environment template
cp env.example .env

# Edit .env with your configuration
nano .env

# Set up secrets (see secrets/README.md)
# Configure firewall
sudo ./scripts/apply-firewall-manual.sh

# Deploy infrastructure
./scripts/deploy-manual.sh
```

## Documentation

- **[Admin Access Guide](docs/ADMIN-ACCESS-GUIDE.md)** - ⭐ Complete guide with links to all services
- **[User Guide](docs/USER-GUIDE.md)** - Complete user guide with all features and access information
- **[Quick Reference](docs/QUICK-REFERENCE.md)** - Quick reference card for daily operations
- **[Deployment Guide](DEPLOYMENT.md)** - Complete deployment instructions
- **[Manual Deployment](MANUAL-DEPLOYMENT.md)** - Deployment without Ansible
- **[Quick Start](QUICK-START.md)** - Quick start guide

### Application Deployment

- **[Inlock AI Deployment](docs/INLOCK-AI-DEPLOYMENT.md)** - Complete guide for deploying Inlock AI application to inlock.ai
- **[Inlock AI Quick Start](docs/INLOCK-AI-QUICK-START.md)** - Quick deployment guide for Inlock AI
- **[Workflow Best Practices](docs/WORKFLOW-BEST-PRACTICES.md)** - ⭐ Two-layer architecture and workflow guide

### Security Documentation

- **[Firewall Management](docs/FIREWALL-MANAGEMENT.md)** - Firewall management guide
- **[Network Security](docs/network-security.md)** - Network security configuration
- **[SSL Certificate Setup](docs/ssl-certificate-setup.md)** - TLS/SSL certificate configuration

### Infrastructure Documentation

- **[Infrastructure Overview](docs/infra.md)** - Infrastructure components overview
- **[DevOps Guide](docs/devops.md)** - DevOps practices and procedures

## Structure

```
inlock-infra/
├── compose/              # Docker Compose files
│   ├── stack.yml        # Main stack (Traefik, Portainer, etc.)
│   ├── postgres.yml     # PostgreSQL database
│   ├── inlock-db.yml    # Inlock AI database
│   └── n8n.yml         # n8n workflow automation
├── traefik/             # Traefik configuration
│   ├── traefik.yml      # Static configuration
│   └── dynamic/        # Dynamic configuration
│       ├── routers.yml
│       ├── services.yml
│       ├── middlewares.yml
│       └── tls.yml
├── ansible/             # Ansible automation
│   ├── playbooks/      # Deployment playbooks
│   ├── roles/          # Ansible roles
│   └── inventories/    # Host inventories
├── scripts/            # Management scripts
├── docs/               # Documentation
├── secrets/            # Secret files (not in Git)
└── .env                # Environment variables (not in Git)
```

## Services

| Service | URL | Access |
|---------|-----|--------|
| Homepage | https://inlock.ai | Public |
| Traefik Dashboard | https://traefik.inlock.ai | Tailscale + Auth |
| Portainer | https://portainer.inlock.ai | Tailscale + Auth |
| n8n | https://n8n.inlock.ai | Tailscale |

## Security

- ✅ IP Allowlisting (Tailscale VPN required for admin services)
- ✅ Authentication (Basic Auth / Forward Auth)
- ✅ Rate Limiting (50 req/min, 100 burst)
- ✅ Secure Headers (HSTS, CSP, etc.)
- ✅ TLS/SSL Encryption (Let's Encrypt + PositiveSSL)
- ✅ Firewall (UFW with deny-by-default)
- ✅ Network Segmentation (Docker networks)

## Prerequisites

- Docker and Docker Compose
- Tailscale VPN (for admin access)
- Cloudflare API token (for Let's Encrypt DNS challenge)
- SSL certificates (PositiveSSL for apex domain)

## Configuration

1. **Environment Variables**: Copy `env.example` to `.env` and configure
2. **Secrets**: Set up secret files in `secrets/` (see `secrets/README.md`)
3. **Firewall**: Configure UFW using `scripts/apply-firewall-manual.sh`
4. **TLS Certificates**: See `docs/ssl-certificate-setup.md`

## Deployment

### Using Ansible (Recommended)

```bash
ansible-playbook playbooks/deploy.yml
```

### Manual Deployment

```bash
./scripts/deploy-manual.sh
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## Management

### Firewall

```bash
# View status
sudo ./scripts/manage-firewall.sh status

# Allow port
sudo ./scripts/manage-firewall.sh allow 8080

# See all commands
sudo ./scripts/manage-firewall.sh help
```

### Services

```bash
# View status
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs -f

# Restart services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env restart
```

### Backups

```bash
# Backup volumes
./scripts/backup-volumes.sh

# Restore volumes
./scripts/restore-volumes.sh
```

## Testing

```bash
# Test entire stack
./scripts/test-stack.sh

# Test endpoints
./scripts/test-endpoints.sh
```

## Contributing

1. Make changes in a feature branch
2. Test changes thoroughly
3. Update documentation
4. Submit pull request

## Security Notes

- **Never commit secrets** - All secrets are in `.gitignore`
- **Review firewall changes** - Use Ansible for production changes
- **Audit regularly** - Review firewall rules and access logs monthly
- **Keep updated** - Apply security updates regularly

## License

Proprietary - INLOCK.AI Infrastructure

## Support

For issues or questions:
1. Check documentation in `docs/`
2. Review logs: `docker logs <service-name>`
3. Run test scripts: `./scripts/test-stack.sh`

---

**Last Updated**: December 8, 2025  
**Version**: GitOps-ready hardened stack  
**Maintainer**: INLOCK.AI Infrastructure Team



