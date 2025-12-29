# Phase 1 Implementation Guide: Vulnerability Scanning

**Date:** 2025-12-28  
**Status:** Implementation Instructions

---

## Overview

This guide provides step-by-step instructions to implement Phase 1: Vulnerability Scanning. All scripts and configurations have been created and are ready to use.

---

## Prerequisites

- Root/sudo access for installation
- Docker installed and running
- Git repository cloned
- GPG configured (for report encryption, optional)

---

## Step 1: Install Trivy Scanner

**Run the installation script:**

```bash
cd /home/comzis/projects/inlock-ai-mvp
sudo ./scripts/security/install-trivy.sh
```

**What it does:**
- Downloads latest Trivy binary
- Installs to `/usr/local/bin/trivy`
- Initializes vulnerability database
- Verifies installation

**Verify installation:**
```bash
trivy --version
```

**Expected output:**
```
Version: 0.x.x
```

---

## Step 2: Test Container Scanning

**Scan running containers:**

```bash
cd /home/comzis/projects/inlock-ai-mvp
./scripts/security/scan-containers.sh
```

**Options:**
```bash
# JSON output only
./scripts/security/scan-containers.sh --format json

# Fail on critical vulnerabilities
./scripts/security/scan-containers.sh --fail-on-critical

# Minimum severity HIGH
./scripts/security/scan-containers.sh --severity HIGH
```

**Reports saved to:**
```
docs/reports/security/vulnerabilities/container-scan-*.json
docs/reports/security/vulnerabilities/container-scan-*.html
```

---

## Step 3: Test Image Scanning

**Scan Docker images from compose files:**

```bash
cd /home/comzis/projects/inlock-ai-mvp
./scripts/security/scan-images.sh
```

**Options:**
```bash
# Scan specific compose file
./scripts/security/scan-images.sh --compose-file compose/services/stack.yml

# Pull images before scanning
./scripts/security/scan-images.sh --pull

# Fail on critical vulnerabilities
./scripts/security/scan-images.sh --fail-on-critical
```

**Reports saved to:**
```
docs/reports/security/vulnerabilities/image-scan-*.json
docs/reports/security/vulnerabilities/image-scan-*.html
```

---

## Step 4: Test Filesystem Scanning

**Scan host filesystem (requires sudo):**

```bash
cd /home/comzis/projects/inlock-ai-mvp
sudo ./scripts/security/scan-filesystem.sh
```

**Options:**
```bash
# JSON output only
sudo ./scripts/security/scan-filesystem.sh --format json

# Fail on critical vulnerabilities
sudo ./scripts/security/scan-filesystem.sh --fail-on-critical
```

**Reports saved to:**
```
docs/reports/security/vulnerabilities/filesystem-scan-*.json
docs/reports/security/vulnerabilities/filesystem-scan-*.html
```

---

## Step 5: Set Up CI/CD Integration

**GitHub Actions workflow is already created:**

- Location: `.github/workflows/vulnerability-scanning.yml`
- Triggers: PR, push to main, weekly schedule
- Action: Automatically scans images on PR/push

**Verify workflow:**
```bash
cat .github/workflows/vulnerability-scanning.yml
```

**To enable:**
1. Commit and push the workflow file
2. GitHub Actions will run automatically on next PR/push
3. Check Actions tab in GitHub to view results

---

## Step 6: Set Up Monitoring Dashboard (Optional)

**Grafana dashboard configuration is ready:**

- Location: `config/grafana/dashboards/vulnerability-metrics.json`

**To import in Grafana:**
1. Log in to Grafana
2. Go to Dashboards → Import
3. Upload `config/grafana/dashboards/vulnerability-metrics.json`
4. Configure Prometheus data source if needed

**Note:** This dashboard requires a Prometheus exporter for Trivy metrics (not included in Phase 1).

---

## Step 7: Schedule Regular Scans

### Option 1: Cron Job

**Daily scan of running containers:**

```bash
# Add to crontab (crontab -e)
0 2 * * * cd /home/comzis/projects/inlock-ai-mvp && ./scripts/security/scan-containers.sh >> /var/log/vulnerability-scan.log 2>&1
```

