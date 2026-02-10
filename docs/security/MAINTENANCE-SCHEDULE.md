# Security Maintenance Schedule

**Effective Date:** 2026-01-03  
**Status:** Active

## Overview

Regular security maintenance tasks to maintain and improve security posture.

## Upgrade Execution Runbook

For production upgrade execution steps (preflight, phased rollout, validation, rollback), use:

- `runbooks/ZERO-SURPRISE-UPGRADE-WINDOW.md`

## Monthly Tasks

### Week 1: Image Scanning

**Task:** Scan all production images for vulnerabilities

**Commands:**
```bash
# Scan all images
./scripts/security/scan-images.sh --fail-on-critical

# Review reports
ls -lh docs/security/scan-reports/
```

**Deliverables:**
- Vulnerability scan reports
- Action items for critical/high vulnerabilities

### Week 2: Dependency Updates

**Task:** Check for and apply security updates

**Commands:**
```bash
# System updates
sudo apt update
sudo apt list --upgradable | grep -i security

# Docker image updates
./scripts/security/check-image-versions.sh
```

**Deliverables:**
- List of available updates
- Update plan for production

### Week 3: Access Review

**Task:** Review access logs and user permissions

**Commands:**
```bash
# Check SSH access
sudo grep "Accepted" /var/log/auth.log | tail -20

# Check fail2ban status
sudo fail2ban-client status sshd

# Verify firewall rules
sudo ufw status numbered
```

**Deliverables:**
- Access log summary
- Unusual activity report

### Week 4: Configuration Review

**Task:** Review security configurations

**Commands:**
```bash
# Verify container hardening
./scripts/security/verify-container-hardening.sh

# Check SSH restrictions
sudo ./scripts/security/verify-ssh-restrictions.sh

# Verify image versions
./scripts/security/check-image-versions.sh
```

**Deliverables:**
- Configuration compliance report
- Recommendations for improvements

## Quarterly Tasks

### Full Security Audit

**Task:** Comprehensive security review

**Activities:**
1. Run full security audit script
2. Review all security documentation
3. Check compliance with security policies
4. Review and update security rules
5. Test incident response procedures

**Commands:**
```bash
# Run comprehensive audit
./scripts/security/security-review.sh

# Generate audit report
# Review docs/security/SECURITY-AUDIT-*.md
```

**Deliverables:**
- Security audit report
- Action plan for improvements
- Updated security documentation

### Access Log Review

**Task:** Comprehensive review of access logs

**Activities:**
1. Review SSH access logs
2. Review application access logs
3. Check for suspicious activity
4. Review fail2ban bans
5. Update IP allowlists if needed

**Commands:**
```bash
# Review SSH logs
sudo grep "Failed" /var/log/auth.log | tail -50

# Review application logs
docker logs services-traefik-1 --tail 100

# Check fail2ban
sudo fail2ban-client status
```

**Deliverables:**
- Access log analysis
- Security incident report (if any)
- Recommendations

### Policy Review

**Task:** Review and update security policies

**Activities:**
1. Review `.cursorrules-security`
2. Update security documentation
3. Review image version policy
4. Update maintenance schedule if needed

**Deliverables:**
- Updated security policies
- Policy change log

## Annually

### Penetration Testing

**Task:** External security assessment

**Activities:**
1. Engage security firm or perform internal test
2. Test all attack vectors
3. Review findings
4. Implement fixes
5. Update security measures

**Deliverables:**
- Penetration test report
- Remediation plan
- Updated security measures

### Security Policy Review

**Task:** Comprehensive policy review

**Activities:**
1. Review all security policies
2. Update based on industry best practices
3. Review compliance requirements
4. Update documentation

**Deliverables:**
- Updated security policies
- Policy review report

## Automated Tasks

### Daily

- **Fail2ban Monitoring:** Automatic (active)
- **Firewall Monitoring:** Automatic (UFW active)
- **Auto-updates:** Automatic (unattended-upgrades)

### Weekly

- **Security Script Checks:** Run verification scripts
- **Log Rotation:** Automatic (configured)

## Maintenance Script

Run comprehensive maintenance:

```bash
./scripts/security/security-maintenance.sh
```

This script runs:
- Image version checks
- Container hardening verification
- SSH restrictions verification
- Security scanning (if configured)
- Generates maintenance report

## Reminders

### Calendar Integration

Add to calendar:
- **Monthly:** First Monday - Image scanning
- **Monthly:** Second Monday - Dependency updates
- **Monthly:** Third Monday - Access review
- **Monthly:** Fourth Monday - Configuration review
- **Quarterly:** First Monday of quarter - Full audit
- **Annually:** January - Penetration testing

### Notification Setup

Configure alerts for:
- Critical vulnerabilities found
- Failed security checks
- Unusual access patterns
- Policy violations

## Documentation Updates

After each maintenance task:
1. Update relevant documentation
2. Record findings in security logs
3. Update security audit reports
4. Document any changes made

## Related Files

- `scripts/security/security-maintenance.sh` - Automated maintenance script
- `scripts/security/security-review.sh` - Comprehensive review script
- `docs/security/` - Security documentation directory

## Review Schedule

- **Monthly:** Review maintenance schedule effectiveness
- **Quarterly:** Update schedule based on findings
- **Annually:** Comprehensive schedule review
