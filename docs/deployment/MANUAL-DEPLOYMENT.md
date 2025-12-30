# Manual Deployment Guide (Without Ansible)

This guide covers deployment when Ansible is not available or you prefer manual steps.

## Prerequisites

- Docker and Docker Compose installed
- Access to server with sudo privileges
- Tailscale IPs for allowlist configuration

## Ansible Status

**Ansible is installed** on this system (version 2.10.8).

To use Ansible for deployment:
```bash
cd /home/comzis/inlock-infra/ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml --ask-become-pass
ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml
```

**If Ansible is not available**, follow the manual steps below.

## Step-by-Step Manual Deployment

### Step 1: Capture Tailscale Status (Optional)

If you want to auto-populate allowlists:

```bash
sudo ./scripts/capture-tailnet-status.sh
```

This creates audit files in `/tmp/inlock-audit/` including `tailscale-peer-ips-*.txt`.

**Or manually note your Tailscale IPs:**
```bash
sudo tailscale ip -4
sudo tailscale status --json | jq -r '.Peer[] | select(.Online == true) | .TailscaleIPs[0]'
```

### Step 2: Configure IP Allowlists

**Option A: Auto-update (if Step 1 completed)**
```bash
./scripts/update-allowlists.sh
```

**Option B: Manual edit**
Edit `traefik/dynamic/middlewares.yml`:

```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - 100.83.222.69/32  # Your Tailscale IP 1
      - 100.96.110.8/32   # Your Tailscale IP 2
```

### Step 3: Configure Firewall (Manual)

**Without Ansible, apply UFW rules manually:**

```bash
# Install UFW if not present
sudo apt update && sudo apt install -y ufw

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed

# Allow required ports
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Enable firewall
sudo ufw enable

# Verify
sudo ufw status verbose
```

**Or use the hardening scripts directly:**
```bash
sudo bash scripts/harden-ssh.sh
sudo bash scripts/harden-docker.sh
```

### Step 4: Create Required Networks

```bash
docker network create edge 2>/dev/null || true
docker network create mgmt 2>/dev/null || true
docker network create internal 2>/dev/null || true
docker network create socket-proxy 2>/dev/null || true
```

### Step 5: Configure Secrets

**Ensure secrets exist at external path:**
```bash
mkdir -p /home/comzis/apps/secrets-real
chmod 700 /home/comzis/apps/secrets-real

# Create placeholder files (replace with real values)
touch /home/comzis/apps/secrets-real/{positive-ssl.crt,positive-ssl.key,traefik-dashboard-users.htpasswd,portainer-admin-password,n8n-db-password,n8n-encryption-key}
chmod 600 /home/comzis/apps/secrets-real/*
```

**Or use the rotation script:**
```bash
./scripts/rotate-secrets.sh
```

### Step 6: Configure Environment

```bash
# Copy example env
cp env.example .env

# Edit .env with real values
nano .env  # or your preferred editor

# Required variables:
# - DOMAIN=inlock.ai
# - EMAIL=admin@inlock.ai
# - CLOUDFLARE_API_TOKEN=your-token-here
# - N8N_DB=n8n
# - N8N_DB_USER=n8n
# - N8N_ENCRYPTION_KEY=your-key-here
```

### Step 7: Validate Configuration

```bash
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config
```

### Step 8: Deploy Stack

```bash
# Deploy all services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d

# Check status
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs -f
```

### Step 9: Fix Service Permissions

**Portainer:**
```bash
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
docker compose -f compose/stack.yml --env-file .env restart portainer
```

**Homepage:** Already fixed (permissions relaxed temporarily)

### Step 10: Verify Deployment

```bash
# Check all services
docker ps

# Test Traefik
curl -H "Host: traefik.inlock.ai" http://localhost

# Check firewall
sudo ufw status verbose

# Run comprehensive check
./scripts/finalize-deployment.sh
```

## Troubleshooting

### Ansible Not Available

All steps can be done manually:
- Firewall: Use UFW commands above
- Deployment: Use `docker compose` directly
- Hardening: Run scripts with sudo

### Tailscale Peer IPs Not Captured

Manually edit `traefik/dynamic/middlewares.yml` with known IPs:
```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - YOUR_TAILSCALE_IP/32
```

### Services Not Starting

1. Check logs: `docker logs <container-name>`
2. Verify networks: `docker network ls`
3. Check secrets: `ls -la /home/comzis/apps/secrets-real/`
4. Validate config: `docker compose config`

## Quick Reference

```bash
# Full manual deployment
./scripts/finalize-deployment.sh  # Check status
sudo bash scripts/harden-ssh.sh   # SSH hardening
sudo bash scripts/harden-docker.sh # Docker hardening
sudo ufw enable                    # Firewall (after rules above)
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d
```

## Next Steps After Deployment

1. **Configure TLS**: `./scripts/setup-tls.sh`
2. **Test Access Control**: `./scripts/test-access-control.sh` (from external IP)
3. **Rotate Secrets**: `./scripts/rotate-secrets.sh`
4. **Pin Images**: See `docs/image-pinning-guide.md`

