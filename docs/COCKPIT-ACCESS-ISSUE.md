# Cockpit Access Issue - Network Connectivity Problem

## Current Status

**Router**: ✅ Configured correctly  
**Service**: ✅ Configured correctly  
**IP Allowlist**: ✅ Server IP (156.67.29.52) added  
**Backend Connectivity**: ❌ Traefik cannot reach Cockpit

## Problem

Traefik is getting HTTP 502/504 errors when trying to connect to Cockpit backend. The router and IP allowlist are working, but Traefik container cannot establish a connection to Cockpit running on the host.

## Attempted Solutions

1. **Gateway IP (172.20.0.1)**: Connection timeout
2. **Public IP (156.67.29.52)**: Connection timeout  
3. **host.docker.internal**: DNS resolution fails (even with `extra_hosts: host-gateway`)

## Root Cause Analysis

Cockpit is listening on `*:9090` (all interfaces) and responds to:
- `localhost:9090` ✅
- `127.0.0.1:9090` ✅
- `172.20.0.1:9090` (from host) ✅
- `156.67.29.52:9090` (from host) ✅

But Traefik container cannot connect to:
- `172.20.0.1:9090` ❌ (timeout)
- `156.67.29.52:9090` ❌ (timeout)
- `host.docker.internal:9090` ❌ (DNS resolution fails)

## Possible Causes

1. **Firewall blocking Docker network**: UFW or iptables may be blocking connections from Docker networks to port 9090
2. **Cockpit network binding**: Cockpit may be configured to only accept connections from specific interfaces
3. **Docker network isolation**: Network policy preventing container-to-host communication
4. **Cockpit service configuration**: Service may have restrictions on allowed origins

## Recommended Solutions

### Option 1: Add Firewall Rule (Quick Fix)

```bash
# Allow Docker network to access Cockpit
sudo ufw allow from 172.20.0.0/16 to any port 9090
```

Then test:
```bash
docker exec compose-traefik-1 wget -qO- --timeout=5 http://172.20.0.1:9090
```

### Option 2: Run Cockpit in Docker Container

Create a Cockpit Docker service in `compose/stack.yml`:

```yaml
cockpit:
  image: quay.io/cockpit/ws:latest
  container_name: compose-cockpit-1
  ports:
    - "127.0.0.1:9090:9090"  # Only expose to localhost
  networks:
    - edge
  restart: unless-stopped
```

Then update Traefik service to:
```yaml
cockpit:
  loadBalancer:
    servers:
      - url: http://cockpit:9090
```

### Option 3: Use Host Network Mode for Traefik (Not Recommended)

This would allow Traefik to access `localhost:9090` directly, but reduces container isolation.

### Option 4: Configure Cockpit to Accept Docker Network

Check Cockpit configuration:
```bash
cat /etc/cockpit/cockpit.conf
```

Add if needed:
```ini
[WebService]
AllowUnencrypted=true
Origins=https://cockpit.inlock.ai
```

## Current Configuration

**Router**: `cockpit.inlock.ai` → `http://172.20.0.1:9090`  
**IP Allowlist**: Includes `156.67.29.52/32`  
**Status**: HTTP 502 (Bad Gateway)

## Next Steps

1. Check firewall rules: `sudo ufw status` or `sudo iptables -L -n`
2. Test direct connection: `docker exec compose-traefik-1 wget http://172.20.0.1:9090`
3. Check Cockpit logs: `journalctl -u cockpit.service -n 50`
4. Consider Docker container approach if firewall fix doesn't work

## Temporary Workaround

Access Cockpit directly via SSH tunnel:
```bash
ssh -L 9090:localhost:9090 user@156.67.29.52
```

Then access: `http://localhost:9090`

