# Database Backup Strategy

**Date:** 2025-12-28  
**Status:** Active Strategy

---

## Overview

This document describes the database backup strategy for PostgreSQL databases, including replication-aware backups, point-in-time recovery (PITR), and WAL archiving.

---

## Current Backup Approach

### Logical Backups (pg_dump)

**Current Implementation:**
- Daily pg_dump backups
- Encrypted backups (GPG)
- Retention: 30 days

**Script:** `scripts/backup/backup-databases.sh`

**Usage:**
```bash
./scripts/backup/backup-databases.sh
```

---

## Enhanced Backup Strategy

### Multi-Tier Backup Approach

1. **Logical Backups (pg_dump)**
   - Full database dumps
   - Easy to restore
   - Platform-independent
   - Suitable for point-in-time recovery

2. **Physical Backups (pg_basebackup)**
   - Complete database cluster copy
   - Faster restore
   - Requires PostgreSQL version compatibility
   - Used for replication setup

3. **WAL Archiving (Point-in-Time Recovery)**
   - Continuous transaction log archiving
   - Enables PITR to any point in time
   - Required for minimal data loss

---

## Logical Backups

### Implementation

**Enhanced Script:** `scripts/backup/backup-databases.sh`

**Features:**
- Multiple database support
- Compression
- Encryption (GPG)
- Retention policies
- Replication lag checks

**Configuration:**
```bash
# Backup all databases
BACKUP_DIR="/var/backups/inlock/databases"
RETENTION_DAYS=30
GPG_RECIPIENT="admin@inlock.ai"
```

**Replication Awareness:**
- Check replication lag before backup
- Prefer backup from standby (if available)
- Reduce impact on primary

### Backup from Standby

When replication is configured, prefer backing up from standby:

```bash
# Connect to standby server
pg_dump -h standby-server -U backup_user database_name
```

**Benefits:**
- No load on primary
- Consistent backups
- No impact on production

---

## Physical Backups

### pg_basebackup

**Use Cases:**
- Initial replication setup
- Full cluster restore
- Faster restore times

**Implementation:**
```bash
pg_basebackup \
    -h primary-server \
    -D /backup/base-backup-$(date +%Y%m%d) \
    -U replicator \
    -Ft \
    -z \
    -P
```

**Scheduling:**
- Weekly full backups
- Before major changes
- After replication setup

---

## WAL Archiving (Point-in-Time Recovery)

### Configuration

**PostgreSQL Configuration (`postgresql.conf`):**
```conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /var/backups/postgresql/wal_archive/%f && cp %p /var/backups/postgresql/wal_archive/%f'
```

**Directory Structure:**
```
/var/backups/postgresql/
├── base_backups/
│   └── base-20251228-120000.tar.gz
└── wal_archive/
    ├── 000000010000000000000001
    ├── 000000010000000000000002
    └── ...
```

### Archive Management

**Script:** `scripts/backup/manage-wal-archive.sh`

**Features:**
- Automatic WAL archiving
- Retention policies
- Compression
- Off-site sync

**Retention:**
- Keep WAL files for 7 days minimum
- Keep WAL files for last base backup
- Archive older WAL files

---

## Replication-Aware Backups

### Replication Lag Checks

Before taking backups, check replication lag:

```bash
# Check lag on primary
psql -c "SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS lag FROM pg_stat_replication;"
```

**Strategy:**
- If lag > 1MB, wait or backup from primary
- If lag < 1MB, safe to backup from standby
- Alert if lag is excessive

### Backup Script Enhancement

**Add to backup script:**
```bash
# Check replication lag
LAG_BYTES=$(psql -tAc "SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)), 0) FROM pg_stat_replication;")

if [ "$LAG_BYTES" -gt 1048576 ]; then
    echo "WARNING: Replication lag exceeds 1MB, backing up from primary"
    BACKUP_FROM="primary"
else
    echo "Replication lag acceptable, backing up from standby"
    BACKUP_FROM="standby"
fi
```

---

## Backup Retention

### Retention Policy

