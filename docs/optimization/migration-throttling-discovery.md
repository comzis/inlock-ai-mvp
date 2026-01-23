# ClickHouse Migration Scheduler Discovery

**Date**: 2026-01-21  
**Status**: ✅ Discovery Complete

---

## Discovery Results

### Current State

**Finding**: The `python manage.py migrate_clickhouse --check` command is **NOT currently scheduled** in any of the following locations:

- ❌ **Systemd timers**: No timers found
- ❌ **User crontab**: No entries found
- ❌ **Root crontab**: No entries found
- ❌ **System cron directories**: No entries found
- ❌ **Docker container cron**: No cron processes found in containers

### Conclusion

The migration command appears to be:
1. **Manually executed** when needed, OR
2. **Triggered from within the application** (Django management command), OR
3. **Scheduled elsewhere** (not found in standard locations)

### Recommendation

Since the command is not currently scheduled, the new systemd timer solution provides:
- **Automatic scheduling** at off-peak hours (02:00 CET)
- **Resource throttling** to prevent CPU saturation
- **Load guard** to skip execution during high system load
- **Proper logging** for monitoring and troubleshooting

---

## Files Created

### 1. Throttled Wrapper Script
- **Location**: `scripts/run-migrate-clickhouse-throttled.sh`
- **Purpose**: Wraps the migration command with throttling and load guard
- **Status**: ✅ Created and syntax-checked

### 2. Systemd Service Template
- **Location**: `runbooks/systemd/migrate-clickhouse.service`
- **Purpose**: Defines the service with resource limits
- **Status**: ✅ Created

### 3. Systemd Timer Template
- **Location**: `runbooks/systemd/migrate-clickhouse.timer`
- **Purpose**: Schedules the service to run at 02:00 CET daily
- **Status**: ✅ Created

### 4. Documentation
- **Location**: `docs/optimization/migration-job-throttling.md`
- **Purpose**: Complete guide for installation, configuration, and troubleshooting
- **Status**: ✅ Created

---

## Next Steps

1. **Install systemd files** (see main documentation)
2. **Enable and start timer**
3. **Monitor first execution** to verify throttling works
4. **Adjust settings** if needed based on system behavior

---

**Last Updated**: 2026-01-21
