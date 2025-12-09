# Cloudflare IP Allowlist Configuration

## Overview

When accessing services through Cloudflare proxy, Traefik sees Cloudflare's IP addresses, not your actual client IP. To make IP allowlists work correctly, Traefik must be configured to trust `X-Forwarded-For` headers from Cloudflare.

## Configuration

### 1. Traefik EntryPoint Configuration

In `traefik/traefik.yml`, the `websecure` entrypoint is configured to trust `X-Forwarded-For` headers from Cloudflare IP ranges:

```yaml
websecure:
  address: :443
  http:
    tls:
      options: default
    forwardedHeaders:
      trustedIPs:
        # Cloudflare IPv4 ranges
        - "173.245.48.0/20"
        - "103.21.244.0/22"
        # ... (see traefik.yml for complete list)
        # Cloudflare IPv6 ranges
        - "2400:cb00::/32"
        - "2606:4700::/32"
        # ... (see traefik.yml for complete list)
```

### 2. IP Allowlist Middleware

The `allowed-admins` middleware in `traefik/dynamic/middlewares.yml` checks the `X-Forwarded-For` header (when behind a trusted proxy) for the real client IP:

```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - "100.83.222.69/32"  # Device 1 - Tailscale IP
      - "100.96.110.8/32"   # Device 2 - Tailscale IP
```

## How It Works

1. **Request Flow:**
   ```
   Your Browser (Tailscale IP: 100.83.222.69)
   → Cloudflare (adds X-Forwarded-For: 100.83.222.69)
   → Traefik (sees Cloudflare IP, but trusts X-Forwarded-For)
   → IP Allowlist checks X-Forwarded-For header
   → Access allowed ✅
   ```

2. **Without Trust Configuration:**
   - Traefik sees Cloudflare IP (not in allowlist)
   - Access denied ❌

3. **With Trust Configuration:**
   - Traefik trusts X-Forwarded-For from Cloudflare
   - IP allowlist checks X-Forwarded-For (your Tailscale IP)
   - Access allowed ✅

## Adding New IPs

To allow additional Tailscale IPs:

1. Get your Tailscale IP:
   ```bash
   tailscale ip -4
   ```

2. Edit `traefik/dynamic/middlewares.yml`:
   ```yaml
   allowed-admins:
     ipAllowList:
       sourceRange:
         - "100.83.222.69/32"  # Existing IP
         - "100.96.110.8/32"    # Existing IP
         - "YOUR_NEW_IP/32"     # Add your IP here
   ```

3. Restart Traefik:
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

## Cloudflare IP Ranges

Cloudflare publishes their IP ranges at:
- https://www.cloudflare.com/ips/
- IPv4: https://www.cloudflare.com/ips-v4
- IPv6: https://www.cloudflare.com/ips-v6

These ranges are updated periodically. The configuration in `traefik.yml` includes the major ranges as of 2024.

## Testing

Test from a Tailscale-connected device:

```bash
# Test Traefik Dashboard
curl -k -u "admin:YOUR_PASSWORD" https://traefik.inlock.ai/dashboard/

# Test Portainer
curl -k https://portainer.inlock.ai
```

Both should return content (not 403) when accessed from an allowed Tailscale IP.

## Troubleshooting

**If you get 403 Forbidden:**

1. Verify your Tailscale IP:
   ```bash
   tailscale ip -4
   ```

2. Check if IP is in allowlist:
   ```bash
   grep -A 5 "allowed-admins:" traefik/dynamic/middlewares.yml
   ```

3. Verify Cloudflare proxy is enabled:
   - Check Cloudflare dashboard
   - DNS record should have orange cloud (proxied)

4. Check Traefik logs:
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs traefik | grep -i "forwarded\|403"
   ```

**If X-Forwarded-For is not working:**

- Verify Cloudflare proxy is enabled (orange cloud in DNS)
- Check Traefik configuration has `forwardedHeaders.trustedIPs` set
- Ensure Cloudflare IP ranges are up to date

## Security Notes

- Only Cloudflare IP ranges are trusted for X-Forwarded-For
- Direct connections (bypassing Cloudflare) will use direct client IP
- IP allowlist uses `/32` (single IP) for maximum security
- Consider adding additional security layers (2FA, VPN-only access)

