# ClickHouse Migration Job Throttling

**Date Created**: 2026-01-21  
**Status**: ✅ Implemented

---

## Background

On **2026-01-20 12:21–14:00 CET**, the `python manage.py migrate_clickhouse --check` command triggered a severe system resource spike:

- **CPU**: 96–99% utilization for 90 minutes
- **Disk I/O**: Up to 760 MB/s
- **Timing**: Ran during business hours when baseline CPU was already ~90%
- **Impact**: System performance degradation, potential service disruption

This document describes the solution implemented to prevent future incidents by:
1. **Rescheduling** the migration check to off-peak hours (02:00 CET)
2. **Throttling** CPU and I/O resources for the migration process
3. **Adding a load guard** to skip execution when system load is already high

---

## Solution Components

### 1. Throttled Wrapper Script

**Location**: `scripts/run-migrate-clickhouse-throttled.sh`

**Features**:
- **Flock-based locking**: Prevents concurrent runs
- **Load guard**: Refuses to run when system load exceeds threshold (default: 80% of CPU cores)
- **Resource throttling**: Uses `nice`, `ionice`, and `systemd-run` (if available) to limit CPU/I/O
- **Logging**: Logs to syslog (tag: `migrate-clickhouse`) and optional file (`/var/log/migrate-clickhouse.log`)
- **Configurable**: Environment variables allow tuning of all limits

**Exit Codes**:
- `0`: Success
- `73`: Another process is already running (lock conflict)
- `75`: System load too high (temporary failure, try again later)
- `1+`: Migration command failed

### 2. Systemd Service

**Location**: `runbooks/systemd/migrate-clickhouse.service`

**Resource Limits**:
- **CPU Quota**: 200% (≈2 cores on 6-core system)
- **Nice Level**: 10 (lower priority)
- **I/O Scheduling**: Best-effort class (2), priority 7 (lowest)

**Configuration**: All limits can be overridden via environment variables or systemd overrides.

### 3. Systemd Timer

**Location**: `runbooks/systemd/migrate-clickhouse.timer`

**Schedule**:
- **Time**: 01:00 UTC daily (≈02:00 CET, adjusts for DST)
- **Randomized Delay**: 0–15 minutes to avoid thundering herd
- **Persistent**: Runs immediately on boot if system was off during scheduled time

---

## Installation

### Step 1: Copy Systemd Files

```bash
# Copy service file
sudo cp /home/comzis/.cursor/projects/home-comzis-inlock/runbooks/systemd/migrate-clickhouse.service /etc/systemd/system/

# Copy timer file
sudo cp /home/comzis/.cursor/projects/home-comzis-inlock/runbooks/systemd/migrate-clickhouse.timer /etc/systemd/system/
```

### Step 2: Reload Systemd

```bash
sudo systemctl daemon-reload
```

### Step 3: Enable and Start Timer

```bash
# Enable timer (starts automatically on boot)
sudo systemctl enable migrate-clickhouse.timer

# Start timer immediately
sudo systemctl start migrate-clickhouse.timer
```

### Step 4: Verify Installation

```bash
# Check timer status
systemctl list-timers | grep migrate-clickhouse

# Check next run time
systemctl status migrate-clickhouse.timer

# View service logs
journalctl -u migrate-clickhouse.service -n 50
```

---

## Manual Execution

### Run with Default Settings

```bash
sudo /home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh
```

### Dry Run (Test Without Executing)

```bash
DRY_RUN=true /home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh

# Or
/home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh --dry-run
```

### Run with Custom Settings

```bash
# Example: More aggressive throttling
CPU_QUOTA_PERCENT=150 \
IONICE_PRIO=7 \
NICE_LEVEL=15 \
LOAD_FACTOR=0.70 \
sudo -E /home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh
```

### Run via Systemd Service (Manual Trigger)

```bash
# Run the service manually (respects all throttling)
sudo systemctl start migrate-clickhouse.service

# Check result
systemctl status migrate-clickhouse.service
```

---

## Configuration

### Environment Variables

All settings can be customized via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CPU_QUOTA_PERCENT` | `200` | CPU quota percentage (200% = ~2 cores on 6-core system) |
| `IONICE_CLASS` | `2` | I/O scheduling class (2 = best-effort) |
| `IONICE_PRIO` | `7` | I/O priority (0-7, 7 = lowest) |
| `NICE_LEVEL` | `10` | Process nice level (-20 to 19, higher = lower priority) |
| `LOAD_FACTOR` | `0.80` | Load threshold factor (0.80 = 80% of CPU cores) |
| `PROJECT_DIR` | `/home/comzis/projects/inlock-ai-mvp` | Path to application directory |
| `MIGRATION_CMD` | `python manage.py migrate_clickhouse --check` | Migration command to execute |
| `LOG_FILE` | `/var/log/migrate-clickhouse.log` | Log file path (optional) |
| `LOCK_FILE` | `/var/run/migrate-clickhouse.lock` | Lock file path |
| `DRY_RUN` | `false` | Enable dry-run mode (no actual execution) |

### Systemd Override

To permanently change settings, create a systemd override:

```bash
# Create override directory
sudo mkdir -p /etc/systemd/system/migrate-clickhouse.service.d/

