# Coolify Non-Root User Migration Guide

**Date:** 2025-12-28  
**Status:** Future Migration Plan  
**Current:** Root user required  
**Target:** Non-root user with limited sudo

---

## Overview

Coolify currently requires root access for server management. This document tracks Coolify's non-root user support maturity and provides a migration plan for when it becomes stable.

---

## Current Status

### Current Configuration

- **User:** `root`
- **Authentication:** SSH key-only (`prohibit-password`)
- **Access:** Tailscale network + Docker gateway IP
- **Status:** ✅ Working, but less secure than non-root

### Why Root is Currently Required

1. **Coolify Design:** Coolify is designed for root access
2. **Non-Root Support:** Experimental feature, users report issues
3. **Sudo Requirements:** Would require `NOPASSWD: ALL` (security risk)
4. **Stability:** Root access is most reliable option

---

## Coolify Non-Root Support Status

### Official Documentation

- **Status:** Experimental
- **Documentation:** [Coolify Non-Root User Docs](https://coolify.io/docs/knowledge-base/server/non-root-user)
- **Stability:** Users report issues and failures

### Known Issues

- Permission errors during deployment
- Deployment failures
- Docker access problems
- Service management issues

### Requirements for Non-Root

According to Coolify documentation:
1. Non-root user with SSH key access
2. Passwordless sudo: `NOPASSWD: ALL`
3. Docker group membership (may not be sufficient)
4. Proper file permissions

---

## Migration Plan

### Prerequisites

Before migrating to non-root:

1. **Coolify Non-Root Support:**
   - [ ] Feature is stable (not experimental)
   - [ ] Official documentation updated
   - [ ] No known critical issues
   - [ ] Community reports successful deployments

2. **Security Assessment:**
   - [ ] Evaluate `NOPASSWD: ALL` security risk
   - [ ] Document security trade-offs
   - [ ] Approval from security team

3. **Testing:**
   - [ ] Test in staging environment
   - [ ] Verify all deployments work
   - [ ] Test rollback procedure

### Migration Steps

#### Step 1: Prepare Non-Root User

```bash
# Ensure comzis user exists and is configured
id comzis

# Verify Docker group membership
groups comzis | grep docker

# Verify SSH key access
ssh -i ~/.ssh/keys/deploy-inlock-ai-key comzis@172.18.0.1 "echo test"
```

#### Step 2: Configure Passwordless Sudo

⚠️ **Security Warning:** This requires `NOPASSWD: ALL`, which is less secure than current key-only root.

```bash
# Create sudoers file (SECURITY EXCEPTION)
sudo visudo -f /etc/sudoers.d/coolify-comzis

# Add:
comzis ALL=(ALL) NOPASSWD: ALL
```

**Document the exception:**
- Why it's needed (Coolify requirement)
- Security implications
- Review schedule

#### Step 3: Update Coolify Configuration

1. **In Coolify UI:**
   - Go to Server configuration
   - Change User from `root` to `comzis`
   - Update IP address if needed (172.18.0.1)
   - Click "Validate Server"

2. **Verify Connection:**
   - Should succeed with comzis user
   - Test deployment functionality

#### Step 4: Disable Root Access

Only after confirming Coolify works with non-root:

```bash
sudo ./scripts/infrastructure/disable-root-access.sh
```

This will:
- Set `PermitRootLogin no`
- Remove `/root/.ssh/authorized_keys`
- Restart SSH service

#### Step 5: Monitor and Verify

- Monitor Coolify deployments for issues
- Check SSH logs for access patterns
- Verify all functionality works
- Document any problems

---

## Rollback Procedure

If migration fails or causes issues:

### Step 1: Re-enable Root Access

```bash
sudo ./scripts/infrastructure/enable-root-for-coolify.sh
```

### Step 2: Update Coolify Configuration

1. Change user back to `root` in Coolify UI
2. Validate connection
3. Test deployments

### Step 3: Remove Non-Root Sudo Configuration

```bash
sudo rm /etc/sudoers.d/coolify-comzis
```

---

## Security Comparison

### Current: Root with Key-Only

| Aspect | Status | Risk |
|--------|--------|------|
| Authentication | Key-only | Low (requires key compromise) |
| Access scope | Full root | High (full system access) |
| Sudo | Not needed | N/A |
| Security posture | Medium | Acceptable with mitigations |

### Target: Non-Root with NOPASSWD: ALL

| Aspect | Status | Risk |
|--------|--------|------|
| Authentication | Key-only | Low (requires key compromise) |
| Access scope | Full via sudo | High (full system access via sudo) |
| Sudo | NOPASSWD: ALL | High (no password protection) |
| Security posture | Medium-High | More risk than key-only root |

### Analysis

**Non-root with `NOPASSWD: ALL` is actually LESS secure than key-only root because:**
- Still requires key compromise (same authentication)
- Sudo has no password protection (additional risk)
- Same access scope (full system)
- More complexity (sudo configuration)

**Recommendation:** Keep root access with key-only until Coolify supports limited sudo commands.

---

## Future Improvements

### Ideal Configuration (When Supported)

If Coolify adds support for limited sudo commands:

```bash
# Limited sudo (more secure)
comzis ALL=(ALL) NOPASSWD: /usr/bin/docker, /bin/systemctl, ...
```

This would be:
- More secure than `NOPASSWD: ALL`
- More secure than root (better audit trail)
- Acceptable security posture

### Track Coolify Development

Monitor:
- Coolify GitHub issues for non-root support
- Coolify documentation updates
- Community feedback on non-root deployments
- Release notes for non-root improvements

---

## Decision Matrix

### When to Migrate

**Migrate to Non-Root When:**
- ✅ Coolify non-root support is stable (not experimental)
- ✅ No critical issues reported
- ✅ Limited sudo commands supported (not NOPASSWD: ALL)
- ✅ Security assessment approves
- ✅ Staging tests successful

**Keep Root Access When:**
- ⚠️ Coolify non-root is experimental
- ⚠️ Requires NOPASSWD: ALL
- ⚠️ Users report issues
- ⚠️ Security risk is higher than current setup

---

## Monitoring Checklist

Quarterly review:

- [ ] Check Coolify non-root support status
- [ ] Review community feedback
- [ ] Assess security improvements
- [ ] Update migration plan if needed
- [ ] Document decision to stay on root or migrate

---

## Related Documentation

- [Root Access Security Status](../../../ROOT-ACCESS-SECURITY-STATUS.md)
- [Coolify SSH Restriction](./COOLIFY-SSH-RESTRICTION.md)
- [Coolify Sudo Configuration](./COOLIFY-SUDO-CONFIGURATION.md)
- [Coolify IP Address Guide](./COOLIFY-IP-ADDRESS-GUIDE.md)

---

## References

- [Coolify Non-Root User Documentation](https://coolify.io/docs/knowledge-base/server/non-root-user)
- [Coolify GitHub Issues](https://github.com/coollabsio/coolify/issues)
- [Coolify Community Discussions](https://github.com/coollabsio/coolify/discussions)

---

**Last Updated:** 2025-12-28  
**Next Review:** Quarterly or when Coolify non-root support matures







