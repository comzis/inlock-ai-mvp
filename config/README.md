# Config Directory

Centralized configuration files for all services.

## Directory Structure

### `traefik/`
Traefik reverse proxy configuration:
- `traefik.yml` - Static configuration
- `dynamic/` - Dynamic configuration (routers, middlewares, TLS)

### `nginx/`
Nginx configuration files:
- `crash.conf` - Crash recovery configuration
- `live.conf` - Live configuration
- `front.conf` - Frontend configuration

### `mailu/`
Mail server configuration:
- `config.py` - Mailu configuration
- `dovecot.conf` - Dovecot IMAP configuration

### `prometheus/`
Prometheus monitoring configuration (from compose/config/prometheus)

### `alertmanager/`
Alertmanager configuration (from compose/config/alertmanager)

### `logging/`
Loki and Promtail logging configuration (from compose/config/logging)

### `grafana/`
Grafana dashboards and datasources

## Usage

Configuration files are referenced by Docker Compose services. After making changes, restart the relevant service:

```bash
docker compose -f compose/services/stack.yml restart traefik
```

## Security

**Never commit sensitive information to git.** Use environment variables or the `secrets/` directory for sensitive data.
