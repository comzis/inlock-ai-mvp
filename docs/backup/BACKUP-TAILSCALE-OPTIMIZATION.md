# Backup and Tailscale Optimization Guide

## Overview

This document describes optimizations made to backup scripts to minimize impact on Tailscale network stability. Docker backup operations can cause network interface churn that affects Tailscale's connection stability.

## Problem

When Docker creates temporary containers during backup operations, it can create and destroy network interfaces rapidly. This causes Tailscale to detect network changes and rebind its connection, leading to:
- Connection drops
- Increased latency
- Unstable network connections

## Solutions Implemented

### 1. Network Interface Exclusions

**File:** `scripts/backup/backup-volumes.sh`

**Changes:**
- Added `--network=none` to Docker backup containers to prevent network interface creation
- Added exclusions for Tailscale-related volumes: `--exclude='*tailscale*' --exclude='*wireguard*'`

**Benefits:**
- Prevents Docker from creating network interfaces during backups
- Reduces network interface churn
- Minimizes Tailscale rebind events

### 2. Tailscale Status Monitoring

**File:** `scripts/backup/automated-backup-system.sh`

**Changes:**
- Added pre-backup Tailscale status check
- Added post-backup Tailscale status check
- Logs Tailscale connection status and IP address

**Benefits:**
- Detects if backups are affecting Tailscale
- Provides visibility into network stability
- Helps identify backup-related network issues

### 3. Dedicated Monitoring Script

**File:** `scripts/backup/monitor-tailscale-during-backup.sh`

**Features:**
- Monitors Tailscale connection status
- Tracks network interface changes
- Detects Tailscale rebind events
- Provides detailed logging

**Usage:**
```bash
./scripts/backup/monitor-tailscale-during-backup.sh
```

### 4. Backup Timing

**Current Schedule:** Daily at 03:00 (configured in cron)

**Recommendation:**
- ✅ Already scheduled during low network activity (3 AM)
- Minimal user activity during this time
- Reduces impact on active connections

**To verify cron schedule:**
```bash
crontab -l | grep backup
```

## Tailscale Configuration

### Current Configuration

**File:** `/etc/systemd/system/tailscaled.service.d/override.conf`

**Current Setting:**
```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --netfilter-mode=off
```

**Purpose:**
- `--netfilter-mode=off` uses userspace networking
- Reduces sensitivity to Docker network interface changes
- Prevents excessive rebind events

### Alternative Configuration Options

If you need userspace networking but want to avoid `--netfilter-mode=off`, Tailscale offers:

1. **Userspace Networking Mode:**
   ```bash
   --tun=userspace-networking
   ```
   - Useful in containerized environments
   - Doesn't require VPN tunnel device
   - Less sensitive to interface changes

2. **Interface Filtering:**
   - Configure Tailscale to ignore specific interfaces
   - Use `--accept-routes=false` to ignore route changes
   - Monitor specific interfaces only

3. **Network Namespace Isolation:**
   - Run backups in isolated network namespaces
   - Prevents interface changes from affecting Tailscale

## Monitoring Backup Impact

### During Backup

Run the monitoring script in a separate terminal:
```bash
./scripts/backup/monitor-tailscale-during-backup.sh
```

### After Backup

Check backup logs for Tailscale status:
```bash
tail -50 logs/inlock-backup-system.log | grep -i tailscale
```

### Check Tailscale Rebind Events

```bash
journalctl -u tailscaled -f | grep -E '(Rebind|LinkChange)'
```

### Verify Network Stability

```bash
# Check Tailscale status
tailscale status

# Check connection quality
tailscale ping <peer-ip>

# Monitor interface changes
watch -n 5 'ip link show | wc -l'
```

## Best Practices

### 1. Schedule Backups During Low Activity
- ✅ Current: 03:00 (already optimal)
- Avoid peak usage hours
- Consider weekend backups for large operations

### 2. Monitor Backup Impact
- Run monitoring script during first few backups
- Check Tailscale logs after backups
- Verify connection stability

### 3. Use Network Isolation
- Always use `--network=none` for backup containers
- Exclude Tailscale-related volumes
- Minimize Docker network operations

### 4. Regular Health Checks
- Weekly Tailscale status review
- Monitor rebind event frequency
- Check backup success rates

## Troubleshooting

### Issue: Tailscale Drops During Backup

**Symptoms:**
- Connection drops during backup operations
- Increased rebind events in logs
- Network instability

**Solutions:**
1. Verify `--network=none` is used in backup scripts
2. Check for Tailscale-related volumes being backed up
3. Review Tailscale logs: `journalctl -u tailscaled -n 100`
4. Consider adjusting backup timing

### Issue: Backup Fails Due to Network

**Symptoms:**
- Backup script fails
- Network errors in logs
- Docker network issues

**Solutions:**
1. Verify Docker network is stable
2. Check for network interface conflicts
3. Review Docker logs: `docker logs <container>`
4. Ensure backup script uses `--network=none`

### Issue: High Rebind Frequency

**Symptoms:**
- Frequent rebind events in Tailscale logs
- Network instability
- Connection quality issues

**Solutions:**
1. Verify Tailscale configuration (`--netfilter-mode=off`)
2. Check for other processes creating network interfaces
3. Review system network configuration
4. Consider alternative Tailscale configuration

## Verification

### Test Backup Impact

1. **Before Backup:**
   ```bash
   tailscale status
   ./scripts/backup/monitor-tailscale-during-backup.sh
   ```

2. **Run Backup:**
   ```bash
   ./scripts/backup/automated-backup-system.sh --backup-type all
   ```

3. **After Backup:**
   ```bash
   tailscale status
   journalctl -u tailscaled --since "10 minutes ago" | grep Rebind
   ```

### Expected Results

- ✅ Tailscale remains connected
- ✅ No rebind events during backup
- ✅ Network interface count stable
- ✅ Backup completes successfully

## Related Documentation

- [Tailscale Stability Fix](../tailscale-stability-fix.md)
- [Backup System Documentation](./README.md)
- [Automated Backup Script](../scripts/backup/automated-backup-system.sh)

## Summary

**Optimizations Applied:**
1. ✅ Network interface exclusions (`--network=none`)
2. ✅ Tailscale volume exclusions
3. ✅ Pre/post backup status monitoring
4. ✅ Dedicated monitoring script
5. ✅ Optimal backup timing (03:00)

**Benefits:**
- Reduced network interface churn
- Improved Tailscale stability
- Better visibility into backup impact
- Minimal disruption to network operations

**Next Steps:**
- Monitor backup operations for 1 week
- Review Tailscale logs weekly
- Adjust configuration if needed
- Document any additional optimizations

---

**Last Updated:** January 3, 2026  
**Related Scripts:**
- `scripts/backup/automated-backup-system.sh`
- `scripts/backup/backup-volumes.sh`
- `scripts/backup/monitor-tailscale-during-backup.sh`

