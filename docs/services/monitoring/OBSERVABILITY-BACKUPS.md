# Observability & Backups

## Overview

This document covers monitoring, observability, and backup/restore procedures for the INLOCK.AI infrastructure.

## Monitoring Stack

### Current State

**Available Metrics:**
- **Traefik:** Prometheus metrics on port 8080 (`/metrics`)
- **cAdvisor:** Container metrics on port 8080 (`/metrics`)
- **Postgres:** Can be monitored via pg_stat_statements (if enabled)

**Gaps:**
- Prometheus not deployed (metrics not scraped)
- Grafana not deployed (no visualization)
- Alerting not configured

### Traefik Metrics

Traefik exposes Prometheus metrics on the `metrics` entrypoint:

```bash
# Access metrics from host
curl http://localhost:8080/metrics

# Or from within Docker network
docker compose -f compose/stack.yml --env-file .env exec traefik wget -qO- http://localhost:8080/metrics
```

**Key Metrics:**
- `traefik_entrypoint_requests_total` - Request count per entrypoint
- `traefik_service_requests_total` - Request count per service
- `traefik_entrypoint_request_duration_seconds` - Request latency
- `traefik_certificate_expiration_timestamp_seconds` - Certificate expiration

### cAdvisor Metrics

cAdvisor provides container resource usage metrics:

```bash
# Access metrics
curl http://localhost:8080/metrics
```

**Key Metrics:**
- `container_cpu_usage_seconds_total` - CPU usage
- `container_memory_usage_bytes` - Memory usage
- `container_network_receive_bytes_total` - Network receive
- `container_network_transmit_bytes_total` - Network transmit

### Recommended Monitoring Stack

**Option 1: Prometheus + Grafana (Recommended)**

1. **Deploy Prometheus:**
   ```yaml
   # compose/monitoring.yml
   services:
     prometheus:
       image: prom/prometheus:latest
       volumes:
         - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
         - prometheus_data:/prometheus
       command:
         - '--config.file=/etc/prometheus/prometheus.yml'
         - '--storage.tsdb.path=/prometheus'
       networks:
         - mgmt
   ```

2. **Deploy Grafana:**
   ```yaml
   services:
     grafana:
       image: grafana/grafana:latest
       volumes:
         - grafana_data:/var/lib/grafana
       networks:
         - mgmt
         - edge
   ```

3. **Configure Prometheus Scraping:**
   ```yaml
   # prometheus/prometheus.yml
   scrape_configs:
     - job_name: 'traefik'
       static_configs:
         - targets: ['traefik:8080']
     - job_name: 'cadvisor'
       static_configs:
         - targets: ['cadvisor:8080']
   ```

**Option 2: Use Provider Monitoring**

- **Hetzner Cloud:** Built-in monitoring dashboard
- **Cloudflare:** Analytics and logs
- **External:** Datadog, New Relic, etc.

## Backups

### Backup Strategy

**Volume Backups:**
- **Frequency:** Daily (automated via cron)
- **Retention:** 7 days local, 30 days encrypted
- **Encryption:** GPG (required for sensitive data)
- **Storage:** Local + optional Restic repository

**Database Backups:**
- **Postgres:** Daily pg_dump (encrypted)
- **n8n:** Included in volume backup (workflows in volume)

**Configuration Backups:**
- **Git:** All configs in Git repository
- **Secrets:** Stored separately (not in Git)

### Backup Scripts

#### Volume Backup (`scripts/backup-volumes.sh`)

**⚠️ IMPORTANT: Encryption is REQUIRED. Backups will fail if GPG key is not imported.**

**Usage:**
```bash
# 1. First, ensure GPG key is imported (one-time setup)
./scripts/import-gpg-key.sh /path/to/admin-inlock-ai.pub

# 2. Verify backup readiness
./scripts/check-backup-readiness.sh

# 3. Set GPG recipient (required for encryption)
export GPG_RECIPIENT="admin@inlock.ai"

# 4. Run backup
./scripts/backup-volumes.sh
```

