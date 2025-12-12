# Cockpit Access Solution

## Issue
Cockpit is configured correctly but returning HTTP 403 (Forbidden) due to IP allowlist restrictions.

## Root Cause
Cockpit router is working, but the `allowed-admins` middleware is blocking access because your current IP is not in the allowlist.

**Recent access attempts show IP**: `23.27.145.205` (not in allowlist)

## Solution Options

### Option 1: Access via Tailscale (Recommended)
Connect via Tailscale VPN and access from one of these IPs:
- `100.83.222.69` (Tailscale Server)
- `100.96.110.8` (Tailscale MacBook)

Then visit: `https://cockpit.inlock.ai`

### Option 2: Add Your IP to Allowlist
If you need temporary access from your current IP:

```bash
cd /home/comzis/inlock-infra
./scripts/add-cockpit-ip.sh 23.27.145.205 "Temporary access"
```

This will:
1. Add your IP to the allowlist
2. Restart Traefik
3. Allow immediate access

### Option 3: Check Your Current IP
Find your current IP and verify if it matches any in the allowlist:

```bash
# Your current public IP
curl -s ifconfig.me

# Check if it's in allowlist
grep -A 10 "allowed-admins:" traefik/dynamic/middlewares.yml | grep "sourceRange:" -A 10
```

## Current Configuration

### Router
- **URL**: `https://cockpit.inlock.ai`
- **Service**: `http://172.20.0.1:9090` (host Cockpit)
- **Middlewares**: `secure-headers`, `allowed-admins`, `mgmt-ratelimit`

### Allowed IPs
- `100.83.222.69/32` - Tailscale Server
- `100.96.110.8/32` - Tailscale MacBook
- `31.10.147.220/32` - MacBook public IPv4
- `172.71.147.142/32` - MacBook public IPv4 (alternate)
- `172.71.146.180/32` - MacBook public IPv4 (alternate)

## Verification

Test access:
```bash
# Should return 200 or 302 (not 403) when accessed from allowed IP
curl -k -I https://cockpit.inlock.ai
```

## Troubleshooting

### Still getting 403 after adding IP
1. Verify IP was added correctly:
   ```bash
   grep "23.27.145.205" traefik/dynamic/middlewares.yml
   ```

2. Restart Traefik:
   ```bash
   docker restart compose-traefik-1
   ```

3. Check Traefik logs:
   ```bash
   docker logs compose-traefik-1 | grep cockpit | tail -5
   ```

### Getting 502/503
- Cockpit service may not be running
- Network connectivity issue
- Check: `systemctl status cockpit.socket`

### Getting 404
- Router not configured
- Check: `docker exec compose-traefik-1 cat /etc/traefik/dynamic/routers.yml | grep cockpit`

## Quick Fix Script

Run the test script:
```bash
./scripts/test-cockpit-access.sh
```

This will show:
- Cockpit service status
- Port listening status
- Traefik configuration
- Access test results

## Security Note

Cockpit requires IP allowlist access for security. Only add temporary IPs if necessary, and remove them after use.

