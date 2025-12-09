# Hardened Stack Deployment Guide

This guide follows the three-step security review process outlined in `.cursor/commands/security-review.md`.

## Quick Start

Run the automated deployment script:

```bash
cd /home/comzis/inlock-infra
sudo ./scripts/deploy-hardened-stack.sh
```

Or follow the manual steps below.

## Step-by-Step Deployment

### Step 1: Capture Tailnet Posture (Privileged)

**Purpose**: Gather baseline information about Tailscale peers and infrastructure status.

```bash
sudo ./scripts/capture-tailnet-status.sh
```

This creates audit files in `/tmp/inlock-audit/`:
- `tailscale-status-*.json` - Full Tailscale status
- `tailscale-peer-ips-*.txt` - Extracted peer IPs for allowlists
- `containers-*.txt` - Container status
- `ufw-status-*.txt` - Firewall status

**Manual alternative**:
```bash
sudo tailscale status --json | jq '.Peer[] | {HostName:.HostName, IPs:.TailscaleIPs}' > /tmp/tailscale-peers.json
sudo tailscale ip -4 > /tmp/tailscale-ip.txt
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' > /tmp/containers.txt
sudo ufw status verbose > /tmp/ufw-status.txt
```

### Step 2: Update IP Allowlists

**Purpose**: Replace placeholder CIDRs with actual Tailscale peer IPs.

**Automated**:
```bash
./scripts/update-allowlists.sh
```

This reads peer IPs from the capture script output and updates `traefik/dynamic/middlewares.yml`.

**Manual alternative**:
1. Extract peer IPs from `/tmp/inlock-audit/tailscale-peer-ips-*.txt`
2. Edit `traefik/dynamic/middlewares.yml`
3. Replace placeholder ranges with `/32` addresses:
   ```yaml
   allowed-admins:
     ipAllowList:
       sourceRange:
         - 100.x.x.x/32  # Your Tailscale node IP
         - 100.y.y.y/32  # Additional admin nodes
   ```

### Step 3: Apply Firewall Hardening

**Purpose**: Deploy UFW rules via Ansible.

```bash
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml
```

**Verification**:
```bash
sudo ufw status verbose
```

Expected output:
- Default: deny (incoming), allow (outgoing, routed)
- Allowed: 41641/udp (Tailscale), 22/tcp (SSH), 80/tcp, 443/tcp

### Step 4: Validate Compose Configuration

**Purpose**: Ensure Docker Compose files are valid before deployment.

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config
```

If `.env` doesn't exist, copy from `env.example`:
```bash
cp env.example .env
# Edit .env with real values
```

### Step 5: Deploy Stack

**Via Ansible** (recommended):
```bash
ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml
```

**Manual Docker Compose**:
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d
```

## Post-Deployment Verification

### 1. Verify Services

```bash
sudo docker ps
```

All services should be running:
- docker-socket-proxy
- traefik
- homepage
- portainer
- n8n
- postgres
- cadvisor

### 2. Test Access Control

**From authorized IP** (Tailscale):
- ✅ `https://traefik.inlock.ai` - Should load with auth
- ✅ `https://portainer.inlock.ai` - Should load with auth
- ✅ `https://n8n.inlock.ai` - Should load

**From unauthorized IP** (public internet):
- ❌ `https://traefik.inlock.ai` - Should return 403
- ❌ `https://portainer.inlock.ai` - Should return 403
- ❌ `https://n8n.inlock.ai` - Should return 403

### 3. Verify Firewall

```bash
sudo ufw status verbose
```

Should show:
- Default policies: deny (incoming), allow (outgoing, routed)
- Only required ports open: 41641/udp, 22/tcp, 80/tcp, 443/tcp

### 4. Check Logs

```bash
sudo docker logs traefik
sudo docker logs portainer
sudo docker logs n8n
```

## Remaining Manual Steps

### Secrets Management

1. **Verify secrets location**:
   ```bash
   ls -la /home/comzis/apps/secrets/
   ```
   Should contain:
   - `positive-ssl.crt` / `positive-ssl.key`
   - `traefik-dashboard-users.htpasswd`
   - `portainer-admin-password`
   - `n8n-db-password`
   - `n8n-encryption-key`

2. **Set permissions**:
   ```bash
   sudo chmod 600 /home/comzis/apps/secrets/*
   ```

3. **Rotate credentials**: If any secrets were previously committed to Git, rotate them immediately.

### Image Digest Pinning (Optional)

See `docs/image-pinning-guide.md` for converting version tags to digest references.

### Admin Entrypoint Binding (Optional)

For interface-level isolation, consider binding admin services to Tailscale interface. See `docs/network-security.md` for details.

## Troubleshooting

### Compose Validation Fails

- Check `.env` file exists and has required variables
- Verify secret files exist at referenced paths
- Run: `docker compose config` to see detailed errors

### Firewall Blocks Access

- Verify UFW rules: `sudo ufw status verbose`
- Check Tailscale connectivity: `sudo tailscale status`
- Review IP allowlists in `traefik/dynamic/middlewares.yml`

### Services Won't Start

- Check logs: `sudo docker logs <service-name>`
- Verify networks exist: `sudo docker network ls`
- Check resource limits: `sudo docker stats`

## Security Checklist

- [ ] Tailnet status captured and archived
- [ ] IP allowlists updated with real `/32` addresses
- [ ] Firewall rules applied and verified
- [ ] Secrets migrated to external path (`/home/comzis/apps/secrets/`)
- [ ] All credentials rotated (if previously committed)
- [ ] Compose config validates successfully
- [ ] Stack deployed and services running
- [ ] Access control tested (403 from unauthorized IPs)
- [ ] Logs reviewed for errors
- [ ] Backup scripts tested with encryption

## Support

- Security review: `.cursor/commands/security-review.md`
- Network security: `docs/network-security.md`
- Next steps: `docs/next-steps.md`
- Image pinning: `docs/image-pinning-guide.md`

