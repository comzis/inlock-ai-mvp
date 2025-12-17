# Inlock AI Infrastructure TODO

*Last Updated: 2024-12-14*

## 🔴 Critical (This Week)

### 1. Hardening (Ongoing)
- [ ] Container Hardening (Read-only FS, no-new-privileges) for remaining services
- [ ] Normalize IP Allowlists across all services



## ✅ Recently Completed (Dec 2024)

### CI/CD & Automation (100%)
- ✅ Implemented GitHub Actions pipeline (`deploy.yml`)
- ✅ Created robust deployment scripts (`deploy_production.sh`)
- ✅ Automated container version pinning and security scanning (Trivy)

### Security Hardening (100%)
- ✅ Secured file permissions (Secrets & deployed files)
- ✅ Implemented `socket-proxy` for Traefik (Docker Socket Hardening)
- ✅ Verified SSO integration (OAuth2-Proxy + Auth0)

### Stabilization (100%)
- ✅ Fixed N8N crash loop & restored workflows
- ✅ Restored Mailu stack availability
- ✅ Resolved Cron script issues (`self_heal.sh`)

### Project Organization (100%)
- ✅ Validated GitHub as source of truth
- ✅ Cleaned up remote server file clutter

See TODO_archive_2024-12-14.md for full history.
