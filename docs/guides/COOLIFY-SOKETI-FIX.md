# Coolify Soketi Real-Time Service Fix

**Date:** December 11, 2025  
**Issue:** "WARNING: Cannot connect to real-time service" in Coolify UI

## Problem

Coolify was showing a warning about not being able to connect to the real-time service (Soketi WebSocket server).

## Root Cause

1. **Network Isolation:**
   - Coolify uses `network_mode: host` (runs on host network)
   - Soketi was running on Docker bridge network (`coolify`)
   - Coolify couldn't reach Soketi because they were on different networks

2. **Missing Configuration:**
   - Soketi port (6001) wasn't exposed to host
   - Coolify wasn't configured with `PUSHER_HOST`, `PUSHER_PORT`, `PUSHER_SCHEME`

## Solution

### 1. Expose Soketi Port to Host

Added port mapping in `compose/coolify.yml`:

```yaml
coolify-soketi:
  ports:
    - "6001:6001"
```

This allows Coolify (running on host network) to connect to Soketi via `localhost:6001`.

### 2. Configure Coolify Pusher Settings

Added environment variables to Coolify service:

```yaml
coolify:
  environment:
    - PUSHER_HOST=127.0.0.1
    - PUSHER_PORT=6001
    - PUSHER_SCHEME=http
```

This tells Coolify where to find the Soketi server.

## Configuration Details

**Soketi:**
- Port: `6001` (exposed to host)
- Network: `coolify` (Docker bridge network)
- Accessible from host: `http://127.0.0.1:6001`

**Coolify:**
- Network: `host` (host network mode)
- Connects to Soketi via: `http://127.0.0.1:6001`
- Pusher credentials: Configured via environment variables

## Verification

1. Check Soketi is accessible:
   ```bash
   curl http://127.0.0.1:6001/ready
   # Should return: OK
   ```

2. Check Coolify environment:
   ```bash
   docker compose -f compose/coolify.yml exec coolify printenv | grep PUSHER
   # Should show: PUSHER_HOST, PUSHER_PORT, PUSHER_SCHEME
   ```

3. Check Coolify UI:
   - Warning should disappear
   - Real-time features should work (live logs, status updates, etc.)

## Files Modified

- `/home/comzis/inlock-infra/compose/coolify.yml`
  - Added `ports` to `coolify-soketi` service
  - Added `PUSHER_HOST`, `PUSHER_PORT`, `PUSHER_SCHEME` to `coolify` environment

## Status

✅ **Fixed** - Soketi port exposed and Coolify configured to connect

---

**Last Updated:** December 11, 2025
