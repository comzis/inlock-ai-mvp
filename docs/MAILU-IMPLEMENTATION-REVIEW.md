# Mailu Email Stack - Implementation Review

**Date:** December 11, 2025  
**Status:** Pre-Implementation Review  
**Priority:** High (TODO Item #4)

---

## 📋 Executive Summary

This document reviews the implementation plan for Mailu email stack deployment, ensuring alignment with existing infrastructure patterns and security requirements before implementation.

### Current Infrastructure Analysis

#### Network Architecture
- **`edge`**: External-facing network (Traefik ingress)
- **`mgmt`**: Management network (internal services, monitoring)
- **`internal`**: Database and backend services
- **`socket-proxy`**: Docker socket proxy network

#### Security Patterns
1. **Container Hardening:**
   - `no-new-privileges: true`
   - `read_only: true` where possible
   - `tmpfs` for temporary files
   - `cap_drop: ALL` with minimal `cap_add`
   - Non-root users (`user: "1000:1000"`)

2. **Secrets Management:**
   - Docker secrets via file-based secrets
   - Secrets stored in `/home/comzis/apps/secrets-real/`
   - Secrets referenced in compose files via `secrets:` section

3. **Traefik Integration:**
   - File-based router configuration (`traefik/dynamic/routers.yml`)
   - File-based service configuration (`traefik/dynamic/services.yml`)
   - OAuth2-Proxy forward-auth for admin services
   - IP allowlists via `allowed-admins` middleware
   - Security headers via `secure-headers` middleware

4. **Backup Patterns:**
   - Volume backups via `scripts/backup-volumes.sh`
   - GPG encryption for backups
   - Volume naming: `{service}_data`

---

## 🎯 Mailu Requirements

### Core Services
1. **Frontend (mailu/front)**: Webmail and admin UI
2. **Postfix (mailu/postfix)**: SMTP server
3. **Dovecot (mailu/imap)**: IMAP server
4. **Rspamd (mailu/rspamd)**: Spam filtering
5. **Admin (mailu/admin)**: Admin API
6. **Webmail (mailu/webmail)**: Webmail interface (optional, frontend can serve this)

### Network Requirements
- **Public-facing**: SMTP (25, 465, 587), IMAP (143, 993)
- **Internal**: Admin API, Rspamd, Redis, Postgres
- **Traefik**: Admin UI and Webmail via HTTPS

### Volume Requirements
- Mail data: `/mail` (persistent)
- DKIM keys: `/dkim` (persistent, sensitive)
- Rspamd data: `/rspamd` (persistent)
- Redis data: `/redis` (persistent, optional)
- Postgres data: `/postgres` (if using Mailu's DB, or reuse existing)

### Security Requirements
1. **Mail protocols (SMTP/IMAP)**: 
   - Exposed via Traefik TCP routing (ports 25, 465, 587, 143, 993)
   - Firewall allowlists for trusted IPs only
   - NOT exposed via HTTP/HTTPS (different protocol)

2. **Admin UI**:
   - OAuth2-Proxy forward-auth
   - IP allowlists
   - Security headers

3. **Secrets**:
   - DKIM private keys
   - Admin password
   - Database passwords
   - Secret key for sessions

---

## 🏗️ Implementation Plan

### Phase 1: Compose File Structure

**File:** `compose/mailu.yml`

**Key Design Decisions:**
1. **Image Pinning**: Use SHA256 digests for all Mailu images (security best practice)
2. **Network Isolation**: 
   - `mail` network: Internal Mailu services
   - `internal` network: Database access (if using shared Postgres)
   - `mgmt` network: Admin UI via Traefik
   - **NO `edge` network** - Mail protocols handled via Traefik TCP routing

3. **Secrets**:
   - `mailu-secret-key`: Session encryption
   - `mailu-admin-password`: Admin UI password
   - `mailu-dkim-key`: DKIM private key (if not auto-generated)
   - `mailu-db-password`: Database password (if using separate DB)

4. **Volumes**:
   - `mailu_mail_data`: `/mail`
   - `mailu_dkim_data`: `/dkim`
   - `mailu_rspamd_data`: `/rspamd`
   - `mailu_redis_data`: `/redis` (optional)

5. **Hardening**:
   - Apply `x-hardening` anchor (no-new-privileges)
   - Apply `x-default-logging` anchor
   - Read-only filesystems where possible
   - tmpfs for temporary files
   - Capability dropping

### Phase 2: Traefik Configuration

**TCP Routing for Mail Protocols:**
- Traefik TCP router for SMTP (port 25, 465, 587)
- Traefik TCP router for IMAP (port 143, 993)
- TLS passthrough for STARTTLS/TLS connections

**HTTP Routing for Admin UI:**
- Router: `mailu-admin` → `mail.inlock.ai/admin`
- Middlewares: `secure-headers`, `admin-forward-auth`, `allowed-admins`, `mgmt-ratelimit`
- Service: `mailu-front:80`

**HTTP Routing for Webmail:**
- Router: `mailu-webmail` → `mail.inlock.ai`
- Middlewares: `secure-headers`, `admin-forward-auth` (optional, or public with rate limiting)
- Service: `mailu-front:80`

### Phase 3: DNS Configuration

**Required DNS Records:**
- MX: `inlock.ai` → `mail.inlock.ai` (priority 10)
- A/AAAA: `mail.inlock.ai` → Server IP
- TXT: SPF record (`v=spf1 mx a:mail.inlock.ai ~all`)
- TXT: DKIM record (generated after Mailu setup)
- TXT: DMARC record (`v=DMARC1; p=quarantine; rua=mailto:admin@inlock.ai`)

**Automation:**
- Cloudflare API script to create/update DNS records
- DKIM key extraction and DNS record creation

### Phase 4: Backup Integration

**Update `scripts/backup-volumes.sh`:**
- Add `mailu_mail_data` volume
- Add `mailu_dkim_data` volume (critical - contains private keys)
- Add `mailu_rspamd_data` volume
- Add `mailu_redis_data` volume (if used)

### Phase 5: Monitoring Integration

**Prometheus Exporters:**
- Postfix exporter (if available)
- Rspamd metrics (built-in)
- Blackbox exporter checks for SMTP/IMAP ports

**Grafana Dashboard:**
- Mail queue size
- Spam detection rates
- Delivery success rates
- Storage usage

---

## ⚠️ Risk Assessment

### High Risk
1. **Port Conflicts**: 
   - **Risk**: Mailu requires ports 25, 465, 587, 143, 993
   - **Mitigation**: Verify no existing services use these ports
   - **Check**: `sudo netstat -tulpn | grep -E ':(25|465|587|143|993)'`

2. **DNS Propagation**:
   - **Risk**: MX records must be correct before mail delivery works
   - **Mitigation**: Test DNS records before enabling mail sending
   - **Check**: `dig MX inlock.ai`, `dig TXT inlock.ai`

3. **DKIM Key Management**:
   - **Risk**: DKIM keys must be backed up and secured
   - **Mitigation**: Include in backup script, encrypt with GPG
   - **Check**: Verify DKIM keys in backup

### Medium Risk
1. **Database Choice**:
   - **Risk**: Using Mailu's internal Postgres vs shared Postgres
   - **Mitigation**: Start with separate Postgres, can migrate later
   - **Decision**: Use separate Postgres for isolation

2. **Storage Growth**:
   - **Risk**: Mail data can grow quickly
   - **Mitigation**: Set retention policies, monitor disk usage
   - **Check**: Add disk usage alerts

3. **Spam Reputation**:
   - **Risk**: New mail server may be flagged as spam
   - **Mitigation**: Proper SPF/DKIM/DMARC, warm-up period
   - **Check**: Monitor delivery rates

### Low Risk
1. **Traefik TCP Routing Complexity**:
   - **Risk**: TCP routing is more complex than HTTP
   - **Mitigation**: Test thoroughly, use Traefik documentation
   - **Check**: Test SMTP/IMAP connections

2. **OAuth2-Proxy for Webmail**:
   - **Risk**: Users may need to authenticate twice
   - **Mitigation**: Consider making webmail public with rate limiting
   - **Decision**: Make webmail public, admin UI requires auth

---

## 🧪 Testing Strategy

### Pre-Deployment
1. **Port Availability Check**:
   ```bash
   sudo netstat -tulpn | grep -E ':(25|465|587|143|993)'
   ```

2. **DNS Pre-Check**:
   ```bash
   dig MX inlock.ai
   dig A mail.inlock.ai
   dig TXT inlock.ai | grep -E '(SPF|DKIM|DMARC)'
   ```

3. **Compose Validation**:
   ```bash
   docker compose -f compose/mailu.yml --env-file .env config
   ```

### Post-Deployment
1. **Service Health**:
   ```bash
   docker compose -f compose/mailu.yml --env-file .env ps
   docker logs compose-mailu-front-1 --tail 50
   ```

2. **SMTP Test**:
   ```bash
   telnet mail.inlock.ai 25
   # Or use swaks: swaks --to test@inlock.ai --from admin@inlock.ai --server mail.inlock.ai
   ```

3. **IMAP Test**:
   ```bash
   telnet mail.inlock.ai 143
   # Or use openssl: openssl s_client -connect mail.inlock.ai:993
   ```

4. **Admin UI Test**:
   ```bash
   curl -I https://mail.inlock.ai/admin
   # Should redirect to Auth0
   ```

5. **Webmail Test**:
   ```bash
   curl -I https://mail.inlock.ai
   # Should return 200 (or redirect to login)
   ```

### Integration Tests
1. **n8n Integration**:
   - Create workflow to send test email via Mailu SMTP
   - Verify email delivery
   - Test mailbox creation via Mailu Admin API

2. **Backup Test**:
   - Run backup script
   - Verify Mailu volumes are included
   - Test restore (dry-run)

3. **Monitoring Test**:
   - Verify Prometheus scrapes Mailu metrics
   - Check Grafana dashboard loads
   - Test alerting rules

---

## 📝 Implementation Checklist

### Compose File
- [ ] Create `compose/mailu.yml` with all services
- [ ] Pin all images to SHA256 digests
- [ ] Configure networks (mail, internal, mgmt)
- [ ] Set up secrets (secret-key, admin-password, dkim-key, db-password)
- [ ] Configure volumes (mail, dkim, rspamd, redis)
- [ ] Apply hardening (no-new-privileges, read-only, tmpfs, cap_drop)
- [ ] Add healthchecks for all services
- [ ] Configure environment variables

### Traefik Configuration
- [ ] Add TCP routers for SMTP (25, 465, 587)
- [ ] Add TCP routers for IMAP (143, 993)
- [ ] Add HTTP router for admin UI (`mail.inlock.ai/admin`)
- [ ] Add HTTP router for webmail (`mail.inlock.ai`)
- [ ] Add service definitions in `services.yml`
- [ ] Configure TLS for HTTP routes
- [ ] Test TCP routing

### DNS Configuration
- [ ] Create MX record for `inlock.ai`
- [ ] Create A/AAAA records for `mail.inlock.ai`
- [ ] Create SPF TXT record
- [ ] Generate DKIM key and create TXT record
- [ ] Create DMARC TXT record
- [ ] Verify DNS propagation

### Secrets Management
- [ ] Create `mailu-secret-key` secret file
- [ ] Create `mailu-admin-password` secret file
- [ ] Create `mailu-dkim-key` secret file (if manual)
- [ ] Create `mailu-db-password` secret file (if separate DB)
- [ ] Set proper file permissions (600)

### Backup Integration
- [ ] Update `scripts/backup-volumes.sh` to include Mailu volumes
- [ ] Test backup includes all Mailu volumes
- [ ] Verify DKIM keys are backed up

### Monitoring Integration
- [ ] Add Prometheus scrape configs for Mailu services
- [ ] Create Grafana dashboard for Mailu
- [ ] Add blackbox exporter checks for SMTP/IMAP
- [ ] Configure alerting rules

### Documentation
- [ ] Update `docs/runbooks/devops-runbook.md` with Mailu procedures
- [ ] Create `docs/MAILU-SETUP.md` with setup instructions
- [ ] Update `TODO.md` to mark Mailu items as complete

---

## 🔄 Rollback Plan

If issues occur during deployment:

1. **Stop Mailu services**:
   ```bash
   docker compose -f compose/mailu.yml --env-file .env down
   ```

2. **Remove DNS records** (if needed):
   - Remove MX record
   - Remove mail subdomain A/AAAA records
   - Keep SPF/DKIM/DMARC for future use

3. **Restore volumes** (if corrupted):
   ```bash
   scripts/restore-volumes.sh mailu_mail_data mailu_dkim_data
   ```

4. **Revert Traefik config**:
   - Remove Mailu routers from `routers.yml`
   - Remove Mailu services from `services.yml`
   - Reload Traefik

---

## 📚 References

- [Mailu Documentation](https://mailu.io/master/)
- [Traefik TCP Routing](https://doc.traefik.io/traefik/routing/routers/#tcp-routers)
- [SPF/DKIM/DMARC Setup](https://www.dmarcanalyzer.com/spf-dkim-dmarc-setup/)
- Existing infrastructure patterns in `compose/stack.yml`, `compose/postgres.yml`, `compose/n8n.yml`

---

## ✅ Approval

**Review Status:** ✅ Ready for Implementation  
**Reviewer:** DevOps Expert  
**Date:** December 11, 2025

**Next Steps:**
1. Review this document
2. Approve implementation plan
3. Begin Phase 1: Compose file creation

---

**Last Updated:** December 11, 2025
