# Inlock Infra Notes

- Apex `inlock.ai` served via PositiveSSL (Docker secret `positive_ssl_cert`/`positive_ssl_key`).
- Subdomains use Let's Encrypt (DNS challenge for most, TLS-ALPN for homepage fallback).
- Services behind Traefik:
  - Homepage `https://inlock.ai`
  - Portainer `https://portainer.inlock.ai` (auth + allowlist + rate limit)
  - n8n `https://n8n.inlock.ai`
- Networks: `edge` (ingress), `mgmt` (admin), `internal` (DB/backends), `socket-proxy` (Traefik <-> Docker).
- Docker socket is proxied via `docker-socket-proxy` with read-only scopes.

## Network Security

- **Firewall**: UFW configured via Ansible hardening role to:
  - Allow Tailscale (UDP 41641)
  - Allow SSH (port 22)
  - Allow HTTP/HTTPS (ports 80/443) for Traefik
  - Deny all other incoming traffic by default
- **Admin Access**: Traefik dashboard and Portainer protected by:
  - IP allowlist middleware (configured in `traefik/dynamic/middlewares.yml`)
  - Rate limiting
  - Basic auth (dashboard) / Forward auth (Portainer)
- **Optional Enhancement**: For additional security, admin services (Traefik dashboard, Portainer) can be bound to Tailscale interface (`tailscale0`) by:
  1. Adding a separate admin entrypoint in Traefik config binding to tailscale0 IP
  2. Using host network mode or custom Docker network configuration
  3. Updating router rules to use the admin entrypoint instead of `websecure`
  
  Current approach uses IP allowlists + firewall rules which provides strong protection while maintaining flexibility.