**Features:**
- **Encryption Required:** Backups will fail if GPG key is not available
- **No Plaintext:** Backups are encrypted directly (tar | gpg) - no unencrypted files on disk
- **Streaming Encryption:** Tar output is piped directly to GPG to avoid plaintext intermediate files
- Optional Restic upload
- Automatic cleanup (7 days local, 30 days encrypted)

**Output:**
- Encrypted backup: `/var/backups/inlock/encrypted/volumes-YYYY-MM-DD-HHMMSS.tar.gz.gpg`

**Error Handling:**
- Script will exit with error if GPG is not installed
- Script will exit with error if GPG_RECIPIENT is not set
- Script will exit with error if GPG public key is not imported
- Provides helpful error messages with import instructions

#### Database Backup

**Postgres Backup:**
```bash
# Manual backup
docker compose -f compose/postgres.yml --env-file .env exec postgres \
  pg_dump -U n8n n8n | gpg --encrypt --recipient admin@inlock.ai \
  > /var/backups/inlock/encrypted/postgres-$(date +%F).sql.gpg
```

**Automated Backup Script:**
```bash
#!/bin/bash
# scripts/backup-databases.sh

BACKUP_DIR="/var/backups/inlock/encrypted"
GPG_RECIPIENT="${GPG_RECIPIENT:-admin@inlock.ai}"

mkdir -p "$BACKUP_DIR"

# Backup Postgres
docker compose -f compose/postgres.yml --env-file .env exec -T postgres \
  pg_dump -U n8n n8n | \
  gpg --encrypt --recipient "$GPG_RECIPIENT" \
  > "$BACKUP_DIR/postgres-$(date +%F-%H%M%S).sql.gpg"

echo "✅ Database backup complete: $BACKUP_DIR/postgres-*.sql.gpg"
```

### Restore Procedures

#### Volume Restore (`scripts/restore-volumes.sh`)

**Usage:**
```bash
# Restore from encrypted backup
./scripts/restore-volumes.sh /var/backups/inlock/encrypted/volumes-2025-12-08-120000.tar.gz.gpg --gpg

# Restore from Restic
./scripts/restore-volumes.sh latest --restic
```

**Steps:**
1. Stops all services
2. Decrypts backup (if GPG)
3. Extracts to `/var/lib/docker/volumes`
4. Cleans up temporary files
5. Restart services manually

**⚠️ Warning:** This will overwrite existing volumes!

#### Database Restore

**Postgres Restore:**
```bash
# Decrypt and restore
gpg --decrypt /var/backups/inlock/encrypted/postgres-2025-12-08.sql.gpg | \
  docker compose -f compose/postgres.yml --env-file .env exec -T postgres \
  psql -U n8n -d n8n
```

### Backup Testing

**Test Restore Procedure:**
```bash
# 1. Create test backup
./scripts/backup-volumes.sh

# 2. Create test volume
docker volume create test_volume
echo "test data" | docker run --rm -i -v test_volume:/data alpine sh -c "cat > /data/test.txt"

# 3. Restore backup (this will overwrite test_volume if it exists in backup)
./scripts/restore-volumes.sh /var/backups/inlock/encrypted/volumes-*.tar.gz.gpg --gpg

# 4. Verify restore
docker run --rm -v test_volume:/data alpine cat /data/test.txt
```

### Automated Backups

**Cron Job Setup:**
```bash
# Add to crontab (crontab -e)
# Daily backup at 2 AM
0 2 * * * /home/comzis/inlock-infra/scripts/backup-volumes.sh >> /var/log/backup.log 2>&1
0 3 * * * /home/comzis/inlock-infra/scripts/backup-databases.sh >> /var/log/backup.log 2>&1
```

