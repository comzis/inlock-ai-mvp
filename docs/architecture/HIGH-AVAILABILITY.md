# High Availability Architecture

**Date:** 2025-12-28  
**Status:** Design Document

---

## Overview

This document outlines the high availability (HA) architecture design for the inlock-ai infrastructure, focusing on database replication, load balancing, and disaster recovery strategies.

---

## Current State

### Single Server Architecture

**Current Setup:**
- Single server hosting all services
- Single PostgreSQL instance
- No replication or redundancy
- Manual backup procedures

**Limitations:**
- Single point of failure
- No automatic failover
- Downtime during maintenance
- Limited scalability

---

## Target Architecture

### Multi-Server High Availability

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
│                  (Traefik HA / DNS)                     │
└────────────┬──────────────────────────────┬─────────────┘
             │                              │
    ┌────────▼────────┐          ┌─────────▼─────────┐
    │   Server 1      │          │   Server 2        │
    │  (Primary)      │◄────────►│  (Secondary)      │
    │                 │          │                   │
    │  - Traefik      │          │  - Traefik        │
    │  - Services     │          │  - Services       │
    │  - PostgreSQL   │          │  - PostgreSQL     │
    │    (Primary)    │          │    (Standby)      │
    │                 │          │                   │
    │  - Redis        │          │  - Redis          │
    │  - Coolify      │          │  - (Standby)      │
    └─────────────────┘          └───────────────────┘
             │                              │
             └──────────┬───────────────────┘
                        │
                ┌───────▼────────┐
                │  Shared Storage│
                │  (Backups)     │
                └────────────────┘
```

---

## Phase 3A: Database Replication (PostgreSQL)

### Architecture

**Primary (Server 1):**
- Accepts read/write connections
- Streams WAL to standby
- Handles all writes

**Standby (Server 2):**
- Receives WAL stream from primary
- Read-only connections
- Automatic failover capability

### Configuration

#### Primary Server Setup

**PostgreSQL Configuration (`postgresql.conf`):**
```conf
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
```

**Replication User:**
```sql
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'secure_password';
```

**Replication Slot:**
```sql
SELECT pg_create_physical_replication_slot('standby_slot');
```

#### Standby Server Setup

**Recovery Configuration (`postgresql.conf`):**
```conf
hot_standby = on
```

**Recovery File (`recovery.conf` or `postgresql.auto.conf`):**
```
primary_conninfo = 'host=primary_server port=5432 user=replicator'
primary_slot_name = 'standby_slot'
```

### Implementation Scripts

- `scripts/ha/setup-postgres-replication.sh` - Configure primary
- `scripts/ha/setup-postgres-standby.sh` - Configure standby
- `scripts/ha/promote-postgres-standby.sh` - Promote standby to primary
- `scripts/ha/monitor-postgres-replication.sh` - Monitor replication lag

### Monitoring

**Replication Lag:**
```sql
SELECT 
    client_addr,
    state,
    sync_state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS replication_lag_bytes
FROM pg_stat_replication;
```

**Health Checks:**
- Monitor replication lag (target: < 1MB)
- Check standby connection status
- Alert on replication failures

---

## Phase 3B: Load Balancing & Redundancy

### Traefik High Availability

**Option 1: Multiple Traefik Instances**

Run Traefik on both servers with shared configuration:

```yaml
services:
  traefik-primary:
    # Server 1
    networks:
      - edge
    
  traefik-secondary:
    # Server 2
    networks:
      - edge
```

**Shared Configuration:**
- Use external storage (Consul, etcd, or file sync)
- Keep routers and services in sync
- DNS round-robin or health-checked load balancing

**Option 2: Traefik with Consul/etcd**

Use Consul or etcd for shared configuration:
- Dynamic configuration storage
- Automatic discovery
- Configuration synchronization

### Service Redundancy

**Stateless Services:**
- Run on both servers
- Load balanced via Traefik
- No special configuration needed

**Stateful Services:**
- Database: Replicated (Phase 3A)
- Redis: Consider Redis Sentinel or Cluster
- Coolify: Primary/Secondary setup

### Health Checks

**Traefik Health Checks:**
```yaml
healthcheck:
  path: /ping
  interval: 10s
  timeout: 3s
