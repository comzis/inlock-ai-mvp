# Portainer Access Guide

## Access URL

**https://portainer.inlock.ai**

## Access Requirements

### 1. Tailscale VPN Connection (Required)

You **must** be connected to Tailscale VPN to access Portainer.

**Allowed IPs:**
- `100.83.222.69/32` (Admin device 1)
- `100.96.110.8/32` (Admin device 2)

**To connect:**
1. Ensure Tailscale is installed and running on your device
2. Connect to your Tailscale network
3. Verify your IP is in the allowlist

**To check your Tailscale IP:**
```bash
tailscale ip
```

**To update allowlist:**
Edit `traefik/dynamic/middlewares.yml` and update the `allowed-admins` middleware with your Tailscale IP.

### 2. IP Allowlist (via Traefik)

Portainer is protected by IP allowlist middleware that restricts access to Tailscale VPN IPs only.

**Note:** Forward authentication was removed as the auth service is not configured. Portainer now relies on:
- IP allowlist (Tailscale VPN required)
- Portainer's built-in authentication
- Rate limiting
- Secure headers

### 3. Portainer Admin Password

The admin password is stored in:
- Docker secret: `portainer_admin_password`
- File: `/home/comzis/apps/secrets/portainer-admin-password`

**On first access:**
- You'll be prompted to create an admin account
- Or use the password from the secret file

## Data Directory Ownership

**Important:** Portainer requires the data directory to be owned by UID 1000 (portainer user).

If you see `mkdir /data/certs: permission denied` errors:

```bash
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
docker compose -f compose/stack.yml --env-file .env restart portainer
```

This ownership requirement is documented in the Portainer deployment configuration.

## Current Status

**⚠️ Portainer is currently restarting due to permission issues.**

**Error:** `mkdir /data/certs: permission denied`

## Fixing Portainer

### Step 1: Fix Permissions

```bash
cd /home/comzis/inlock-infra
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
```

### Step 2: Restart Portainer

```bash
docker compose -f compose/stack.yml --env-file .env restart portainer
```

### Step 3: Verify

```bash
# Check status
docker ps | grep portainer

# Check logs
docker logs compose-portainer-1 --tail 20
```

**Or use the fix script:**
```bash
sudo ./scripts/fix-portainer.sh
```

## Access Steps

1. **Connect to Tailscale VPN**
   ```bash
   # On your device
   tailscale up
   ```

2. **Verify your IP is allowed**
   ```bash
   tailscale ip
   # Should match one of the allowed IPs
   ```

3. **Navigate to Portainer**
   - Open browser: https://portainer.inlock.ai
   - Complete forward authentication (if configured)
   - Enter Portainer admin password

4. **First Time Setup**
   - If this is first access, you may need to:
     - Create admin account
     - Select Docker environment
     - Connect to Docker socket

## Troubleshooting

### Cannot Access (403 Forbidden)

**Problem:** Getting 403 Forbidden

**Solutions:**
1. ✅ Verify Tailscale VPN is connected
2. ✅ Check your Tailscale IP matches allowlist
3. ✅ Update allowlist if needed: `traefik/dynamic/middlewares.yml`
4. ✅ Restart Traefik after updating allowlist

### Portainer Not Starting

**Problem:** Container keeps restarting

**Solutions:**
1. ✅ Fix permissions: `sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data`
2. ✅ Check logs: `docker logs compose-portainer-1`
3. ✅ Verify data directory exists and is writable

### Forward Auth Error

**Problem:** Forward authentication failing

**Solutions:**
1. ✅ Check if auth service is running: `https://auth.inlock.ai/check`
2. ✅ Temporarily disable forward auth in `traefik/dynamic/routers.yml`
3. ✅ Use only IP allowlist and basic auth

### Certificate Error

**Problem:** Browser shows certificate warning

**Solutions:**
1. ✅ Let's Encrypt certificate should be auto-generated
2. ✅ Check Traefik logs: `docker logs compose-traefik-1 | grep acme`
3. ✅ Wait a few minutes for certificate generation

## Security Features

Portainer is protected by:

- ✅ **IP Allowlist** - Only Tailscale IPs can access
- ✅ **Forward Authentication** - Additional auth layer
- ✅ **Rate Limiting** - 50 req/min average, 100 burst
- ✅ **Secure Headers** - HSTS, CSP, etc.
- ✅ **TLS Encryption** - Let's Encrypt certificate
- ✅ **HTTPS Only** - HTTP redirects to HTTPS

## Quick Access Checklist

- [ ] Tailscale VPN connected
- [ ] Tailscale IP in allowlist
- [ ] Portainer container running (not restarting)
- [ ] Forward auth configured (or disabled)
- [ ] Portainer admin password available
- [ ] Browser can access https://portainer.inlock.ai

## Related Documentation

- **[User Guide](USER-GUIDE.md)** - Complete infrastructure guide
- **[Network Security](network-security.md)** - Security configuration
- **[Firewall Management](FIREWALL-MANAGEMENT.md)** - Firewall setup

---

**Last Updated**: December 8, 2025  
**Maintainer**: INLOCK.AI Infrastructure Team

