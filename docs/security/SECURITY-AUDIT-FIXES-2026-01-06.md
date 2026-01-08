# Security Audit Fixes - 2026-01-06

## Overview

This document summarizes the security fixes applied in response to the security review findings.

## Issues Fixed

### 1. ✅ Token Leakage in Scripts (HIGH PRIORITY)

**Issue:** Auth0 scripts were printing full token responses to stdout, which could expose credentials in terminal logs, CI logs, shell scrollback, or support bundles.

**Files Fixed:**
- `scripts/auth/test-auth0-api.sh`
- `scripts/auth/auth0-api-helper.sh`
- `scripts/auth/configure-auth0-api.sh`
- `scripts/auth/test-auth0-api-examples.sh`

**Fix Applied:** Modified error handling to only show error codes and descriptions, not the full token response JSON. This prevents access tokens from being exposed in logs while still providing useful debugging information.

**Example Change:**
```bash
# Before:
echo "Response: $TOKEN_RESPONSE"

# After:
ERROR_CODE=$(echo "$TOKEN_RESPONSE" | jq -r '.error // "unknown"')
ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // "See Auth0 logs for details"')
echo "Error: $ERROR_CODE"
echo "Description: $ERROR_DESC"
```

### 2. ✅ Traefik Security Configuration Documentation

**Issue:** 
- `insecureSkipVerify: true` for Cockpit transport could enable MitM attacks
- Authorization header forwarding could leak credentials to upstream services if they log headers

**Files Updated:**
- `traefik/dynamic/services.yml`
- `traefik/dynamic/middlewares.yml`

**Fix Applied:** Added security comments documenting:
- The risk of `insecureSkipVerify` (lower risk since Cockpit runs on localhost)
- Mitigation recommendations (consider adding CA cert to trust store)
- The risk of Authorization header forwarding
- Reminder that headers may appear in upstream service logs

**Note:** These are configuration choices with documented risks. The insecureSkipVerify is necessary for Cockpit's self-signed certificate on localhost, and the Authorization header forwarding is required for OAuth2-Proxy functionality.

### 3. ✅ Docker Image Version Pinning

**Status:** Already compliant

**Verification:** All production compose files use pinned versions:
- Specific version tags (e.g., `traefik:v3.6.4`, `portainer/portainer-ce:2.33.5`)
- SHA256 digests (e.g., `n8nio/n8n@sha256:85214df20cd7bc020f8e4b0f60f87ea87f0a754ca7ba3d1ccdfc503ccd6e7f9c`)

The only `:latest` tag is in `docker-compose.local.yml` (local development), which is acceptable.

### 4. ✅ Environment Example Files

**Status:** Verified safe

**Verification:** `env.example` file contains only clear placeholder values:
- `CLOUDFLARE_API_TOKEN=replace-with-cf-dns-token`
- `AUTH0_ADMIN_CLIENT_SECRET=your-admin-client-secret`
- `OAUTH2_COOKIE_SECRET=$(openssl rand -base64 32 | head -c 32)` (command to generate)
- `VAULT_ROOT_TOKEN=dev-only-token-change-in-production`

All values are clearly placeholders, not real secrets.

## Remaining Recommendations

### 1. Credential Rotation (If Needed)

**Action Required:** If any secrets in `env.example` or documentation files were ever real credentials:
1. Rotate all affected credentials immediately
2. Audit git history for exact values
3. Check GitHub secret scanning alerts (if enabled)

**Note:** Based on review, all values appear to be placeholders, but verification is recommended.

### 2. ✅ Dependency Lockfiles

**Status:** Fixed

**Issue:** Missing lockfile for Node.js e2e project (`e2e/package.json`)

**Fix Applied:**
- Generated `e2e/package-lock.json` using `npm install --package-lock-only`
- Lockfile ensures reproducible builds and prevents dependency drift

**Files Created:**
- `e2e/package-lock.json` (2.7KB, 5 packages locked)

### 3. ✅ Ansible Collection Pinning

**File:** `ansible/requirements.yml`

**Status:** Fixed

**Issue:** Used version range (`community.general >= 7.0.0`) which allows behavior changes between runs

**Fix Applied:**
- Pinned to exact version `12.1.0` (currently installed version)
- Added security comment explaining why exact version is required
- Added note about update procedure (check changelog, test, then update)

**Before:**
```yaml
- name: community.general
  version: ">=7.0.0"
```

**After:**
```yaml
# SECURITY: Pinned to exact version to prevent dependency drift
# Current version: 12.1.0 (verified installed)
# To update: Check changelog, test, then update version here
- name: community.general
  version: "12.1.0"
```

### 4. Remove "Update to Latest" Scripts

**Action:** Review and remove or disable any scripts that automatically update all images to `:latest`, as these can introduce breaking changes and security vulnerabilities.

## Security Best Practices Going Forward

1. **Never commit secrets:** Use `.env.example` with placeholders only
2. **Redact in logs:** Scripts should never print full token responses or sensitive data
3. **Pin dependencies:** Always use specific versions or SHA256 digests in production
4. **Document security choices:** When security tradeoffs are made (like `insecureSkipVerify`), document the risk and mitigation
5. **Regular audits:** Periodically review scripts and configurations for potential credential leaks

## References

- Original security review findings (2026-01-06)
- [n8n Security Documentation](https://docs.n8n.io/hosting/environment-variables/configuration-methods/#encryption-key)
- [Docker Image Tagging Best Practices](https://docs.docker.com/build/building/tags/)

