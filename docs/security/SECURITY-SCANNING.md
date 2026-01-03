# Security Scanning

**Effective Date:** 2026-01-03  
**Status:** Active

## Overview

Automated security scanning of container images to detect vulnerabilities.

## Tools

### Trivy (Recommended)

**Why Trivy:**
- Open-source and free
- Lightweight and fast
- Comprehensive vulnerability database
- Supports multiple output formats
- Easy to integrate into CI/CD

**Installation:**
```bash
./scripts/security/install-trivy.sh
```

Or manually:
```bash
# Download and install
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install trivy
```

## Usage

### Scan All Images

Run the scanning script:
```bash
./scripts/security/scan-images.sh
```

This will:
1. Extract all images from compose files
2. Scan each image for vulnerabilities
3. Generate HTML report
4. Exit with error if critical vulnerabilities found

### Manual Scanning

**Scan a specific image:**
```bash
trivy image traefik:v3.6.4
```

**Scan with HTML report:**
```bash
trivy image --format template --template "@contrib/html.tpl" -o report.html traefik:v3.6.4
```

**Scan with JSON output:**
```bash
trivy image --format json -o report.json traefik:v3.6.4
```

## Vulnerability Severity

Trivy reports vulnerabilities with severity levels:

- **CRITICAL:** Immediate action required
- **HIGH:** Fix as soon as possible
- **MEDIUM:** Fix in next update cycle
- **LOW:** Fix when convenient
- **UNKNOWN:** Severity not determined

## Response Process

### Critical Vulnerabilities

1. **Immediate:** Stop deployment if found
2. **Assess:** Determine if vulnerability is exploitable
3. **Fix:** Update to patched version or apply workaround
4. **Verify:** Re-scan to confirm fix
5. **Deploy:** Only after vulnerability is resolved

### High Vulnerabilities

1. **Assess:** Review within 7 days
2. **Plan:** Schedule fix in next update cycle
3. **Fix:** Update image or apply patch
4. **Verify:** Re-scan after fix

### Medium/Low Vulnerabilities

1. **Track:** Add to vulnerability backlog
2. **Fix:** Address in regular update cycle
3. **Monitor:** Check if severity increases

## Scanning Schedule

### Automated Scanning

- **On Build:** Scan images during CI/CD pipeline
- **Monthly:** Full scan of all production images
- **On Update:** Scan new image versions before deployment

### Manual Scanning

Run before:
- Major deployments
- Security audits
- After security incidents

## Integration

### CI/CD Pipeline

Add to deployment pipeline:
```bash
# In deployment script
./scripts/security/scan-images.sh
if [ $? -ne 0 ]; then
    echo "Critical vulnerabilities found. Deployment blocked."
    exit 1
fi
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Scan images before commit (if compose files changed)
if git diff --cached --name-only | grep -q "compose.*\.yml"; then
    ./scripts/security/scan-images.sh --exit-on-critical
fi
```

## Reports

### Report Location

- **HTML Reports:** `docs/security/scan-reports/`
- **JSON Reports:** `docs/security/scan-reports/` (for automation)
- **Archive:** Keep reports for 90 days

### Report Naming

Format: `scan-report-YYYY-MM-DD-<image-name>.html`

Example: `scan-report-2026-01-03-traefik.html`

## Limitations

- **False Positives:** Some vulnerabilities may not be exploitable
- **Context Required:** Assess vulnerabilities in context of usage
- **Update Frequency:** Database updates daily, may miss 0-day vulnerabilities

## Best Practices

1. **Scan Before Deploy:** Always scan new images
2. **Regular Updates:** Keep images updated
3. **Pin Versions:** Use specific versions, not `:latest`
4. **Review Reports:** Don't ignore warnings
5. **Document Decisions:** Record why vulnerabilities are accepted (if any)

## Related Files

- `scripts/security/scan-images.sh` - Automated scanning script
- `scripts/security/install-trivy.sh` - Trivy installation script
- `docs/security/scan-reports/` - Scan report directory

## Alternative Tools

### Docker Scout

Docker's native scanning tool:
```bash
docker scout cves traefik:v3.6.4
```

### Snyk

Commercial option with additional features:
- Dependency scanning
- License compliance
- Container runtime security

## Review Schedule

- **Monthly:** Review all scan reports
- **Quarterly:** Update scanning tools
- **Annually:** Review scanning policy

