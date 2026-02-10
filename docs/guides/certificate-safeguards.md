# Certificate and SSL/TLS Safeguards for Codex

## 🚨 CRITICAL: Certificate Protection Protocol

### Overview
SSL/TLS certificate misconfiguration can cause complete platform failure. This document defines mandatory safeguards that MUST be followed for any task involving certificates, Traefik, subdomains, or network configuration.

---

## Pre-Task Mandatory Checks

### 1. Positive SSL Certificate Protection

**CRITICAL RULE:** `inlock.ai` and `www.inlock.ai` MUST ALWAYS use the Positive SSL certificate.

#### Configuration Details:
- **Certificate Files:**
  - Certificate: `/home/comzis/apps/secrets-real/positive-ssl.crt`
  - Private Key: `/home/comzis/apps/secrets-real/positive-ssl.key`
  - Mounted in Traefik: `/run/secrets/positive_ssl_cert` and `/run/secrets/positive_ssl_key`

- **Traefik Configuration:**
  - File: `traefik/dynamic/tls.yml`
  - Default store uses Positive SSL certificate
  - Router: `traefik/dynamic/routers.yml` → `inlock-ai` router
  - TLS config: `tls.options: default` (NOT `certResolver`)

- **Certificate Fingerprint (SHA256):**
  ```
  FB:FD:85:7E:20:F0:E3:9C:79:D4:0D:BC:7B:7F:5A:2C:5F:E9:1D:39:BF:08:41:C4:53:A4:06:D5:E4:D2:2B:E8
  ```

- **Certificate Details:**
  - Issuer: Sectigo Limited (Positive SSL)
  - Valid Until: December 7, 2026
  - Subject: CN = inlock.ai

#### Verification Commands:
```bash
# Verify certificate fingerprint matches
openssl s_client -connect inlock.ai:443 -servername inlock.ai 2>/dev/null | \
  openssl x509 -noout -fingerprint -sha256

# Verify certificate expiration
openssl s_client -connect inlock.ai:443 -servername inlock.ai 2>/dev/null | \
  openssl x509 -noout -dates
```

### 2. Cloudflare API Token Verification

**Required for:** Let's Encrypt DNS-01 challenge for subdomains

#### Configuration:
- **Environment Variables:**
  - Primary: `CLOUDFLARE_DNS_API_TOKEN`
  - Fallback: `CLOUDFLARE_API_TOKEN`
  - Location: `/home/comzis/inlock/.env`

- **Required Permissions:**
  - Zone: DNS:Edit
  - Zone: Zone:Read
  - Zone Resource: `inlock.ai` (Zone ID: `8d7c44f4c4a25263d10b87f394bc9076`)

