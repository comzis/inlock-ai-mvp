# DevOps Notes

- Certificates:
  - Apex `inlock.ai` uses PositiveSSL via Docker secrets `positive_ssl_cert` / `positive_ssl_key`.
  - All subdomains use Let's Encrypt DNS (Cloudflare token) or TLS-ALPN (fallback for homepage).
- Traefik:
  - Static config at `traefik/traefik.yml`.
  - Dynamic split under `traefik/dynamic/{middlewares,routers,services,tls}.yml`.
  - Dashboard and Portainer protected by basic auth secret, IP allowlist, and rate-limit middlewares.
  - Metrics endpoint enabled at `:9100` (Prometheus).
- Services:
  - Homepage via `homepage` service.
  - Portainer via `portainer` service (Docker provider through socket proxy).
  - n8n via `n8n` service, backed by Postgres.
- Deploy:
  - `docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml config` to validate.
  - Then `docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml up -d`.


