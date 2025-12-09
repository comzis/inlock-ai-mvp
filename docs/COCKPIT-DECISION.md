# Cockpit Decision

**Date:** 2025-12-08  
**Status:** DNS record exists, router not configured

## Current State

- **DNS Record:** `cockpit.inlock.ai` → `156.67.29.52` (exists in Cloudflare)
- **Traefik Router:** Not configured
- **Service:** Not deployed
- **Access Control:** Not configured

## Decision

**Recommendation: Remove DNS Record**

### Rationale

1. **Not Configured:** No Traefik router or service exists
2. **Not Deployed:** Cockpit container/service not in Docker Compose
3. **Security:** Dangling DNS record without access control
4. **Maintenance:** Reduces attack surface and confusion

### Action Required

**Option 1: Remove DNS Record (Recommended)**
1. Go to Cloudflare Dashboard → DNS → Records
2. Find `cockpit.inlock.ai` A record
3. Delete the record
4. Document removal in this file

**Option 2: Add Router + Service (If Needed Later)**
If Cockpit is needed in the future:

1. **Add router** (`traefik/dynamic/routers.yml`):
```yaml
http:
  routers:
    cockpit:
      entryPoints:
        - websecure
      rule: Host(`cockpit.inlock.ai`)
      middlewares:
        - secure-headers
        - allowed-admins  # IP allowlist
        - mgmt-ratelimit
      service: cockpit
      tls:
        certResolver: le-dns
```

2. **Add service** (`traefik/dynamic/services.yml`):
```yaml
http:
  services:
    cockpit:
      loadBalancer:
        servers:
          - url: http://cockpit:9090  # Adjust port if needed
```

3. **Add Docker Compose service** (if deploying Cockpit):
```yaml
services:
  cockpit:
    image: cockpit/ws:latest
    # ... configuration
```

## Status

**Decision:** Remove DNS record  
**Action:** Pending manual removal in Cloudflare  
**Date:** 2025-12-08

---

**Note:** If Cockpit is needed later, this file documents how to add it properly with access control.



