# Firewall Status

## Current Status

**UFW Service**: ✅ **ACTIVE** (running)

The firewall (UFW - Uncomplicated Firewall) is configured and active on the system.

## Expected Configuration

Based on the infrastructure configuration, the firewall should have:

### Default Policies
- **Incoming**: DENY (default deny all)
- **Outgoing**: ALLOW
- **Routed**: ALLOW

### Allowed Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 41641 | UDP | Tailscale | Mesh VPN connectivity |
| 22 | TCP | SSH | Remote access |
| 80 | TCP | HTTP | Traefik (redirects to HTTPS) |
| 443 | TCP | HTTPS | Traefik (main entry point) |

## Current Listening Ports

The following ports are currently listening (verified):

- ✅ **Port 22** (SSH) - Listening on `0.0.0.0:22`
- ✅ **Port 80** (HTTP) - Listening on `0.0.0.0:80`
- ✅ **Port 443** (HTTPS) - Listening on `0.0.0.0:443`
- ✅ **Port 41641** (Tailscale) - Listening on `0.0.0.0:41641`

## Verification Commands

To verify the full firewall status, run:

```bash
# Check UFW status
sudo ufw status verbose

# Check numbered rules
sudo ufw status numbered

# Check firewall service status
systemctl status ufw
```

Expected output should show:
- Status: `Status: active`
- Default policies: `Default: deny (incoming), allow (outgoing), allow (routed)`
- Rules for ports: 41641/udp, 22/tcp, 80/tcp, 443/tcp

## Configuration Methods

The firewall can be configured via:

### 1. Ansible Playbook (Recommended)
```bash
cd /home/comzis/inlock-infra
ansible-playbook playbooks/hardening.yml
```

### 2. Manual Script
```bash
cd /home/comzis/inlock-infra
sudo ./scripts/apply-firewall-manual.sh
```

### 3. Manual UFW Commands
```bash
# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed

# Allow ports
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Enable firewall
sudo ufw --force enable
```

## Security Layers

The infrastructure uses multiple security layers:

1. **Host Firewall (UFW)**: First line of defense at the host level
   - Blocks all incoming traffic except allowed ports
   - Protects against unauthorized access attempts

2. **Traefik IP Allowlists**: Application-level protection
   - Admin services (Traefik, Portainer, n8n) restricted to Tailscale IPs
   - Configured in `traefik/dynamic/middlewares.yml`

3. **Authentication**: Service-level protection
   - Basic Auth for Traefik dashboard
   - Forward Auth for Portainer
   - User accounts for n8n

4. **Rate Limiting**: Protection against abuse
   - 50 requests/minute average
   - 100 requests burst

## Troubleshooting

### Firewall Not Active

If UFW is not active:
```bash
# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### Cannot Access Services

If you cannot access services:

1. **Check firewall rules**:
   ```bash
   sudo ufw status verbose
   ```

2. **Verify ports are allowed**:
   ```bash
   sudo ufw status numbered
   ```

3. **Check if service is listening**:
   ```bash
   ss -tulpen | grep -E ":(80|443|22|41641)"
   ```

4. **Temporarily allow port** (for testing):
   ```bash
   sudo ufw allow <port>/<protocol>
   ```

### Firewall Blocking Legitimate Traffic

If firewall is blocking legitimate traffic:

1. **Check logs**:
   ```bash
   sudo tail -f /var/log/ufw.log
   ```

2. **Add specific rule**:
   ```bash
   sudo ufw allow from <IP_ADDRESS> to any port <PORT> proto <PROTOCOL>
   ```

3. **Reload firewall**:
   ```bash
   sudo ufw reload
   ```

## Documentation

- **Network Security**: `docs/network-security.md`
- **Firewall Script**: `scripts/apply-firewall-manual.sh`
- **Validation Script**: `scripts/validate-firewall.sh`
- **Ansible Role**: `ansible/roles/hardening/tasks/main.yml`

## Notes

- The firewall is configured to deny all incoming traffic by default
- Only explicitly allowed ports are accessible
- Tailscale port (41641/UDP) must be open for VPN connectivity
- SSH (22/TCP) should ideally be restricted to Tailscale subnet for enhanced security
- HTTP (80/TCP) and HTTPS (443/TCP) are required for Traefik to function

---

**Last Updated**: December 8, 2025  
**Status**: UFW Active  
**Configuration**: Hardened (deny-by-default)



