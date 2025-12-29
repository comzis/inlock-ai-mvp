# Portainer & Cloudflare Setup Guide

**Date:** December 28, 2025  
**Issue:** Portainer returning 403 Forbidden due to Cloudflare proxy configuration

---

## 🔍 Problem Analysis

### Current Issue
Portainer is returning **403 Forbidden** errors when accessed via `https://portainer.inlock.ai`.

### Root Cause
1. **Cloudflare Proxy is ON** (orange cloud) for `portainer.inlock.ai`
2. When Cloudflare proxy is ON, Traefik sees **Cloudflare IPs** (e.g., `104.28.130.5`) instead of real client IPs
3. The IP allowlist middleware `allowed-admins` only allows:
   - Tailscale IPs (`100.64.0.0/10`, specific `/32` addresses)
   - Docker networks (`172.18.0.0/16`, `172.20.0.0/16`)
4. **Cloudflare IPs are NOT in the allowlist**, so requests are blocked

### Evidence
From Traefik logs:
```json
{
  "ClientAddr": "104.28.130.5:54578",  // Cloudflare IP, not real client
  "RequestHost": "portainer.inlock.ai",
  "DownstreamStatus": 403,  // Blocked by IP allowlist
  "RouterName": "portainer@file"
}
```

---

## ✅ Solution Options

### Option 1: Turn Cloudflare Proxy OFF (Recommended for Admin Services)

**Best for:** Admin services that require IP-based access control

**Steps:**
1. Log into Cloudflare Dashboard
2. Go to DNS settings for `inlock.ai`
3. Find `portainer.inlock.ai` A record
4. Click the **orange cloud** icon to turn it **gray** (proxy OFF)
5. Wait 1-2 minutes for DNS propagation
6. Test access: `https://portainer.inlock.ai`

**Pros:**
- ✅ Traefik sees real client IPs
- ✅ IP allowlist middleware works correctly
- ✅ Better security (direct connection)
- ✅ No additional configuration needed

**Cons:**
- ⚠️ No Cloudflare DDoS protection
- ⚠️ No Cloudflare caching
- ⚠️ Real server IP exposed in DNS

**Note:** This is the recommended approach for admin services that use IP allowlists.

---

### Option 2: Use Cloudflare WAF Rules (Keep Proxy ON)

**Best for:** When you want Cloudflare protection but need IP filtering

**Steps:**
1. Keep Cloudflare proxy ON (orange cloud)
2. Go to Cloudflare Dashboard → Security → WAF
3. Create a WAF rule:
   - **Rule Name:** Allow Tailscale IPs for Portainer
   - **Expression:** `(http.host eq "portainer.inlock.ai") and (ip.src in {100.64.0.0/10 100.96.110.8 100.83.222.69})`
   - **Action:** Allow
4. Create another rule to block all other IPs:
   - **Expression:** `(http.host eq "portainer.inlock.ai") and not (ip.src in {100.64.0.0/10 100.96.110.8 100.83.222.69})`
   - **Action:** Block
5. Remove `allowed-admins` middleware from Portainer router in Traefik

**Pros:**
- ✅ Cloudflare DDoS protection
- ✅ Cloudflare caching
- ✅ Server IP hidden
- ✅ IP filtering at Cloudflare level

**Cons:**
- ⚠️ Requires Cloudflare WAF subscription (paid feature)
- ⚠️ More complex configuration
- ⚠️ Need to maintain IP list in Cloudflare

---

### Option 3: Configure Traefik to Read Real Client IP from Cloudflare Headers

**Best for:** When you want to keep proxy ON and use Traefik IP allowlist

**Steps:**
1. Keep Cloudflare proxy ON
2. Update Traefik configuration to trust Cloudflare headers
3. Configure IP allowlist to read from `CF-Connecting-IP` header

**Traefik Configuration:**
```yaml
# traefik/traefik.yml
entryPoints:
  websecure:
    forwardedHeaders:
      trustedIPs:
        - "173.245.48.0/20"    # Cloudflare IPv4
        - "103.21.244.0/22"     # Cloudflare IPv4
        - "103.22.200.0/22"    # Cloudflare IPv4
        - "103.31.4.0/22"      # Cloudflare IPv4
        - "141.101.64.0/18"    # Cloudflare IPv4
        - "108.162.192.0/18"   # Cloudflare IPv4
        - "190.93.240.0/20"    # Cloudflare IPv4
        - "188.114.96.0/20"    # Cloudflare IPv4
        - "197.234.240.0/22"   # Cloudflare IPv4
        - "198.41.128.0/17"    # Cloudflare IPv4
        - "162.158.0.0/15"     # Cloudflare IPv4
        - "104.16.0.0/13"      # Cloudflare IPv4
        - "104.24.0.0/14"      # Cloudflare IPv4
        - "172.64.0.0/13"      # Cloudflare IPv4
        - "131.0.72.0/22"      # Cloudflare IPv4
        - "2400:cb00::/32"     # Cloudflare IPv6
        - "2606:4700::/32"     # Cloudflare IPv6
        - "2803:f800::/32"     # Cloudflare IPv6
        - "2405:b500::/32"     # Cloudflare IPv6
        - "2405:8100::/32"     # Cloudflare IPv6
        - "2a06:98c0::/29"     # Cloudflare IPv6
        - "2c0f:f248::/32"     # Cloudflare IPv6
```

