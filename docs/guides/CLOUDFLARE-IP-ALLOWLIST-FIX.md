# Cloudflare + IP Allowlist Fix

## Problem

When Cloudflare proxy is enabled (orange cloud 🟠), Traefik sees Cloudflare's IP instead of your real Tailscale IP, causing IP allowlist to block access.

## Solution: Turn Proxy OFF for Admin Services

### Steps

1. Go to **Cloudflare Dashboard** → **DNS** → **Records**
2. For each admin service, click the **orange cloud** to turn it **gray** (Proxy OFF):
   - `portainer.inlock.ai` → Proxy OFF ⚪
   - `traefik.inlock.ai` → Proxy OFF ⚪
   - `n8n.inlock.ai` → Proxy OFF ⚪

3. Keep proxy **ON** (orange cloud 🟠) for public services:
   - `inlock.ai` → Proxy ON 🟠
   - `www.inlock.ai` → Proxy ON 🟠

### Why This Works

- **Direct connection**: Your MacBook → Server (no Cloudflare proxy)
- **Traefik sees your Tailscale IP directly**: `100.96.110.8`
- **IP allowlist works immediately**: No X-Forwarded-For needed
- **Still get SSL/TLS**: Traefik handles encryption
- **No configuration changes needed**: IP allowlist works as-is

### Security

✅ IP allowlist still protects admin services  
✅ Tailscale VPN adds extra security layer  
✅ SSL/TLS encryption still works  
⚠️ Only lose Cloudflare DDoS protection (but Tailscale provides protection)

## Alternative: Keep Proxy ON

If you must keep Cloudflare proxy ON for admin services:

### Option 1: Cloudflare WAF Rules (Paid)
- Create WAF rule to allow only your Tailscale IPs
- Requires Cloudflare Pro plan or higher

### Option 2: Accept Limitations
- IP allowlist won't work reliably
- Use Tailscale-only access instead
- Or disable IP allowlist (less secure)

## Current Configuration

- **IP Allowlist**: Enabled on all admin services
- **Allowed IPs**: 
  - `100.83.222.69/32` (Device 1)
  - `100.96.110.8/32` (Device 2 - MacBook)
- **ipStrategy**: Configured to check X-Forwarded-For, but has limitations

## Recommendation

**Turn Cloudflare proxy OFF for admin services** - it's the simplest and most reliable solution.
