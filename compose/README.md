# Compose Directory

Docker Compose files and configurations for all services.

## Directory Structure

### `services/`
Individual service compose files:
- `stack.yml` - Main infrastructure stack (Traefik, Portainer, etc.)
- `inlock-ai.yml` - Inlock AI application
- `postgres.yml` - PostgreSQL databases
- `n8n.yml` - N8N workflow automation
- `coolify.yml` - Coolify deployment platform
- `tooling.yml` - Tooling services (placeholder, currently empty)

### `monitoring/`
Monitoring and observability stack:
- `prometheus.yml` - Prometheus metrics
- `logging.yml` - Loki and Promtail logging

### `n8n/workflows/`
N8N workflow JSON exports:
- Health check workflows
- Automation workflows
- Integration workflows

### `config/`
Service-specific configuration files:
- `prometheus/` - Prometheus configuration and rules
- `alertmanager/` - Alertmanager configuration
- `logging/` - Loki and Promtail configs
- `monitoring/` - Monitoring exporters config

## Usage

Deploy services from project root:

```bash
# Deploy main stack
docker compose -f compose/services/stack.yml --env-file .env up -d

# Deploy monitoring
docker compose -f compose/monitoring/prometheus.yml --env-file .env up -d
```

## Note

Local development compose file is available at `compose/docker-compose.local.yml`.
