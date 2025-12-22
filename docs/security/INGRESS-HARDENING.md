# Ingress Hardening

## Overview

All admin services are protected behind a consistent middleware stack that includes:
- **Security headers** (HSTS, CSP, frame protection)
- **IP allowlist** (Tailscale VPN + approved public IPs)
- **Rate limiting** (50 req/s average, 100 burst)

## Admin Services

All admin services use the same hardened middleware stack:

| Service | Domain | Middlewares |
|---------|--------|-------------|
| Traefik Dashboard | `traefik.inlock.ai` | secure-headers, dashboard-auth, allowed-admins, mgmt-ratelimit |
| Portainer | `portainer.inlock.ai` | secure-headers, allowed-admins, mgmt-ratelimit |
| n8n | `n8n.inlock.ai` | secure-headers, allowed-admins, mgmt-ratelimit |
| Cockpit | `cockpit.inlock.ai` | secure-headers, allowed-admins, mgmt-ratelimit |
| Grafana | `grafana.inlock.ai` | secure-headers, allowed-admins, mgmt-ratelimit |

## Public Services

| Service | Domain | Middlewares |
|---------|--------|-------------|
| Homepage | `inlock.ai`, `www.inlock.ai` | secure-headers (public access) |

## IP Allowlist

The `allowed-admins` middleware restricts access to:

### Tailscale VPN IPs
- `100.83.222.69/32` - Server Tailscale IP
- `100.96.110.8/32` - MacBook Tailscale IP

### Approved Public IPs
- `156.67.29.52/32` - Server public IP (for testing)
- `2a09:bac3:1e53:2664::3d3:2f/128` - MacBook public IPv6
- `31.10.147.220/32` - MacBook public IPv4
- `172.71.147.142/32` - MacBook public IPv4 (alternate)
- `172.71.146.180/32` - MacBook public IPv4 (alternate)

### Updating IP Allowlist

1. **Update middleware file:**
   ```bash
   vim traefik/dynamic/middlewares.yml
   # Edit the allowed-admins sourceRange list
   ```

2. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

3. **Or use the update script:**
   ```bash
   ./scripts/update-allowlists.sh
   ```

## Cloudflare Integration

### DNS Records

All admin services should have DNS records in Cloudflare with **Proxy OFF** (gray cloud) to ensure direct IP allowlist functionality:

- `traefik.inlock.ai` → `156.67.29.52` (Proxy: OFF)
- `portainer.inlock.ai` → `156.67.29.52` (Proxy: OFF)
- `n8n.inlock.ai` → `156.67.29.52` (Proxy: OFF)
- `cockpit.inlock.ai` → `156.67.29.52` (Proxy: OFF)
- `grafana.inlock.ai` → `156.67.29.52` (Proxy: OFF)

**Why Proxy OFF?**
- Traefik's IP allowlist checks the real client IP
- With Cloudflare proxy ON, Traefik sees Cloudflare IPs, not client IPs
- This breaks the IP allowlist functionality

### Alternative: Cloudflare Access

If you want to use Cloudflare proxy, consider:
- Cloudflare Access (application-level authentication)
- Cloudflare WAF rules (IP-based restrictions)
- Remove Traefik IP allowlist and rely on Cloudflare

## Adding New Admin Services

When adding a new admin service:

1. **Add router in `traefik/dynamic/routers.yml`:**
   ```yaml
   new-service:
     entryPoints:
       - websecure
     rule: Host(`new-service.inlock.ai`)
     middlewares:
       - secure-headers      # Security headers
       - allowed-admins      # IP allowlist
       - mgmt-ratelimit      # Rate limiting
     service: new-service
     tls:
       certResolver: le-dns
   ```

2. **Add service in `traefik/dynamic/services.yml`:**
   ```yaml
   new-service:
     loadBalancer:
       servers:
         - url: http://new-service:PORT
   ```

3. **Add DNS record in Cloudflare:**
   - Domain: `new-service.inlock.ai`
   - IP: `156.67.29.52`
   - Proxy: **OFF** (gray cloud)

4. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

## Grafana

Grafana is configured and deployed:

- **Service:** `grafana` in `compose/stack.yml`
- **Router:** `grafana.inlock.ai` with same middleware stack as other admin services
- **DNS:** `grafana.inlock.ai` → `156.67.29.52` (Proxy: OFF)
- **Access:** https://grafana.inlock.ai (IP allowlist protected)

**Configuration:**
- Admin user: `admin` (or `GRAFANA_ADMIN_USER` from .env)
- Admin password: From `/home/comzis/apps/secrets-real/grafana-admin-password`
- Data directory: `grafana_data` volume

**Next Steps:**
- Add Prometheus datasource (if deploying Prometheus)
- Configure dashboards for Traefik/cAdvisor metrics
- Set up alerting rules

## Testing Access Control

