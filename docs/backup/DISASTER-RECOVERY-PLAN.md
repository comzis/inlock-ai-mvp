# Disaster Recovery Plan

**Date:** 2025-12-28  
**Status:** Active Plan

---

## Overview

This document outlines the disaster recovery procedures for the inlock-ai infrastructure, including recovery time objectives (RTO), recovery point objectives (RPO), and step-by-step recovery procedures.

---

## Recovery Objectives

### Recovery Time Objective (RTO)

**Target:** < 1 hour

**Definition:** Maximum acceptable downtime before services are restored.

**Breakdown:**
- Detection: 5 minutes
- Assessment: 10 minutes
- Recovery execution: 30 minutes
- Verification: 15 minutes

### Recovery Point Objective (RPO)

**Target:** < 15 minutes

**Definition:** Maximum acceptable data loss (time between last backup and failure).

**Achieved through:**
- Continuous WAL archiving (PostgreSQL)
- Frequent backups (daily)
- Replication (when configured)

---

## Disaster Scenarios

### Scenario 1: Complete Server Failure

**Impact:**
- All services down
- No access to server
- Data on server may be lost

**Recovery Steps:**
1. Provision new server
2. Restore from latest backup
3. Restore databases
4. Restore volumes
5. Configure services
6. Verify functionality

**Estimated Time:** 45-60 minutes

### Scenario 2: Database Corruption

**Impact:**
- Database unavailable
- Application errors
- Data may be lost

**Recovery Steps:**
1. Stop affected services
2. Restore database from backup
3. Apply WAL archives (if PITR)
4. Verify data integrity
5. Restart services
6. Monitor for issues

**Estimated Time:** 20-30 minutes

### Scenario 3: Data Loss (Accidental Deletion)

**Impact:**
- Specific data missing
- Application functional but incomplete

**Recovery Steps:**
1. Identify data loss scope
2. Determine recovery point
3. Restore from appropriate backup
4. Verify restored data
5. Update application if needed

**Estimated Time:** 15-30 minutes

### Scenario 4: Security Breach

**Impact:**
- Potential data compromise
- System integrity questioned
- Services may be compromised

**Recovery Steps:**
1. Isolate affected systems
2. Assess damage
3. Restore from clean backup
4. Update security measures
5. Rotate credentials
6. Monitor for suspicious activity

**Estimated Time:** 1-2 hours

### Scenario 5: Partial Service Failure

**Impact:**
- Some services down
- Others functional
- Degraded functionality

**Recovery Steps:**
1. Identify failed services
2. Check service health
3. Restart failed services
4. Restore service data if needed
5. Verify functionality

**Estimated Time:** 10-20 minutes

---

## Recovery Procedures

### Full Infrastructure Restore

**Prerequisites:**
- New server provisioned
- Backup files available
- GPG decryption key
- Network connectivity

**Steps:**

