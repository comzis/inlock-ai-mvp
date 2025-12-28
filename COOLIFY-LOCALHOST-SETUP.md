# Coolify Localhost Server Setup

**Date:** 2025-12-28  
**Status:** Configuration Guide

---

## Do You Need to Set Up Localhost?

**Yes!** The "localhost" server in Coolify is the server where Coolify itself is running. You need to configure it so Coolify can manage deployments on the same server.

---

## Configuration Values

Based on our setup, use these values for the localhost server:

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | `localhost` or `deploy-inlock-ai` | (your choice) |
| **Description** | `This is the server where Coolify is running` | (optional) |
| **Wildcard Domain** | `https://inlock.ai` | ⚠️ **Important: Use your domain** |
| **IP Address/Domain** | `172.18.0.1` | ⚠️ **Docker gateway IP (NOT Tailscale IP)** |
| **User** | `root` | (required) |
| **Port** | `22` | (standard SSH port) |
| **Server Timezone** | `UTC` or your timezone | (optional) |

---

## Critical Fields

### Wildcard Domain
**Use:** `https://inlock.ai`

**Do NOT use:**
- ❌ `https://example.com` (default/example)
- ❌ `https://*.inlock.ai` (don't include the asterisk)
- ❌ `*.inlock.ai` (must include `https://`)

**Why:** Coolify uses this to automatically assign subdomains to applications you deploy.

### IP Address/Domain
**Use:** `172.18.0.1` (Docker gateway IP)

**Do NOT use:**
- ❌ `localhost` or `127.0.0.1` (refers to container, not host)
- ❌ `100.83.222.69` (Tailscale IP - won't work from container)

**Why:** Coolify runs in a Docker container, so it needs the Docker gateway IP to reach the host.

### User
**Use:** `root`

**Why:** Coolify is designed for root access. We've enabled root login with key-only authentication for security.

---

## Steps to Configure

1. **Fill in all the fields** with the values above
2. **Click "Save"** to save the configuration
3. **Click "Validate Server"** button
4. **It should succeed!** ✅

---

## After Validation

Once validated, you can:
- ✅ Deploy applications to this server
- ✅ Manage Docker containers
- ✅ Set up databases
- ✅ Use automatic subdomain assignment (e.g., `app-name.inlock.ai`)

---

## Troubleshooting

### Validation Fails?

Check:
1. **IP Address** is `172.18.0.1` (not localhost or Tailscale IP)
2. **User** is `root`
3. **SSH key** is correctly configured in Coolify
4. **Root login** is enabled (key-only): `sudo grep PermitRootLogin /etc/ssh/sshd_config`
5. **Root's authorized_keys** has your SSH key: `sudo cat /root/.ssh/authorized_keys`

### Wildcard Domain Issues?

Make sure:
- Uses `https://` (not `http://`)
- Base domain only (no `*` wildcard)
- Matches your DNS domain

---

**Ready to configure?** Fill in the fields and click "Validate Server"! 🚀