| Backup Type | Retention | Location |
|-------------|-----------|----------|
| Daily logical backups | 30 days | Local + Off-site |
| Weekly physical backups | 12 weeks | Local + Off-site |
| WAL archives | 7 days (minimum) | Local |
| Monthly full backups | 12 months | Off-site only |

### Cleanup Script

**Script:** `scripts/backup/cleanup-old-backups.sh`

**Functionality:**
- Remove backups older than retention
- Keep monthly backups longer
- Archive before deletion
- Generate cleanup reports

---

## Restore Procedures

### Logical Backup Restore

**Full Database Restore:**
```bash
# Decrypt and restore
gpg --decrypt database-20251228.sql.gpg | \
    psql -h localhost -U postgres -d database_name
```

**Single Table Restore:**
```bash
# Extract specific table
gpg --decrypt database-20251228.sql.gpg | \
    pg_restore -t table_name | \
    psql -h localhost -U postgres -d database_name
```

### Physical Backup Restore

**Full Cluster Restore:**
```bash
# Stop PostgreSQL
systemctl stop postgresql

# Remove old data directory
rm -rf /var/lib/postgresql/data/*

# Restore base backup
tar -xzf base-backup-20251228.tar.gz -C /var/lib/postgresql/data

# Start PostgreSQL (will recover from WAL if needed)
systemctl start postgresql
```

### Point-in-Time Recovery

**Recovery to Specific Time:**
```bash
# Create recovery.conf
cat > /var/lib/postgresql/data/recovery.conf << EOF
restore_command = 'cp /var/backups/postgresql/wal_archive/%f %p'
recovery_target_time = '2025-12-28 14:30:00'
recovery_target_action = 'promote'
EOF

# Start PostgreSQL (will recover to target time)
systemctl start postgresql
```

---

## Off-Site Backup Sync

### S3/Backblaze B2 Sync

**Sync Script:** `scripts/backup/sync-backups-offsite.sh`

**Implementation:**
```bash
# Sync to S3
aws s3 sync /var/backups/inlock/ s3://inlock-backups/ --storage-class GLACIER

# Sync to Backblaze B2
rclone sync /var/backups/inlock/ b2:inlock-backups/
```

**Scheduling:**
- Daily sync for recent backups
- Weekly sync for full backups
- Monthly archival sync

---

## Testing & Validation

### Backup Verification

**Script:** `scripts/backup/verify-backups.sh`

**Checks:**
- Backup file integrity
- Encryption verification
- Restore test (optional)
- Size validation

**Schedule:**
- Weekly verification
- After backup changes
- Before major restores

### Restore Testing

**Quarterly DR Test:**
1. Restore from backup
2. Verify data integrity
3. Test application connectivity
4. Document results
5. Update procedures if needed

---

## Monitoring & Alerting

### Backup Monitoring

**Metrics to Track:**
- Backup success/failure
- Backup duration
- Backup size
- Retention compliance
- Off-site sync status

### Alerts

**Critical Alerts:**
- Backup failures
- Off-site sync failures
- Disk space low
- Retention violations

**Warning Alerts:**
- Slow backups
- Large backup sizes
- Replication lag during backup

---

## Automation

### Scheduled Backups

**Cron Schedule:**
```bash
# Daily database backups at 2 AM
0 2 * * * /path/to/scripts/backup/backup-databases.sh

# Weekly physical backups on Sunday at 3 AM
0 3 * * 0 /path/to/scripts/backup/backup-physical.sh

# Daily off-site sync at 4 AM
0 4 * * * /path/to/scripts/backup/sync-backups-offsite.sh

# Weekly backup verification on Monday at 5 AM
0 5 * * 1 /path/to/scripts/backup/verify-backups.sh
```

**systemd Timers:**
```ini
[Unit]
Description=Daily Database Backup

[Timer]
OnCalendar=daily
OnCalendar=02:00

[Install]
WantedBy=timers.target
```

---

## Related Documentation

- [Automated Backup System](./AUTOMATED-BACKUP-SYSTEM.md)
- [Disaster Recovery Plan](./DISASTER-RECOVERY-PLAN.md)
- [High Availability Architecture](../architecture/HIGH-AVAILABILITY.md)

---

**Last Updated:** 2025-12-28

