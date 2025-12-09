# Quick Start Guide - INLOCK.AI Deployment

## Current Status ✅

**Already Done:**
- ✅ IP Allowlist configured: `100.83.222.69/32`, `100.96.110.8/32`
- ✅ Services deployed via Docker Compose
- ✅ Core infrastructure running

**What You Need:**

### Option 1: With Ansible (Recommended for Production)

```bash
# Install Ansible
sudo apt update && sudo apt install -y ansible
ansible-galaxy collection install community.docker community.general

# Capture Tailscale status (optional, for audit)
sudo ./scripts/capture-tailnet-status.sh

# Run full deployment
./scripts/deploy-hardened-stack.sh
```

### Option 2: Manual Deployment (No Ansible)

**The allowlist is already configured!** Use the automated manual script:

```bash
# Complete manual deployment (handles firewall + services)
./scripts/deploy-manual.sh
```

**Or step-by-step:**

```bash
# 1. Configure firewall
sudo ./scripts/apply-firewall-manual.sh

# 2. Fix Portainer and restart services
./scripts/fix-and-restart-services.sh

# 3. Verify deployment
./scripts/finalize-deployment.sh
```

**Or fully manual commands:**

```bash
# Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw enable

# Portainer
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
docker compose -f compose/stack.yml --env-file .env restart portainer
```

## What's Already Working

The allowlist middleware is **already active** in `traefik/dynamic/middlewares.yml`:
```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - 100.83.222.69/32 # Admin device 1 (Tailscale)
      - 100.96.110.8/32  # Admin device 2 (Tailscale)
```

**No need to run `update-allowlists.sh`** - it's already configured!

## Next Steps

1. **Configure Firewall** (choose one):
   - With Ansible: `ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml`
   - Manual: See commands above

2. **Fix Portainer**:
   ```bash
   sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
   docker compose -f compose/stack.yml --env-file .env restart portainer
   ```

3. **Setup TLS**:
   ```bash
   ./scripts/setup-tls.sh
   ```

4. **Test Access Control** (once TLS works):
   ```bash
   ./scripts/test-access-control.sh
   ```

## Documentation

- **Full Manual Guide**: `MANUAL-DEPLOYMENT.md`
- **Deployment Status**: `DEPLOYMENT-STATUS.md`
- **Network Security**: `docs/network-security.md`

## Quick Commands

```bash
# Check everything
./scripts/finalize-deployment.sh

# View service status
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs -f

# Restart services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env restart
```

---

**Note**: The allowlist is already configured and active. You can proceed with firewall configuration and service fixes without needing to capture Tailscale peers again.

