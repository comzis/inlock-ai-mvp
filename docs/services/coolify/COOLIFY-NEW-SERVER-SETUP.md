# Coolify New Server Setup Guide

**Date:** 2025-12-28  
**Status:** Recommended Configuration

---

## Form Field Configuration

Fill out the "New Server" form with these exact values:

### Required Fields

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | `deploy-inlock-ai` | (or your preferred name) |
| **Description** | `Inlock AI Production Server` | (optional) |
| **IP Address/Domain** | `172.18.0.1` | ⚠️ **CRITICAL: Use Docker gateway IP** |
| **Port** | `22` | Standard SSH port |
| **User** | `comzis` | ⚠️ **NOT root** (root login disabled) |
| **Private Key** | `inlock-ai-infrastructure` | (matches deploy-inlock-ai-key) |
| **Use it as a build server?** | ✓ Checked | (recommended) |

---

## Important Notes

### ⚠️ About the "Non-root user is experimental" Warning

Coolify shows: *"Non-root user is experimental: docs."*

**This is OK!** ✅
- We've tested `comzis` user and it works
- Passwordless sudo is configured for required commands
- Root login is disabled for security (as preferred)
- This warning is informational - proceed with `comzis`

### IP Address: Use Docker Gateway (`172.18.0.1`)

**Why not use Tailscale IP (`100.83.222.69`)?**
- ❌ Docker containers cannot reliably connect to Tailscale IP
- ❌ Network routing issues from container → host's Tailscale interface
- ✅ `172.18.0.1` is the Docker network gateway - direct path to host

**Why not use `localhost` or `127.0.0.1`?**
- ❌ `localhost` in a container refers to the container itself, not the host
- ❌ Connection will be refused
- ✅ `172.18.0.1` correctly routes to the host

**Why not use public IP (`156.67.29.52`)?**
- ⚠️ Firewall complexity and routing issues
- ✅ `172.18.0.1` is internal, secure, and works reliably

---

## Verification Checklist

Before clicking "Continue", verify:

- [x] IP Address is `172.18.0.1` (NOT Tailscale or localhost)
- [x] User is `comzis` (lowercase, exactly as shown)
- [x] Port is `22`
- [x] Private Key is selected (`inlock-ai-infrastructure`)
- [x] Root login is disabled on server (security preference)
- [x] Sudo configuration script has been run (passwordless for specific commands)
- [x] Firewall allows Docker networks (172.18.0.0/16)

---

## What Happens Next

After clicking "Continue":

1. **Coolify validates the connection:**
   - Tests SSH connectivity to `172.18.0.1:22`
   - Authenticates with the selected SSH key
   - Verifies user `comzis` has sudo access
   - Checks Docker availability

2. **If validation fails:**
   - Check the error message
   - Verify all fields match exactly
   - See troubleshooting guide below

3. **If validation succeeds:**
   - Server will be added
   - You can configure wildcard domain (`https://inlock.ai`)
   - Ready to deploy applications

---

## Troubleshooting

### Connection Refused

**Symptom:** `ssh: connect to host 172.18.0.1 port 22: Connection refused`

**Fix:**
- Verify UFW allows Docker networks: `sudo ufw status | grep 172.18`
- Check SSH is running: `sudo systemctl status sshd`
- Test from container: `docker exec services-coolify-1 nc -zv 172.18.0.1 22`

### Permission Denied (publickey)

**Symptom:** `Permission denied (publickey,password)`

**Fix:**
- Verify SSH key is correctly selected in Coolify
- Check key exists on server: `cat ~/.ssh/authorized_keys | grep deploy`
- Verify permissions: `.ssh` = 700, `authorized_keys` = 600

### Sudo Password Required

**Symptom:** `sudo: a password is required`

**Fix:**
- Run the sudo configuration script:
  ```bash
  sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/configure-coolify-sudo.sh
  ```
- Verify it works: `sudo -n /usr/bin/docker ps`

### IP Already in Use

**Symptom:** "IP address is already in use by another team"

**Fix:**
- This shouldn't happen with `172.18.0.1` (internal IP)
- If it does, check if you've already added this server
- Use a unique server name

---

## Configuration Summary

```yaml
Server Configuration:
  Name: deploy-inlock-ai
  IP: 172.18.0.1 (Docker gateway)
  User: comzis
  Port: 22
  SSH Key: inlock-ai-infrastructure
  
Security:
  Root Login: Disabled ✅
  Sudo: Limited passwordless ✅
  Firewall: Docker networks allowed ✅
```

---

## Related Documentation

- [Coolify IP Address Guide](./COOLIFY-IP-ADDRESS-GUIDE.md)
- [Coolify Sudo Configuration](./COOLIFY-SUDO-CONFIGURATION.md)
- [Coolify comzis User Troubleshooting](./COOLIFY-COMZIS-USER-TROUBLESHOOTING.md)
- [Coolify Firewall Fix](./COOLIFY-FIREWALL-FIX.md)

---

**Last Updated:** 2025-12-28  
**Status:** Ready to Use


