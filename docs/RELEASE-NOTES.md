# Release Notes

## 2025-12-30
- Archived legacy docs/reports/scripts to `archive/docs/` and `archive/scripts/` (active configs untouched).
- Hardened admin access: allowlists added to all admin routers; OAuth2-Proxy now enforces verified email and domain restriction.
- Security automation: added `scripts/security/audit-secrets-age.sh` and `generate-secrets-checksums.sh`; cron entries for monthly audits/checksums.
- Image pinning: Prometheus, n8n, Coolify (and soketi), Homarr, cockpit-proxy, PostHog stack pinned to local digests; Prometheus pin aligned in stack and monitoring config.
- Docs updated: secret management, archive references, and pinning guidance refreshed.

