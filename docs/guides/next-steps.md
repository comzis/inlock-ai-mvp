# Security Hardening - Next Steps

## Immediate Actions Required

### 1. Capture Tailnet Posture (Privileged Session Required)
Run these commands as root/admin to gather baseline information:

```bash
# Tailscale status
sudo tailscale status --json | jq '.Peer[] | {HostName:.HostName, Online:.Online, IPs:.TailscaleIPs}' > /tmp/tailscale-peers.json

# Tailscale IP
sudo tailscale ip -4 > /tmp/tailscale-ip.txt

# Container status
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' > /tmp/containers.txt

# Firewall status
sudo ufw status verbose > /tmp/ufw-status.txt
```

**Action**: Archive these outputs for audit and use Tailscale IPs to update allowlists.

### 2. Update IP Allowlists with Real Addresses
Edit `traefik/dynamic/middlewares.yml`:

```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - 100.x.x.x/32  # Replace with actual Tailscale node IPs (one per admin device)
      - 100.y.y.y/32  # Add additional admin nodes
      # Remove placeholder ranges (100.64.0.0/10, 10.0.0.0/8) once real IPs are added
```

**Action**: 
1. Extract Tailscale IPs from step 1 outputs
2. Replace placeholder CIDRs with `/32` addresses for each admin device
3. Redeploy: `ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml`
4. Test from unauthorized IP to confirm 403 responses

### 3. Apply Firewall Hardening
Deploy UFW rules via Ansible:

```bash
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml
```

**Verification**:
```bash
# On each host, verify firewall is active
sudo ufw status verbose
```

Expected output should show:
- Default: deny (incoming), allow (outgoing, routed)
- Allowed: 41641/udp (Tailscale), 22/tcp (SSH), 80/tcp, 443/tcp

### 4. Migrate Secrets (If Not Already Done)
Secrets should be at `/home/comzis/apps/secrets/` (outside repo):

- `positive-ssl.crt` / `positive-ssl.key`
- `traefik-dashboard-users.htpasswd`
- `portainer-admin-password`
- `n8n-db-password`
- `n8n-encryption-key`

**Action**:
1. Verify secrets are at external path (not in `inlock-infra/secrets/`)
2. Ensure permissions: `chmod 600 /home/comzis/apps/secrets/*`
3. Rotate all credentials that were previously committed to Git
4. Keep only `.example` placeholders in repo

### 5. Fix n8n Router Hostname
✅ **COMPLETED**: `traefik/dynamic/routers.yml` already uses literal `n8n.inlock.ai`

However, container labels still use `${DOMAIN}` variable. Consider updating `compose/n8n.yml` labels to use literal hostname for consistency:

```yaml
- "traefik.http.routers.n8n.rule=Host(`n8n.inlock.ai`)"
```

### 6. Pin Images to Digests & Add Runtime Restrictions
**Status**: Images are version-pinned but not digest-pinned. Runtime restrictions partially applied.

**Remaining Work**:
- Convert version tags to digest references (e.g., `traefik:v3.6.4` → `traefik@sha256:...`)
- Add `user:` directives to Traefik and Portainer (currently only n8n has this)
- Ensure all services have `cap_drop: ALL` (currently n8n and homepage have this)

**Action**: See `docs/image-pinning-guide.md` for conversion steps.

### 7. Harden Backup Transport
Update `ansible/playbooks/backup.yml` and `scripts/backup-volumes.sh`:

- Encrypt `pg_dump` output before writing to disk
- Use Tailscale/WireGuard for backup transmission
- Store backups on encrypted storage
- Document restic credentials via Vault/SOPS

**Action**: Implement encryption in backup scripts and update playbook to use secure transport.

### 8. Optional: Admin Entrypoint Binding
Decide whether to bind admin services exclusively to Tailscale interface:

**Pros**: Interface-level isolation beyond IP allowlists
**Cons**: Requires host network mode or custom Docker network setup

**Action**: If implementing, uncomment admin entrypoint in `traefik/traefik.yml` and update router rules.

## Validation Checklist

After completing above steps:

- [ ] Tailscale status captured and archived
- [ ] IP allowlists updated with real `/32` addresses
- [ ] Firewall rules applied and verified (`sudo ufw status verbose`)
- [ ] Secrets migrated and rotated
- [ ] Images pinned to digests
- [ ] All services run as non-root with dropped capabilities
- [ ] Backup scripts encrypt and use secure transport
- [ ] Compose config validates: `docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config`
- [ ] Test access denial from unauthorized IPs (should return 403)

## Quick Start Commands

```bash
# 1. Capture baseline
sudo tailscale status --json | jq '.Peer[] | {HostName:.HostName, IPs:.TailscaleIPs}' > /tmp/tailscale-peers.json
sudo tailscale ip -4 > /tmp/tailscale-ip.txt

# 2. Update allowlists (edit traefik/dynamic/middlewares.yml with IPs from above)

# 3. Deploy hardening
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml

# 4. Deploy stack
ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml

# 5. Verify firewall
sudo ufw status verbose

# 6. Validate compose
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config
```

