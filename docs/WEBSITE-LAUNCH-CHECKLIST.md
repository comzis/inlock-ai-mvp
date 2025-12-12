# Website Launch Checklist - inlock.ai

**Purpose**: Pre-flight checklist before pointing `inlock.ai` DNS to the hardened stack  
**Status**: Ready for review and execution

## Pre-Launch Verification

### 1. Content & SEO
- [ ] Homepage content reviewed and finalized
- [ ] Meta tags configured (title, description, Open Graph)
- [ ] SEO-friendly URLs and structure
- [ ] Sitemap.xml generated and accessible
- [ ] robots.txt configured appropriately

### 2. Analytics & Monitoring
- [ ] Analytics tracking code added (if applicable)
- [ ] Uptime monitoring configured (external service)
- [ ] Error tracking/logging configured
- [ ] Performance monitoring in place

### 3. DNS & Cloudflare Configuration
- [ ] Cloudflare DNS records verified:
  - `inlock.ai` → `156.67.29.52` (Proxy: ON for DDoS protection)
  - `www.inlock.ai` → `156.67.29.52` (Proxy: ON)
- [ ] SSL/TLS mode: Full (strict) or Full
- [ ] Caching rules configured (if needed)
- [ ] Page Rules configured (if needed)
- [ ] DNS propagation verified: `dig inlock.ai +short`

### 4. Traefik Configuration
- [ ] Router for `inlock.ai` configured in `traefik/dynamic/routers.yml`
- [ ] Router for `www.inlock.ai` configured (or redirect)
- [ ] SSL certificate resolver: `le-dns` (Let's Encrypt)
- [ ] Middlewares applied (secure-headers, rate limiting if needed)
- [ ] Service points to correct backend (homepage container)

### 5. Security Validation
- [ ] Run access control validation:
  ```bash
  ./scripts/validate-access-control.sh
  ```
- [ ] Test from public IP (non-Tailscale):
  ```bash
  curl -I https://inlock.ai
  curl -I https://www.inlock.ai
  ```
- [ ] Verify security headers present:
  ```bash
  curl -I https://inlock.ai | grep -iE "strict-transport|x-frame|x-content-type"
  ```
- [ ] Verify SSL certificate:
  ```bash
  openssl s_client -connect inlock.ai:443 -servername inlock.ai </dev/null 2>&1 | grep -E "subject=|issuer=|Verify return code"
  ```

### 6. Performance & Availability
- [ ] Homepage container healthcheck passing
- [ ] Traefik healthcheck passing
- [ ] Load testing completed (if applicable)
- [ ] CDN/caching configured (Cloudflare)
- [ ] Response times acceptable

### 7. Backup & Recovery
- [ ] Backup script tested and working
- [ ] Restore procedure documented and tested
- [ ] GPG key imported for encrypted backups
- [ ] Backup schedule configured (if automated)

## Launch Steps

### Step 1: Final Pre-Launch Check
```bash
# Verify all services healthy
docker compose -f compose/stack.yml --env-file .env ps

# Check Traefik routers
docker exec compose-traefik-1 wget -qO- http://localhost:8080/api/http/routers 2>&1 | python3 -m json.tool | grep -E "name|rule" | grep inlock

# Test homepage service
curl -I http://localhost:80 -H "Host: inlock.ai"
```

### Step 2: Update Cloudflare DNS
1. Log into Cloudflare Dashboard
2. Navigate to DNS → Records
3. Update `inlock.ai` A record:
   - Name: `inlock.ai`
   - IPv4 address: `156.67.29.52`
   - Proxy status: **ON** (orange cloud) for DDoS protection
   - TTL: Auto
4. Update `www.inlock.ai` CNAME or A record:
   - Name: `www`
   - Target: `inlock.ai` (CNAME) or `156.67.29.52` (A)
   - Proxy status: **ON**
   - TTL: Auto

### Step 3: Wait for DNS Propagation
```bash
# Check DNS propagation
dig inlock.ai +short
dig www.inlock.ai +short

# Should return: 156.67.29.52 (or Cloudflare IPs if proxied)
# Wait 5-10 minutes for global propagation
```

### Step 4: Verify SSL Certificate Issuance
```bash
# Traefik should automatically request Let's Encrypt certificate
docker logs compose-traefik-1 | grep -iE "acme.*inlock|certificate.*obtained"

# Verify certificate
openssl s_client -connect inlock.ai:443 -servername inlock.ai </dev/null 2>&1 | grep -E "subject=|issuer="

# Should show Let's Encrypt issuer
```

### Step 5: Post-Launch Validation
```bash
# Test from public network (not Tailscale)
curl -I https://inlock.ai
curl -I https://www.inlock.ai

# Verify security headers
curl -I https://inlock.ai | grep -iE "strict-transport|content-security-policy"

# Test redirects (if configured)
curl -I http://inlock.ai  # Should redirect to https://

# Check SSL Labs rating (optional)
# https://www.ssllabs.com/ssltest/analyze.html?d=inlock.ai
```

### Step 6: Monitor Initial Traffic
- [ ] Check Traefik access logs: `docker logs compose-traefik-1 --tail 100`
- [ ] Monitor Grafana dashboards for traffic patterns
- [ ] Check for any errors in container logs
- [ ] Verify analytics tracking (if configured)

## Rollback Plan

If issues occur after DNS cutover:

1. **Immediate Rollback**: Update Cloudflare DNS to point to previous server/IP
2. **Investigate**: Check Traefik logs, container status, SSL certificate status
3. **Fix Issues**: Address any configuration problems
4. **Re-test**: Validate fixes before re-attempting cutover

## Post-Launch Tasks

- [ ] Monitor for 24-48 hours for stability
- [ ] Set up automated alerts (if not already configured)
- [ ] Document any issues encountered and resolutions
- [ ] Update monitoring dashboards with production metrics
- [ ] Schedule regular backup verification

## Notes

- **Cloudflare Proxy**: Keep ON (orange cloud) for DDoS protection and CDN benefits
- **SSL Mode**: Use "Full (strict)" if using Let's Encrypt, or "Full" if using self-signed certs
- **Rate Limiting**: Consider adding rate limiting middleware for public endpoints
- **Monitoring**: Ensure Grafana/Prometheus dashboards are accessible for post-launch monitoring

---

**Last Updated**: 2025-12-09  
**Status**: Ready for execution









