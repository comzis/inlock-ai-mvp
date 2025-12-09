# Monitoring Guide

## Traefik Metrics

Traefik exposes Prometheus metrics on the `metrics` entrypoint (port 8080 by default).

**Metrics Endpoint:** `http://traefik:8080/metrics`

**Health Check:**
- Command: `traefik healthcheck`
- Interval: 30s
- Timeout: 5s
- Retries: 3

**Current Status:** Health check configured and active.

## Service Health Checks

All services have health checks configured:

- **Traefik:** `traefik healthcheck` (30s interval)
- **Postgres:** `pg_isready` (30s interval)
- **n8n:** `wget --spider http://localhost:5678/healthz` (30s interval)
- **Portainer:** `wget --spider http://localhost:9000` (30s interval)
- **cAdvisor:** Container health check (30s interval)
- **docker-socket-proxy:** `wget --spider http://localhost:2375/_ping` (30s interval)

## Prometheus, Alerts & Logs

- **Prometheus:** Live, scraping Prometheus, cAdvisor, Traefik, and Docker health
- **Alert rules:** `compose/prometheus/rules/inlock-ai.yml`
  - Downtime (no metrics from container)
  - High memory/CPU
  - Traefik healthcheck failures
  - HTTP 5xx rate > 5%
- **Log aggregation:** Loki + Promtail (see `compose/logging.yml`) collects Docker logs and exposes them via Grafana/Loki datasource.

## Grafana

- Datasources: Prometheus (default) + Loki
- Dashboards: `grafana/dashboards/inlock-observability.json`
  - Service availability gauge
  - CPU + memory utilization
  - Throughput + error-rate charts
  - Traefik health status
  - Live log panel for `compose-inlock-ai-1`

## Next Steps

1. Configure alert notifications (PagerDuty, email, Slack) if desired
2. Add dashboard panels for database + n8n workloads
3. Monitor PositiveSSL expiration (Dec 7 2026)
