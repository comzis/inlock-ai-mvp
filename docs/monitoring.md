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

## Monitoring Gaps

- **Prometheus:** Not configured (metrics endpoint available but not scraped)
- **Grafana:** Not configured (no visualization dashboard)
- **Alerting:** Not configured (no alert rules)

## Next Steps

1. Deploy Prometheus to scrape Traefik metrics
2. Configure Grafana dashboards
3. Set up alerting rules for service failures
4. Monitor certificate expiration (PositiveSSL expires Dec 7 2026)
