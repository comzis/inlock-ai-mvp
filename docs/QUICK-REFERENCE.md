# INLOCK.AI Infrastructure - Quick Reference

## 🔗 Service URLs

| Service | URL | Access Required |
|---------|-----|----------------|
| **Homepage** | https://inlock.ai | None (Public) |
| **Traefik Dashboard** | https://traefik.inlock.ai | Tailscale + Basic Auth |
| **Portainer** | https://portainer.inlock.ai | Tailscale + Forward Auth |
| **n8n** | https://n8n.inlock.ai | Tailscale |

## 🔐 Access Requirements

### Tailscale VPN Required For:
- ✅ Traefik Dashboard
- ✅ Portainer
- ✅ n8n

### Allowed IPs:
- `100.83.222.69/32` (Admin device 1)
- `100.96.110.8/32` (Admin device 2)

## 📋 Common Commands

```bash
# Navigate to infrastructure
cd /home/comzis/inlock-infra

# View all services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env ps

# View logs
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env logs -f

# Restart all services
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env restart

# Restart specific service
docker compose -f compose/stack.yml --env-file .env restart traefik

# Validate configuration
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config

# Test stack
./scripts/test-stack.sh

# Fix Portainer permissions
sudo ./scripts/fix-portainer.sh
```

## 🔒 Security Features

- ✅ IP Allowlisting (Tailscale VPN)
- ✅ Authentication (Basic Auth / Forward Auth)
- ✅ Rate Limiting (50 req/min, 100 burst)
- ✅ Secure Headers (HSTS, CSP, etc.)
- ✅ TLS/SSL Encryption (Let's Encrypt + PositiveSSL)

## 📊 Monitoring

- **Traefik Metrics**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080
- **Service Health**: `docker ps` (check STATUS column)

## 💾 Backup

```bash
# Backup volumes
./scripts/backup-volumes.sh

# Restore volumes
./scripts/restore-volumes.sh

# Database backup
docker exec compose-postgres-1 pg_dump -U n8n n8n > backup.sql
```

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| 403 Forbidden | Connect to Tailscale VPN |
| Certificate Error | Wait for Let's Encrypt (check logs) |
| Service Restarting | Check logs: `docker logs <service>` |
| Portainer Permission Error | Run: `sudo ./scripts/fix-portainer.sh` |

## 📚 Documentation

- **Full User Guide**: `docs/USER-GUIDE.md`
- **Deployment Guide**: `DEPLOYMENT.md`
- **Quick Start**: `QUICK-START.md`
- **Manual Deployment**: `MANUAL-DEPLOYMENT.md`

## 🔑 Key Files

- **Compose Files**: `compose/stack.yml`, `compose/postgres.yml`, `compose/n8n.yml`
- **Traefik Config**: `traefik/traefik.yml`, `traefik/dynamic/`
- **Environment**: `.env` (not in git)
- **Secrets**: `/home/comzis/apps/secrets/` (not in git)

## 📞 Support

1. Check logs: `docker logs <service-name>`
2. Review docs: `docs/`
3. Run tests: `./scripts/test-stack.sh`

---

**For detailed information, see**: `docs/USER-GUIDE.md`