**Update Middleware:**
```yaml
# traefik/dynamic/middlewares.yml
allowed-admins:
  ipAllowList:
    ipStrategy:
      depth: 1
      excludedIPs:
        - "173.245.48.0/20"    # Cloudflare ranges
        # ... (all Cloudflare IPs)
    sourceRange:
      - "100.64.0.0/10"      # Tailscale
      - "100.96.110.8/32"    # Tailscale client
      - "100.83.222.69/32"   # Tailscale server
```

**Pros:**
- ✅ Cloudflare protection maintained
- ✅ Traefik IP allowlist works
- ✅ Single source of truth for IPs

**Cons:**
- ⚠️ Complex configuration
- ⚠️ Need to maintain Cloudflare IP ranges
- ⚠️ More moving parts

---

## 🎯 Recommended Solution

**For Admin Services (Portainer, Grafana, n8n, etc.):**

**✅ Use Option 1: Turn Cloudflare Proxy OFF**

**Reasoning:**
- Admin services should be accessed via Tailscale VPN anyway
- Direct connection is more secure
- Simpler configuration
- IP allowlist works immediately
- No need for Cloudflare caching on admin interfaces

**For Public Services (inlock.ai, www.inlock.ai):**

**✅ Keep Cloudflare Proxy ON**

**Reasoning:**
- Public services benefit from DDoS protection
- Caching improves performance
- CDN benefits for global users

---

## 📋 Implementation Steps (Option 1 - Recommended)

### Step 1: Check Current Cloudflare DNS Settings

1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select your domain (`inlock.ai`)
3. Go to **DNS** → **Records**
4. Find `portainer.inlock.ai` A record
5. Note if the cloud icon is **orange** (proxy ON) or **gray** (proxy OFF)

### Step 2: Turn Proxy OFF

1. Click the **orange cloud** icon next to `portainer.inlock.ai`
2. It should turn **gray** (proxy OFF)
3. Click **Save**

### Step 3: Wait for DNS Propagation

```bash
# Check DNS propagation
dig +short portainer.inlock.ai

# Should return your server's real IP (not Cloudflare IPs)
```

### Step 4: Verify Traefik Configuration

```bash
# Check Portainer router configuration
cat traefik/dynamic/routers.yml | grep -A 10 portainer

# Check IP allowlist middleware
cat traefik/dynamic/middlewares.yml | grep -A 10 allowed-admins
```

### Step 5: Test Access

1. **Connect to Tailscale VPN** on your device
2. **Verify your Tailscale IP:**
   ```bash
   tailscale ip
   # Should be: 100.96.110.8 (MacBook) or 100.83.222.69 (Server)
   ```
3. **Access Portainer:**
   - Open browser: `https://portainer.inlock.ai`
   - Should now work without 403 errors

### Step 6: Verify in Traefik Logs

```bash
# Check Traefik logs for successful access
docker logs services-traefik-1 --tail 20 | grep portainer

# Should see 200 status codes instead of 403
```

---

## 🔍 Verification Commands

### Check Cloudflare Proxy Status
```bash
# If proxy is OFF, returns real server IP
# If proxy is ON, returns Cloudflare IPs
dig +short portainer.inlock.ai
```

### Check Your Tailscale IP
```bash
tailscale ip -4
# Should match one of the allowed IPs in middlewares.yml
```

### Test Portainer Access
```bash
# From a device connected to Tailscale
curl -I https://portainer.inlock.ai

# Should return 200 or 302 (not 403)
```

### Check Traefik Logs
```bash
docker logs services-traefik-1 --tail 50 | grep -i portainer
```

---

## 📝 Current Configuration

### Traefik Router (portainer.inlock.ai)
```yaml
portainer:
  entryPoints:
    - websecure
  rule: Host(`portainer.inlock.ai`)
  middlewares:
    - secure-headers
    - admin-forward-auth      # OAuth2/Auth0
    - allowed-admins          # IP allowlist (blocks Cloudflare IPs)
    - mgmt-ratelimit          # Rate limiting
  service: portainer
  tls:
    certResolver: le-dns
```

### IP Allowlist Middleware
```yaml
allowed-admins:
  ipAllowList:
    sourceRange:
      - "100.64.0.0/10"      # Tailscale (tailnet range)
      - "100.96.110.8/32"    # Tailscale client (MacBook)
      - "100.83.222.69/32"   # Tailscale server
      - "172.18.0.0/16"      # Docker mgmt network
      - "172.20.0.0/16"      # Docker edge network
```

**Note:** Cloudflare IPs are NOT in this list, which causes 403 errors when proxy is ON.

---

## 🚨 Important Notes

1. **Security:** Admin services should always be accessed via Tailscale VPN
2. **DNS:** When proxy is OFF, the real server IP is visible in DNS
3. **SSL:** Let's Encrypt certificates still work with proxy OFF
4. **Performance:** Direct connection is faster (no Cloudflare hop)
5. **Monitoring:** Check Traefik logs regularly for access patterns

---

## 📚 Related Documentation

- **[Portainer Access Guide](PORTAINER-ACCESS.md)** - General Portainer access information
- **[Cloudflare IP Allowlist](CLOUDFLARE-IP-ALLOWLIST.md)** - Cloudflare configuration guide
- **[Network Security](../../security/network-security.md)** - Network security configuration
- **[Traefik Configuration](../../../traefik/dynamic/routers.yml)** - Traefik routing rules

---

**Last Updated:** December 28, 2025  
**Status:** Issue identified, solution documented  
**Next Action:** Turn Cloudflare proxy OFF for portainer.inlock.ai



