# Cockpit Container Setup

## Overview

Cockpit is now running in a Docker container instead of on the host system. This provides better integration with Traefik and eliminates network connectivity issues.

## Configuration

### Docker Compose Service

**File**: `compose/stack.yml`

```yaml
cockpit:
  image: quay.io/cockpit/ws:latest
  restart: always
  network_mode: host  # Required for full system access
  environment:
    - COCKPIT_WS_PORT=9090
  healthcheck:
    test: ["CMD", "wget", "--spider", "-q", "http://localhost:9090"]
    interval: 30s
    timeout: 5s
    retries: 3
  cap_add:
    - SYS_ADMIN
    - NET_ADMIN
  security_opt:
    - no-new-privileges:false  # Required for system management
```

### Traefik Service

**File**: `traefik/dynamic/services.yml`

```yaml
cockpit:
  loadBalancer:
    servers:
      - url: http://156.67.29.52:9090  # Host IP (since using host network)
```

### Traefik Router

**File**: `traefik/dynamic/routers.yml`

```yaml
cockpit:
  entryPoints:
    - websecure
  rule: Host(`cockpit.inlock.ai`)
  middlewares:
    - secure-headers
    - allowed-admins
  service: cockpit
  tls:
    certResolver: le-dns
```

## Why Host Network Mode?

Cockpit needs to manage the host system, which requires:
- Access to systemd
- Access to network interfaces
- Access to hardware resources
- Ability to execute system commands

Using `network_mode: host` gives Cockpit the necessary access while still running in a container.

## Alternative: Bridge Network (More Secure)

If you prefer better isolation, you can use bridge network mode:

```yaml
cockpit:
  image: quay.io/cockpit/ws:latest
  restart: always
  networks:
    - edge
  volumes:
    - /:/host:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /sys:/sys:ro
    - /proc:/proc:ro
  ports:
    - "127.0.0.1:9090:9090"
  # ... rest of config
```

Then update Traefik service to:
```yaml
cockpit:
  loadBalancer:
    servers:
      - url: http://cockpit:9090
```

**Note**: Bridge network mode may limit some Cockpit features that require direct host access.

## Benefits of Containerization

1. ✅ **No Network Issues**: Uses Docker service networking
2. ✅ **Consistent Management**: Same pattern as other services
3. ✅ **Easy Updates**: `docker compose pull cockpit && docker compose up -d cockpit`
4. ✅ **Better Isolation**: Still isolated from other containers
5. ✅ **Health Checks**: Built-in health monitoring
6. ✅ **Logging**: Integrated with Docker logging

## Access

**URL**: `https://cockpit.inlock.ai`

**Access Control**:
- IP allowlist: Tailscale IPs and server IP (156.67.29.52)
- TLS: Automatic via Let's Encrypt
- Security headers: Applied

## Management

### Start/Stop
```bash
docker compose -f compose/stack.yml --env-file .env up -d cockpit
docker compose -f compose/stack.yml --env-file .env stop cockpit
```

### View Logs
```bash
docker logs compose-cockpit-1
docker logs compose-cockpit-1 --follow
```

### Update
```bash
docker compose -f compose/stack.yml --env-file .env pull cockpit
docker compose -f compose/stack.yml --env-file .env up -d cockpit
```

### Health Check
```bash
docker ps | grep cockpit
curl http://localhost:9090
```

## Troubleshooting

### Container Not Starting
```bash
docker logs compose-cockpit-1
docker inspect compose-cockpit-1
```

### Cannot Access via Traefik
1. Check container is running: `docker ps | grep cockpit`
2. Check Traefik logs: `docker logs compose-traefik-1 | grep cockpit`
3. Test direct access: `curl http://localhost:9090`
4. Verify router: `docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml | grep cockpit`

### Permission Issues
Cockpit needs elevated privileges. If features don't work:
- Verify `cap_add` includes `SYS_ADMIN` and `NET_ADMIN`
- Check `security_opt: no-new-privileges:false`
- Review container logs for permission errors

## Security Considerations

⚠️ **Host Network Mode**: Using `network_mode: host` reduces container isolation. Cockpit has access to the entire host network stack.

**Mitigations**:
- IP allowlist via Traefik middleware
- TLS encryption
- Security headers
- Regular updates
- Monitor access logs

## Migration from Host Service

If you previously ran Cockpit on the host:

### Automated Migration

Run the migration script:
```bash
sudo ./scripts/migrate-cockpit-to-container.sh
```

This will:
1. Stop and disable the host Cockpit service
2. Verify port 9090 is free
3. Start the Docker container
4. Test access

### Manual Migration

1. **Stop host service** (required, container needs port 9090):
   ```bash
   sudo systemctl stop cockpit.socket cockpit.service
   sudo systemctl disable cockpit.socket
   ```

2. **Verify port is free**:
   ```bash
   ss -tulpn | grep :9090  # Should return nothing
   ```

3. **Start container**:
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d cockpit
   ```

4. **Verify container is running**:
   ```bash
   docker ps | grep cockpit
   docker logs compose-cockpit-1
   ```

5. **Test access**:
   ```bash
   curl -k -I https://cockpit.inlock.ai
   ```

The containerized version provides the same functionality with better integration.

