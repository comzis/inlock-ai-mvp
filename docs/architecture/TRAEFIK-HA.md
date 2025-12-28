# Traefik High Availability Configuration

**Date:** 2025-12-28  
**Status:** Design Document

---

## Overview

This document describes the high availability (HA) configuration for Traefik reverse proxy, enabling redundancy and failover capabilities.

---

## Current Setup

### Single Traefik Instance

**Current Configuration:**
- Single Traefik container
- File-based dynamic configuration
- No redundancy

**Limitations:**
- Single point of failure
- Downtime during updates
- No automatic failover

---

## Target Architecture

### Multiple Traefik Instances

```
                    ┌─────────────┐
                    │   DNS/LB    │
                    │  (Round-Robin)│
                    └──────┬──────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
    ┌───────▼────────┐          ┌────────▼────────┐
    │  Traefik 1     │          │  Traefik 2      │
    │  (Server 1)    │          │  (Server 2)     │
    └───────┬────────┘          └────────┬────────┘
            │                             │
            └──────────────┬──────────────┘
                           │
                    ┌──────▼──────┐
                    │  Services   │
                    │  (Backend)  │
                    └─────────────┘
```

---

## Implementation Options

### Option 1: File-Based Configuration Sync

**Approach:**
- Multiple Traefik instances
- Shared configuration files (via Git, rsync, or shared storage)
- DNS round-robin or health-checked load balancing

**Pros:**
- Simple to implement
- No additional infrastructure
- Works with current setup

**Cons:**
- Requires manual sync or automation
- Potential configuration drift
- No automatic discovery

**Implementation:**
```yaml
# compose/services/traefik-primary.yml
services:
  traefik-primary:
    image: traefik:v3.0
    volumes:
      - ./traefik:/etc/traefik
    networks:
      - edge
      - internal

# compose/services/traefik-secondary.yml
services:
  traefik-secondary:
    image: traefik:v3.0
    volumes:
      - ./traefik:/etc/traefik  # Synced configuration
    networks:
      - edge
      - internal
```

### Option 2: Consul/etcd Backend

**Approach:**
- Use Consul or etcd for configuration storage
- Traefik watches Consul/etcd for changes
- Automatic configuration synchronization

**Pros:**
- Automatic synchronization
- No configuration drift
- Supports dynamic discovery
- Better for distributed setups

**Cons:**
- Additional infrastructure (Consul/etcd)
- More complex setup
- Additional maintenance

**Implementation:**
```yaml
services:
  traefik:
    image: traefik:v3.0
    command:
      - --providers.consul.endpoints=consul:8500
      - --providers.consul.prefix=traefik
    networks:
      - edge
      - internal
      - consul
```

### Option 3: Traefik API + File Provider

**Approach:**
- Multiple Traefik instances
- Primary instance serves as configuration source
- Secondary instances sync via API (if supported) or file sync

**Pros:**
- Uses existing infrastructure
- Can leverage Traefik API

**Cons:**
- Limited API support for configuration sync
- May require custom tooling

---

## Recommended Approach: File-Based with Sync

For the current infrastructure, we recommend **Option 1 (File-Based with Sync)** because:
- Simple to implement
- Works with existing setup
- No additional infrastructure
- Easy to maintain

---

## Implementation Steps

### Step 1: Prepare Configuration

Ensure Traefik configuration is in a shared location or version-controlled:

```bash
# Current location
ls -la traefik/
# dynamic/
# routers.yml
# middlewares.yml
# services.yml
```

### Step 2: Deploy Multiple Traefik Instances

**Server 1 (Primary):**
```yaml
services:
  traefik-primary:
    image: traefik:v3.0
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./traefik:/etc/traefik
    networks:
      - edge
      - internal
```

**Server 2 (Secondary):**
```yaml
services:
  traefik-secondary:
    image: traefik:v3.0
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./traefik:/etc/traefik  # Synced via Git/rsync
    networks:
      - edge
      - internal
```

