# INLOCK.AI Infrastructure

GitOps-ready, hardened Docker Compose infrastructure stack for INLOCK.AI.

**Repository:** [https://github.com/comzis/inlock-ai-mvp](https://github.com/comzis/inlock-ai-mvp)

## Overview

Latest changes: see [Release Notes](docs/RELEASE-NOTES.md)

This repository contains the complete infrastructure configuration for INLOCK.AI, including:

- **Reverse Proxy**: Traefik with TLS termination (Positive SSL + Let's Encrypt)
- **Container Management**: Portainer
- **Workflow Automation**: n8n
- **Database**: PostgreSQL (multiple instances)
- **Monitoring & Observability**: Prometheus, Alertmanager, Grafana, Node Exporter, Blackbox Exporter, cAdvisor, Loki/Promtail
- **Security**: Hardened with IP allowlists, authentication, rate limiting
- **Application**: Inlock AI production application (Next.js)

## AI Workspaces & Workflow

This repo is the codebase. The AI control workspaces are separate and should not contain code changes.

- **Code repo**: `/home/comzis/projects/inlock-ai-mvp`
- **Cursor control workspace** (rules + health checks): `/home/comzis/.cursor/projects/home-comzis-inlock`
- **Antigravity config workspace**: `/home/comzis/antigravity`

Workflow for infra changes:

1) Preflight: `bash /home/comzis/.cursor/projects/home-comzis-inlock/scripts/preflight.sh`
2) Make changes in this repo only
3) Postflight: `bash /home/comzis/.cursor/projects/home-comzis-inlock/scripts/postflight.sh`

## Quick Start