#### Verification:
```bash
# Verify token is valid
TOKEN=$(grep "^CLOUDFLARE_API_TOKEN=" /home/comzis/inlock/.env | cut -d'=' -f2-)
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### 3. Traefik Router Configuration Rules

#### Domain-Specific TLS Configuration:

| Domain | TLS Configuration | Certificate Source |
|--------|------------------|-------------------|
| `inlock.ai` | `tls.options: default` | Positive SSL |
| `www.inlock.ai` | `tls.options: default` | Positive SSL |
| All other subdomains | `tls.certResolver: le-dns` | Let's Encrypt |

#### NEVER:
- ❌ Add `certResolver` to `inlock.ai` or `www.inlock.ai` routers
- ❌ Remove `options: default` from `inlock-ai` router
- ❌ Change `tls.yml` default store configuration
- ❌ Modify Positive SSL certificate files without backup

#### ALWAYS:
- ✅ Use `tls.options: default` for inlock.ai/www.inlock.ai
- ✅ Use `tls.certResolver: le-dns` for all other subdomains
- ✅ Verify certificate after any router changes
- ✅ Backup configuration before modifications

---

## Task-Specific Safeguards

### When Adding New Subdomains

1. **Determine Certificate Type:**
   - If domain is `inlock.ai` or `www.inlock.ai` → Positive SSL
   - All other subdomains → Let's Encrypt

2. **Add Router Configuration:**
   ```yaml
   # For subdomains (Let's Encrypt)
   new-subdomain:
     entryPoints:
       - websecure
     rule: Host(`newsubdomain.inlock.ai`)
     middlewares:
       - secure-headers
     service: service-name
     tls:
       certResolver: le-dns  # ✅ Correct for subdomains
   
   # For inlock.ai/www.inlock.ai (Positive SSL)
   inlock-ai:
     entryPoints:
       - websecure
     rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
     middlewares:
       - secure-headers
     service: inlock-ai
     tls:
       options: default  # ✅ Correct for main domain
   ```

3. **Post-Configuration Verification:**
   ```bash
   # Wait 1-2 minutes for certificate provisioning
   sleep 120
   
   # Test HTTPS connectivity
   curl -I https://newsubdomain.inlock.ai
   
   # Verify certificate
   openssl s_client -connect newsubdomain.inlock.ai:443 \
     -servername newsubdomain.inlock.ai 2>/dev/null | \
     openssl x509 -noout -subject -issuer -dates
   ```

### When Modifying Traefik Configuration

1. **Pre-Change Backup:**
   ```bash
   cd /home/comzis/projects/inlock-ai-mvp
   cp traefik/dynamic/routers.yml traefik/dynamic/routers.yml.backup.$(date +%Y%m%d-%H%M%S)
   cp traefik/dynamic/tls.yml traefik/dynamic/tls.yml.backup.$(date +%Y%m%d-%H%M%S)
   cp traefik/dynamic/services.yml traefik/dynamic/services.yml.backup.$(date +%Y%m%d-%H%M%S)
   ```

2. **Verify Positive SSL Configuration:**
   ```bash
   # Check tls.yml has Positive SSL in default store
   grep -A 5 "default:" traefik/dynamic/tls.yml | grep -q "positive_ssl" && \
     echo "✅ Positive SSL configured" || echo "❌ MISSING Positive SSL"
   
   # Check inlock-ai router uses options: default
   grep -A 10 "inlock-ai:" traefik/dynamic/routers.yml | grep -q "options: default" && \
     echo "✅ Positive SSL router config correct" || echo "❌ WRONG TLS CONFIG"
   ```

3. **Apply Changes:**
   ```bash
   # Restart Traefik
   docker compose -f compose/services/stack.yml restart traefik
   
   # Wait for restart
   sleep 10
   ```

4. **Post-Change Verification:**
   ```bash
   # Verify Positive SSL is still active
   INLOCK_FP=$(openssl s_client -connect inlock.ai:443 -servername inlock.ai 2>/dev/null | \
     openssl x509 -noout -fingerprint -sha256 | cut -d'=' -f2)
   EXPECTED_FP="FB:FD:85:7E:20:F0:E3:9C:79:D4:0D:BC:7B:7F:5A:2C:5F:E9:1D:39:BF:08:41:C4:53:A4:06:D5:E4:D2:2B:E8"
   
   if [ "$INLOCK_FP" = "$EXPECTED_FP" ]; then
     echo "✅ Positive SSL certificate verified"
   else
     echo "❌ CERTIFICATE MISMATCH - ROLLBACK REQUIRED"
     # Rollback
     cp traefik/dynamic/routers.yml.backup.* traefik/dynamic/routers.yml
     docker compose -f compose/services/stack.yml restart traefik
     exit 1
   fi
   ```

### When Modifying Docker Compose

1. **Check Environment Variables:**
   - Verify `CLOUDFLARE_DNS_API_TOKEN` or `CLOUDFLARE_API_TOKEN` is set
   - Verify `DOMAIN` is set to `inlock.ai`
   - Check Traefik service has correct secret mounts

2. **Verify Secret Mounts:**
   ```yaml
   secrets:
     - positive_ssl_cert
     - positive_ssl_key
   ```

3. **Test After Changes:**
   ```bash
   # Verify secrets are mounted
   docker compose -f compose/services/stack.yml exec traefik \
     ls -la /run/secrets/ | grep positive_ssl
   ```

---

## Error Detection and Response

### Critical Errors

If you encounter these errors, **STOP immediately** and verify certificates:

1. **SSL Handshake Failures:**
   - `error:0A000458:SSL routines::tlsv1 unrecognized name`
   - `SSL routines::ssl3_get_server_certificate:certificate verify failed`
   - `unable to get local issuer certificate`

2. **Certificate Mismatch:**
   - Certificate fingerprint doesn't match expected Positive SSL fingerprint
   - Certificate issuer is not "Sectigo Limited"
   - Certificate subject is not "CN = inlock.ai"

3. **Cloudflare API Errors:**
   - `9109: Invalid access token`
   - `403: Forbidden`
   - `failed to find zone inlock.ai`

### Emergency Rollback Procedure

```bash
# 1. Stop Traefik
docker compose -f compose/services/stack.yml stop traefik

