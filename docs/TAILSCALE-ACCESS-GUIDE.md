# Tailscale Access Guide

## The Problem

When accessing `portainer.inlock.ai` from your MacBook:
- DNS resolves via public DNS (Cloudflare) → Server's public IP
- Connection goes through public internet
- Traefik sees your MacBook's **PUBLIC IP**, not Tailscale IP
- IP allowlist checks public IP → **BLOCKED** ❌

## Solution 1: Add Public IP to Allowlist (Quick Fix)

### Steps:
1. On your MacBook, find your public IP:
   ```bash
   curl ifconfig.me
   ```
   Or visit: https://ifconfig.me

2. Share the IP with the admin

3. Admin adds it to `traefik/dynamic/middlewares.yml`:
   ```yaml
   allowed-admins:
     ipAllowList:
       sourceRange:
         - "100.83.222.69/32"  # Device 1 - Tailscale IP
         - "100.96.110.8/32"    # Device 2 - Tailscale IP (MacBook)
         - "YOUR_PUBLIC_IP/32"  # MacBook public IP
   ```

4. Restart Traefik:
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

### Pros:
- ✅ Works immediately
- ✅ No Tailscale configuration needed

### Cons:
- ⚠️ Public IP can change
- ⚠️ Less secure (public IP exposed)

## Solution 2: Tailscale MagicDNS (Recommended)

Configure Tailscale to resolve `.inlock.ai` domains via Tailscale.

### Steps:
1. Go to Tailscale Admin Console: https://login.tailscale.com/admin/dns

2. Configure MagicDNS:
   - Enable MagicDNS
   - Add DNS record: `*.inlock.ai` → `100.83.222.69` (server's Tailscale IP)
   - Or configure split DNS for `.inlock.ai` domain

3. On your MacBook:
   - Tailscale will automatically use MagicDNS
   - `portainer.inlock.ai` resolves to Tailscale IP
   - Connection goes through Tailscale
   - Traefik sees Tailscale IP → **ALLOWED** ✅

### Pros:
- ✅ Most secure (all traffic via Tailscale)
- ✅ Works for all `.inlock.ai` subdomains
- ✅ No need to update allowlist

### Cons:
- ⚠️ Requires Tailscale admin access
- ⚠️ Requires DNS configuration

## Solution 3: Access via Tailscale IP Directly

Access services using the server's Tailscale IP with Host header.

### Using curl:
```bash
curl -H "Host: portainer.inlock.ai" https://100.83.222.69
```

### Using browser extension:
- Install a browser extension that allows custom Host headers
- Configure: `100.83.222.69` with Host: `portainer.inlock.ai`

### Pros:
- ✅ Works immediately
- ✅ No configuration needed

### Cons:
- ⚠️ Not user-friendly
- ⚠️ Requires browser extension or command-line

## Recommendation

**For quick access:** Use Solution 1 (add public IP)
**For production:** Use Solution 2 (Tailscale MagicDNS)



