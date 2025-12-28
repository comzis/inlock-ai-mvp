# Coolify Sudo Configuration

**Date:** 2025-12-28  
**Status:** Security Exception - Documented

---

## Overview

Coolify requires passwordless sudo access for automation, as it cannot provide passwords interactively during server validation and operations.

**Security Decision:** Limited passwordless sudo has been configured for specific commands only, rather than full `NOPASSWD:ALL`. This balances functionality with security.

---

## Configuration

### Sudoers File

Location: `/etc/sudoers.d/coolify-comzis`

**Allowed Commands (passwordless):**
- Docker: `/usr/bin/docker`, `/usr/bin/docker-compose`, `/usr/bin/docker-compose-v1`
- System: `/bin/systemctl`, `/usr/sbin/service`
- File Operations: `/bin/mkdir`, `/bin/chmod`, `/bin/chown`, `/usr/bin/tee`
- Network: `/bin/ss`, `/usr/bin/netstat`, `/usr/sbin/iptables`

### Installation

Run the configuration script:
```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/configure-coolify-sudo.sh
```

### Verification

Test passwordless sudo for allowed commands:
```bash
# Should work without password
sudo -n /usr/bin/docker ps
sudo -n /bin/systemctl status docker

# Should require password (not in allowed list)
sudo -n /usr/bin/whoami
```

---

## Security Rationale

### Why This Exception Was Made

1. **Coolify Requirement:** Coolify's validation process requires sudo access but cannot provide passwords
2. **Limited Scope:** Only specific commands are allowed, not full sudo access
3. **Docker Group Alternative:** User is already in docker group, but Coolify checks sudo specifically
4. **Documented Exception:** This is explicitly documented as a security exception

### Security Measures

- ✅ **Limited Commands:** Only necessary commands are passwordless
- ✅ **Not NOPASSWD:ALL:** Full sudo access still requires password
- ✅ **Documented:** Exception is clearly documented
- ✅ **Auditable:** Changes are tracked in git
- ✅ **Reversible:** Can be removed via disable script

### Security Trade-offs

| Aspect | Passwordless Sudo | Limited Commands | Full NOPASSWD |
|--------|-------------------|------------------|---------------|
| Security | ⚠️ Weakened | ✅ Better | ❌ Much Worse |
| Functionality | ✅ Works | ✅ Works | ✅ Works |
| Risk Level | Medium | Low-Medium | High |

---

## Comparison to Root Access

### Root Login
- ❌ Full system access with single key compromise
- ❌ No audit trail separation
- ❌ Violates security best practices

### Limited Passwordless Sudo
- ✅ Only specific commands allowed
- ✅ Other operations still require password
- ✅ Better audit trail
- ✅ More secure than root

---

## Maintenance

### Removing Configuration

To revert to password-protected sudo:

```bash
sudo rm /etc/sudoers.d/coolify-comzis
```

Or use the disable script:
```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/disable-coolify-sudo.sh
```

### Updating Allowed Commands

Edit the sudoers file:
```bash
sudo visudo -f /etc/sudoers.d/coolify-comzis
```

**Important:** Always validate syntax:
```bash
sudo visudo -c -f /etc/sudoers.d/coolify-comzis
```

---

## Coolify Configuration

After configuring sudo, use these settings in Coolify:

- **User:** `comzis`
- **IP Address:** `172.18.0.1` (Docker gateway IP - use this from containers)
- **Port:** `22`
- **SSH Key:** `deploy-inlock-ai-key` (or `inlock-ai-infrastructure` in Coolify UI)

Validation should now succeed.

**Note:** Use Docker gateway IP (`172.18.0.1`) when configuring from Coolify container, not Tailscale IP. See [Coolify IP Address Guide](./COOLIFY-IP-ADDRESS-GUIDE.md) for details.

---

## Related Documentation

- [Coolify Server Setup Guide](../guides/COOLIFY-SERVER-SETUP.md)
- [Security Rules](../../../.cursorrules-security)
- [SSH Configuration](../../reports/ssh/SSH-CONNECTION-GUIDE.md)

---

**Last Updated:** 2025-12-28  
**Status:** Active - Security Exception