**Systemd Timer (Alternative):**
```ini
# /etc/systemd/system/inlock-backup.service
[Unit]
Description=INLOCK Infrastructure Backup
After=docker.service

[Service]
Type=oneshot
ExecStart=/home/comzis/inlock-infra/scripts/backup-volumes.sh
ExecStart=/home/comzis/inlock-infra/scripts/backup-databases.sh
```

```ini
# /etc/systemd/system/inlock-backup.timer
[Unit]
Description=Daily INLOCK Backup

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

## Encryption

### GPG Setup

**Generate GPG Key:**
```bash
gpg --full-generate-key
# Select: RSA and RSA, 4096 bits, no expiration
# Email: admin@inlock.ai
```

**Export Public Key:**
```bash
gpg --armor --export admin@inlock.ai > admin-public-key.asc
```

**Import Public Key (on backup server):**
```bash
# Using helper script (recommended)
./scripts/import-gpg-key.sh /path/to/admin-public-key.asc

# Or manually
gpg --import admin-public-key.asc

# Verify import
gpg --list-keys admin@inlock.ai
```

**Check Backup Readiness:**
```bash
# Run health check before backups
./scripts/check-backup-readiness.sh
```

This will verify:
- GPG key is imported and available
- Backup script is executable
- All prerequisites are met

### Restic Setup

**Initialize Repository:**
```bash
# Backblaze B2
restic -r b2:inlock-infra init

# Or local/S3/etc.
restic -r /backup/inlock init
```

**Set Password:**
```bash
mkdir -p /root/.config/restic
echo "your-restic-password" > /root/.config/restic/password
chmod 600 /root/.config/restic/password
```

**Backup to Restic:**
```bash
restic -r b2:inlock-infra \
  --password-file /root/.config/restic/password \
  backup /var/backups/inlock/encrypted
```

## Disaster Recovery

### Recovery Procedures

**1. Full Infrastructure Restore:**
```bash
# Restore volumes
./scripts/restore-volumes.sh /path/to/backup.tar.gz.gpg --gpg

# Restore databases
gpg --decrypt postgres-*.sql.gpg | docker compose ... exec -T postgres psql ...

# Start services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d
```

**2. Partial Restore (Single Service):**
```bash
# Stop service
docker compose -f compose/n8n.yml --env-file .env stop n8n

# Restore specific volume
docker run --rm \
  -v n8n_data:/dest \
  -v /backup/n8n_data.tar.gz:/backup.tar.gz:ro \
  alpine:3.20 \
  sh -c "cd /dest && tar xzf /backup.tar.gz"

# Start service
docker compose -f compose/n8n.yml --env-file .env start n8n
```

**3. Configuration Restore:**
```bash
# Restore from Git
git clone https://github.com/your-org/inlock-infra.git
cd inlock-infra

# Restore secrets (from secure location)
cp /secure/backup/secrets/* /home/comzis/apps/secrets-real/

# Deploy
./scripts/deploy-hardened-stack.sh
```

### Recovery Testing

**Quarterly DR Test:**
1. Create backup
2. Stop all services
3. Restore from backup
4. Verify all services healthy
5. Document any issues

## Monitoring Alerts

### Recommended Alerts

**Service Health:**
- Container down > 5 minutes
- Healthcheck failing > 3 attempts
- Restart loop detected

**Resource Usage:**
- CPU > 80% for 10 minutes
- Memory > 90% for 5 minutes
- Disk > 85% full

**Certificate Expiration:**
- PositiveSSL expires in 30 days
- Let's Encrypt expires in 7 days

**Backup Status:**
- Backup failed
- Backup older than 25 hours
- Restore test failed

### Alert Channels

- **Email:** admin@inlock.ai
- **Slack/Discord:** (if configured)
- **PagerDuty:** (for critical alerts)

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Restic Documentation](https://restic.readthedocs.io/)
- [GPG Documentation](https://www.gnupg.org/documentation/)
- [Docker Volume Backup](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)