# Create override file
sudo tee /etc/systemd/system/migrate-clickhouse.service.d/override.conf <<EOF
[Service]
Environment="CPU_QUOTA_PERCENT=150"
Environment="LOAD_FACTOR=0.70"
EOF

# Reload systemd
sudo systemctl daemon-reload
```

### Timer Schedule Adjustment

To change the schedule, edit the timer file:

```bash
sudo systemctl edit migrate-clickhouse.timer
```

Example: Run at 03:00 CET instead of 02:00:

```ini
[Timer]
OnCalendar=*-*-* 02:00:00
```

Then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart migrate-clickhouse.timer
```

---

## Monitoring

### Check Timer Status

```bash
# List all timers
systemctl list-timers

# Check specific timer
systemctl status migrate-clickhouse.timer

# View timer logs
journalctl -u migrate-clickhouse.timer -n 20
```

### Check Service Execution

```bash
# View service logs
journalctl -u migrate-clickhouse.service -n 50

# Follow logs in real-time
journalctl -u migrate-clickhouse.service -f

# Check last execution
systemctl status migrate-clickhouse.service
```

### Check Log File

```bash
# View log file (if writable)
sudo tail -f /var/log/migrate-clickhouse.log

# Or via syslog
sudo journalctl -t migrate-clickhouse -n 50
```

### Verify Load Guard

```bash
# Check current load
cat /proc/loadavg

# Check CPU cores
nproc

# Calculate threshold (80% of cores)
echo "scale=2; $(nproc) * 0.80" | bc
```

---

## Troubleshooting

### Timer Not Running

```bash
# Check if timer is enabled
systemctl is-enabled migrate-clickhouse.timer

# Check timer status
systemctl status migrate-clickhouse.timer

# Check for errors
journalctl -u migrate-clickhouse.timer -n 20
```

### Service Fails with Exit Code 75

**Cause**: System load too high (load guard triggered)

**Solution**: 
- Wait for system load to decrease
- Manually run when load is lower
- Adjust `LOAD_FACTOR` if threshold is too strict

```bash
# Check current load
cat /proc/loadavg

# Manually run when load is acceptable
sudo systemctl start migrate-clickhouse.service
```

### Service Fails with Exit Code 73

**Cause**: Another migration process is already running (lock conflict)

**Solution**: 
- Wait for the other process to complete
- Check for stuck processes: `ps aux | grep migrate-clickhouse`
- Remove lock file if process is dead: `sudo rm /var/run/migrate-clickhouse.lock`

### Migration Command Fails

**Cause**: Actual migration command error (not throttling issue)

**Solution**:
- Check application logs
- Verify database connectivity
- Check migration command syntax
- Review service logs: `journalctl -u migrate-clickhouse.service -n 100`

### Resource Limits Not Applied

**Cause**: Running inside Docker container without proper cgroup support

**Solution**:
- Script falls back to `nice`/`ionice` if `systemd-run` unavailable
- Verify Docker container has proper cgroup access
- Consider running migration on host instead of in container

---

## Rollback

### Disable Timer

```bash
# Stop timer
sudo systemctl stop migrate-clickhouse.timer

# Disable timer (prevents auto-start on boot)
sudo systemctl disable migrate-clickhouse.timer
```

### Remove Systemd Files

```bash
# Stop and disable
sudo systemctl stop migrate-clickhouse.timer
sudo systemctl disable migrate-clickhouse.timer

# Remove files
sudo rm /etc/systemd/system/migrate-clickhouse.service
sudo rm /etc/systemd/system/migrate-clickhouse.timer
sudo rm -rf /etc/systemd/system/migrate-clickhouse.service.d

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl reset-failed
```

### Restore Original Schedule

If the migration was previously scheduled elsewhere (cron, etc.), restore that schedule after removing the systemd timer.

---

## Verification Commands

```bash
# Test script syntax
bash -n /home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh

# Dry run test
/home/comzis/.cursor/projects/home-comzis-inlock/scripts/run-migrate-clickhouse-throttled.sh --dry-run

# Check timer status
systemctl list-timers | grep migrate-clickhouse

# View service logs
journalctl -u migrate-clickhouse.service -n 50

# Test logger
logger -t migrate-clickhouse "test message"
journalctl -t migrate-clickhouse -n 5

# Check lock file
ls -l /var/run/migrate-clickhouse.lock

# Check log file (if writable)
ls -l /var/log/migrate-clickhouse.log
```

---

## Related Documentation

- **System Resource Optimization**: `docs/optimization/implementation-review.md`
- **Implementation Summary**: `docs/optimization/implementation-summary.md`
- **Scheduled Tasks Analysis**: `scripts/analyze-scheduled-tasks.sh`

---

## Incident Reference

**Date**: 2026-01-20 12:21–14:00 CET  
**Duration**: ~90 minutes  
**Impact**: CPU 96–99%, Disk I/O 760 MB/s  
**Root Cause**: Unthrottled migration check during business hours  
**Resolution**: Implemented throttling, load guard, and off-peak scheduling

---

**Last Updated**: 2026-01-21  
**Status**: ✅ Production Ready
