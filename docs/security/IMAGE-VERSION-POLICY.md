# Image Version Policy

**Effective Date:** 2026-01-03  
**Status:** Active

## Policy

**No `:latest` tags in production compose files.**

### Rules

1. **Production Services:**
   - Use SHA256 digests for critical services (databases, security services)
   - Use specific version tags for application services
   - Never use `:latest` tag

2. **Development/Local:**
   - `:latest` tags allowed only in `docker-compose.local.yml`
   - Must be clearly marked as development-only

3. **Custom Images:**
   - Must implement versioning system
   - Tag images with semantic versioning (e.g., `v1.2.3`)
   - Use git commit SHA as part of tag for traceability

## Current Status

### Services Using Specific Versions ✅
- `postgres@sha256:a5074487380d4e686036ce61ed6f2d363939ae9a0c40123d1a9e3bb3a5f344b4`
- `n8nio/n8n@sha256:85214df20cd7bc020f8e4b0f60f87ea87f0a754ca7ba3d1ccdfc503ccd6e7f9c`
- `traefik:v3.6.4`
- `portainer/portainer-ce:2.33.5`
- `grafana/grafana:11.1.0`
- `linuxserver/heimdall:2.5.7` (updated 2026-01-03)

### Services Needing Updates ⚠️
- `inlock-ai:latest` → Needs versioning system
  - Location: `compose/services/inlock-ai.yml`
  - Action: Implement version tagging in build process

## Implementation for Custom Images

### Inlock AI Image

**Current:** Uses `inlock-ai:latest`

**Recommended Approach:**

1. **Build with version tag:**
   ```bash
   # Get version from package.json or git tag
   VERSION=$(git describe --tags --always)
   docker build -t inlock-ai:${VERSION} .
   docker tag inlock-ai:${VERSION} inlock-ai:latest  # Keep latest for dev
   ```

2. **Update compose file:**
   ```yaml
   image: inlock-ai:v1.2.3  # Or use SHA256 digest
   ```

3. **Alternative: Use SHA256 digest:**
   ```bash
   docker build -t inlock-ai:latest .
   DIGEST=$(docker inspect inlock-ai:latest --format='{{index .RepoDigests 0}}' | cut -d'@' -f2)
   # Update compose file with: inlock-ai@sha256:${DIGEST}
   ```

## Update Process

### When Updating Images

1. **Check for updates:**
   ```bash
   docker pull <image>:latest
   docker inspect <image>:latest | grep -i version
   ```

2. **Test new version:**
   - Update compose file with new version
   - Test in staging/dev environment
   - Verify functionality

3. **Deploy:**
   - Update production compose file
   - Deploy and monitor
   - Document version change

### Automated Checks

Run monthly:
```bash
./scripts/security/check-image-versions.sh
```

This script will:
- Scan all compose files for `:latest` tags
- Check for outdated versions
- Suggest updates
- Generate report

## Exceptions

### Development Files
- `compose/services/docker-compose.local.yml` - Allowed to use `:latest`
- Must be clearly marked as development-only

## Enforcement

### Pre-commit Checks
- Script: `scripts/security/pre-commit-check.sh`
- Checks for `:latest` tags in production files
- Fails commit if found

### CI/CD Integration
- Add image version check to CI pipeline
- Block deployment if `:latest` tags found in production

## Related Files

- `scripts/security/check-image-versions.sh` - Version checking script
- `scripts/security/pre-commit-check.sh` - Pre-commit validation
- `compose/services/*.yml` - Service definitions

## Review Schedule

- **Monthly:** Check for image updates
- **Quarterly:** Review version policy
- **Annually:** Update policy as needed

