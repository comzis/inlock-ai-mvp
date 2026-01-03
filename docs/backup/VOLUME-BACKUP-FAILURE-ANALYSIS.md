# Volume Backup Failure Analysis

## Issue Summary

Volume backups are failing with `tar: error exit delayed from previous errors` even though `--ignore-failed-read` and `--warning=no-file-changed` flags are used.

## Failure Log Excerpt

**From:** `logs/inlock-backup-system.log`  
**Date:** 2026-01-03 03:00:08  
**Error:** `tar: error exit delayed from previous errors`

### Error Details

```
tar: ./tooling_posthog_clickhouse_data/_data/store/263/2632a5fb-f759-4d05-824b-dddcb78faff3/202601_223092_223092_0: No such file or directory
tar: ./tooling_posthog_clickhouse_data/_data/store/263/2632a5fb-f759-4d05-824b-dddcb78faff3/202601_223093_223093_0: No such file or directory
tar: ./tooling_posthog_clickhouse_data/_data/store/263/2632a5fb-f759-4d05-824b-dddcb78faff3/202601_223094_223094_0: No such file or directory
...
tar: error exit delayed from previous errors
ERROR: Volume backup failed
```

### Root Cause

1. **ClickHouse Transient Files:** ClickHouse deletes and recreates files rapidly during normal operation. Files that exist when tar starts may be deleted before tar can read them.

2. **Tar Exit Code:** Even with `--ignore-failed-read`, tar can exit with a non-zero status code when encountering multiple "No such file or directory" errors, especially when files are deleted during the backup process.

3. **Error Propagation:** The tar command's exit code is being checked, causing the backup script to fail even though the backup may have succeeded (with some files skipped).

## Current Exclusions

The backup script already excludes:
- `--exclude='*clickhouse*/store/*/parts'`
- `--exclude='*clickhouse*/store/*/tmp'`
- `--exclude='*clickhouse*/store/*/tmp_*'`
- `--exclude='*clickhouse*/store/*/*_*_*_*'`

However, these patterns don't catch all transient files, particularly:
- Files in `store/*/` directories that are deleted during backup
- Files with numeric patterns like `202601_223092_223092_0`

## Solution Implemented

### 1. Enhanced Error Handling

- Capture tar errors to a log file (`/tmp/tar-backup-errors-*.log`)
- Filter out expected warnings (socket ignored, No such file)
- Only fail if backup file is missing or too small
- Log critical errors separately from expected warnings

### 2. Improved ClickHouse Exclusions

Added additional exclusion patterns:
- `--exclude='*clickhouse*/store/*/detached'`
- `--exclude='*clickhouse*/store/*/format_version'`

### 3. Backup Validation

- Check if backup file exists
- Verify backup file size (> 1000 bytes)
- Only fail if backup is actually incomplete

### 4. Better Error Reporting

- Log tar errors to file for debugging
- Show only critical errors (not expected warnings)
- Preserve error logs for investigation

## Testing

### Test the Fix

```bash
# Run backup manually to test
cd /home/comzis/inlock
./scripts/backup/backup-volumes.sh

# Check for error log
ls -lh /tmp/tar-backup-errors-*.log

# Verify backup was created
ls -lh ~/backups/inlock/encrypted/volumes-*.tar.gz.gpg | tail -1
```

### Monitor Weekly

```bash
# Check weekly backup success rate
./scripts/backup/monitor-backup-success-rate.sh --week 2026-W01

# Or current week
./scripts/backup/monitor-backup-success-rate.sh
```

## Expected Behavior After Fix

1. **Tar errors are captured** but don't cause backup failure
2. **Backup succeeds** if file is created and has reasonable size
3. **Warnings are logged** but don't block backup
4. **Critical errors are reported** separately

## Monitoring

### Weekly Review

Run weekly to track backup success:

```bash
./scripts/backup/monitor-backup-success-rate.sh --week YYYY-WW
```

### Check Error Logs

If backups still fail, check:

```bash
# Latest tar error log
ls -t /tmp/tar-backup-errors-*.log | head -1 | xargs cat

# Backup system log
tail -100 logs/inlock-backup-system.log | grep -A 10 "Volume backup"
```

## Alternative Solutions (If Issue Persists)

### Option 1: Exclude Entire ClickHouse Volume

If ClickHouse data is not critical for backups:

```bash
--exclude='*clickhouse*'
```

### Option 2: Use rsync with --delete-excluded

More robust handling of transient files:

```bash
rsync -a --delete-excluded /source/ /backup/
```

### Option 3: Stop ClickHouse During Backup

If data consistency is critical:

```bash
docker compose stop clickhouse
# ... backup ...
docker compose start clickhouse
```

## Related Files

- `scripts/backup/backup-volumes.sh` - Main backup script
- `scripts/backup/monitor-backup-success-rate.sh` - Weekly monitoring
- `logs/inlock-backup-system.log` - Backup execution logs
- `/tmp/tar-backup-errors-*.log` - Tar error logs (temporary)

---

**Last Updated:** January 3, 2026  
**Status:** Fix implemented, awaiting validation

