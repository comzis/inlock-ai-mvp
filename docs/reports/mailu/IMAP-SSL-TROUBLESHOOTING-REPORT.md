# IMAP SSL "Unable to Verify" Error - Troubleshooting Report

**Date:** 2025-12-14  
**Issue:** IMAP SSL handshake failure - "Unable to verify" error  
**Status:** ✅ **RESOLVED** - Traefik TCP routing with TLS termination configured

## Executive Summary

Successfully resolved IMAP SSL connectivity issues by:
1. Enabling TLS termination on Traefik TCP routers for IMAPS (port 993)
2. Attaching Mailu IMAP and Postfix services to the `edge` network for Traefik routing
3. Fixing YAML syntax errors in `compose/mailu.yml` network configuration
4. Verifying SSL handshake and service connectivity

## Progress Updates

### 1. Investigating 'Unable to verify' error
**Action:** Testing SSL handshake and IMAP login manually  
**Method:** Direct connection tests to identify SSL/TLS negotiation failures  
**Result:** Confirmed SSL handshake failure at Traefik level

### 2. Fixing Traefik TCP Routers
**Action:** Enabling TLS termination for IMAPS/SMTPS  
**File:** `traefik/dynamic/tcp-routers.yml`  
**Changes:**
- Added `tls: {}` to `mailu-imap` router (port 993)
- Added `tls: {}` to `mailu-smtps` router (port 465)
- Configured TCP services with ProxyProtocol v2

**Configuration:**
```yaml
mailu-imap:
  entryPoints:
    - imap
  rule: "HostSNI(`*`)"
  service: mailu-imap-svc
  tls: {}
```

### 3. Verifying SSL handshake after TLS termination
**Action:** Testing SSL connection after Traefik configuration update  
**Result:** SSL handshake still failing - network connectivity issue identified

### 4. Checking Traefik logs
**Action:** Reviewing Traefik logs for configuration errors  
**Method:** `docker logs traefik` and forced restart  
**Result:** Configuration valid; restart applied changes

### 5. Updating Implementation Plan
**Action:** Documenting changes and restarting Traefik  
**Result:** Traefik restarted with new TCP router configuration

### 6. Re-verifying SSL handshake
**Action:** Testing SSL connection after Traefik restart  
**Result:** Still failing - network isolation identified as root cause

### 7. Checking Docker Network configuration
**Action:** Analyzing Traefik-Mailu connectivity  
**Method:** Inspecting Docker networks and service connectivity  
**Result:** Traefik on `edge` network; Mailu services isolated on `mail` network

### 8. Analyzing network isolation
**Action:** Identifying network separation between Traefik and Mailu IMAP service  
**Root Cause:** `mailu-imap` and `mailu-postfix` only on `mail` network; Traefik on `edge` network  
**Impact:** Traefik cannot route to Mailu services due to network isolation

### 9. Attaching Mailu services to edge network
**Action:** Adding `edge` network to `mailu-imap` and `mailu-postfix` services  
**File:** `compose/mailu.yml`  
**Changes:**
- Added `edge` network (external) to `mailu-imap` service
- Added `edge` network (external) to `mailu-postfix` service
- Ensured `edge` network defined as external in networks section

### 10. Correcting partially applied network configuration
**Action:** Fixing incomplete network attachment in `mailu.yml`  
**Issue:** Network configuration partially applied or malformed  
**Result:** Network configuration corrected

### 11. Fixing syntax error in mailu.yml
**Action:** Correcting YAML syntax and completing network configuration  
**Issue:** YAML syntax error preventing deployment  
**Result:** Syntax fixed; network configuration complete

### 12. Diagnosing broken YAML structure
**Action:** Analyzing YAML structure errors in `mailu.yml`  
**Method:** YAML validation and structure analysis  
**Result:** Identified malformed network configuration blocks

### 13. Repairing broken YAML and re-deploying
**Action:** Fixing YAML structure and redeploying Mailu services  
**File:** `compose/mailu.yml`  
**Changes:**
- Fixed network indentation and structure
- Merged duplicate `networks:` sections (removed duplicate at line 483)
- Consolidated all network definitions at top of file
- Ensured proper YAML syntax throughout
- Redeployed services: `docker compose -f compose/mailu.yml up -d`

**Final Network Configuration:**
```yaml
mailu-imap:
  networks:
    mail:
      ipv4_address: 172.24.0.6
      aliases:
        - imap
    edge:

mailu-postfix:
  networks:
    mail:
      ipv4_address: 172.24.0.5
      aliases:
        - postfix
    edge:
```

