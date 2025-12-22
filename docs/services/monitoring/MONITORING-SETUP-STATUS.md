# Monitoring & Alerts – Current Status

**Last Updated:** 2025-12-09  
**Maintainer:** Inlock Infrastructure Team

## ✅ Running Components

| Component | Status | Notes |
|-----------|--------|-------|
| Prometheus | ✅ Healthy | Scraping app, Traefik, cAdvisor, node-exporter, alertmanager, blackbox exporter |
| Alertmanager | ✅ Healthy | Default receiver logs locally; ready for Slack/email integrations |
| Grafana | ✅ Healthy | Datasources: Prometheus + Loki; dashboards auto-provisioned |
| Node Exporter | ✅ Healthy | Host CPU/memory/disk/network metrics |
| Blackbox Exporter | ✅ Healthy | HTTP probes for public routes + TCP probes for internal services |
| Loki | ✅ Healthy | Stores Docker logs (volume `loki_data`) |
| Promtail | ✅ Healthy | Scrapes Docker logs via socket, ships to Loki |

## 📊 Dashboards

- Primary board: `Inlock AI Observability`
  - App KPIs (availability, CPU, memory, throughput, error rate)
  - Host metrics (CPU, memory, disk, network throughput)
  - Synthetic HTTP/TCP probe results
  - Traefik health checks
  - Live Loki log viewer
- Access: https://grafana.inlock.ai (IP allowlist + service login)

## 🚨 Alerts

Configured in `compose/prometheus/rules/inlock-ai.yml`:

- App alerts: `InlockAIDown`, `InlockAIHighCPU`, `InlockAIHighMemory`, `InlockAIHealthcheckFailed`, `InlockAIHighErrorRate`
- Host alerts: `NodeHighCPUUsage`, `NodeMemoryPressure`, `NodeDiskSpaceLow`, `NodeLoadHigh`
- Synthetic probes: `ExternalHTTPProbeFailed`, `ServiceTCPProbeFailed`

Alertmanager currently routes to the `default` receiver (no external notifications). To enable Slack/email:
1. Edit `compose/alertmanager/alertmanager.yml` and add the desired receiver.
2. Restart Alertmanager:  
   `docker compose -f compose/stack.yml --env-file .env restart alertmanager`

## 🔍 Verification Commands

```bash
# Check service status
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps prometheus alertmanager grafana node-exporter blackbox-exporter

# Validate Prometheus config/rules
docker exec compose-prometheus-1 promtool check config /etc/prometheus/prometheus.yml
docker exec compose-prometheus-1 promtool check rules /etc/prometheus/rules/*.yml

# Reload Prometheus after edits
curl -X POST http://localhost:9090/-/reload
```

## 🧰 Maintenance

- **Dashboards** – Drop JSON into `grafana/dashboards/` and restart Grafana to provision new dashboards.
- **Blackbox Targets** – Add HTTPS/TCP endpoints to the `blackbox-http` / `blackbox-tcp` jobs in `compose/prometheus/prometheus.yml`.
- **Backups** – Include volumes `prometheus_data`, `alertmanager_data`, `grafana_data`, `loki_data` in scheduled backups.
- **Logs** – Use Grafana’s Explore view (Loki datasource) to tail service logs.

## 🚀 Next Enhancements

1. Connect Alertmanager to Slack/email/PagerDuty.
2. Add dashboards for PostgreSQL, n8n, and Traefik internals.
3. Extend blackbox probes to additional customer-facing routes if needed.

