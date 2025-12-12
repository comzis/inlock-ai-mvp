# Coolify Proxy Port Conflict Fix

## Problem
Coolify proxy cannot start because port 80 is already in use by the main Traefik instance.

**Error:** `Port 80 is in use. You must stop the process using this port.`

## Root Cause
- Main Traefik (compose-traefik-1) is using ports 80 and 443
- Coolify's proxy also wants to use ports 80 and 443
- Both cannot bind to the same ports

## Solution

Since Traefik is already handling reverse proxy duties and routing to Coolify at `https://deploy.inlock.ai`, we have two options:

### Option 1: Change Coolify Proxy Ports (Applied)

Modified `/data/coolify/proxy/docker-compose.yml` to use:
- Port 8081 instead of 80 (HTTP)
- Port 8444 instead of 443 (HTTPS)

**Note:** This means Coolify's proxy won't handle standard HTTP/HTTPS traffic, but since Traefik is already doing that, this is acceptable.

### Option 2: Disable Coolify Proxy (Alternative)

If Coolify doesn't require its proxy for core functionality:
1. Don't start the proxy in Coolify UI
2. Continue using Traefik for all routing

## Current Configuration

**Main Traefik:**
- Ports: 80 (HTTP), 443 (HTTPS)
- Routes: All services including Coolify
- Access: `https://deploy.inlock.ai`

**Coolify Proxy (if started):**
- Ports: 8081 (HTTP), 8444 (HTTPS)  
- Purpose: Managed by Coolify for applications it deploys
- Note: May not be needed if Traefik handles all routing

## Verification

After modifying the proxy config, try starting the proxy again in Coolify UI. It should start without port conflicts.

## Recommendation

Since Traefik is already handling reverse proxy and SSL termination, you can:
1. **Leave Coolify proxy stopped** - Traefik handles everything
2. **Or start Coolify proxy on alternate ports** - For Coolify-managed applications (if needed)

The server validation should work regardless of proxy status.
