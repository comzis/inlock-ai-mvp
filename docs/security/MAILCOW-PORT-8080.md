# Mailcow Port 8080 Security

**Date:** 2026-01-03  
**Status:** Needs Decision

## Issue

Mailcow exposes port 8080 directly to the public internet, outside the main Docker stack.

**Current Setup:**
- Mailcow runs at `/home/comzis/mailcow` (separate from main stack)
- Port 8080 exposed directly (not behind Traefik)
- Service: `mailcowdockerized-nginx-mailcow-1`

## Security Concerns

1. **Direct Port Exposure:** Port 8080 accessible from internet
2. **No Traefik Integration:** Missing security headers, rate limiting
3. **No Centralized Auth:** Not behind OAuth2-Proxy
4. **Inconsistent Security:** Different security posture from other services

## Options

### Option A: Move Mailcow Behind Traefik (Recommended)

**Pros:**
- Consistent security with other services
- Security headers, rate limiting
- OAuth2/Auth0 authentication (optional)
- Centralized TLS management
- Better monitoring and logging

**Cons:**
- Requires Traefik router configuration
- May need Mailcow configuration changes
- More complex setup

**Implementation:**
1. Add Mailcow service to Traefik routers
2. Configure middleware (secure-headers, auth if needed)
3. Remove direct port 8080 exposure
4. Update Mailcow configuration if needed

**Router Configuration:**
```yaml
# In traefik/dynamic/routers.yml
mailcow:
  entryPoints:
    - websecure
  rule: Host(`mail.inlock.ai`)
  middlewares:
    - secure-headers
    # Add admin-forward-auth if admin access needed
  service: mailcow
  tls:
    certResolver: le-tls
```

### Option B: Restrict to Tailscale Subnet Only

**Pros:**
- Simple firewall rule change
- No Mailcow configuration changes
- Quick to implement

**Cons:**
- Still direct port exposure (within Tailscale)
- No security headers
- No rate limiting
- Inconsistent with other services

**Implementation:**
```bash
# Add firewall rule
sudo ufw allow from 100.64.0.0/10 to any port 8080 proto tcp comment 'Mailcow web interface (Tailscale only)'

# Verify
sudo ufw status numbered | grep 8080
```

### Option C: Add Firewall Rule with Comment (Minimal)

**Pros:**
- Very simple
- Documents the service

**Cons:**
- Still publicly accessible
- No security improvements
- Not recommended

**Implementation:**
```bash
sudo ufw allow from 100.64.0.0/10 to any port 8080 proto tcp comment 'Mailcow web interface'
```

## Recommendation

**Option A (Traefik Integration)** is recommended for:
- Security consistency
- Better access control
- Centralized management
- Future-proofing

## Current Status

Port 8080 is currently exposed. Action required to improve security.

## Next Steps

1. **Decision:** Choose option (A, B, or C)
2. **Implementation:** Apply chosen solution
3. **Verification:** Test access and functionality
4. **Documentation:** Update this document with implementation details

## Related Files

- `traefik/dynamic/routers.yml` - Traefik router configuration (if Option A)
- `/home/comzis/mailcow/` - Mailcow installation directory
- `docs/security/FIREWALL-SECURITY-STATUS-2025-12-25.md` - Firewall documentation

## Notes

- Mailcow runs outside main Docker stack
- Consider Mailcow's own authentication mechanisms
- May need to coordinate with Mailcow updates

