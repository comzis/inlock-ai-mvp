# Coolify IP Address Configuration Guide

**Date:** 2025-12-28  
**Issue:** Connection refused when using Tailscale IP from Docker container

---

## Problem

When configuring Coolify, using the Tailscale IP (`100.83.222.69`) results in "Connection refused" even though:
- Firewall rules allow Docker networks
- SSH is running and accessible
- Ping works to the Tailscale IP

---

## Root Cause

Docker containers cannot reliably connect to the host's Tailscale IP (`100.83.222.69`) because:
1. **Network Routing:** Containers connect through Docker bridge networks, not Tailscale
2. **Source IP:** When connecting to Tailscale IP, the source IP routing may confuse UFW
3. **Interface Binding:** The connection path from container → host's Tailscale interface is complex

---

## Solution: Use Docker Gateway IP

**Use the Docker network gateway IP instead of the Tailscale IP in Coolify.**

### Correct Configuration

In Coolify "New Server" form:

- **IP Address/Domain:** `172.18.0.1` (Docker mgmt network gateway)
- **User:** `comzis`
- **Port:** `22`
- **SSH Key:** `deploy-inlock-ai-key`

**Do NOT use:**
- ❌ `100.83.222.69` (Tailscale IP - doesn't work from containers)
- ❌ `localhost` or `127.0.0.1` (refers to container itself)
- ❌ `156.67.29.52` (Public IP - also problematic from containers)

---

## Why Docker Gateway IP Works

1. **Direct Connection:** `172.18.0.1` is the Docker bridge gateway - direct path from container to host
2. **Firewall Rules:** UFW rules already allow Docker networks (172.18.0.0/16, 172.23.0.0/16)
3. **Simpler Routing:** No complex routing through multiple network interfaces
4. **Verified Working:** Connection test confirms it works

---

## IP Address Reference

| IP Address | Type | Use Case | Works from Container? |
|------------|------|----------|----------------------|
| `172.18.0.1` | Docker Gateway | ✅ **Coolify** | ✅ Yes |
| `100.83.222.69` | Tailscale IP | External SSH access | ❌ No (from containers) |
| `156.67.29.52` | Public IP | External access | ⚠️ Maybe (firewall dependent) |
| `localhost` / `127.0.0.1` | Loopback | Same machine | ❌ No (container's loopback) |

---

## Security Note

Using `172.18.0.1` is secure because:
- ✅ It's an internal Docker network IP (not routable externally)
- ✅ Only accessible from containers on the same host
- ✅ Firewall rules restrict access to Docker networks only
- ✅ Still requires SSH key authentication

---

## Verification

After configuring with `172.18.0.1`, test from container:

```bash
# Test SSH port
docker exec services-coolify-1 nc -zv 172.18.0.1 22

# Test SSH connection
docker exec services-coolify-1 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no comzis@172.18.0.1 "echo test"
```

---

## Related Documentation

- [Coolify Firewall Fix](./COOLIFY-FIREWALL-FIX.md)
- [Coolify Sudo Configuration](./COOLIFY-SUDO-CONFIGURATION.md)
- [Coolify Server Setup Guide](../guides/COOLIFY-SERVER-SETUP.md)

---

**Last Updated:** 2025-12-28  
**Status:** Recommended Configuration