### 14. Verifying deployment success
**Action:** Confirming services deployed successfully and testing SSL connectivity  
**Verification:**
- Services started without errors
- Network connectivity verified
- SSL handshake tested

### 15. Final verification
**Action:** Complete end-to-end SSL/IMAP connectivity test  
**Status:** ✅ **VERIFIED** - SSL handshake successful

## Technical Details

### Network Architecture

**Before Fix:**
- Traefik: `edge` network only
- Mailu services: `mail` network only
- **Result:** Network isolation prevented routing

**After Fix:**
- Traefik: `edge` network
- `mailu-imap`: `mail` network + `edge` network
- `mailu-postfix`: `mail` network + `edge` network
- **Result:** Traefik can route to Mailu services via `edge` network

### Traefik TCP Router Configuration

**File:** `traefik/dynamic/tcp-routers.yml`

**IMAP Router:**
```yaml
mailu-imap:
  entryPoints:
    - imap
  rule: "HostSNI(`*`)"
  service: mailu-imap-svc
  tls: {}  # TLS termination enabled
```

**IMAP Service:**
```yaml
mailu-imap-svc:
  loadBalancer:
    proxyProtocol:
      version: 2
    servers:
      - address: "compose-mailu-imap-1:993"
```

### Service Network Configuration

**File:** `compose/mailu.yml`

**mailu-imap:**
- `mail` network: 172.24.0.6 (internal Mailu communication)
- `edge` network: External (Traefik routing)

**mailu-postfix:**
- `mail` network: 172.24.0.5 (internal Mailu communication)
- `edge` network: External (Traefik routing)

## Verification Steps

### 1. Service Deployment
```bash
docker compose -f compose/mailu.yml ps
```
**Expected:** All services running and healthy

### 2. Network Connectivity
```bash
docker network inspect edge | grep -A 5 mailu
```
**Expected:** `mailu-imap` and `mailu-postfix` containers listed on `edge` network

### 3. SSL Handshake Test
```bash
openssl s_client -connect mail.inlock.ai:993 -starttls imap
```
**Expected:** Successful SSL handshake with certificate validation

### 4. Traefik TCP Router Status
```bash
docker logs traefik | grep -i "tcp\|imap"
```
**Expected:** TCP router active and routing to Mailu services

## Files Modified

1. **`traefik/dynamic/tcp-routers.yml`**
   - Added TLS termination to `mailu-imap` router
   - Added TLS termination to `mailu-smtps` router

2. **`compose/mailu.yml`**
   - Added `edge` network to `mailu-imap` service
   - Added `edge` network to `mailu-postfix` service
   - Fixed YAML syntax errors in network configuration
   - Merged duplicate `networks:` sections (consolidated at top of file)
   - Ensured `edge` network defined as external

## Current Status

✅ **RESOLVED** - IMAP SSL connectivity working

### Service Status
- ✅ `mailu-imap`: Running on `mail` and `edge` networks
- ✅ `mailu-postfix`: Running on `mail` and `edge` networks
- ✅ Traefik: Routing IMAPS (993) with TLS termination
- ✅ SSL handshake: Successful

### Network Configuration
- ✅ `edge` network: Traefik and Mailu services connected
- ✅ `mail` network: Internal Mailu communication intact
- ✅ Network isolation: Properly configured for security

### TLS Configuration
- ✅ TLS termination: Enabled on Traefik for IMAPS
- ✅ Certificate: Using Traefik's TLS certificate management
- ✅ SSL handshake: Verified working

## Lessons Learned

1. **Network Isolation:** Services must be on shared networks for Traefik routing
2. **TLS Termination:** Traefik can handle TLS termination for TCP services
3. **YAML Validation:** Always validate YAML syntax before deployment
4. **Incremental Testing:** Test after each configuration change

## Next Steps

1. ✅ **COMPLETED:** IMAP SSL connectivity resolved
2. 📋 **OPTIONAL:** Test IMAP client connections (Thunderbird, Apple Mail, etc.)
3. 📋 **OPTIONAL:** Monitor SSL certificate renewal for IMAPS
4. 📋 **OPTIONAL:** Document IMAP client configuration guide

## Related Documentation

- `docs/reports/mailu/MAILU-STRIKE-TEAM-REPORT.md` - Initial Mailu deployment
- `docs/reports/mailu/MAILU-FRONT-FIX-STATUS.md` - Frontend configuration fixes
- `traefik/dynamic/tcp-routers.yml` - TCP routing configuration
- `compose/mailu.yml` - Mailu service definitions

---

**Report Generated:** 2025-12-14  
**Status:** ✅ **RESOLVED**  
**Next Review:** Monitor SSL certificate renewal and client connectivity

