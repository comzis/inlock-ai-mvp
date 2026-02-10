# Security Scorecard

Last updated: 2026-02-10

## Access Control -- Strong

| Check | Status |
|-------|--------|
| SSH root login | Disabled |
| SSH password auth | Disabled (keys only) |
| Failed SSH attempts (24h) | 0 (Tailscale VPN restricts access) |
| Admin services auth | Auth0 + OAuth2-Proxy + IP allowlist |
| Privileged containers | 1 (`netfilter-mailcow` -- expected, it manages iptables) |

## TLS Certificates -- All Valid

| Domain | Expires |
|--------|---------|
| inlock.ai | Dec 7, 2026 (PositiveSSL) |
| mail.inlock.ai | Apr 2, 2026 (Let's Encrypt) |
| traefik.inlock.ai | Apr 1, 2026 |
| grafana.inlock.ai | Apr 2, 2026 |
| n8n.inlock.ai | Apr 2, 2026 |
| portainer.inlock.ai | Apr 2, 2026 |

## Network Exposure -- Good

Externally listening ports are only what's expected:

- **22** -- SSH (Tailscale-restricted via iptables)
- **80/443** -- Traefik (web traffic)
- **25/465/587** -- Mailcow SMTP
- **110/143/993/995/4190** -- Mailcow IMAP/POP
- **8080/8443** -- Mailcow web UI

All internal services (Prometheus, Loki, databases, Redis) are localhost-only.

## Docker Socket -- Acceptable

4 containers mount `docker.sock`, all expected:

- `docker-socket-proxy` (Traefik uses this proxy, not the raw socket)
- `netdata`, `dockerapi-mailcow`, `ofelia-mailcow` (monitoring/mailcow standard)

## Operational Automation -- Clean

System cron is clean (no broken jobs). User crontab has 6 legitimate entries (backups, MTA-STS check, daily report, monthly secrets audit).

## Areas to Watch

- 22 packages upgradable (including `libexpat1` security fix) -- unattended-upgrades is active, so these should auto-install. Worth confirming.
- 19 mailcow containers have no memory limits -- this is Mailcow's default; ClamAV is already using ~1 GB. If you ever have memory pressure, ClamAV is the first candidate for a limit.
- Some images are aging:
  - `grafana/loki` 2.9.4 and `grafana/promtail` 2.9.4 -- 2 years old
  - `prom/alertmanager` v0.27.0 -- 23 months
  - `oauth2-proxy` v7.6.0 -- 24 months
  - `cadvisor` v0.49.1 -- 23 months

  These aren't urgent but worth updating on a maintenance day.
- Docker socket mounted by `netdata` -- lower risk since Netdata only reads, but the socket-proxy pattern used for Traefik is safer. Minor improvement opportunity.

## Overall

Solid posture. SSH is locked down, no unnecessary exposure, TLS is healthy, and the broken cron/timer noise cleaned up on 2026-02-10 was the biggest operational risk.
