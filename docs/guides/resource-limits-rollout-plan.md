# Resource Limits Staged Rollout Plan

## Overview
This document provides a safe, staged rollout plan for applying conservative resource limits to production Docker Compose services.

## Prerequisites

**CRITICAL:** Always source environment variables before running docker-compose commands:
```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp
```

## Pre-Rollout Verification

Before starting the rollout, verify current system state:

```bash
# Check current resource usage
docker stats --no-stream

# Verify all services are healthy
/home/comzis/.cursor/projects/home-comzis-inlock/rules/service-health-check.sh

# Check service status
docker compose -f compose/services/stack.yml ps
docker compose -f compose/services/coolify.yml ps
```

## Staged Rollout Plan

### Stage 1: Infrastructure Services (Low Risk)
**Services:** docker-socket-proxy, traefik, oauth2-proxy

These services are critical but have low memory requirements. Start here to validate the approach.

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Apply limits to infrastructure services
docker compose -f compose/services/stack.yml up -d --force-recreate docker-socket-proxy traefik oauth2-proxy

# Wait 30 seconds for services to stabilize
sleep 30

# Verify services are running
docker compose -f compose/services/stack.yml ps docker-socket-proxy traefik oauth2-proxy

# Check resource usage
docker stats --no-stream docker-socket-proxy traefik oauth2-proxy

# Verify functionality
curl -I https://deploy.inlock.ai 2>&1 | head -3
curl -I https://auth.inlock.ai 2>&1 | head -3

# Check logs for errors
docker compose -f compose/services/stack.yml logs --tail 20 traefik oauth2-proxy docker-socket-proxy | grep -i error
```

**Success Criteria:**
- All services show as "running" or "healthy"
- No OOM (Out of Memory) errors in logs
- HTTPS endpoints respond correctly
- Memory usage is within limits

**Wait Period:** 10 minutes before proceeding to Stage 2

---

### Stage 2: Monitoring Services (Medium Risk)
**Services:** node-exporter, blackbox-exporter, postgres-exporter, alertmanager, promtail

These services are monitoring tools that can be restarted without affecting user-facing services.

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Apply limits to monitoring exporters
docker compose -f compose/services/stack.yml up -d --force-recreate node-exporter blackbox-exporter postgres-exporter alertmanager

# Apply limits to logging services
docker compose -f compose/services/stack.yml up -d --force-recreate promtail

# Wait 30 seconds
sleep 30

# Verify services
docker compose -f compose/services/stack.yml ps node-exporter blackbox-exporter postgres-exporter alertmanager promtail

# Check resource usage
docker stats --no-stream node-exporter blackbox-exporter postgres-exporter alertmanager promtail

# Verify metrics are still being collected (check Prometheus targets)
curl -s http://localhost:9100/metrics | head -5
curl -s http://localhost:9115/metrics | head -5
```

**Success Criteria:**
- All services running
- No OOM errors
- Metrics endpoints responding
- Prometheus targets still healthy (if accessible)

**Wait Period:** 15 minutes before proceeding to Stage 3

---

### Stage 3: Management & Observability (Medium-High Risk)
**Services:** portainer, cadvisor, loki, prometheus, grafana

These services are important for management and monitoring but not directly user-facing.

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Apply limits to management services
docker compose -f compose/services/stack.yml up -d --force-recreate portainer cadvisor

# Apply limits to logging
docker compose -f compose/services/stack.yml up -d --force-recreate loki

# Apply limits to monitoring (prometheus has highest memory limit - 1536m)
docker compose -f compose/services/stack.yml up -d --force-recreate prometheus grafana

# Wait 60 seconds (prometheus may take longer to start)
sleep 60

# Verify services
docker compose -f compose/services/stack.yml ps portainer cadvisor loki prometheus grafana

# Check resource usage
docker stats --no-stream portainer cadvisor loki prometheus grafana

# Verify functionality
curl -I https://grafana.inlock.ai 2>&1 | head -3
curl -I https://dashboard.inlock.ai 2>&1 | head -3

# Check Prometheus is collecting data
curl -s http://localhost:9100/metrics | grep -c "prometheus" || echo "Prometheus metrics check"
```

**Success Criteria:**
- All services running
- No OOM errors
- Grafana accessible
- Prometheus collecting metrics
- Loki receiving logs

**Wait Period:** 20 minutes before proceeding to Stage 4

---

### Stage 4: Coolify Services (High Risk)
**Services:** coolify-redis, coolify-soketi, coolify-postgres, coolify

Coolify is the deployment platform. Apply limits carefully and monitor closely.

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Start with supporting services
docker compose -f compose/services/coolify.yml up -d --force-recreate coolify-redis coolify-soketi

# Wait 30 seconds
sleep 30

# Verify Redis and Soketi
docker compose -f compose/services/coolify.yml ps coolify-redis coolify-soketi
docker stats --no-stream coolify-redis coolify-soketi

# Apply limits to database (critical - monitor closely)
docker compose -f compose/services/coolify.yml up -d --force-recreate coolify-postgres

# Wait 60 seconds for database to stabilize
sleep 60

# Verify database connection
docker compose -f compose/services/coolify.yml exec coolify-postgres psql -U coolify -d coolify -c "SELECT 1;" 2>&1

# Apply limits to main Coolify service
docker compose -f compose/services/coolify.yml up -d --force-recreate coolify

# Wait 60 seconds
sleep 60

# Verify Coolify
docker compose -f compose/services/coolify.yml ps coolify
docker stats --no-stream coolify coolify-postgres

# Verify functionality
curl -I https://deploy.inlock.ai 2>&1 | head -3

# Check database connection from Coolify
docker compose -f compose/services/coolify.yml exec coolify sh -c 'php artisan migrate:status' 2>&1 | head -5
```