```bash
# Clone the repository
git clone git@github.com:comzis/inlock-ai-mvp.git inlock-infra
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

### Core Guides

- **[Admin Access Guide](docs/guides/ADMIN-ACCESS-GUIDE.md)** - ⭐ Complete guide with links to all services
- **[User Guide](docs/guides/USER-GUIDE.md)** - Complete user guide with all features and access information
- **[Quick Reference](docs/reference/QUICK-REFERENCE.md)** - Quick reference card for daily operations
- **[Deployment Guide](docs/deployment/DEPLOYMENT.md)** - Complete deployment instructions
- **[Manual Deployment](docs/deployment/MANUAL-DEPLOYMENT.md)** - Deployment without Ansible
- **[Quick Start](docs/guides/INLOCK-AI-QUICK-START.md)** - Quick start guide

### Application Deployment

- **[Inlock AI Deployment](docs/deployment/INLOCK-AI-DEPLOYMENT.md)** - Complete guide for deploying Inlock AI application to inlock.ai
- **[Inlock AI Quick Start](docs/guides/INLOCK-AI-QUICK-START.md)** - Quick deployment guide for Inlock AI
- **[Inlock AI Deployment Verification](docs/deployment/INLOCK-DEPLOYMENT-VERIFICATION.md)** - Automated verification checklist & script output
- **[Workflow Best Practices](docs/guides/WORKFLOW-BEST-PRACTICES.md)** - ⭐ Two-layer architecture and workflow guide
- **[Inlock Content Management](docs/guides/INLOCK-CONTENT-MANAGEMENT.md)** - Managing application content and branding

### Monitoring & Observability

- **[Monitoring Guide](docs/services/monitoring/MONITORING-OVERVIEW.md)** - Prometheus, Grafana, Loki setup and usage
- **[Monitoring Setup Status](docs/services/monitoring/MONITORING-SETUP-STATUS.md)** - Current monitoring stack status
- **[Observability Backups](docs/services/monitoring/OBSERVABILITY-BACKUPS.md)** - Backup strategies for monitoring data

### Automation & Scripts

- **[Automation Scripts](docs/guides/AUTOMATION-SCRIPTS.md)** - Regression, deploy, monitoring, and cron automation
- **[Orphan Container Cleanup](docs/guides/ORPHAN-CONTAINER-CLEANUP.md)** - Managing orphaned Docker containers
- **[Directory Cleanup](docs/guides/DIRECTORY-CLEANUP.md)** - Directory organization and cleanup procedures
- **[Home Directory Cleanup](docs/guides/HOME-DIRECTORY-CLEANUP.md)** - Home directory organization and cleanup summary

### Authentication & Authorization

- **[Auth0 Stack Consistency](docs/guides/auth0-verification-checklist.md)** - ⭐ Complete Auth0 integration guide
- **[Auth0 + NextAuth.js Setup](docs/guides/AUTH0-NEXTAUTH-SETUP.md)** - Auth0 and NextAuth.js configuration
- **[Auth0 Testing Guide](docs/guides/AUTH0-TESTING-GUIDE.md)** - Manual testing procedures
- **[Auth0 Quick Reference](docs/reference/AUTH0-QUICK-REFERENCE.md)** - Quick reference for Auth0 URLs

### Security Documentation

- **[Ingress Hardening](docs/guides/SECURITY-HARDENING-GUIDE.md)** - Traefik security middleware configuration
- **[Firewall Management](docs/guides/RESTORE-FIREWALL-INSTRUCTIONS.md)** - Firewall management guide
- **[Network Security](docs/architecture/NETWORK-LAYOUT.md)** - Network security configuration
- **[SSL Certificate Setup](docs/guides/ssl-certificate-setup.md)** - TLS/SSL certificate configuration
- **[Secret Management](docs/guides/SECRET-MANAGEMENT.md)** - Managing secrets and credentials
- **[Container Hardening](docs/guides/COMPLETE-PORT-RESTRICTION-GUIDE.md)** - Container security best practices
- **[Access Control Validation](docs/architecture/SERVER-STRUCTURE-ANALYSIS.md)** - Validating security controls

### Infrastructure Documentation

- **[Infrastructure Overview](docs/architecture/INFRA-NOTES.md)** - Infrastructure components overview
- **[DevOps Guide](docs/guides/devops.md)** - DevOps practices and procedures
- **[Cloudflare Setup](docs/guides/CLOUDFLARE-ACME-SETUP.md)** - Cloudflare DNS and ACME configuration
- **[Cloudflare IP Allowlist](docs/guides/CLOUDFLARE-IP-ALLOWLIST-FIX.md)** - Cloudflare IP restrictions
- **[Node.js Docker-Only Setup](docs/guides/NODE-JS-DOCKER-ONLY.md)** - Using Docker exclusively for Node.js (recommended)

### Git & Publishing

- **[Git Publish Guide](docs/guides/PUBLISH-TO-GIT.md)** - Publishing code to GitHub repositories

## Structure

```
inlock-infra/
├── compose/              # Docker Compose files
│   ├── stack.yml        # Main stack (Traefik, Portainer, etc.)
│   ├── postgres.yml     # PostgreSQL database
│   ├── inlock-db.yml    # Inlock AI database
│   ├── inlock-ai.yml    # Inlock AI application service
│   ├── logging.yml      # Loki & Promtail logging stack
│   ├── n8n.yml         # n8n workflow automation
│   ├── prometheus.yml  # Prometheus monitoring
│   ├── prometheus/     # Prometheus configuration
│   │   ├── prometheus.yml
│   │   └── rules/      # Alert rules
│   ├── alertmanager/   # Alertmanager configuration
│   │   └── alertmanager.yml
│   ├── monitoring/     # Monitoring exporters
│   │   └── blackbox.yml
│   ├── logging/        # Logging configuration
│   │   ├── loki-config.yaml
│   │   └── promtail-config.yaml
│   └── grafana/        # Grafana configuration
│       ├── provisioning/
│       │   ├── datasources/
│       │   ├── dashboards/
│       │   └── alerting/
│       └── dashboards/
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
│   ├── deploy-inlock.sh           # Full deployment automation
│   ├── verify-inlock-deployment.sh # Deployment verification
│   ├── cleanup-orphan-containers.sh # Container cleanup
│   ├── nightly-regression.sh      # Automated regression testing
│   └── ...             # Other management scripts
├── docs/               # Documentation
├── secrets/            # Secret files (not in Git)
└── .env                # Environment variables (not in Git)
```

## Services

### Production Application

| Service | URL | Access |
|---------|-----|--------|
| **Inlock AI** | https://inlock.ai | Public |
| **Inlock AI (WWW)** | https://www.inlock.ai | Public |
| **Prometheus** | http://localhost:9090 (internal) | Internal only |
| **Alertmanager** | http://localhost:9093 (internal) | Internal only |

### Admin Services (Auth0 Protected)

| Service | URL | Access |
|---------|-----|--------|
| Traefik Dashboard | https://traefik.inlock.ai/dashboard/ | Auth0 + IP allowlist |
| Traefik API | https://traefik.inlock.ai/api/overview | Auth0 + IP allowlist |
| Portainer | https://portainer.inlock.ai | Auth0 + IP allowlist |
| Grafana | https://grafana.inlock.ai | Auth0 + IP allowlist |
| Prometheus | http://localhost:9090 (internal) | Internal only |
| Loki | http://localhost:3100 (internal) | Internal only |
| n8n | https://n8n.inlock.ai | Auth0 + IP allowlist |
| Coolify | https://deploy.inlock.ai | Auth0 + IP allowlist |
| Homarr | https://dashboard.inlock.ai | Auth0 + IP allowlist |

**Note:** All admin services use Auth0 authentication via OAuth2-Proxy. See [Auth0 Stack Consistency](docs/AUTH0-STACK-CONSISTENCY.md) for details.

## Security

- ✅ **Auth0 Authentication** - Single sign-on for all admin services (Google/Apple/Passkeys)
- ✅ IP Allowlisting (Tailscale VPN required for admin services)
- ✅ Forward Auth (OAuth2-Proxy for admin, NextAuth.js for frontend)
- ✅ Rate Limiting (50 req/min, 100 burst)
- ✅ Secure Headers (HSTS, CSP, etc.)
- ✅ TLS/SSL Encryption (Let's Encrypt + PositiveSSL)
- ✅ Firewall (UFW with deny-by-default)
- ✅ Network Segmentation (Docker networks)
- ✅ Role-Based Access Control (via Auth0 roles)

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
   - Admin subdomains (portainer/deploy/grafana/dashboard/cockpit/n8n/auth/traefik) use Let’s Encrypt via Cloudflare DNS.
   - `mail.inlock.ai` uses Let’s Encrypt (tls challenge).
   - `inlock.ai`/`www.inlock.ai` remain on PositiveSSL (fallback cert still present).
   - Optional expiry check: `echo | openssl s_client -connect portainer.inlock.ai:443 -servername portainer.inlock.ai 2>/dev/null | openssl x509 -noout -enddate`

## Deployment

### Using Ansible (Recommended)

```bash
ansible-playbook playbooks/deploy.yml
```

### Manual Deployment

```bash
./scripts/deploy-manual.sh
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions. For one-button application deploys, use:

