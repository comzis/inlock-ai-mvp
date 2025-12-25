# Cockpit Access Fix Summary

## Current Issue

Cockpit is running on the host (port 9090) but Traefik cannot connect to it, resulting in HTTP 504 errors.

## Root Cause

Docker containers cannot establish TCP connections to the host's port 9090, even though:
- ✅ Host can access Cockpit via `localhost:9090`
- ✅ Traefik container can ping the host gateway (172.20.0.1)
- ❌ Traefik container cannot connect to `172.20.0.1:9090` (timeout)

This is likely due to iptables rules or Docker's network isolation.

## Solutions Attempted

1. **Direct Gateway IP**: Failed - connection timeout
2. **Public IP**: Failed - connection timeout  
3. **host.docker.internal**: Failed - DNS resolution issues
4. **Nginx Proxy Container**: Failed - permission issues with read-only filesystem
5. **Socat Proxy Container**: In progress

## Current Setup

- **Cockpit**: Running on host, port 9090
- **Proxy**: `cockpit-proxy` container using socat to bridge Docker network to host
- **Traefik**: Routes `cockpit.inlock.ai` → `cockpit-proxy:8080` → `172.20.0.1:9090`

## Quick Fix (Recommended)

The simplest solution is to add a firewall rule to allow Docker network access:

```bash
sudo ufw allow from 172.20.0.0/16 to any port 9090
```

Or if using iptables directly:
```bash
sudo iptables -I INPUT -s 172.20.0.0/16 -p tcp --dport 9090 -j ACCEPT
```

Then update Traefik service to use gateway IP directly:
```yaml
cockpit:
  loadBalancer:
    servers:
      - url: http://172.20.0.1:9090
```

## Alternative: Use Proxy Container

If firewall rules don't work, the socat proxy container should bridge the connection.

## Verification

After applying the fix:
```bash
# Test from Traefik container
docker exec compose-traefik-1 wget -qO- http://172.20.0.1:9090

# Test via Traefik
curl -k -I https://cockpit.inlock.ai
```

Expected: HTTP 200 or 302 (not 504)

