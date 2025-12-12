# Runtime Visibility & Monitoring

## Overview

This document describes how to monitor and inspect running services despite "no new privileges" (NNP) restrictions that prevent sudo usage.

## Docker Access Methods

### Method 1: Direct Docker Access (Recommended)

**Prerequisites:**
- User must be in `docker` group

**Check membership:**
```bash
groups | grep docker
```

**Add user to group (requires sudo):**
```bash
sudo usermod -aG docker $USER
newgrp docker  # Apply without logout
```

**Usage:**
```bash
# Container status
docker compose -f compose/stack.yml --env-file .env ps

# Container logs
docker logs compose-inlock-ai-1 --tail 50

# Container health
docker inspect compose-inlock-ai-1 --format '{{.State.Health.Status}}'
```

### Method 2: Helper Scripts

**Status:**
```bash
cd /home/comzis/inlock-infra
./scripts/docker-status.sh
./scripts/docker-status.sh inlock-ai  # Specific service
```

**Logs:**
```bash
./scripts/docker-logs.sh compose-inlock-ai-1 50
```

**Features:**
- Falls back to Portainer API if Docker unavailable
- Provides SSH alternatives if both fail
- Non-blocking warnings

### Method 3: Portainer Web UI

**Access:**
- URL: `https://portainer.inlock.ai`
- Authenticate via Traefik (basic auth + IP allowlist)

**Capabilities:**
- View all containers and status
- Access container logs
- Execute commands in containers
- View container stats

**API Access:**
```bash
# Get API key from Portainer UI:
# Settings → API Keys → Create Key

PORTAINER_URL="https://portainer.inlock.ai"
PORTAINER_API_KEY="your-api-key"

# List containers
curl -H "X-API-Key: $PORTAINER_API_KEY" \
  "$PORTAINER_URL/api/endpoints/1/docker/containers/json"
```

### Method 4: SSH to Management Node

If direct Docker access is blocked:

**Setup SSH access:**
```bash
# From management node, add your SSH key
ssh-copy-id user@mgmt-node

# SSH and run Docker commands
ssh user@mgmt-node 'docker ps'
ssh user@mgmt-node 'docker logs compose-inlock-ai-1 --tail 50'
```

**Automated check script:**
```bash
#!/bin/bash
# check-services-remote.sh
ssh user@mgmt-node << 'EOF'
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps
EOF
```

## Monitoring & Health Checks

### Container Health Status

**All services:**
```bash
docker compose -f compose/stack.yml --env-file .env ps \
  --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
```

**Specific service:**
```bash
docker inspect compose-inlock-ai-1 --format '{{.State.Health.Status}}'
```

### Application Logs

**Recent logs:**
```bash
docker logs compose-inlock-ai-1 --tail 50 --follow
```

**Filtered logs:**
```bash
docker logs compose-inlock-ai-1 2>&1 | grep -i error
```

**Multiple services:**
```bash
docker compose -f compose/stack.yml --env-file .env logs -f --tail=50 inlock-ai traefik
```

**Blog & readiness probes:**
```bash
# Verify the public blog still renders Markdown
curl -I https://inlock.ai/blog || true

# Hit the internal readiness endpoint
curl -s https://inlock.ai/api/readiness | jq

# If either fails, tail app logs immediately:
docker logs compose-inlock-ai-1 --tail 200 | rg -i \"blog\"
```

Adding these probes to your routine catches missing assets (e.g., `/app/content`) before they reach production.

### Metrics & Monitoring

**Prometheus:**
- URL: `http://localhost:9090` (if port forwarded)
- Or via Grafana: `https://grafana.inlock.ai`

**cAdvisor:**
- Container metrics available in Prometheus
- Query: `container_memory_usage_bytes{name="compose-inlock-ai-1"}`

**Grafana Dashboards:**
- Pre-built: "Inlock AI Observability"
- Shows: CPU, memory, request rate, errors, logs

## Automated Monitoring Scripts

### Health Check Script

Create `scripts/health-check.sh`:
```bash
#!/bin/bash
# Check health of all services

cd "$(dirname "$0")/.."

echo "Health Check Report"
echo "=================="
echo ""

# Check each service
for service in traefik inlock-ai grafana prometheus; do
  status=$(docker inspect "compose-${service}-1" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
  echo "$service: $status"
done
```

### Log Aggregation Check

```bash
#!/bin/bash
# Verify logs are flowing to Loki

# Check Promtail
docker logs compose-promtail-1 --tail 20 | grep -i error

# Check Loki
curl -s http://localhost:3100/ready

# Query logs in Grafana
# Explore → Loki → Query: {job="docker"}
```

## Troubleshooting NNP Restrictions

### Issue: "Permission denied" on Docker commands

**Solution 1: Add user to docker group**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Solution 2: Use helper scripts**
```bash
./scripts/docker-status.sh
```

**Solution 3: Use Portainer UI**
- Web-based access doesn't require Docker group membership

### Issue: Cannot use sudo

**Workarounds:**
- Use helper scripts that don't require sudo
- Use Portainer API
- SSH to management node where sudo is available
- Use Docker API directly (if user has access)

## Best Practices

1. **Always check health status before deployments**
   ```bash
   ./scripts/docker-status.sh
   ```

2. **Monitor logs during deployments**
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs -f
   ```

3. **Set up alerts**
   - Use Prometheus alerts (Alertmanager)
   - Monitor Grafana dashboards
   - Set up log-based alerts in Loki

4. **Regular health checks**
   ```bash
   # Add to cron
   0 * * * * /home/comzis/inlock-infra/scripts/health-check.sh >> /var/log/health-check.log
   ```

---

**Last Updated:** December 10, 2025  
**Related:** `scripts/docker-status.sh`, `scripts/docker-logs.sh`
