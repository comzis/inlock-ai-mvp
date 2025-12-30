# Tailscale MacBook Access Test Guide

**Date:** 2025-12-08

## Overview

This guide helps you test all admin endpoints from your Tailscale-connected MacBook to verify IP allowlist is working correctly.

## Prerequisites

1. **Tailscale Connected:**
   - Open Tailscale app on MacBook
   - Verify connection status shows "Connected"
   - Your Tailscale IP should be: `100.96.110.8`

2. **Check Your Tailscale IP:**
   ```bash
   tailscale ip -4
   # Should show: 100.96.110.8
   ```

## Test Script

Run the automated test script from your MacBook:

```bash
# Copy script to MacBook or run via SSH
./scripts/test-from-tailscale-macbook.sh
```

## Manual Testing

### Test Each Endpoint

From your MacBook, test each admin endpoint:

```bash
# Traefik Dashboard (should return 401 - auth required)
curl -I https://traefik.inlock.ai/dashboard/

# Portainer (should return 200 - if healthy)
curl -I https://portainer.inlock.ai

# n8n (should return 200 - if healthy)
curl -I https://n8n.inlock.ai

# Cockpit (should return 200 or 404 - depending on service)
curl -I https://cockpit.inlock.ai

# Homepage (should return 200 - public)
curl -I https://inlock.ai
```

### Expected Results

| Endpoint | Expected Status | Meaning |
|----------|----------------|---------|
| `traefik.inlock.ai/dashboard/` | 401 | Auth required (correct) |
| `portainer.inlock.ai` | 200 | Allowed and healthy |
| `n8n.inlock.ai` | 200 | Allowed and healthy |
| `cockpit.inlock.ai` | 200 or 404 | Allowed (404 if service not running) |
| `inlock.ai` | 200 | Public access (correct) |

### Browser Testing

1. Open Safari/Chrome on your MacBook
2. Navigate to each URL:
   - `https://traefik.inlock.ai/dashboard/` → Should prompt for username/password
   - `https://portainer.inlock.ai` → Should show Portainer login/interface
   - `https://n8n.inlock.ai` → Should show n8n interface
   - `https://cockpit.inlock.ai` → Should show Cockpit or 404
   - `https://inlock.ai` → Should show homepage

## Troubleshooting

### If You Get 403 Forbidden

1. **Check Tailscale Connection:**
   ```bash
   tailscale status
   # Should show your MacBook as connected
   ```

2. **Verify Your IP:**
   ```bash
   tailscale ip -4
   # Should be: 100.96.110.8
   ```

3. **Check Allowlist:**
   - Your IP (`100.96.110.8`) should be in `traefik/dynamic/middlewares.yml`
   - Under `allowed-admins` → `sourceRange`

4. **DNS Propagation:**
   - Wait 2-3 minutes after DNS changes
   - Clear browser cache (Cmd+Shift+R)

### If You Get 404 Not Found

- Service may not be running
- Check service status: `docker compose ps`
- Check Traefik logs: `docker compose logs traefik`

### If You Get Connection Refused

- Check if Tailscale is connected
- Verify DNS resolution: `dig +short portainer.inlock.ai`
- Check firewall rules

## Test from Non-Tailscale IP (Verification)

To verify access control is working, test from a non-Tailscale IP:

```bash
# From a different network (not Tailscale)
curl -I https://portainer.inlock.ai
# Expected: HTTP/2 403 (Forbidden)
```

This confirms that non-allowed IPs are properly blocked.

## Test Results Log

After testing, document results:

```bash
# Create test log
cat > logs/validation/tailscale-macbook-test-$(date +%Y%m%d-%H%M%S).log << EOF
Tailscale MacBook Test Results
Date: $(date)
Tailscale IP: $(tailscale ip -4 2>/dev/null || echo "Not found")

Results:
- Traefik Dashboard: [STATUS]
- Portainer: [STATUS]
- n8n: [STATUS]
- Cockpit: [STATUS]
- Homepage: [STATUS]
EOF
```

## Success Criteria

✅ All admin endpoints return 200 or 401 (not 403)  
✅ Homepage returns 200 (public access)  
✅ Non-Tailscale IPs return 403 (blocked)  
✅ Tailscale IP matches allowlist  

## Next Steps

After successful testing:
1. Document results in validation logs
2. Update `docs/ACCESS-CONTROL-VALIDATION.md` with test results
3. Mark all services as verified and operational

---

**Last Updated:** 2025-12-08
