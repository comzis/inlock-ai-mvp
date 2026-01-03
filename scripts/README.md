# Scripts Directory

This directory contains all automation and management scripts, organized by functional category.
Archived and legacy scripts now live under `../archive/scripts/` (read-only reference).

**Total Scripts:** 158 scripts across 10 categories  
**Project Root:** `/home/comzis/inlock`  
**Last Updated:** January 3, 2026

## Directory Structure

### `auth/` (13 scripts)
Authentication and authorization management:
- `auth0-api-helper.sh` - Auth0 API utilities
- `configure-auth0-api.sh` - Configure Auth0 API
- `configure-auth0-optimal.sh` - Optimal Auth0 setup
- `setup-auth0-management-api.sh` - Configure Auth0 Management API
- `test-auth0-api.sh` - Test Auth0 API
- `monitor-auth0-status.sh` - Monitor Auth0 status
- `verify-auth-consistency.sh` - Validate auth configuration

### `backup/` (8 scripts)
Backup and restore operations:
- `automated-backup-system.sh` - Main backup coordinator (runs daily at 03:00)
- `backup-databases.sh` - Database backup (PostgreSQL)
- `backup-volumes.sh` - Docker volume backup (encrypted)
- `restore-volumes.sh` - Restore from backup
- `install-backup-cron.sh` - Install daily cron job
- `monitor-backup-success-rate.sh` - Weekly backup success monitoring
- `disaster-recovery-test.sh` - DR testing
- `backup-with-checks.sh` - Legacy backup wrapper (deprecated)

### `deployment/` (12 scripts)
Scripts for deploying and releasing services:
- `deploy_production.sh` - Main production deployment script
- `deploy-hardened-stack.sh` - Hardened stack deployment
- `deploy-inlock.sh` - Inlock AI application deployment
- `deploy-manual.sh` - Manual deployment without automation
- `finalize-deployment.sh` - Post-deployment finalization
- `update-all-services.sh` - Update all services
- `fresh-start-and-update-all.sh` - Fresh start and update
- `PUSH-TO-GIT.sh` - Git push automation

### `security/` (31 scripts)
Security hardening and auditing:
- `harden-security.sh` - Apply security hardening
- `security-review.sh` - Comprehensive security review
- `achieve-10-10-security.sh` - Achieve 10/10 security score
- `audit-root-access.sh` - Root access audit
- `audit-secrets.sh` - Secrets audit
- `scan-containers.sh` - Container image scanning
- `scan-images.sh` - Image vulnerability scanning
- `fix-ssh-firewall-access.sh` - Fix SSH firewall access
- `enable-ufw-complete.sh` - Complete UFW setup
- `verify-ssh-restrictions.sh` - Verify SSH restrictions
- `pre-commit-check.sh` - Lightweight pre-commit checks for staged changes

### `infrastructure/` (19 scripts)
Infrastructure setup and configuration:
- `configure-firewall.sh` - Firewall configuration
- `manage-firewall.sh` - Firewall management
- `restore-firewall-safe.sh` - Safe firewall restore
- `setup-tls.sh` - TLS/SSL setup
- `update-allowlists.sh` - Update IP allowlists
- `setup-backup-cron.sh` - **DEPRECATED** (use backup/install-backup-cron.sh)

### `utilities/` (30 scripts)
General utility scripts:
- `check-cursor-compliance.sh` - Cursor rules compliance checker
- `cleanup-project.sh` - Project cleanup
- `lint-shell.sh` - Shell script linting (shellcheck)
- `show-credentials.sh` - Display credentials
- `docker-status.sh` - Docker status check
- `docker-logs.sh` - Docker logs viewer
- `check-backup-readiness.sh` - Backup readiness check

### `ha/` (6 scripts)
High Availability setup and failover:
- `setup-postgres-replication.sh` - PostgreSQL replication setup
- `setup-postgres-standby.sh` - PostgreSQL standby setup
- `monitor-postgres-replication.sh` - Replication monitoring
- `failover-procedures.sh` - Failover procedures
- `check-service-health.sh` - Service health checks

### `maintenance/` (8 scripts)
Maintenance and cleanup tasks:
- `cleanup-docker.sh` - Docker cleanup
- `self_heal_improved.sh` - Improved self-healing automation
- `self_heal.sh` - Self-healing automation (legacy)
- `nightly-regression.sh` - Nightly regression tests
- `update-kernel-packages.sh` - Kernel package updates

### `testing/` (15 scripts)
Test and verification scripts (root level):
- `test-all.sh` - Run all tests
- `test-stack.sh` - Test entire stack health
- `test-endpoints.sh` - Endpoint testing
- `verify-inlock-deployment.sh` - Verify deployment success
- `verify-cloudflare-proxy.sh` - Cloudflare verification
- `verify-sso-config.sh` - SSO verification
- `health_check_remote.sh` - Remote health checks

### `entrypoints/` (2 scripts)
Container entrypoint scripts:
- `grafana-entrypoint/entrypoint.sh` - Grafana container entrypoint
- `postgres-entrypoint/entrypoint.sh` - PostgreSQL container entrypoint

### `archive/scripts/`
Legacy and troubleshooting scripts (moved out of active tree). Use for reference only.

## Usage

Scripts should be run from the project root directory:

```bash
cd /home/comzis/inlock
./scripts/deployment/deploy_production.sh
```

## Permissions

All scripts should have execute permissions. To fix permissions:

```bash
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;
```

## Script Standards

All scripts follow these standards:
- Use `#!/usr/bin/env bash` shebang
- Use `set -euo pipefail` for error handling
- Include documentation headers (purpose, usage, dependencies, env vars)
- Exit codes: 0=success, 1=error

## Linting

Run shellcheck on all scripts:

```bash
./scripts/utilities/lint-shell.sh
```

Or on specific scripts:

```bash
./scripts/utilities/lint-shell.sh scripts/backup/*.sh
```

## Testing

Unit tests are planned for critical scripts. See `docs/backup/RECOMMENDATIONS-IMPLEMENTATION.md` for details.

## Related Documentation

- [Backup System](../docs/backup/README.md)
- [Security Scripts](../docs/security/README.md)
- [Deployment Guide](../docs/deployment/README.md)