Use the validation script:
```bash
./scripts/validate-access-control.sh
```

Or test manually:
```bash
# From allowed IP (should work)
curl -I https://portainer.inlock.ai

# From non-allowed IP (should return 403)
curl -I https://portainer.inlock.ai
```

## Troubleshooting

### 403 Forbidden from Allowed IP

1. **Check IP is in allowlist:**
   ```bash
   grep -A 10 "allowed-admins:" traefik/dynamic/middlewares.yml
   ```

2. **Check Cloudflare proxy status:**
   - DNS record should have Proxy OFF (gray cloud)
   - If Proxy ON, Traefik sees Cloudflare IPs, not client IPs

3. **Check Traefik logs:**
   ```bash
   docker logs compose-traefik-1 | grep -i "403\|forbidden\|allowed"
   ```

### Service Not Accessible

1. **Check router exists:**
   ```bash
   grep "new-service" traefik/dynamic/routers.yml
   ```

2. **Check service exists:**
   ```bash
   grep "new-service" traefik/dynamic/services.yml
   ```

3. **Check DNS:**
   ```bash
   dig +short new-service.inlock.ai
   ```

4. **Check Traefik logs:**
   ```bash
   docker logs compose-traefik-1 | tail -50
   ```

## Security Best Practices

1. **Always use HTTPS** - All admin services use `websecure` entrypoint
2. **Consistent middleware stack** - All admin services use the same security middlewares
3. **IP allowlist** - Restrict access to known IPs only
4. **Rate limiting** - Prevent brute force and DoS attacks
5. **Security headers** - HSTS, CSP, frame protection, etc.
6. **Regular IP review** - Remove unused IPs from allowlist
7. **Cloudflare Proxy OFF** - For admin services to ensure IP allowlist works

## Ongoing Monitoring

- Enable Traefik access/error log shipping to Loki/ELK and build Grafana panels that highlight spikes in 403/429 codes
- Set up cAdvisor + Prometheus (or equivalent) alerts for container restarts, CPU, memory, and disk pressure that could impact ingress
- Track Let's Encrypt renewal events (`traefik.log` or webhook) so certificate issues do not take down ingress
- Periodically run `./scripts/validate-access-control.sh` from different networks to ensure allowlists match expectations

## Password Recovery

### Grafana

1. Check the current admin password stored in `/home/comzis/apps/secrets-real/grafana-admin-password`.
2. If you need to reset it, run:
   ```bash
   docker exec -it compose-grafana-1 grafana-cli admin reset-admin-password NEW_PASSWORD
   ```
3. Update `/home/comzis/apps/secrets-real/grafana-admin-password` with the new value (permissions `600`), then restart Grafana if it is configured to read the file on boot.

### Portainer

1. Generate a new bcrypt hash (replace `NEW_PASSWORD` with the desired secret):
   ```bash
   docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'NEW_PASSWORD' | cut -d: -f2
   ```
2. Reset the admin account inside the running container with that hash:
   ```bash
   docker exec -it compose-portainer-1 /portainer --admin-password '$2y$05$...'
   ```
3. Update any secret files or password vault entries with the plaintext. Restart Portainer only if it fails to pick up the change automatically.

### Traefik / Other Services

- Secrets now live under `/home/comzis/apps/secrets-real/`. Replace the relevant file (permissions `600`, owner `1000:1000`) with the new value and restart the affected container so the environment variable refreshes.
- Keep a record of password rotations in the ops log and verify access from an allowed IP immediately after changing credentials.

## Change Management Checklist

1. **Plan** - Document the service, domain, and middleware changes you intend to make
2. **Review** - Have another operator confirm the router/service definitions and DNS plan
3. **Apply** - Ship the change (git commit + deploy) and restart Traefik if dynamic config changed
4. **Verify** - Run health checks (`curl`, dashboards) from both allowed and non-allowed IPs
5. **Record** - Note the change in the ops log with timestamps, IPs added/removed, and validation results

## Incident Response Snapshot

- **Lock down quickly:** Temporarily narrow the allowlist (or remove all but Tailscale) if unauthorized access is suspected
- **Capture evidence:** Export relevant Traefik logs, Cloudflare request logs, and router/service definitions before modifying them
- **Rotate secrets:** Refresh admin passwords, API tokens, and TLS certificates if compromise is possible
- **Post-mortem:** Document root cause, timeline, and preventive actions; update this guide as part of the remediation

## References

- [Traefik IP Allowlist](https://doc.traefik.io/traefik/middlewares/http/ipallowlist/)
- [Traefik Security Headers](https://doc.traefik.io/traefik/middlewares/http/headers/)
- [Traefik Rate Limiting](https://doc.traefik.io/traefik/middlewares/http/ratelimit/)
- [Cloudflare DNS Settings](https://developers.cloudflare.com/dns/manage-dns-records/)
