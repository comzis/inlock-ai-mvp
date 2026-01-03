# Tailscale Connection Stability Fix
**Date:** January 3, 2026

## Problem

Tailscale connections have been dropping intermittently since yesterday. Investigation revealed:

- **28,634 network state change events** in the last 24 hours
- **Excessive Docker network interface churn** (60+ veth interfaces)
- Tailscale constantly rebinding due to Docker container network changes
- DERP connections closing and reopening frequently
- Connection latency increasing (31ms → 108ms)

## Root Cause

Docker containers creating/destroying network interfaces (veth pairs) are triggering Tailscale's network monitor, causing it to:
1. Detect "major link changes"
2. Rebind network configuration
3. Close and reopen DERP connections
4. Drop active connections during rebind

## Solution

Configure Tailscale to ignore Docker network interfaces to prevent unnecessary rebinds.

### Step 1: Configure Tailscale to Ignore Docker Interfaces

Create or edit `/etc/default/tailscaled`:

```bash
sudo nano /etc/default/tailscaled
```

Add the following configuration:

```bash
# Ignore Docker network interfaces to prevent excessive rebinds
FLAGS="--tun=userspace-networking"
```

**OR** use systemd override (recommended):

```bash
sudo systemctl edit tailscaled
```

Add:

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --accept-routes=false --netfilter-mode=off
```

**Note:** The `--netfilter-mode=off` flag tells Tailscale to use userspace networking, which is less sensitive to network interface changes.

### Step 2: Restart Tailscale

```bash
sudo systemctl restart tailscaled
```

### Step 3: Verify Stability

Monitor Tailscale logs for reduced rebind events:

```bash
journalctl -u tailscaled -f | grep -E "(Rebind|LinkChange)"
```

You should see significantly fewer rebind events.

## Alternative: Reduce Docker Network Churn

If the above doesn't fully resolve the issue, investigate which containers are causing excessive network interface creation:

```bash
# Monitor Docker events
docker events --filter "type=network" --filter "event=create" --filter "event=destroy"

# Check for containers restarting frequently
docker ps -a --format "{{.Names}} {{.Status}}" | grep -E "(Restarting|Exited)"
```

## Expected Results

After applying the fix:
- ✅ Fewer network state change events (< 100/day instead of 28,634)
- ✅ Stable DERP connections (no frequent closing/reopening)
- ✅ Consistent connection latency (~30-50ms)
- ✅ No connection drops during normal operation

## Monitoring

To monitor Tailscale stability:

```bash
# Check connection status
tailscale status

# Monitor rebind events
journalctl -u tailscaled --since "1 hour ago" | grep -c "Rebind"

# Check DERP connection stability
journalctl -u tailscaled --since "1 hour ago" | grep -E "closing connection|adding connection"
```

## References

- [Tailscale Network Interface Handling](https://tailscale.com/kb/1082/clients/)
- [Docker Network Interface Management](https://docs.docker.com/network/)

