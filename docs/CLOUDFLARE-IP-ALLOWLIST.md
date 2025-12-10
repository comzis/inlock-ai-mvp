# Cloudflare IP Allowlist Strategy

## Overview

When Cloudflare proxy is **ON** (orange cloud), Traefik sees Cloudflare IPs in `X-Forwarded-For`, not real client IPs. This breaks direct IP allowlisting.

## Strategy Options

### Option 1: Gray Cloud (Recommended for Admin Services)

**When:** You want Traefik to enforce IP allowlisting directly.

**How:**
1. Set DNS records to "DNS only" (gray cloud) in Cloudflare dashboard
2. Traefik sees real client IPs directly
3. IP allowlist in `middlewares.yml` works as expected

**Pros:**
- Simple: Direct IP checking works
- No Cloudflare WAF needed
- Full control at Traefik level

**Cons:**
- No Cloudflare DDoS protection for admin services
- Real server IP exposed (use Tailscale for admin access)

**Verification:**
```bash
./scripts/verify-cloudflare-proxy.sh
```

### Option 2: Orange Cloud + Cloudflare WAF

**When:** You want Cloudflare's DDoS protection and WAF.

**How:**
1. Keep DNS records proxied (orange cloud)
2. Use Cloudflare Firewall Rules or Access for IP filtering
3. Remove IP allowlist from Traefik (or use for additional defense-in-depth)

**Pros:**
- Cloudflare DDoS protection active
- WAF rules available
- Hides origin IP

**Cons:**
- Requires Cloudflare dashboard configuration
- Less direct control at Traefik level

**Setup:**
1. Cloudflare Dashboard → Security → WAF
2. Create firewall rule: `(ip.src in {100.83.222.69 100.96.110.8 ...}) and (http.host eq "traefik.inlock.ai")`
3. Action: Allow, or use Access for MFA

### Option 3: Orange Cloud + ipStrategy (Advanced)

**When:** You must keep proxy ON but still want Traefik IP checking.

**How:**
1. Keep DNS records proxied (orange cloud)
2. Configure Traefik `ipStrategy` with Cloudflare CIDRs
3. Use `X-Forwarded-For` header depth to extract real client IP

**Pros:**
- Cloudflare protection + Traefik IP checking
- Defense-in-depth

**Cons:**
- Complex configuration
- Must maintain Cloudflare CIDR list
- `X-Forwarded-For` can be spoofed (but Cloudflare validates it)

**Setup:**

Get Cloudflare CIDRs:
```bash
./scripts/get-cloudflare-cidrs.sh
```

Update `traefik/dynamic/middlewares.yml`:
```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - "100.83.222.69/32"  # Your Tailscale IPs
      - "100.96.110.8/32"
      # ... other allowed IPs ...
  ipStrategy:
    depth: 1  # Use first IP in X-Forwarded-For (Cloudflare adds real IP)
    excludedIPs:
      # Add Cloudflare IPv4 ranges (fetch via get-cloudflare-cidrs.sh)
      - "173.245.48.0/20"
      - "103.21.244.0/22"
      # ... all Cloudflare CIDRs ...
```

**Security Note:** This relies on `X-Forwarded-For` header. While Cloudflare validates it, this is less secure than direct IP checking. Prefer Option 1 or 2.

## Current Configuration

**Admin Subdomains:**
- `traefik.inlock.ai`
- `portainer.inlock.ai`
- `n8n.inlock.ai`
- `grafana.inlock.ai`
- `deploy.inlock.ai`

**Recommendation:** Keep these **gray-clouded** (DNS only) for direct IP allowlisting.

**Public Subdomains:**
- `inlock.ai` / `www.inlock.ai` - Can be proxied (orange cloud) for DDoS protection

## Verification

Run the verification script to check proxy status:
```bash
cd /home/comzis/inlock-infra
./scripts/verify-cloudflare-proxy.sh
```

Add to cron or CI to catch accidental proxy changes:
```bash
# Check daily at 3 AM
0 3 * * * /home/comzis/inlock-infra/scripts/verify-cloudflare-proxy.sh >> /var/log/cloudflare-check.log 2>&1
```

## Troubleshooting

**Issue:** IP allowlist not working on proxied domains
- **Cause:** Traefik sees Cloudflare IPs, not real client IPs
- **Fix:** Gray-cloud the DNS record or use Cloudflare WAF

**Issue:** Can't access admin services from allowed IP
- **Check:** Run `./scripts/verify-cloudflare-proxy.sh`
- **Check:** Verify IP in `middlewares.yml` sourceRange
- **Check:** Cloudflare firewall rules if using Option 2

---

**Last Updated:** December 10, 2025  
**Related:** `docs/SECRET-MANAGEMENT.md`, `traefik/dynamic/middlewares.yml`
