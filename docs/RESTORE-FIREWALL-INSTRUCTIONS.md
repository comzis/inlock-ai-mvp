# Firewall Restoration Instructions

## Current Status

✅ **Auth0 Configuration**: Verified and working
- AUTH0_ISSUER: https://comzis.eu.auth0.com/
- AUTH0_ADMIN_CLIENT_ID: Configured
- OAuth2-Proxy: Running and healthy
- All services: Running and healthy

⚠️ **Firewall**: Currently disabled (stopped to restore SSH access)

## Problem Summary

You lost SSH access and stopped the firewall to regain access. Now we need to restore the firewall with proper security rules while maintaining SSH access.

## Solution: Safe Firewall Restoration

A script has been created to safely restore firewall settings: `scripts/restore-firewall-safe.sh`

### What the Script Does

1. ✅ Verifies SSH service is running
2. ✅ Backs up current firewall state
3. ✅ Resets firewall rules to a clean state
4. ✅ Configures default policies (deny incoming, allow outgoing)
5. ✅ Allows essential services:
   - Tailscale (port 41641/udp)
   - HTTP/HTTPS (ports 80, 443)
6. ✅ **CRITICALLY**: Configures SSH access:
   - Allows SSH from Tailscale IPs: `100.83.222.69`, `100.96.110.8`
   - Allows SSH from Docker networks (for Coolify)
7. ✅ Blocks unnecessary ports (11434, 3040, 5432)
8. ✅ Allows internal Docker networks
9. ✅ Enables firewall
10. ✅ Verifies Auth0 configuration

## Step-by-Step Restoration

### Step 1: Verify Current Access

Before running the script, ensure you have current SSH access:

```bash
# From your Tailscale-connected machine, test SSH:
ssh comzis@<server-ip>
```

### Step 2: Run the Restoration Script

```bash
cd /home/comzis/inlock-infra
sudo ./scripts/restore-firewall-safe.sh
```

**Important**: The script will:
- Show a 5-second warning before enabling the firewall
- You can press Ctrl+C to cancel if needed
- Backup will be saved to `/root/firewall-backups/`

### Step 3: Verify SSH Access After Restoration

After the script completes, **immediately test SSH access** from a Tailscale IP:

```bash
# From Tailscale-connected machine:
ssh comzis@<server-ip>
```

If SSH access is lost:
```bash
# On the server (if you have console access):
sudo ufw disable
```

### Step 4: Verify Services

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps
```

All services should show as "Up" and "healthy".

### Step 5: Test Auth0 Authentication

1. Visit an admin service: https://traefik.inlock.ai
2. Should redirect to Auth0 login
3. After authentication, should access the service

## Firewall Rules Summary

After restoration, the firewall will have:

### Allowed Incoming:
- **SSH (22/tcp)**: Only from:
  - Tailscale IP: `100.83.222.69/32`
  - Tailscale IP: `100.96.110.8/32`
  - Docker networks: `172.18.0.0/16`, `172.23.0.0/16`, `172.16.0.0/12`
- **HTTP (80/tcp)**: Public access
- **HTTPS (443/tcp)**: Public access
- **Tailscale (41641/udp)**: Public access
- **Docker networks**: Internal communication

### Blocked:
- **Ollama (11434/tcp)**: Internal only
- **Port 3040/tcp**: Internal only
- **PostgreSQL (5432/tcp)**: Internal only

## Troubleshooting

### If SSH Access is Lost After Restoration

1. **If you have console access**:
   ```bash
   sudo ufw disable
   ```

2. **Review firewall rules**:
   ```bash
   sudo ufw status numbered
   ```

3. **Manually add SSH rule**:
   ```bash
   sudo ufw allow from <your-ip>/32 to any port 22
   sudo ufw enable
   ```

### If Services Are Not Accessible

1. **Check firewall logs**:
   ```bash
   sudo tail -f /var/log/ufw.log
   ```

2. **Check service status**:
   ```bash
   cd /home/comzis/inlock-infra
   docker compose -f compose/stack.yml --env-file .env ps
   docker compose -f compose/stack.yml --env-file .env logs traefik --tail 50
   ```

3. **Verify ports are allowed**:
   ```bash
   sudo ufw status | grep -E "80|443"
   ```

### If Auth0 Authentication Fails

1. **Check OAuth2-Proxy logs**:
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 50
   ```

2. **Verify Auth0 configuration**:
   ```bash
   cd /home/comzis/inlock-infra
   ./scripts/check-auth-config.sh
   ```

3. **Check callback URLs in Auth0 Dashboard**:
   - Admin: `https://auth.inlock.ai/oauth2/callback`
   - Web: `https://inlock.ai/api/auth/callback/auth0`

## Manual Firewall Configuration (Alternative)

If you prefer to configure manually:

```bash
# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow essential services
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Configure SSH (CRITICAL - do this first!)
sudo ufw allow from 100.83.222.69/32 to any port 22 proto tcp comment 'SSH - Tailscale Server'
sudo ufw allow from 100.96.110.8/32 to any port 22 proto tcp comment 'SSH - Tailscale MacBook'
sudo ufw allow from 172.18.0.0/16 to any port 22 proto tcp comment 'SSH - Docker mgmt'
sudo ufw allow from 172.23.0.0/16 to any port 22 proto tcp comment 'SSH - Docker coolify'
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'SSH - Docker networks'

# Block unnecessary ports
sudo ufw deny 11434/tcp comment 'Ollama - Internal only'
sudo ufw deny 3040/tcp comment 'Port 3040 - Internal only'
sudo ufw deny 5432/tcp comment 'PostgreSQL - Internal only'

# Allow Docker networks
sudo ufw allow from 172.20.0.0/16 comment 'Docker edge network'
sudo ufw allow from 172.18.0.0/16 comment 'Docker default network'
sudo ufw allow from 172.17.0.0/16 comment 'Docker bridge network'

# Enable firewall
sudo ufw enable

# Verify
sudo ufw status verbose
```

## Verification Checklist

After restoration, verify:

- [ ] SSH access works from Tailscale IPs
- [ ] HTTP/HTTPS services are accessible
- [ ] Auth0 authentication works (test with https://traefik.inlock.ai)
- [ ] All Docker services are running
- [ ] Firewall is active: `sudo ufw status | grep "Status: active"`
- [ ] Unnecessary ports are blocked
- [ ] Firewall logs show no unexpected blocks

## Next Steps

1. ✅ Restore firewall using the script
2. ✅ Test SSH access immediately
3. ✅ Verify all services are accessible
4. ✅ Test Auth0 authentication
5. ✅ Monitor firewall logs for 24 hours
6. ✅ Document any additional IPs that need SSH access

## Backup Location

Firewall backups are saved to: `/root/firewall-backups/`

To restore from backup:
```bash
sudo cp /root/firewall-backups/user.rules.backup-YYYYMMDD-HHMMSS /etc/ufw/user.rules
sudo ufw reload
```

---

**Created**: $(date)
**Script**: `scripts/restore-firewall-safe.sh`
**Status**: Ready to execute
