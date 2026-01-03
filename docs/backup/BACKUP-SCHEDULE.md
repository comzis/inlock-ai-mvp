# Backup Schedule and Usage Guide

## Automatic Backup Schedule

### Daily Automated Backups

**Schedule:** Daily at **03:00 (3:00 AM)** local time

**Cron Configuration:**
```cron
0 3 * * * /home/comzis/inlock/scripts/backup/automated-backup-system.sh >> /home/comzis/inlock/logs/backup.log 2>&1
```

**What Runs:**
- Database backups (PostgreSQL: inlock, n8n)
- Volume backups (Docker volumes, encrypted)
- Automatic cleanup of old backups (> 7 days)

**Logs:**
- Main log: `logs/backup.log`
- Detailed log: `logs/inlock-backup-system.log`

---

## Manual Backup Execution

### Run All Backups

```bash
cd /home/comzis/inlock
./scripts/backup/automated-backup-system.sh --backup-type all
```

### Run Only Database Backups

```bash
./scripts/backup/automated-backup-system.sh --backup-type databases
```

### Run Only Volume Backups

```bash
./scripts/backup/automated-backup-system.sh --backup-type volumes
```

### Run with Verification

```bash
./scripts/backup/automated-backup-system.sh --backup-type all --verify
```

### Run with Cleanup

```bash
./scripts/backup/automated-backup-system.sh --backup-type all --cleanup
```

---

## Installing/Verifying Cron Job

### Install Cron Job

```bash
cd /home/comzis/inlock
sudo bash scripts/backup/install-backup-cron.sh
```

### Verify Cron Job is Installed

```bash
# Check user crontab
crontab -l | grep backup

# Check root crontab (if installed as root)
sudo crontab -l -u root | grep backup
```

### Expected Output

```
0 3 * * * /home/comzis/inlock/scripts/backup/automated-backup-system.sh >> /home/comzis/inlock/logs/backup.log 2>&1
```

---

## Backup Timing Rationale

### Why 03:00 AM?

1. **Low Network Activity**
   - Minimal user traffic
   - Reduced impact on Tailscale
   - Optimal for network stability

2. **Low System Load**
   - Fewer active services
   - More resources available
   - Faster backup completion

3. **Off-Peak Hours**
   - No user disruption
   - Maintenance window
   - Standard practice

### Changing Backup Time

To change the backup schedule, edit the cron job:

```bash
crontab -e
```

Change the time in the cron expression:
- `0 3 * * *` = 03:00 daily
- `0 2 * * *` = 02:00 daily
- `0 4 * * *` = 04:00 daily
- `0 3 * * 0` = 03:00 on Sundays only
- `0 3 1 * *` = 03:00 on the 1st of each month

**Cron Format:** `minute hour day month weekday`

---

## Checking Backup Status

### View Recent Backup Logs

```bash
# Last 50 lines of backup log
tail -50 /home/comzis/inlock/logs/inlock-backup-system.log

# Last backup time
ls -lh /home/comzis/inlock/logs/backup.log

# Search for errors
grep -i error /home/comzis/inlock/logs/inlock-backup-system.log | tail -10
```

### Check Backup Files

```bash
# List recent backups
ls -lth ~/backups/inlock/encrypted/ | head -10

# Check backup size
du -sh ~/backups/inlock/encrypted/
```

### Verify Backup Success

```bash
# Check last backup completion
tail -20 /home/comzis/inlock/logs/inlock-backup-system.log | grep -E "completed|failed|ERROR"
```

---

## Backup Schedule Summary

| Schedule | Type | Time | Command |
|----------|------|------|---------|
| **Automatic** | Daily | 03:00 AM | Cron job |
| **Manual** | On-demand | Anytime | `./scripts/backup/automated-backup-system.sh` |
| **With Verification** | On-demand | Anytime | `./scripts/backup/automated-backup-system.sh --verify` |
| **With Cleanup** | On-demand | Anytime | `./scripts/backup/automated-backup-system.sh --cleanup` |

---

## Troubleshooting

### Backup Not Running Automatically

1. **Check if cron is installed:**
   ```bash
   crontab -l | grep backup
   ```

2. **Install cron job if missing:**
   ```bash
   sudo bash scripts/backup/install-backup-cron.sh
   ```

3. **Check cron service:**
   ```bash
   systemctl status cron
   ```

4. **Check cron logs:**
   ```bash
   grep CRON /var/log/syslog | tail -20
   ```

### Backup Running at Wrong Time

1. **View current cron:**
   ```bash
   crontab -l
   ```

2. **Edit cron:**
   ```bash
   crontab -e
   ```

3. **Update time in cron expression**

### Backup Failing

1. **Check logs:**
   ```bash
   tail -50 /home/comzis/inlock/logs/inlock-backup-system.log
   ```

2. **Run manually to see errors:**
   ```bash
   ./scripts/backup/automated-backup-system.sh --backup-type all
   ```

3. **Check disk space:**
   ```bash
   df -h ~/backups/inlock/
   ```

---

## Best Practices

1. **Monitor First Few Automatic Backups**
   - Verify they run successfully
   - Check logs for errors
   - Confirm backup files are created

2. **Run Manual Backup Before Major Changes**
   - Before system updates
   - Before configuration changes
   - Before service restarts

3. **Verify Backups Periodically**
   - Test restore process monthly
   - Verify backup integrity
   - Check backup retention

4. **Monitor Disk Space**
   - Backups are kept for 7 days (volumes) / 30 days (encrypted)
   - Monitor backup directory size
   - Clean up if needed

---

## Related Documentation

- [Backup System Overview](./README.md)
- [Backup and Tailscale Optimization](./BACKUP-TAILSCALE-OPTIMIZATION.md)
- [Disaster Recovery Guide](./disaster-recovery.md)

---

**Last Updated:** January 3, 2026  
**Next Scheduled Backup:** Daily at 03:00 AM  
**Backup Script:** `scripts/backup/automated-backup-system.sh`

