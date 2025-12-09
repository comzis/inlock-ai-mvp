# Monitoring Guide

## Components

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **Prometheus** | Scrapes metrics from application, Traefik, cAdvisor, node-exporter, Alertmanager, blackbox exporter | `compose/prometheus/prometheus.yml` |
| **Alertmanager** | Routes alerts; ready for Slack/email/webhook integrations | `compose/alertmanager/alertmanager.yml` |
| **Node Exporter** | Captures host CPU, memory, disk, and network metrics | Service `node-exporter` in `compose/stack.yml` |
| **Blackbox Exporter** | Synthetic HTTP + TCP probes (public routes + internal ports) | `compose/monitoring/blackbox.yml` |
| **Loki + Promtail** | Centralized Docker logs, queried via Grafana | `compose/logging.yml` |
| **Grafana** | Dashboards + alert visibility | `grafana/dashboards/*.json`, `grafana/provisioning/*` |

## Prometheus & Alertmanager

- `rule_files`: `/etc/prometheus/rules/*.yml` (repo path `compose/prometheus/rules/`)
- Alerting targets (default): `alertmanager:9093`
- Reload Prometheus after config/rule updates:
  ```bash
  curl -X POST http://localhost:9090/-/reload
  ```
- Restart Alertmanager after editing `alertmanager.yml`:
  ```bash
  docker compose -f compose/stack.yml --env-file .env restart alertmanager
  ```
- To forward notifications (Slack/email/etc.), edit `compose/alertmanager/alertmanager.yml` and add the preferred receiver; restart Alertmanager afterwards.

## Alert Coverage

### Application
- `InlockAIDown` – container disappeared from cAdvisor
- `InlockAIHighMemory` – working set > 850MB
- `InlockAIHighCPU` – CPU utilization > 80%
- `InlockAIHealthcheckFailed` – Traefik health checks failing
- `InlockAIHighErrorRate` – HTTP 5xx rate > 5%

### Host
- `NodeHighCPUUsage` – host CPU > 85% for 10m
- `NodeMemoryPressure` – host memory usage > 85% for 10m
- `NodeDiskSpaceLow` – root filesystem < 15% free space
- `NodeLoadHigh` – 5m load average per core > 1.5

### Synthetic Probes
- `ExternalHTTPProbeFailed` – blackbox HTTP probe failure to public domains
- `ServiceTCPProbeFailed` – TCP probe failure for internal ports

## Synthetic Monitoring

Blackbox exporter monitors:
- HTTPS: `inlock.ai`, `www.inlock.ai`, `grafana.inlock.ai`, `n8n.inlock.ai`, `deploy.inlock.ai`, `dashboard.inlock.ai`
- TCP ports: `inlock-ai:3040`, `grafana:3000`, `n8n:5678`

Add/remove targets by editing the `blackbox-http` or `blackbox-tcp` jobs in `compose/prometheus/prometheus.yml` and reloading Prometheus.

## Grafana

- Access: `https://grafana.inlock.ai` (IP allowlist + service login)
- Datasources: Prometheus + Loki (provisioned in `grafana/provisioning/datasources/prometheus.yaml`)
- Dashboards: `grafana/dashboards/inlock-observability.json`
  - Application metrics: availability, throughput, CPU, memory, error rate
  - Host metrics: CPU, memory, disk, network throughput
  - Synthetic probes: HTTP/TCP success
  - Traefik health checks
  - Live Loki logs
- Add dashboards by dropping JSON files into `grafana/dashboards/` and restarting Grafana.

## Logs

- Promtail reads Docker logs via `/var/run/docker.sock`
- Loki stores data in `loki_data` volume
- Query logs through Grafana’s **Explore** tab or the “Inlock AI Logs” panel

## Operations Checklist

| Task | Command |
|------|---------|
| Restart monitoring stack | `docker compose -f compose/stack.yml --env-file .env restart prometheus grafana alertmanager node-exporter blackbox-exporter` |
| Check exporter health | `docker compose -f compose/stack.yml --env-file .env ps` |
| Tail Prometheus logs | `docker logs compose-prometheus-1 -f` |
| Validate alert rules | `docker exec -it compose-prometheus-1 promtool check rules /etc/prometheus/rules/*.yml` |
| Validate config | `docker exec -it compose-prometheus-1 promtool check config /etc/prometheus/prometheus.yml` |
| Backup monitoring data | include volumes `prometheus_data`, `alertmanager_data`, `grafana_data`, `loki_data` |

## Next Steps

1. Wire Alertmanager to Slack/Email/PagerDuty for real notifications.
2. Add dashboards for PostgreSQL, n8n, and Traefik if deeper visibility is required.
3. Monitor certificate expiry timers (Positive SSL expires 7 Dec 2026).
