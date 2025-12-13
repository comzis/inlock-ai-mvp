# Coolify Server Setup - Complete Guide

**Date:** December 11, 2025  
**Server:** deploy.inlock.ai

## ✅ Setup Complete

The Coolify server has been successfully configured and validated.

---

## 📋 Configuration Summary

### Server Configuration
- **Name**: `deploy-inlock-ai`
- **Description**: `Inlock AI Production Server`
- **IP Address**: `100.83.222.69` (Tailscale IP - recommended)
- **User**: `comzis` ⚠️ **IMPORTANT: Use `comzis`, NOT `root`** (root login is disabled)
- **Port**: `22`
- **Wildcard Domain**: `https://inlock.ai`
- **Status**: ✅ Server is reachable and validated

### SSH Configuration
- **Private Key**: `deploy-inlock-ai-key` (stored in Coolify)
- **Public Key**: Added to `/home/comzis/.ssh/authorized_keys` on server
- **Authentication**: ✅ Working

### Network Configuration
- **Coolify**: Running with `network_mode: host` (for Tailscale access)
- **Traefik**: Routes to Coolify via `172.18.0.1:8080`
- **Database**: PostgreSQL on port 5433, Redis on port 6380

---

## 🔑 Key Configuration Details

### Wildcard Domain Format
**Correct Format:**
```
https://inlock.ai
```

**Common Mistakes:**
- ❌ `https://*.inlock.ai` - Don't include the asterisk
- ❌ `*.inlock.ai` - Must include protocol (`https://`)
- ❌ `inlock.ai` - Must include protocol

**Why:** Coolify automatically handles wildcard subdomains when you provide the base domain. The `*` wildcard is only for DNS configuration.

### Proxy Configuration
**Current Status:** Proxy stopped (intentional)

- Traefik is already handling reverse proxy duties
- Coolify proxy would conflict on port 80/443
- Not needed since Traefik routes to Coolify at `https://deploy.inlock.ai`

**If you need to start the proxy:**
1. Modify `/data/coolify/proxy/docker-compose.yml` to use alternate ports (8081/8444)
2. Or leave it stopped - Traefik handles everything

---

## 🚀 Next Steps

### 1. Deploy Your First Application
1. Go to **Projects** → **Add**
2. Create a new project
3. Add an application (Dockerfile, Docker Compose, or Static Site)
4. Coolify will automatically assign a subdomain like `app-name.inlock.ai`

### 2. Configure DNS (if needed)
For applications deployed via Coolify:
- Add DNS A record: `*.inlock.ai` → `156.67.29.52` (public IP)
- Or use Tailscale DNS if accessing via VPN

### 3. SSL Certificates
- Traefik handles SSL certificates automatically via Let's Encrypt
- Certificates are managed by the main Traefik instance
- Coolify applications will get SSL certificates automatically

---

## 🔧 Troubleshooting

### Server Not Reachable
- **Check**: SSH connectivity from Coolify container
- **Test**: `docker exec compose-coolify-1 nc -zv 100.83.222.69 22`
- **Fix**: Ensure SSH key is in `/home/comzis/.ssh/authorized_keys`
- **⚠️ CRITICAL**: Use username `comzis` (NOT `root`) - root login is disabled for security

### Wildcard Domain Validation Error
- **Error**: "The Wildcard Domain must be a valid URL"
- **Fix**: Use `https://inlock.ai` (not `https://*.inlock.ai`)

### Port 80 Conflict
- **Error**: "Port 80 is in use"
- **Solution**: Leave proxy stopped - Traefik handles routing

### Can't Access Coolify UI
- **URL**: `https://deploy.inlock.ai`
- **Check**: Traefik is running and routing correctly
- **Verify**: `curl -k -I https://deploy.inlock.ai`

---

## 📚 Related Documentation

- [Coolify Server Setup Guide](COOLIFY-SERVER-SETUP.md) - Detailed setup instructions
- [Coolify SSH Fix](COOLIFY-SSH-FIX.md) - SSH connection troubleshooting
- [Coolify Proxy Port Conflict](COOLIFY-PROXY-PORT-CONFLICT.md) - Proxy configuration

---

**Last Updated:** December 13, 2025  
**Status:** ✅ Setup Complete - Ready for deployments

---

## ⚠️ IMPORTANT: Username Configuration

**If you see "Permission denied (publickey,password)" error:**

1. **Go to Coolify UI** → **Servers** → **deploy-inlock-ai** → **Edit**
2. **Change SSH Username** from `root` to `comzis`
3. **Click "Validate Connection"** to test
4. **Save** the configuration

**Why:** Root login is disabled on the server for security. The `comzis` user has sudo privileges and Docker access.