```bash
cd /home/comzis/inlock-infra
./scripts/deploy-inlock.sh
```

This script runs the pre-deploy regression suite (`/opt/inlock-ai-secure-mvp/scripts/pre-deploy.sh`), builds the Docker image, rolls out the new container, and automatically executes the verification script.

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
# View status (all services)
docker compose -f compose/stack.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml --env-file .env logs -f [service-name]

# Restart a specific service
docker compose -f compose/stack.yml --env-file .env restart [service-name]

# Restart all services
docker compose -f compose/stack.yml --env-file .env restart

# View logs for Inlock AI specifically
docker compose -f compose/stack.yml --env-file .env logs -f inlock-ai
```

### Backups

```bash
# Backup volumes
./scripts/backup-volumes.sh

# Restore volumes
./scripts/restore-volumes.sh
```

### Automation / Regression

**Application-Level Scripts** (in `/opt/inlock-ai-secure-mvp/`):
- **Regression suite**: `scripts/regression-check.sh` - Runs lint, tests, and build (uses Docker by default)
- **Pre-deploy checks**: `scripts/pre-deploy.sh` - Validates readiness before deployment

**Infrastructure-Level Scripts** (in `/home/comzis/inlock-infra/scripts/`):
- **Full deploy**: `scripts/deploy-inlock.sh` - Complete deployment pipeline (pre-check → build → deploy → verify)
- **Nightly regression wrapper**: `scripts/nightly-regression.sh` - Cron-safe regression testing
- **Deployment verification**: `scripts/verify-inlock-deployment.sh` - Post-deployment health checks
- **Orphan container cleanup**: `scripts/cleanup-orphan-containers.sh` - Removes unused containers

**Scheduling Nightly Regression:**
```bash
# Add to crontab
crontab -e
# Add: 0 3 * * * /home/comzis/inlock-infra/scripts/nightly-regression.sh
```

See [Automation Scripts](docs/AUTOMATION-SCRIPTS.md) for detailed usage.

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

## Monitoring & Observability

### Monitoring Stack

- **Prometheus**: Metrics collection and alerting
  - Configuration: `compose/prometheus/prometheus.yml`
  - Alert rules: `compose/prometheus/rules/inlock-ai.yml`
  - Scrapes: Traefik, cAdvisor, Docker, custom metrics

- **Prometheus**: Scrapes application, Traefik, host, and synthetic metrics (config: `compose/prometheus/`)
- **Alertmanager**: Handles alert fan-out (config: `compose/alertmanager/alertmanager.yml`)
- **Node Exporter**: Host CPU/memory/disk/network metrics
- **Blackbox Exporter**: Synthetic HTTP + TCP probes for public routes and internal services
- **Grafana**: Visualization and dashboards
  - Auto-provisioned datasources: Prometheus, Loki
  - Dashboards:
    - `grafana/dashboards/observability/inlock-observability.json` – host fundamentals + synthetic probes
    - `grafana/dashboards/devops/devops-platform.json` – Traefik, Portainer, Grafana, n8n, Coolify, Homarr status and capacity
    - `grafana/dashboards/devops/inlock-web.json` – inlock.ai HTTPS probe, visits/req per second, response time, 4xx/5xx error rates
    - `grafana/dashboards/postgres/postgres-overview.json` – PostgreSQL connections, database size, cache hit ratio, BGWriter metrics
  - Access: https://grafana.inlock.ai (IP restricted)
- **Loki & Promtail**: Centralized log aggregation
  - Configuration: `compose/logging/loki-config.yaml`, `compose/logging/promtail-config.yaml`
  - Collects Docker container logs
  - Access via Grafana Loki datasource

### Alert Coverage

Configured alerts in Prometheus:
- `InlockAIDown` - Service downtime detection
- `InlockAIHighMemory` - Memory usage > 850MB
- `InlockAIHighCPU` - CPU usage > 80%
- `InlockAIHealthCheckFailed` - Health endpoint failures
- `InlockAIHigh5xxRate` - HTTP 5xx error rate > 5%
- `NodeHighCPUUsage` - Host CPU > 85%
- `NodeMemoryPressure` - Host memory > 85%
- `NodeDiskSpaceLow` - Root filesystem < 15% free
- `NodeLoadHigh` - Sustained load average per core > 1.5
- `ExternalHTTPProbeFailed` - Public routes failing HTTP probe
- `ServiceTCPProbeFailed` - Internal service port unreachable
- `TraefikContainerDown` - Traefik container not reporting metrics
- `AdminServiceContainerDown` - Grafana/Portainer/n8n/Coolify/Homarr container missing
- `AdminHttpProbeFailed` - Grafana/n8n/Coolify/Homarr HTTPS probe failing
- `TraefikHighErrorRate` - 5xx responses > 2% across entrypoints
- `PostgreSQL` metrics exposed via `postgres-exporter` for dashboards (connections, cache hit, BGWriter)

### Documentation

- **[Monitoring Guide](docs/monitoring.md)** - Setup and usage
- **[Monitoring Setup Status](docs/MONITORING-SETUP-STATUS.md)** - Current status
- **[Observability Backups](docs/OBSERVABILITY-BACKUPS.md)** - Backup strategies
- **Alert Automation** – Alertmanager forwards warning/critical alerts to `http://n8n:5678/webhook/alertmanager` for workflow notifications (customize in `compose/alertmanager/alertmanager.yml`)

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

## Repository

- **GitHub**: [https://github.com/comzis/inlock-ai-mvp](https://github.com/comzis/inlock-ai-mvp)
- **Clone**: `git clone git@github.com:comzis/inlock-ai-mvp.git`
- **Branch**: `main`

See [Git Publish Guide](docs/GIT-PUBLISH-GUIDE.md) for publishing workflows.

---

**Last Updated**: December 30, 2025  
**Version**: GitOps-ready hardened stack  
**Maintainer**: INLOCK.AI Infrastructure Team