### Step 3: Configure DNS/Load Balancing

**Option A: DNS Round-Robin**

```
traefik.inlock.ai  A  10.0.1.10  (Server 1)
traefik.inlock.ai  A  10.0.1.11  (Server 2)
```

**Option B: Health-Checked DNS**

Use Route53 health checks or similar:
- Health check endpoint: `http://traefik:8080/ping`
- Failover to secondary if primary fails

**Option C: External Load Balancer**

Use cloud load balancer (AWS ALB, GCP LB, etc.):
- Health checks configured
- Automatic failover
- SSL termination (optional)

### Step 4: Configuration Synchronization

**Option 1: Git-Based Sync**

```bash
# On both servers
git pull origin main
docker compose restart traefik
```

**Option 2: rsync**

```bash
# Sync from primary to secondary
rsync -avz /path/to/traefik/ secondary-server:/path/to/traefik/
```

**Option 3: Shared Storage**

Use NFS, GlusterFS, or cloud storage:
- Mount shared storage on both servers
- Traefik reads from shared location
- Automatic sync

### Step 5: Health Checks

Configure health checks for Traefik:

```yaml
services:
  traefik:
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

## Monitoring

### Health Check Endpoint

Traefik exposes a health check endpoint:
- URL: `http://traefik:8080/ping`
- Returns: `200 OK` if healthy

### Monitoring Queries

**Check Traefik Status:**
```bash
curl http://traefik:8080/ping
```

**Check Active Routers:**
```bash
curl http://traefik:8080/api/http/routers
```

**Check Service Health:**
```bash
curl http://traefik:8080/api/overview
```

### Alerting

Set up alerts for:
- Traefik health check failures
- High error rates
- Response time increases
- Configuration sync failures

---

## Failover Scenarios

### Primary Traefik Failure

**Automatic (with health-checked DNS):**
1. Health check fails
2. DNS automatically routes to secondary
3. Users experience minimal downtime

**Manual:**
1. Detect primary failure
2. Update DNS to point to secondary
3. Investigate and fix primary

### Configuration Update

**Process:**
1. Update configuration in Git
2. Pull changes on both servers
3. Restart Traefik instances (rolling restart)
4. Verify health

---

## Best Practices

### Configuration Management

1. **Version Control:**
   - All Traefik config in Git
   - Tagged releases
   - Change documentation

2. **Testing:**
   - Test config changes in staging
   - Validate syntax before deploying
   - Monitor after deployment

3. **Rollback:**
   - Keep previous config versions
   - Quick rollback procedure
   - Document rollback steps

### Deployment

1. **Rolling Updates:**
   - Update secondary first
   - Verify health
   - Update primary
   - Monitor for issues

2. **Blue-Green:**
   - Deploy new version alongside old
   - Switch traffic gradually
   - Keep old version for rollback

### Monitoring

1. **Health Checks:**
   - Monitor both instances
   - Alert on failures
   - Track response times

2. **Metrics:**
   - Request rates
   - Error rates
   - Response times
   - Connection counts

---

## Current Limitations

**Single Server Setup:**
- Only one Traefik instance possible
- No redundancy
- Requires second server for HA

**Future Enhancements:**
- Deploy second server
- Implement file sync
- Configure DNS load balancing
- Set up monitoring

---

## Related Documentation

- [High Availability Architecture](./HIGH-AVAILABILITY.md)
- [Traefik Configuration](../traefik/README.md)
- [Service Health Checks](../ha/check-service-health.sh)

---

## Next Steps

1. ✅ Design HA architecture (this document)
2. ⏳ Deploy second server (when available)
3. ⏳ Configure multiple Traefik instances
4. ⏳ Set up configuration sync
5. ⏳ Configure DNS/load balancing
6. ⏳ Test failover scenarios

---

**Last Updated:** 2025-12-28  
**Status:** Design Phase - Pending second server deployment

