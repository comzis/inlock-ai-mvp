# Testing from Server vs MacBook

**Date:** 2025-12-08

## The Issue

When testing from the **server itself**, curl uses:
- `localhost` (127.0.0.1) or
- Server's public IP (156.67.29.52)

**NOT** the server's Tailscale IP (100.83.222.69)

## Why This Happens

1. **From Server:**
   - `curl https://portainer.inlock.ai` → Resolves to server's public IP
   - Connection: Server → localhost → Traefik
   - Traefik sees: `127.0.0.1` or `156.67.29.52` (public IP)
   - IP allowlist checks: ❌ Not in allowlist → 403

2. **From MacBook (Tailscale):**
   - `curl https://portainer.inlock.ai` → Resolves via Tailscale
   - Connection: MacBook → Tailscale → Server → Traefik
   - Traefik sees: `100.96.110.8` (MacBook Tailscale IP)
   - IP allowlist checks: ✅ In allowlist → 200

## Solution

**Test from your MacBook, not from the server.**

The server's Tailscale IP (100.83.222.69) IS in the allowlist, but when you test from the server itself, Traefik doesn't see that IP.

## Correct Test Method

### From MacBook (Tailscale-connected):

```bash
# On your MacBook
tailscale ip -4
# Should show: 100.96.110.8

# Test endpoints
curl -I https://portainer.inlock.ai
# Expected: HTTP 200 (not 403)
```

### From Server (for debugging only):

If you need to test from the server, you can temporarily add the server's public IP or localhost to the allowlist, but this is **NOT recommended** for production.

## Current Allowlist

- ✅ `100.83.222.69/32` - Server Tailscale IP (in allowlist)
- ✅ `100.96.110.8/32` - MacBook Tailscale IP (in allowlist)

**Note:** Server's public IP (156.67.29.52) is NOT in allowlist (correct for security).

## Recommendation

**Always test from your MacBook** to verify Tailscale access is working correctly.

The 403 responses when testing from the server are **expected behavior** - the server's public IP is not in the allowlist, which is correct for security.

