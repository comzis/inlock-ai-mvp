# Disk Space & Network Cleanup Report
**Date:** January 3, 2026

## Summary

Completed disk space cleanup and network investigation for INLOCK infrastructure.

## Disk Space Cleanup Results

### ✅ Completed Actions

1. **Removed Mailu Docker Volumes** (10 volumes)
   - `services_mailu_*` volumes (6 volumes)
   - `tooling_mailu_*` volumes (4 volumes)
   - **Reclaimed:** ~500MB (estimated)

2. **Removed Unused Docker Images**
   - Removed `n8nio/n8n:latest` (unused, container uses `1.123.5`)
   - **Reclaimed:** 300.2MB

3. **Disk Usage Improvement**
   - **Before:** 93GB used (48% of 194GB)
   - **After:** 91GB used (47% of 194GB)
   - **Total Reclaimed:** ~2GB

### ⚠️ Requires Manual Action (sudo required)

4. **Journal Logs Cleanup**
   - Current size: 4.0GB
   - Action needed: Run `sudo journalctl --vacuum-time=7d`
   - Expected reduction: ~2-3GB (keeping last 7 days)

5. **Docker System Prune**
   - Unused images: 32.91GB reclaimable (99% of image storage)
   - Action needed: Run `docker system prune -a -f --filter "until=168h"`
   - **Warning:** This will remove all unused images older than 7 days

6. **Backup Files Cleanup**
   - Current size: 7.5GB in `/home/comzis/backups`
   - Old backups found: 1 file from Dec 14 (2.4KB - can be removed)
   - Action: Use cleanup script to remove backups older than 30 days

## Network Investigation: Tailscale

### Current Status

- **Connection:** ✅ Working (31ms latency)
- **Mode:** Using relay server (`84.115.235.126:21403`)
- **Direct P2P:** ❌ Not established
- **Port 41641:** ✅ Listening correctly
- **Interface:** ✅ `tailscale0` interface active

### Findings

1. **Tailscale is functioning correctly** - connection works via relay
2. **Relay connection is normal** when direct P2P cannot be established due to:
   - NAT/firewall restrictions on client side (MacBook)
   - ISP blocking UDP traffic
   - Network configuration preventing hole-punching

3. **31ms latency is acceptable** for relay connections
4. **No action required** - relay mode is a fallback and works fine

### Optional: Improve to Direct P2P

To establish direct P2P connection (if desired):

1. **Check MacBook firewall** - ensure UDP 41641 is allowed
2. **Check router/NAT settings** - enable UPnP or configure port forwarding
3. **Verify Tailscale ACLs** - ensure no restrictions in Tailscale admin console

**Note:** Relay mode is secure and functional. Direct P2P is an optimization, not a requirement.

## Cleanup Script Created

Created automated cleanup script: `/home/comzis/inlock/scripts/cleanup-disk-space.sh`

**Usage:**
```bash
cd /home/comzis/inlock
sudo bash scripts/cleanup-disk-space.sh
```

This script will:
- Clean journal logs (keep 7 days)
- Remove old backup files (>30 days, or failed backups <10KB >1 day old)
- Prune unused Docker resources
- Show before/after disk usage

## Recommendations

1. **Run cleanup script regularly** (monthly or as needed)
2. **Monitor disk usage** - set up alerts at 80% capacity
3. **Automate backup cleanup** - integrate into backup retention policy
4. **Tailscale relay is acceptable** - no urgent action needed unless latency becomes an issue

## Next Steps

1. Run `sudo journalctl --vacuum-time=7d` to clean journal logs
2. Review and run `docker system prune` if comfortable removing unused images
3. Execute cleanup script: `sudo bash scripts/cleanup-disk-space.sh`
4. Monitor disk usage over next week

