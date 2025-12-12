# Coolify Server Setup Guide - deploy.inlock.ai

**Date:** December 11, 2025  
**Server:** deploy.inlock.ai (156.67.29.52)

---

## 📋 Step-by-Step Instructions

### Step 1: Server Configuration

Fill in the form fields:

1. **Server Name**:
   - Current value: `excited-eland-ro4c0gkww40kw4so0sc4800s`
   - You can keep this or change it to: `deploy-inlock-ai` or `inlock-production`

2. **IP Address/Hostname** *(Required)*:
   ```
   100.83.222.69
   ```
   - **✅ STRONGLY RECOMMENDED**: Use Tailscale IP `100.83.222.69`
     - No firewall rules needed
     - More secure (private network)
     - Avoids UFW connection issues
     - Already tested and working
   - **Alternative**: Public IP `156.67.29.52` (requires firewall rules - see troubleshooting)
   - **OR** use the hostname: `deploy.inlock.ai` (if DNS resolution works)

3. **Description** *(Optional)*:
   ```
   Inlock AI Production Server - Main deployment server
   ```

4. **Wildcard Domain** *(Optional but recommended)*:
   ```
   https://inlock.ai
   ```
   - **Important**: Use the base domain with protocol (`https://inlock.ai`), NOT `https://*.inlock.ai`
   - Coolify automatically handles wildcard subdomains when you set the base domain
   - This enables automatic subdomain generation for deployed applications (e.g., `app1.inlock.ai`, `app2.inlock.ai`)

5. **Advanced Connection Settings** (Click to expand):
   - **SSH Port**: `22` (default)
   - **SSH Username**: `root` (or `comzis` if using non-root user)
   - **SSH Private Key**: Will be configured in Step 2

5. Click **"Validate Connection"** button
   - This will test basic connectivity
   - If validation fails, check firewall rules allow SSH from Coolify container

---

### Step 2: Connection Configuration

After clicking "Validate Connection", you'll proceed to Step 2: **Connection**.

1. **SSH Key Selection**:
   - Select the SSH key you just created: `testy-toucan-eoww0gkg0cccg08g0884c4ok`
   - Or if you renamed it: `deploy-inlock-ai-key`

2. **SSH Username**:
   ```
   comzis
   ```
   - This should match your server username
   - User must have Docker permissions (sudo or docker group membership)

3. **SSH Port**:
   ```
   22
   ```
   - Default SSH port (change if your server uses a different port)

4. **Test Connection**:
   - Coolify will attempt to connect using the SSH key
   - Verify the connection succeeds before proceeding

---

### Step 3: Complete Setup

After successful connection test:

1. **Review Configuration**:
   - Verify all settings are correct
   - Server name, IP, username, and SSH key

2. **Complete Setup**:
   - Click "Complete" or "Finish" button
   - Coolify will finalize the server registration

3. **Verify Server Status**:
   - Go to "Servers" page
   - Your server should appear as "Connected" or "Online"
   - Check server health and Docker status

---

## 🔑 SSH Key Information

**Private Key** (already saved in Coolify):
- Key Name: `testy-toucan-eoww0gkg0cccg08g0884c4ok`
- Type: ED25519
- Location: Saved in Coolify SSH keys

**Public Key** (needs to be added to server):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai
```

### Adding Public Key to Server

**Option 1: Add to authorized_keys** (if not already done):
```bash
# On the server (156.67.29.52)
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Option 2: Verify existing access**:
```bash
# Test SSH connection from Coolify container
docker compose -f compose/coolify.yml --env-file .env exec coolify ssh -i /var/www/html/storage/app/ssh/keys/<key-id> comzis@156.67.29.52
```

---

## ✅ Server Requirements

Ensure your server meets these requirements:

1. **SSH Access**:
   - ✅ Port 22 accessible from Coolify container
   - ✅ SSH key authentication configured
   - ✅ User has sudo or docker group access

2. **Docker**:
   - Docker installed and running
   - User in `docker` group OR sudo access for docker commands
   - Docker socket accessible: `/var/run/docker.sock`

3. **Network**:
   - Server accessible from Coolify container network
   - Firewall allows SSH from Coolify IP

4. **Permissions**:
   - User can execute docker commands
   - User can read/write to Docker volumes
   - User has access to system directories if needed

---

## 🔍 Troubleshooting

### Connection Validation Fails