1. **Server Preparation:**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo apt install docker-compose-plugin
   
   # Clone repository
   git clone <repository-url>
   cd inlock-ai-mvp
   ```

2. **Restore Volumes:**
   ```bash
   ./scripts/backup/restore-volumes.sh /path/to/backup.tar.gz.gpg --gpg
   ```

3. **Restore Databases:**
   ```bash
   # Start database services
   docker compose -f compose/services/inlock-db.yml up -d
   
   # Wait for database to be ready
   sleep 10
   
   # Restore database
   gpg --decrypt database-YYYY-MM-DD.sql.gpg | \
       docker compose -f compose/services/inlock-db.yml exec -T inlock-db \
       psql -U inlock -d inlock
   ```

4. **Start Services:**
   ```bash
   docker compose -f compose/services/stack.yml up -d
   ```

5. **Verify:**
   - Check service health
   - Test application functionality
   - Verify data integrity
   - Check monitoring

### Database Restore

**Prerequisites:**
- Database backup available
- PostgreSQL service running
- GPG decryption key

**Steps:**

1. **Stop Affected Services:**
   ```bash
   docker compose -f compose/services/stack.yml stop inlock-ai
   ```

2. **Restore Database:**
   ```bash
   # Full restore
   gpg --decrypt database-YYYY-MM-DD.sql.gpg | \
       docker compose -f compose/services/inlock-db.yml exec -T inlock-db \
       psql -U inlock -d inlock
   
   # Or restore to new database
   gpg --decrypt database-YYYY-MM-DD.sql.gpg | \
       docker compose -f compose/services/inlock-db.yml exec -T inlock-db \
       psql -U inlock -d inlock_restored
   ```

3. **Point-in-Time Recovery (if WAL archiving enabled):**
   ```bash
   # Restore base backup
   # Configure recovery.conf
   # Start PostgreSQL (will recover to target time)
   ```

4. **Restart Services:**
   ```bash
   docker compose -f compose/services/stack.yml start inlock-ai
   ```

5. **Verify:**
   - Check database connectivity
   - Verify data integrity
   - Test application functionality

### Volume Restore

**Prerequisites:**
- Volume backup available
- Services stopped
- GPG decryption key

**Steps:**

1. **Stop Services:**
   ```bash
   docker compose -f compose/services/stack.yml down
   ```

2. **Restore Volume:**
   ```bash
   ./scripts/backup/restore-volumes.sh /path/to/volume-backup.tar.gz.gpg --gpg
   ```

3. **Start Services:**
   ```bash
   docker compose -f compose/services/stack.yml up -d
   ```

4. **Verify:**
   - Check volume contents
   - Verify service functionality
   - Test application features

---

## Backup Verification

### Pre-Recovery Verification

Before starting recovery:

1. **Verify Backup Integrity:**
   ```bash
   ./scripts/backup/verify-backups.sh
   ```

2. **Test Decryption:**
   ```bash
   gpg --decrypt --dry-run backup-file.gpg
   ```

3. **Check Backup Age:**
   ```bash
   ls -lh /var/backups/inlock/
   ```

### Post-Recovery Verification

After recovery:

1. **Service Health:**
   ```bash
   ./scripts/ha/check-service-health.sh
   ```

2. **Database Integrity:**
   ```bash
   docker compose -f compose/services/inlock-db.yml exec inlock-db \
       psql -U inlock -c "SELECT COUNT(*) FROM information_schema.tables;"
   ```

3. **Application Functionality:**
   - Test login
   - Test key features
   - Verify data access
   - Check monitoring

---

## Testing Schedule

### Quarterly DR Tests

**Schedule:**
- Q1: Full infrastructure restore
- Q2: Database restore
- Q3: Volume restore
- Q4: Complete DR test

**Procedure:**
1. Schedule test window
2. Create test environment
3. Execute recovery procedure
4. Verify functionality
5. Document results
6. Update procedures if needed

### Monthly Verification

**Checks:**
- Backup integrity
- Off-site sync status
- Retention compliance
- Recovery procedure updates

---

## Communication Plan

### Incident Response

**Notification Chain:**
1. Detection → Alert admin
2. Assessment → Notify stakeholders
3. Recovery → Status updates
4. Resolution → Post-mortem

### Stakeholders

- System Administrator
- Security Team
- Management
- Users (if extended outage)

### Status Updates

- Initial notification: Within 5 minutes
- Progress updates: Every 15 minutes
- Resolution notification: Immediately

---

## Recovery Resources

### Backup Locations

**Local:**
- `/var/backups/inlock/`
- Encrypted backups (GPG)

**Off-Site:**
- S3: `s3://inlock-backups/`
- Backblaze B2: `b2:inlock-backups/`

### Documentation

- This document (DR Plan)
- Backup procedures
- Service configuration
- Recovery scripts

### Contacts

**Internal:**
- Admin: admin@inlock.ai
- On-call: (update as needed)

**External:**
- Cloud provider support
- Backup service support
- Security team

---

## Post-Recovery

### Immediate Actions

1. **Document Incident:**
   - Timeline
   - Root cause
   - Recovery steps
   - Lessons learned

2. **Monitor:**
   - Service health
   - Error logs
   - Performance metrics
   - User reports

3. **Update:**
   - Security measures
   - Backup procedures
   - Monitoring
   - Documentation

### Post-Mortem

**Within 24 Hours:**
- Incident timeline
- Root cause analysis
- Impact assessment
- Recovery evaluation

**Within 1 Week:**
- Detailed post-mortem
- Action items
- Procedure updates
- Training recommendations

---

## Related Documentation

- [Database Backup Strategy](./DATABASE-BACKUP-STRATEGY.md)
- [Automated Backup System](./AUTOMATED-BACKUP-SYSTEM.md)
- [High Availability Architecture](../architecture/HIGH-AVAILABILITY.md)

---

**Last Updated:** 2025-12-28  
**Next Review:** Quarterly or after incidents


