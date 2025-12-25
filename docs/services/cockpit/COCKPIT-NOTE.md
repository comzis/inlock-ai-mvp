# Cockpit Configuration Note

**Date:** 2025-12-08

## Status

- ✅ **Router:** Configured in `traefik/dynamic/routers.yml`
- ✅ **Service:** Configured in `traefik/dynamic/services.yml`
- ✅ **Access Control:** IP allowlist middleware applied
- ⚠️ **Container:** Not deployed (image issue)

## Issue

The Cockpit Docker image `cockpit/ws:latest` doesn't exist. Cockpit is typically installed as a system service on the host, not as a container.

## Options

### Option 1: Use System Cockpit (Recommended)

If Cockpit is installed on the host system:

1. Ensure Cockpit is installed: `sudo apt install cockpit` (or equivalent)
2. Configure Cockpit to listen on the mgmt network interface
3. Update Traefik service to point to host Cockpit:
   ```yaml
   # In traefik/dynamic/services.yml
   cockpit:
     loadBalancer:
       servers:
         - url: http://HOST_IP:9090  # Replace with actual host IP on mgmt network
   ```

### Option 2: Find Correct Container Image

If a Cockpit container image exists:
- Search Docker Hub for official Cockpit images
- Update `compose/stack.yml` with correct image name
- Uncomment the cockpit service definition

### Option 3: Remove Cockpit

If Cockpit is not needed:
1. Remove DNS record in Cloudflare
2. Remove router from `traefik/dynamic/routers.yml`
3. Remove service from `traefik/dynamic/services.yml`

## Current Configuration

The router is configured and will work once the service is available. The IP allowlist is already applied, so access will be restricted to Tailscale IPs.

**Router URL:** `https://cockpit.inlock.ai`  
**Access Control:** IP allowlist (Tailscale IPs only)  
**Status:** Router ready, service pending

