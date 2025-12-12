# Cockpit Access Fix

## Issue
Cockpit is installed on the host system and running on port 9090, but Traefik was returning 404 because no router was configured for `cockpit.inlock.ai`.

## Solution Applied

### 1. Added Cockpit Service to Traefik
**File**: `/home/comzis/inlock-infra/traefik/dynamic/services.yml`

Added:
```yaml
cockpit:
  loadBalancer:
    servers:
      - url: http://172.20.0.1:9090  # Host Cockpit via Docker network gateway
```

### 2. Added Cockpit Router to Traefik
**File**: `/home/comzis/inlock-infra/traefik/dynamic/routers.yml`

Added:
```yaml
cockpit:
  entryPoints:
    - websecure
  rule: Host(`cockpit.inlock.ai`)
  middlewares:
    - secure-headers
    - allowed-admins
    - mgmt-ratelimit
  service: cockpit
  tls:
    certResolver: le-dns
```

### 3. Restarted Traefik
Traefik was restarted to load the new configuration.

## Access

**URL**: `https://cockpit.inlock.ai`

**Access Control**:
- IP allowlist: Tailscale IPs only (via `allowed-admins` middleware)
- Rate limiting: Applied
- TLS: Automatic via Let's Encrypt

## Verification

Test access:
```bash
curl -k -I https://cockpit.inlock.ai
# Should return 200 or 302 (redirect to login)
```

## Troubleshooting

### If still getting 404

1. **Check Traefik configuration**:
   ```bash
   docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml | grep -A 10 cockpit
   ```

2. **Check Cockpit is running**:
   ```bash
   systemctl status cockpit.socket
   curl http://localhost:9090
   ```

3. **Check network connectivity**:
   ```bash
   docker exec compose-traefik-1 wget -qO- http://172.20.0.1:9090
   ```

4. **Check Traefik logs**:
   ```bash
   docker logs compose-traefik-1 | grep cockpit
   ```

### If getting 502/503

- Cockpit service may not be running on host
- Network connectivity issue between Traefik and host
- Check firewall rules

### Start Cockpit Service

If Cockpit service is not running:
```bash
sudo systemctl start cockpit
sudo systemctl enable cockpit
```

## Notes

- Cockpit runs on the **host system** (not in Docker)
- Accessible via Docker network gateway IP (172.20.0.1)
- Requires Tailscale IP for access (IP allowlist)
- Uses system authentication (Linux user accounts)