**Weekly scan of all images:**

```bash
0 3 * * 0 cd /home/comzis/projects/inlock-ai-mvp && ./scripts/security/scan-images.sh --compose-file compose/services/stack.yml >> /var/log/vulnerability-scan.log 2>&1
```

**Weekly filesystem scan:**

```bash
0 4 * * 0 cd /home/comzis/projects/inlock-ai-mvp && sudo ./scripts/security/scan-filesystem.sh >> /var/log/vulnerability-scan.log 2>&1
```

### Option 2: systemd Timer

**Create service file:**

```bash
sudo nano /etc/systemd/system/vulnerability-scan.service
```

**Content:**
```ini
[Unit]
Description=Vulnerability Scan
After=network-online.target

[Service]
Type=oneshot
ExecStart=/home/comzis/projects/inlock-ai-mvp/scripts/security/scan-containers.sh
User=comzis
```

**Create timer file:**

```bash
sudo nano /etc/systemd/system/vulnerability-scan.timer
```

**Content:**
```ini
[Unit]
Description=Daily Vulnerability Scan
Requires=vulnerability-scan.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

**Enable and start:**

```bash
sudo systemctl enable vulnerability-scan.timer
sudo systemctl start vulnerability-scan.timer
sudo systemctl status vulnerability-scan.timer
```

---

## Step 8: Review Documentation

**Read the comprehensive guide:**

```bash
cat docs/security/VULNERABILITY-SCANNING.md
```

**This includes:**
- Detailed usage instructions
- Interpreting scan results
- Remediation procedures
- Troubleshooting guide

---

## Verification Checklist

- [ ] Trivy installed (`trivy --version`)
- [ ] Container scan script tested (`./scripts/security/scan-containers.sh`)
- [ ] Image scan script tested (`./scripts/security/scan-images.sh`)
- [ ] Filesystem scan script tested (`sudo ./scripts/security/scan-filesystem.sh`)
- [ ] Reports generated in `docs/reports/security/vulnerabilities/`
- [ ] GitHub Actions workflow file committed
- [ ] Cron/systemd timer configured (optional)
- [ ] Documentation reviewed

---

## Quick Start Commands

**Install and test everything:**

```bash
# 1. Install Trivy
sudo ./scripts/security/install-trivy.sh

# 2. Test container scan
./scripts/security/scan-containers.sh

# 3. Test image scan
./scripts/security/scan-images.sh --compose-file compose/services/stack.yml

# 4. Check reports
ls -lh docs/reports/security/vulnerabilities/

# 5. View documentation
cat docs/security/VULNERABILITY-SCANNING.md
```

---

## Troubleshooting

### Trivy Installation Fails

**Issue:** Installation script fails

**Solution:**
- Check internet connectivity
- Verify architecture (x86_64 or ARM64)
- Try manual installation: `sudo snap install trivy` or download from GitHub

### Scan Scripts Fail

**Issue:** Scripts exit with errors

**Solution:**
- Verify Trivy is installed: `which trivy`
- Check script permissions: `chmod +x scripts/security/*.sh`
- Review error messages in script output

### No Reports Generated

**Issue:** Reports directory is empty

**Solution:**
- Verify output directory exists: `mkdir -p docs/reports/security/vulnerabilities/`
- Check script has write permissions
- Review script logs for errors

### GitHub Actions Not Running

**Issue:** Workflow doesn't trigger

**Solution:**
- Verify workflow file is in `.github/workflows/` directory
- Check GitHub Actions is enabled for repository
- Ensure file is committed and pushed to repository

---

## Next Steps

After completing Phase 1:

1. Review scan results and address critical vulnerabilities
2. Integrate into CI/CD pipeline (already configured)
3. Set up regular scanning schedule
4. Monitor scan reports over time
5. Proceed to Phase 2: Root Access Restrictions

---

## Related Documentation

- [Vulnerability Scanning Guide](./VULNERABILITY-SCANNING.md)
- [Project Structure Assessment](../../PROJECT-STRUCTURE-ASSESSMENT.md)
- [Security Review Report](./SECURITY-REVIEW-2025-12-11.md)

---

**Last Updated:** 2025-12-28


