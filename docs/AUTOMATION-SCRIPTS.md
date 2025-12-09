# Automation Scripts for Inlock AI

## Deployment Verification

### Quick Verification Script
**Location**: `/home/comzis/inlock-infra/scripts/verify-inlock-deployment.sh`

**Usage**:
```bash
cd /home/comzis/inlock-infra
./scripts/verify-inlock-deployment.sh
```

**What it checks**:
- Service status (docker compose ps)
- Recent logs (last 20 lines)
- SSL certificate headers
- Health check endpoint
- Traefik routing logs

## Regression Testing

### Application Regression Check
**Location**: `/opt/inlock-ai-secure-mvp/scripts/regression-check.sh`

**Usage**:
```bash
cd /opt/inlock-ai-secure-mvp
./scripts/regression-check.sh
```

**What it runs**:
- `npm run lint` - ESLint checks
- `npm test` - Unit/integration tests
- `npm run build` - Production build verification

**Docker Support**: Automatically uses Docker if npm is not installed on the host.

## Grafana/Prometheus Monitoring

### Alerting + Dashboards

Prometheus now loads alert rules from `compose/prometheus/rules/inlock-ai.yml`. Alerts include:
- `InlockAIDown`: container disappeared from cAdvisor
- `InlockAIHighMemory` / `InlockAIHighCPU`: sustained resource pressure
- `InlockAIHealthcheckFailed`: Traefik health checks failing
- `InlockAIHighErrorRate`: 5xx rate > 5% over 5 minutes

Grafana automatically provisions the **Inlock AI Observability** dashboard (`grafana/dashboards/inlock-observability.json`) with:
- Availability gauge
- CPU + memory timeseries
- Request throughput + 5xx rate graphs
- Traefik health status
- Live Loki-backed logs panel

Datasources:
- Prometheus (`http://prometheus:9090`)
- Loki (`http://loki:3100`)

### Log Aggregation

`compose/logging.yml` adds Loki + Promtail to the stack:
- Loki persists data in the `loki_data` volume
- Promtail scrapes Docker logs via the socket, labels them with container + service, and pushes into Loki
- Grafana datasource `Loki` lets you search through logs (panel already included in the observability dashboard)

### Health & Cron Automation

- **Nightly regression:** `/home/comzis/inlock-infra/scripts/nightly-regression.sh`
  - Writes to `/home/comzis/logs/nightly-regression.log`
  - Add to cron:  
    `0 3 * * * /home/comzis/inlock-infra/scripts/nightly-regression.sh`
- **Pre-deploy checks:** `/opt/inlock-ai-secure-mvp/scripts/pre-deploy.sh`
  - Runs regression suite, branding check, env validation
- **One-button deploy:** `/home/comzis/inlock-infra/scripts/deploy-inlock.sh`
  - Runs pre-deploy, builds Docker image, deploys, then executes `verify-inlock-deployment.sh`

## Automated Deployment Pipeline (Optional)

### Pre-Deployment Checks

Create `/opt/inlock-ai-secure-mvp/scripts/pre-deploy.sh`:

```bash
#!/bin/bash
set -e

cd /opt/inlock-ai-secure-mvp

echo "Running pre-deployment checks..."

# 1. Regression tests
./scripts/regression-check.sh

# 2. Check for StreamArt references
if rg -i "streamart" . --exclude-dir node_modules; then
    echo "❌ ERROR: Found StreamArt references!"
    exit 1
fi

# 3. Verify environment file exists
if [ ! -f .env.production ]; then
    echo "❌ ERROR: .env.production not found!"
    exit 1
fi

echo "✅ Pre-deployment checks passed"
```

### Full Deployment Script

Create `/home/comzis/inlock-infra/scripts/deploy-inlock.sh`:

```bash
#!/bin/bash
set -e

cd /home/comzis/inlock-infra

echo "========================================="
echo "Deploying Inlock AI"
echo "========================================="

# 1. Pre-deployment checks
cd /opt/inlock-ai-secure-mvp
./scripts/pre-deploy.sh

# 2. Build image
echo ""
echo "Building Docker image..."
docker build -t inlock-ai:latest .

# 3. Deploy
echo ""
echo "Deploying..."
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans inlock-ai

# 4. Verify
echo ""
echo "Verifying deployment..."
sleep 10
./scripts/verify-inlock-deployment.sh

echo ""
echo "========================================="
echo "✅ Deployment Complete!"
echo "========================================="
```

## Cron Jobs (Optional)

Set up automated health checks:

```bash
# Add to crontab (crontab -e)
# Run health check every 5 minutes
*/5 * * * * /home/comzis/inlock-infra/scripts/verify-inlock-deployment.sh >> /var/log/inlock-health.log 2>&1

# Run regression tests daily at 2 AM
0 2 * * * cd /opt/inlock-ai-secure-mvp && ./scripts/regression-check.sh >> /var/log/inlock-regression.log 2>&1
```

---

**Last Updated**: 2025-12-09  
**Status**: Scripts ready for use