```

**Service Health Endpoints:**
- All services should expose `/health` endpoint
- Traefik configured to check health
- Unhealthy services automatically removed from load balancer

---

## Phase 3C: Backup & Disaster Recovery

### Backup Strategy

**Automated Backups:**
- Daily full backups
- Continuous WAL archiving (for PITR)
- Off-site backup sync
- Backup verification

**Backup Locations:**
- Local: `/var/backups/inlock/`
- Off-site: S3, Backblaze B2, or similar
- Encrypted backups (GPG)

### Point-in-Time Recovery (PITR)

**Requirements:**
- WAL archiving enabled
- Base backups available
- WAL archive accessible

**Recovery Procedure:**
1. Restore base backup
2. Copy WAL files to recovery location
3. Configure recovery target
4. Start PostgreSQL in recovery mode

### Disaster Recovery Plan

**Recovery Time Objective (RTO):** < 1 hour  
**Recovery Point Objective (RPO):** < 15 minutes

**Recovery Procedures:**
1. **Full Infrastructure Restore:**
   - Restore from latest backup
   - Restore databases
   - Restore volumes
   - Verify services

2. **Partial Restore (Single Service):**
   - Stop service
   - Restore service data
   - Restart service
   - Verify functionality

3. **Database Failover:**
   - Promote standby to primary
   - Update connection strings
   - Reconfigure services
   - Monitor for issues

---

## Implementation Phases

### Phase 1: Single Server Improvements (Current)

- ✅ Automated backups
- ✅ Health checks
- ✅ Monitoring
- ✅ Documentation

### Phase 2: Database Replication

**Prerequisites:**
- Second server available
- Network connectivity between servers
- Shared backup storage (optional)

**Steps:**
1. Set up primary PostgreSQL with replication
2. Configure standby PostgreSQL
3. Test replication
4. Implement monitoring
5. Document failover procedures

### Phase 3: Service Redundancy

**Steps:**
1. Set up Traefik HA
2. Configure load balancing
3. Deploy services on both servers
4. Test failover scenarios
5. Monitor performance

### Phase 4: Advanced Features

**Future Enhancements:**
- Redis Sentinel/Cluster
- Multi-region replication
- Automatic failover
- Zero-downtime deployments

---

## Network Requirements

### Server-to-Server Communication

**Required Ports:**
- PostgreSQL: 5432 (replication)
- Traefik API: 8080 (optional, for HA)
- SSH: 22 (management)
- Docker networks: Internal only

**Network Security:**
- VPN (Tailscale) for management
- Firewall rules for replication
- Encrypted replication connections

### Load Balancer Configuration

**DNS Configuration:**
- Round-robin DNS for multiple Traefik instances
- Health-checked DNS (Route53, etc.)
- Geographic DNS (future)

---

## Monitoring & Alerting

### Key Metrics

**Database:**
- Replication lag
- Connection counts
- Query performance
- WAL generation rate

**Services:**
- Health check status
- Response times
- Error rates
- Resource usage

**Infrastructure:**
- Server health
- Network connectivity
- Disk usage
- Backup status

### Alerts

**Critical:**
- Replication lag > 1MB
- Primary database down
- Standby database down
- Backup failures

**Warning:**
- High replication lag
- High connection counts
- Disk usage > 80%
- Service health check failures

---

## Testing & Validation

### Replication Testing

1. **Test Replication:**
   - Create test data on primary
   - Verify data appears on standby
   - Check replication lag

2. **Test Failover:**
   - Stop primary database
   - Promote standby to primary
   - Verify services work
   - Test failback

### Disaster Recovery Testing

1. **Quarterly DR Tests:**
   - Simulate disaster scenario
   - Execute recovery procedures
   - Validate data integrity
   - Document results

2. **Backup Restoration:**
   - Test backup restoration
   - Verify data integrity
   - Measure recovery time

---

## Cost Considerations

### Infrastructure Costs

**Current (Single Server):**
- 1 server

**High Availability:**
- 2 servers (2x cost)
- Shared backup storage
- Additional network bandwidth

**Trade-offs:**
- Higher cost vs. improved reliability
- Reduced downtime
- Better disaster recovery

---

## Related Documentation

- [Database Backup Strategy](../backup/DATABASE-BACKUP-STRATEGY.md)
- [Automated Backup System](../backup/AUTOMATED-BACKUP-SYSTEM.md)
- [Disaster Recovery Plan](../backup/DISASTER-RECOVERY-PLAN.md)
- [Container Structure](./CONTAINER-STRUCTURE.md)
- [Traefik HA Configuration](./TRAEFIK-HA.md)

---

## Next Steps

1. Review this architecture document
2. Assess infrastructure requirements
3. Plan implementation phases
4. Set up second server (when ready)
5. Begin Phase 2 implementation

---

**Last Updated:** 2025-12-28  
**Status:** Design Phase - Implementation pending infrastructure

