# Coolify SSH Connection Fix - Port 22 Timeout

**Issue**: Coolify server validation stuck - SSH port 22 timing out from container

**Date**: December 11, 2025

---

## 🔍 Problem Identified

- ✅ **Ping works**: Coolify container can ping `156.67.29.52`
- ❌ **SSH port 22 times out**: Connection to port 22 fails from Coolify container
- **Logs show**: `ServerConnectionCheckJob ............. 30s FAIL`

---

## 🔧 Solution Options

### Option 1: Allow Docker Networks in UFW (Recommended)

The firewall may be blocking connections from Docker container networks.

**Check current UFW rules:**
```bash
sudo ufw status numbered
```

**Add rule to allow Docker networks:**
```bash
# Find Docker network subnet (usually 172.x.x.x/16)
docker network inspect mgmt --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'

# Allow SSH from Docker network (replace with actual subnet)
sudo ufw allow from 172.20.0.0/16 to any port 22 proto tcp comment 'Allow SSH from Docker containers'

# Or allow from all Docker networks
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'Allow SSH from Docker networks'
```

**Reload UFW:**
```bash
sudo ufw reload
```

### Option 2: Configure SSH to Listen on Docker Interface

If SSH is only listening on localhost or specific interface:

**Check SSH listening interface:**
```bash
sudo ss -tlnp | grep :22
# Should show: LISTEN 0 128 0.0.0.0:22
# If shows 127.0.0.1:22, SSH is only listening locally
```

**Edit SSH config:**
```bash
sudo nano /etc/ssh/sshd_config
```

**Ensure these lines:**
```
ListenAddress 0.0.0.0
Port 22
```

**Restart SSH:**
```bash
sudo systemctl restart sshd
```

### Option 3: Use Host Network Mode (Quick Fix)

Temporarily use host network to bypass Docker network isolation:

**Not recommended for production** - but works for testing:
- Coolify would use host network instead of Docker bridge
- This bypasses network isolation

### Option 4: Use Different SSH Port

If port 22 is blocked, configure SSH on a different port:

**On server:**
```bash
sudo nano /etc/ssh/sshd_config
# Change: Port 22 to Port 2222
sudo systemctl restart sshd
sudo ufw allow 2222/tcp
```

**In Coolify:**
- Use port `2222` instead of `22` in server configuration

---

## ✅ Quick Fix Steps

**Step 1: Check UFW Status**
```bash
sudo ufw status verbose
```

**Step 2: Allow Docker Network Subnet**
```bash
# Get Docker network subnet
DOCKER_SUBNET=$(docker network inspect mgmt --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | cut -d'/' -f1 | cut -d'.' -f1-3)
echo "Docker subnet: ${DOCKER_SUBNET}.0/24"

# Allow SSH from Docker network
sudo ufw allow from ${DOCKER_SUBNET}.0/24 to any port 22 proto tcp comment 'Coolify SSH access'
```

**Step 3: Verify SSH is Listening**
```bash
sudo ss -tlnp | grep :22
# Should show: LISTEN 0 128 0.0.0.0:22
```

**Step 4: Test Connection from Coolify Container**
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/coolify.yml --env-file .env exec coolify nc -zv -w 5 156.67.29.52 22
# Should succeed now
```

**Step 5: Retry Validation in Coolify UI**
- Go back to server configuration
- Click "Validate Connection" again
- Should complete successfully

---

## 🔍 Diagnostic Commands

**From Coolify container:**
```bash
# Test ping
docker compose -f compose/coolify.yml --env-file .env exec coolify ping -c 3 156.67.29.52

# Test SSH port
docker compose -f compose/coolify.yml --env-file .env exec coolify nc -zv -w 5 156.67.29.52 22

# Test SSH connection
docker compose -f compose/coolify.yml --env-file .env exec coolify ssh -v -o ConnectTimeout=5 comzis@156.67.29.52 "echo test"
```

**On server:**
```bash
# Check SSH status
sudo systemctl status sshd

# Check listening ports
sudo ss -tlnp | grep :22

# Check firewall
sudo ufw status numbered

# Check SSH config
sudo grep -E "ListenAddress|Port" /etc/ssh/sshd_config
```

---

## 📝 Notes

- **Root Cause**: Docker container networks are typically in `172.x.x.x/16` range
- **UFW Default**: May block connections from Docker networks by default
- **Solution**: Explicitly allow Docker network subnet in UFW rules
- **Alternative**: Configure SSH to listen on all interfaces (0.0.0.0)

---

**Last Updated**: December 11, 2025  
**Status**: Diagnostic complete - awaiting firewall fix

