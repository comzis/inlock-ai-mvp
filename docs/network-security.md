# Network Security Configuration

## Firewall (UFW)

The infrastructure uses UFW (Uncomplicated Firewall) configured via Ansible hardening role with the following rules:

### Default Policies
- **Incoming**: Deny all (default deny)
- **Outgoing**: Allow all
- **Routed**: Allow all

### Allowed Ports
- **UDP 41641**: Tailscale mesh VPN
- **TCP 22**: SSH (consider restricting to Tailscale subnet)
- **TCP 80**: HTTP (Traefik redirects to HTTPS)
- **TCP 443**: HTTPS (Traefik)

### Configuration
Firewall rules are applied automatically via `ansible-playbook playbooks/hardening.yml`. The hardening role:
1. Installs UFW if not present
2. Resets to defaults
3. Sets deny-by-default policy
4. Opens required ports
5. Enables UFW

### Manual Verification
```bash
sudo ufw status verbose
```

## Traefik IP Allowlists

Admin services (Traefik dashboard, Portainer) are protected by IP allowlist middlewares configured in `traefik/dynamic/middlewares.yml`:

- **Tailscale Range**: `100.64.0.0/10` (CGNAT range - replace with specific node IPs)
- **Private Admin CIDRs**: `10.0.0.0/8` (replace with your actual admin subnet)

### Updating Allowlists
1. Edit `traefik/dynamic/middlewares.yml`
2. Replace placeholder CIDRs with actual admin IP ranges
3. For Tailscale, use specific node IPs (e.g., `100.x.x.x/32`) instead of the full range
4. Restart Traefik or wait for file watch to reload

## Optional: Admin Entrypoint Binding

For enhanced security, admin services can be bound exclusively to the Tailscale interface:

1. **Add admin entrypoint** in `traefik/traefik.yml`:
   ```yaml
   admin:
     address: 100.x.x.x:8443  # Replace with tailscale0 IP
     http:
       tls:
         options: default
   ```

2. **Update router rules** in `traefik/dynamic/routers.yml` to use `admin` entrypoint instead of `websecure`

3. **Configure Docker network** to bind Traefik to tailscale0 interface (requires host network mode or custom network setup)

**Note**: Current approach using IP allowlists + firewall provides strong protection while maintaining flexibility. Interface binding is optional for defense-in-depth.

## Tailscale Integration

- **SSH**: Configured to accept connections via Tailscale (`tailscale up --ssh`)
- **Admin Access**: All management interfaces should be accessed via Tailscale VPN
- **Device Posture**: Ensure Tailscale ACLs restrict access to authorized devices only

## Network Isolation

Services are isolated across Docker networks:
- **edge**: Public-facing services (Traefik, homepage)
- **mgmt**: Management tools (Portainer, Traefik dashboard)
- **internal**: Backend services (Postgres, Redis) - internal only
- **socket-proxy**: Docker socket proxy communication

## Backup Security

Backup scripts (`scripts/backup-volumes.sh`) should:
- Encrypt backups before transmission
- Use Tailscale or WireGuard for secure transport
- Store backups on encrypted storage with retention policies
- Never expose backup endpoints publicly