# 2. Restore backups
cd /home/comzis/projects/inlock-ai-mvp
cp traefik/dynamic/routers.yml.backup.* traefik/dynamic/routers.yml
cp traefik/dynamic/tls.yml.backup.* traefik/dynamic/tls.yml

# 3. Restart Traefik
docker compose -f compose/services/stack.yml start traefik

# 4. Verify certificates
bash /home/comzis/.cursor/projects/home-comzis-inlock/scripts/check_subdomains.sh

# 5. Check Traefik logs
docker compose -f compose/services/stack.yml logs traefik --tail 50
```

---

## Protected Files and Directories

**NEVER modify without explicit verification and backup:**

1. **Certificate Files:**
   - `/home/comzis/apps/secrets-real/positive-ssl.crt`
   - `/home/comzis/apps/secrets-real/positive-ssl.key`

2. **Traefik Configuration:**
   - `traefik/dynamic/tls.yml` (especially default store)
   - `traefik/dynamic/routers.yml` (especially inlock-ai router)
   - `config/traefik/traefik.yml` (certificate resolvers)

3. **Docker Compose:**
   - `compose/services/stack.yml` (Traefik service, secrets)

---

## Monitoring and Maintenance

### Certificate Expiration Monitoring

- **Positive SSL:** Expires December 7, 2026
- **Check expiration:** Run monthly check script
- **Renewal:** Plan renewal 30 days before expiration

### Health Check Script

```bash
#!/bin/bash
# Certificate health check

EXPECTED_FP="FB:FD:85:7E:20:F0:E3:9C:79:D4:0D:BC:7B:7F:5A:2C:5F:E9:1D:39:BF:08:41:C4:53:A4:06:D5:E4:D2:2B:E8"

check_cert() {
  local domain=$1
  local fp=$(openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | \
    openssl x509 -noout -fingerprint -sha256 | cut -d'=' -f2)
  
  if [ "$fp" = "$EXPECTED_FP" ]; then
    echo "✅ ${domain}: Positive SSL verified"
    return 0
  else
    echo "❌ ${domain}: Certificate mismatch"
    return 1
  fi
}

check_cert inlock.ai
check_cert www.inlock.ai
```

---

## Summary Checklist

Before starting ANY certificate-related task:

- [ ] Verified Positive SSL certificate fingerprint
- [ ] Backed up Traefik configuration files
- [ ] Verified Cloudflare API token is valid
- [ ] Confirmed which domains need Positive SSL vs Let's Encrypt
- [ ] Checked certificate expiration dates
- [ ] Verified Traefik secrets are properly mounted
- [ ] Tested rollback procedure is available

After completing ANY certificate-related task:

- [ ] Verified Positive SSL is still active on inlock.ai/www.inlock.ai
- [ ] Tested all subdomains have valid certificates
- [ ] Checked Traefik logs for errors
- [ ] Verified HTTPS connectivity for all domains
- [ ] Confirmed no certificate warnings in browser

---

**Remember: Certificate misconfiguration = Platform downtime. Always verify before and after changes.**