**Success Criteria:**
- All Coolify services running
- Database connection successful
- Coolify web interface accessible
- No OOM errors
- Database migrations can run

**Wait Period:** 30 minutes before proceeding to Stage 5

---

### Stage 5: Application Services (Highest Risk)
**Services:** inlock-db, inlock-ai, cockpit-proxy

These are the main application services. Apply limits during low-traffic period if possible.

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Start with database
docker compose -f compose/services/inlock-db.yml up -d --force-recreate inlock-db

# Wait 60 seconds for database to stabilize
sleep 60

# Verify database
docker compose -f compose/services/inlock-db.yml ps inlock-db
docker stats --no-stream inlock-db

# Test database connection
docker compose -f compose/services/inlock-db.yml exec inlock-db psql -U inlock -d inlock -c "SELECT 1;" 2>&1

# Apply limits to application
docker compose -f compose/services/inlock-ai.yml up -d --force-recreate inlock-ai

# Wait 90 seconds (application may take time to start)
sleep 90

# Verify application
docker compose -f compose/services/inlock-ai.yml ps inlock-ai
docker stats --no-stream inlock-ai

# Verify application health
curl -I https://inlock.ai 2>&1 | head -3
curl -f http://localhost:3040/api/readiness 2>&1 || echo "Readiness check"

# Apply limits to cockpit-proxy (low risk)
docker compose -f compose/services/cockpit-proxy.yml up -d --force-recreate cockpit-proxy

# Wait 30 seconds
sleep 30

# Verify cockpit-proxy
docker compose -f compose/services/cockpit-proxy.yml ps cockpit-proxy
docker stats --no-stream cockpit-proxy
```

**Success Criteria:**
- Database running and accepting connections
- Application running and healthy
- Main website accessible
- Application API responding
- No OOM errors

**Wait Period:** 60 minutes for final monitoring

---

## Post-Rollout Verification

After all stages are complete, run comprehensive verification:

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Check all services are running
docker compose -f compose/services/stack.yml ps
docker compose -f compose/services/coolify.yml ps
docker compose -f compose/services/inlock-ai.yml ps
docker compose -f compose/services/inlock-db.yml ps
docker compose -f compose/services/cockpit-proxy.yml ps

# Check resource usage across all services
docker stats --no-stream

# Run health check script
/home/comzis/.cursor/projects/home-comzis-inlock/rules/service-health-check.sh

# Check for OOM errors in logs
docker compose -f compose/services/stack.yml logs --since 1h | grep -i "oom\|out of memory" || echo "No OOM errors found"
docker compose -f compose/services/coolify.yml logs --since 1h | grep -i "oom\|out of memory" || echo "No OOM errors found"
docker compose -f compose/services/inlock-ai.yml logs --since 1h | grep -i "oom\|out of memory" || echo "No OOM errors found"

# Verify key endpoints
curl -I https://inlock.ai 2>&1 | head -3
curl -I https://deploy.inlock.ai 2>&1 | head -3
curl -I https://grafana.inlock.ai 2>&1 | head -3
```

## Rollback Procedure

If any service fails or shows OOM errors, rollback immediately:

```bash
source /home/comzis/inlock/.env
cd /home/comzis/projects/inlock-ai-mvp

# Remove resource limits from affected service(s)
# Edit the compose file to remove mem_limit, mem_reservation, and deploy.resources

# Recreate service without limits
docker compose -f compose/services/<file>.yml up -d --force-recreate <service>

# Verify service recovers
docker compose -f compose/services/<file>.yml ps <service>
docker stats --no-stream <service>
```

## Monitoring During Rollout

During the rollout, monitor:

1. **Memory Usage:** `docker stats --no-stream`
2. **Service Health:** `docker compose ps` and health checks
3. **Logs:** Watch for OOM errors, connection failures
4. **Application Metrics:** Check Prometheus/Grafana if accessible
5. **User-Facing Services:** Test HTTPS endpoints regularly

## Resource Limits Summary

| Service | Memory Limit | Memory Reservation |
|---------|-------------|-------------------|
| coolify | 1536m | 512m |
| coolify-postgres | 1g | 256m |
| coolify-redis | 512m | 128m |
| coolify-soketi | 512m | 128m |
| traefik | 256m | 64m |
| oauth2-proxy | 256m | 64m |
| docker-socket-proxy | 128m | 32m |
| portainer | 384m | 128m |
| cadvisor | 384m | 128m |
| prometheus | 1536m | 512m |
| grafana | 512m | 128m |
| alertmanager | 256m | 64m |
| node-exporter | 128m | 32m |
| blackbox-exporter | 128m | 32m |
| postgres-exporter | 128m | 32m |
| loki | 768m | 256m |
| promtail | 256m | 64m |
| inlock-ai | 768m | 256m |
| inlock-db | 768m | 256m |
| cockpit-proxy | 128m | 32m |

## Notes

- All limits are conservative and based on current usage patterns
- Memory limits are hard limits (OOM kill if exceeded)
- Memory reservations are soft guarantees (preferred allocation)
- `deploy.resources` matches limits for consistency (Swarm compatibility)
- Services will be recreated to apply limits (brief downtime expected)
- Monitor closely during first 24 hours after rollout