**Check 1: Network Connectivity**
```bash
# From Coolify container
docker compose -f compose/coolify.yml --env-file .env exec coolify ping -c 3 156.67.29.52
```

**Check 2: SSH Port Accessibility**
```bash
# From Coolify container
docker compose -f compose/coolify.yml --env-file .env exec coolify nc -zv 156.67.29.52 22
```

**Check 3: Firewall Rules**
```bash
# On server
sudo ufw status | grep 22
# Should show: 22/tcp ALLOW
```

### SSH Key Authentication Fails

**Check 1: Key Permissions**
- Ensure private key has correct permissions (600)
- Verify public key is in `~/.ssh/authorized_keys` on server

**Check 2: Test SSH Manually**
```bash
# From Coolify container
docker compose -f compose/coolify.yml --env-file .env exec coolify ssh -v -i /var/www/html/storage/app/ssh/keys/<key-id> comzis@156.67.29.52
```

**Check 3: Server SSH Configuration**
```bash
# On server, check SSH config
sudo grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
# Should show:
# PubkeyAuthentication yes
# AuthorizedKeysFile .ssh/authorized_keys
```

### Docker Access Issues

**Check 1: Docker Group Membership**
```bash
# On server
groups comzis
# Should include: docker

# If not, add user:
sudo usermod -aG docker comzis
# Then logout/login or: newgrp docker
```

**Check 2: Docker Socket Permissions**
```bash
# On server
ls -la /var/run/docker.sock
# Should show: srw-rw---- 1 root docker

# If permissions wrong:
sudo chmod 666 /var/run/docker.sock  # Temporary fix
# Better: Add user to docker group (see above)
```

**Check 3: Test Docker Access**
```bash
# On server, as comzis user
docker ps
# Should list running containers without sudo
```

---

## 📝 Quick Reference

### Server Details
- **IP Address**: `100.83.222.69` (Tailscale) or `156.67.29.52` (Public)
- **Hostname**: `deploy.inlock.ai` or `vmi2953354.contaboserver.net`
- **SSH Port**: `22`
- **SSH Username**: `root` (recommended) or `comzis` (non-root)
- **SSH Key**: `deploy-inlock-ai-key` (in Coolify)
- **Wildcard Domain**: `https://inlock.ai` (base domain, not `*.inlock.ai`)

### Verification Commands

**Test from Coolify container:**
```bash
# Network connectivity (using Tailscale IP)
docker compose -f compose/coolify.yml --env-file .env exec coolify ping -c 3 100.83.222.69

# SSH connectivity (using Tailscale IP)
docker compose -f compose/coolify.yml --env-file .env exec coolify ssh -i /var/www/html/storage/app/ssh/keys/<key-id> root@100.83.222.69 "echo 'Connection successful'"

# Docker access (after server is added)
docker compose -f compose/coolify.yml --env-file .env exec coolify ssh -i /var/www/html/storage/app/ssh/keys/<key-id> root@100.83.222.69 "docker ps"
```

---

## 🎯 Next Steps After Server Setup

1. **Verify Server Status**:
   - Check server appears as "Online" in Coolify
   - Verify Docker connection works
   - Check server resources (CPU, RAM, Disk)

2. **Configure Server Settings**:
   - Set resource limits if needed
   - Configure backup settings
   - Set up monitoring/alerting

3. **Deploy Applications**:
   - Use the server for new deployments
   - Migrate existing applications if needed
   - Set up CI/CD pipelines

---

## ⚠️ Important Notes

### Wildcard Domain Format
- **Correct**: `https://inlock.ai` ✅
- **Incorrect**: `https://*.inlock.ai` ❌
- Coolify automatically handles wildcard subdomains when you provide the base domain
- The `*` wildcard is only for DNS configuration, not for Coolify's wildcard domain field

### Proxy Port Conflict
- If you see "Port 80 is in use" error when starting Coolify proxy:
  - **Solution**: Leave the proxy stopped - Traefik is already handling reverse proxy duties
  - Traefik routes to Coolify at `https://deploy.inlock.ai`
  - Coolify proxy is only needed if you want Coolify to manage its own reverse proxy (not recommended when Traefik is already running)

### Network Configuration
- Coolify is configured with `network_mode: host` to access Tailscale IPs
- Database connections use localhost ports: PostgreSQL (5433), Redis (6380)
- Traefik routes to Coolify via Docker gateway IP `172.18.0.1:8080`

---

**Last Updated:** December 11, 2025  
**Status:** Server validated and ready for use

