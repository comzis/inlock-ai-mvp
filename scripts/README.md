# Scripts Directory

This directory contains all automation and management scripts, organized by functional category.

## Directory Structure

### `deployment/`
Scripts for deploying and releasing services:
- `deploy_production.sh` - Main production deployment script
- `deploy-inlock.sh` - Inlock AI application deployment
- `deploy-manual.sh` - Manual deployment without automation
- `finalize-deployment.sh` - Post-deployment finalization

### `testing/`
Test and verification scripts:
- `test-all.sh` - Run all tests
- `test-stack.sh` - Test entire stack health
- `verify-inlock-deployment.sh` - Verify deployment success
- `health_check_remote.sh` - Remote health checks

### `backup/`
Backup and restore operations:
- `backup-databases.sh` - Database backup
- `backup-volumes.sh` - Docker volume backup
- `restore-volumes.sh` - Restore from backup

### `security/`
Security hardening and auditing:
- `harden-security.sh` - Apply security hardening
- `security-review.sh` - Security audit
- `audit-secrets.sh` - Secrets audit

### `auth/`
Authentication and authorization management:
- `auth0-api-helper.sh` - Auth0 API utilities
- `setup-auth0-management-api.sh` - Configure Auth0
- `verify-auth-consistency.sh` - Validate auth configuration

### `infrastructure/`
Infrastructure setup and configuration:
- `configure-firewall.sh` - Firewall configuration
- `manage-firewall.sh` - Firewall management
- `setup-tls.sh` - TLS/SSL setup

### `maintenance/`
Maintenance and cleanup tasks:
- `cleanup-docker.sh` - Docker cleanup
- `self_heal.sh` - Self-healing automation
- `nightly-regression.sh` - Nightly regression tests

### `troubleshooting/`
Debugging and fixing issues:
- `fix-*.sh` - Service-specific fixes
- `debug-*.sh` - Debugging utilities
- `reset-*.sh` - Reset operations

### `utilities/`
General utility scripts:
- `show-credentials.sh` - Display credentials
- `lint-shell.sh` - Shell script linting
- `generate_n8n_sql.py` - N8N SQL generation

## Usage

Scripts should be run from the project root directory:

```bash
cd /home/comzis/.gemini/antigravity/scratch/inlock-ai
./scripts/deployment/deploy_production.sh
```

## Permissions

Ensure scripts have execute permissions:

```bash
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;
```
