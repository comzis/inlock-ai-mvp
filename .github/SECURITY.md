# GitHub Actions Security Configuration

## Overview

This document describes the security configuration and best practices for GitHub Actions workflows in this repository.

## Secret Management

### Required Secrets

The following secrets must be configured in GitHub repository settings:

1. **SSH_HOST** - Production server hostname/IP
2. **SSH_USER** - SSH username for deployment
3. **SSH_KEY** - Private SSH key for authentication

### Secret Security Features

✅ **Automatic Secret Masking**: GitHub Actions automatically masks secrets in logs
✅ **No Secret Exposure**: Secrets are never printed or logged
✅ **Environment Protection**: Production deployments require approval (if configured)

## Environment Protection

### Production Environment

The `production` environment is configured with:
- **Required Reviewers**: Manual approval required before deployment
- **Deployment URL**: https://inlock.ai
- **Protection Rules**: Prevents accidental deployments

### Setting Up Environment Protection

1. Go to Repository Settings → Environments
2. Create/Edit `production` environment
3. Add required reviewers
4. Configure deployment branches (main only)

## Security Best Practices

### ✅ Implemented

1. **Secret Masking**: All secrets are automatically masked in logs
2. **Minimum Permissions**: Workflows use least-privilege permissions
3. **Action Pinning**: Using specific action versions (not `@master`)
4. **Environment Protection**: Production deployments require approval
5. **Security Scanning**: Trivy scans before deployment
6. **No Debug Logging**: Debug flags disabled to prevent secret exposure

### 🔒 Security Features

- **No Secret Echo**: Secrets are never printed or logged
- **Automatic Redaction**: GitHub Actions redacts secrets from logs
- **Audit Logging**: All actions are logged in GitHub audit logs
- **Required Reviewers**: Production deployments require manual approval

## Audit and Monitoring

### Audit Logs

All GitHub Actions runs are logged in:
- Repository Settings → Audit log
- Organization Settings → Audit log (if applicable)

### Monitoring

Monitor for:
- Failed authentication attempts
- Unauthorized workflow runs
- Secret access patterns
- Environment protection bypasses

## Secret Rotation

### Recommended Rotation Schedule

- **SSH Keys**: Every 90 days
- **API Tokens**: Every 180 days
- **Passwords**: Every 90 days

### Rotation Process

1. Generate new credentials
2. Update GitHub secrets
3. Test deployment in staging
4. Deploy to production
5. Revoke old credentials

## Compliance

This configuration follows:
- GitHub Actions security best practices
- OWASP security guidelines
- Industry-standard secret management

## Reporting Security Issues

If you discover a security vulnerability, please:
1. **DO NOT** create a public issue
2. Email security concerns to: [security contact]
3. Include detailed information about the vulnerability

## References

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Environment Protection](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
