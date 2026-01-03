# Automated Backup System

**Date:** 2025-12-28  
**Status:** Active System

---

## Overview

The automated backup system coordinates all backup operations including scheduling, verification, retention, and off-site synchronization.

---

## System Components

### Core Scripts

1. **automated-backup-system.sh**
   - Main orchestration script
   - Coordinates all backup operations
   - Handles logging and error reporting

2. **backup-databases.sh**
   - Database logical backups (pg_dump)
   - Multiple database support
   - Encryption (GPG)

3. **backup-volumes.sh**
   - Docker volume backups
   - Compression
   - Encryption

4. **verify-backups.sh**
   - Backup integrity checks
   - Restore testing (optional)
   - Validation reports

5. **sync-backups-offsite.sh**
   - Off-site backup synchronization
   - S3, Backblaze B2, or other storage
   - Incremental sync

6. **cleanup-old-backups.sh**
   - Retention policy enforcement
   - Old backup removal
   - Archival management

---

## Usage

### Manual Execution

**Run all backups:**
```bash
./scripts/backup/automated-backup-system.sh
```

**Run specific backup type:**
```bash
./scripts/backup/automated-backup-system.sh --backup-type databases
./scripts/backup/automated-backup-system.sh --backup-type volumes
./scripts/backup/automated-backup-system.sh --backup-type full
```

**With verification:**
```bash
./scripts/backup/automated-backup-system.sh --verify
```

**With off-site sync:**
```bash
./scripts/backup/automated-backup-system.sh --sync-offsite
```

**With cleanup:**
```bash
./scripts/backup/automated-backup-system.sh --cleanup
```

**All options:**
```bash
./scripts/backup/automated-backup-system.sh \
    --backup-type full \
    --verify \
    --sync-offsite \
    --cleanup
```

---

## Scheduling

### Cron Schedule

**Daily Backups:**
```bash
# Daily database and volume backups at 2 AM
0 2 * * * /path/to/scripts/backup/automated-backup-system.sh --backup-type all
```

**Weekly Full Backups:**
```bash
# Weekly full backup with verification and cleanup on Sunday at 3 AM
0 3 * * 0 /path/to/scripts/backup/automated-backup-system.sh --backup-type full --verify --cleanup
```

**Daily Off-Site Sync:**
```bash
# Daily off-site sync at 4 AM
0 4 * * * /path/to/scripts/backup/automated-backup-system.sh --sync-offsite
```

### systemd Timers

**Daily Backup Timer:**
```ini
# /etc/systemd/system/inlock-daily-backup.timer
[Unit]
Description=Daily Inlock Backup
Requires=inlock-daily-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

**Service:**
```ini
# /etc/systemd/system/inlock-daily-backup.service
[Unit]
Description=Daily Inlock Backup
After=network-online.target

[Service]
Type=oneshot
ExecStart=/path/to/scripts/backup/automated-backup-system.sh --backup-type all
User=root
```

**Enable:**
```bash
sudo systemctl enable inlock-daily-backup.timer
sudo systemctl start inlock-daily-backup.timer
```

---

## Backup Types

### All Backups
- Database backups (pg_dump)
- Volume backups (Docker volumes)
- Full system backup

### Database Only
- Logical backups (pg_dump)
- All PostgreSQL databases
- Encrypted output

### Volume Only
- Docker volume backups
- Application data
- Service configurations

### Full Backup
- All databases
- All volumes
- System configurations
- Complete system state

---

## Verification

### Backup Verification Process

1. **File Integrity:**
   - Check backup file existence
   - Verify file size
   - Test file readability

2. **Encryption Verification:**
   - Verify GPG encryption
   - Test decryption (dry-run)
   - Check GPG key availability

3. **Restore Testing (Optional):**
   - Restore to test environment
   - Verify data integrity
   - Check application connectivity

### Verification Script

**Manual verification:**
```bash
./scripts/backup/verify-backups.sh
```

**Automated verification:**
```bash
./scripts/backup/automated-backup-system.sh --verify
```

---

## Off-Site Synchronization

### Supported Backends

1. **AWS S3:**
   ```bash
   aws s3 sync /var/backups/inlock/ s3://inlock-backups/
   ```

2. **Backblaze B2:**
   ```bash
   rclone sync /var/backups/inlock/ b2:inlock-backups/
   ```

3. **Other S3-Compatible:**
   - MinIO
   - DigitalOcean Spaces
   - Wasabi

### Sync Configuration

**Environment Variables:**
```bash
export BACKUP_S3_BUCKET="inlock-backups"
export BACKUP_B2_BUCKET="inlock-backups"
export BACKUP_RETENTION_DAYS=30
```

---

## Retention Policy

### Local Retention

| Backup Type | Retention | Location |
|-------------|-----------|----------|
| Daily backups | 7 days | `/var/backups/inlock/` |
| Weekly backups | 30 days | `/var/backups/inlock/` |
| Monthly backups | 12 months | Off-site only |

### Off-Site Retention

| Backup Type | Retention | Location |
|-------------|-----------|----------|
| Daily backups | 30 days | S3/B2 (Standard) |
| Weekly backups | 12 weeks | S3/B2 (Standard) |
| Monthly backups | 12 months | S3/B2 (Glacier/Cold) |

### Cleanup Process

**Automatic Cleanup:**
```bash
./scripts/backup/automated-backup-system.sh --cleanup
```

**Manual Cleanup:**
```bash
./scripts/backup/cleanup-old-backups.sh
```

**Cleanup Rules:**
- Remove backups older than retention period
- Archive monthly backups before deletion
- Generate cleanup reports
- Log all deletions

---

## Logging

### Log Files

**Main Log:**
- Location: `/var/log/inlock-backup-system.log`
- Rotation: Weekly
- Retention: 30 days

**Backup Logs:**
- Location: `/var/log/inlock-backup-*.log`
- Per-backup-type logs
- Detailed operation logs

### Log Rotation

**Configuration (`/etc/logrotate.d/inlock-backups`):**
```
/var/log/inlock-backup*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

---

## Monitoring & Alerting

### Metrics

- Backup success/failure rate
- Backup duration
- Backup size
- Disk usage
- Off-site sync status
- Retention compliance

### Alerts

**Critical:**
- Backup failures
- Off-site sync failures
- Disk space < 10%
- Verification failures

**Warning:**
- Slow backups (> 1 hour)
- Large backup sizes
- Disk space < 20%
- Retention violations

### Monitoring Integration

**Prometheus Metrics (Future):**
- `backup_duration_seconds`
- `backup_size_bytes`
- `backup_success_total`
- `backup_failure_total`

---

## Troubleshooting

### Common Issues

**1. Backup Failures**

**Symptoms:**
- Backup script exits with error
- No backup files created

**Solutions:**
- Check disk space
- Verify GPG key availability
- Check service status
- Review logs

**2. Slow Backups**

**Symptoms:**
- Backups take > 1 hour
- High disk I/O

**Solutions:**
- Check database size
- Optimize backup process
- Consider incremental backups
- Check disk performance

**3. Off-Site Sync Failures**

**Symptoms:**
- Sync script fails
- Backups not in cloud storage

**Solutions:**
- Check network connectivity
- Verify credentials
- Check cloud storage quotas
- Review sync logs

---

## Related Documentation

- [Database Backup Strategy](./DATABASE-BACKUP-STRATEGY.md)
- [Disaster Recovery Plan](./DISASTER-RECOVERY-PLAN.md)
- [Backup Verification](./verify-backups.md)

---

**Last Updated:** 2025-12-28












