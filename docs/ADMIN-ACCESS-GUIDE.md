# Admin Access Guide - Inlock Infrastructure

Complete guide to accessing all services in the Inlock infrastructure stack.

## 🔐 Access Requirements

### IP Allowlist

All admin services require you to be on an **allowed IP address**:

**Tailscale VPN IPs:**
- `100.83.222.69/32` - Server Tailscale IP
- `100.96.110.8/32` - MacBook Tailscale IP

**Approved Public IPs:**
- `156.67.29.52/32` - Server public IP
- `2a09:bac3:1e53:2664::3d3:2f/128` - MacBook public IPv6
- `31.10.147.220/32` - MacBook public IPv4
- `172.71.147.142/32` - MacBook public IPv4 (alternate)
- `172.71.146.180/32` - MacBook public IPv4 (alternate)

**To add your IP:**
1. Edit `/home/comzis/inlock-infra/traefik/dynamic/middlewares.yml`
2. Add your IP to the `allowed-admins` sourceRange
3. Restart Traefik: `docker compose -f compose/stack.yml --env-file .env restart traefik`

### Authentication

Some services require additional authentication (Basic Auth, service login).

---

## 🌐 Service Access Links

### Production Application

| Service | URL | Access | Authentication |
|---------|-----|--------|----------------|
| **Inlock AI** | [https://inlock.ai](https://inlock.ai) | Public | Service login required |
| **Inlock AI (WWW)** | [https://www.inlock.ai](https://www.inlock.ai) | Public | Service login required |

**Notes:**
- Public access (no IP restriction)
- Uses Positive SSL certificate
- Production application

---

### Admin Services (IP Restricted)

#### 1. Traefik Dashboard

**URL:** [https://traefik.inlock.ai/dashboard/](https://traefik.inlock.ai/dashboard/)

**Access:** IP allowlist + Basic Auth  
**Authentication:**
- Username/Password stored in: `/home/comzis/apps/secrets-real/traefik-dashboard-users.htpasswd`
- View users: `cat /home/comzis/apps/secrets-real/traefik-dashboard-users.htpasswd`

**Features:**
- View all configured routers, services, and middlewares
- Monitor HTTP entrypoints
- Check SSL certificate status
- Real-time request metrics

**Alternative API:** [https://traefik.inlock.ai/api/](https://traefik.inlock.ai/api/)

---

#### 2. Portainer

**URL:** [https://portainer.inlock.ai](https://portainer.inlock.ai)

**Access:** IP allowlist  
**Authentication:** Service login (admin account)

**Credentials:**
- Password stored in: `/home/comzis/apps/secrets-real/portainer-admin-password`
- View password: `cat /home/comzis/apps/secrets-real/portainer-admin-password`

**Features:**
- Docker container management
- Container logs and console access
- Volume and network management
- Docker Compose stack management
- Container stats and monitoring

**First-time setup:** Create admin account on first login (password from secret file)

---

#### 3. n8n Workflow Automation

**URL:** [https://n8n.inlock.ai](https://n8n.inlock.ai)

**Access:** IP allowlist  
**Authentication:** Service login

**Credentials:**
- Admin account credentials managed within n8n
- Database: PostgreSQL (separate instance)

**Features:**
- Workflow automation
- API integrations
- Data processing workflows
- Scheduled tasks

---

#### 4. Grafana

**URL:** [https://grafana.inlock.ai](https://grafana.inlock.ai)

**Access:** IP allowlist  
**Authentication:** Service login

**Credentials:**
- Admin user: `admin` (or from env `GRAFANA_ADMIN_USER`)
- Password: `/home/comzis/apps/secrets-real/grafana-admin-password`
- View password: `cat /home/comzis/apps/secrets-real/grafana-admin-password`

**Features:**
- Metrics visualization and dashboards
- Prometheus datasource integration
- cAdvisor container metrics
- Traefik metrics visualization
- Alerting and notifications

**Data Sources:**
- Prometheus: `http://prometheus:9090`
- cAdvisor: `http://cadvisor:8080`

---

#### 5. Coolify

**URL:** [https://deploy.inlock.ai](https://deploy.inlock.ai)

**Access:** IP allowlist  
**Authentication:** Service login

**Features:**
- Application deployment management
- Git-based deployments
- Docker container orchestration

---

#### 6. Homarr Dashboard

**URL:** [https://dashboard.inlock.ai](https://dashboard.inlock.ai)

**Access:** IP allowlist  
**Authentication:** Service login (if configured)

**Features:**
- Unified dashboard for all services
- Quick access to all admin tools
- Service monitoring and shortcuts

---

### Monitoring & Metrics Services

#### 7. Prometheus

**URL:** Not directly exposed via Traefik (internal only)

**Internal Access:**
- URL: `http://prometheus:9090`
- From containers on `mgmt` network

**External Access:** Via Grafana dashboard

**Metrics Endpoints:**
- Targets: `http://prometheus:9090/targets`
- Query: `http://prometheus:9090/graph`
- Metrics: `http://prometheus:9090/metrics`

**Features:**
- Metrics collection and storage
- Time-series database
- Query language (PromQL)
- Alerting rules

---

#### 8. cAdvisor

**URL:** Not directly exposed via Traefik (internal only)

**Internal Access:**
- URL: `http://cadvisor:8080`
- From containers on `mgmt` network

**External Access:** Via Grafana dashboard (metrics)

**Metrics Endpoints:**
- Container metrics: `http://cadvisor:8080/metrics`
- Web UI: `http://cadvisor:8080` (if exposed)

**Features:**
- Container resource usage (CPU, memory, network, filesystem)
- Per-container statistics
- Historical metrics

---

### Database Services

#### 9. PostgreSQL (n8n)

**Service:** `postgres`  
**Internal Access:** `postgresql://n8n:password@postgres:5432/n8n`

**Connection Info:**
- Host: `postgres` (internal network)
- Port: `5432`
- Database: `n8n`
- User: `n8n`
- Password: `/home/comzis/apps/secrets-real/n8n-db-password`

**Direct Access:**
```bash
docker exec -it compose-postgres-1 psql -U n8n -d n8n
```

---

#### 10. PostgreSQL (Inlock AI)

**Service:** `inlock-db`  
**Internal Access:** `postgresql://inlock:password@inlock-db:5432/inlock`

**Connection Info:**
- Host: `inlock-db` (internal network)
- Port: `5432`
- Database: `inlock`
- User: `inlock`
- Password: `/home/comzis/apps/secrets-real/inlock-db-password`

**Direct Access:**
```bash
docker exec -it compose-inlock-db-1 psql -U inlock -d inlock
```

---

## 🔧 Service Management Commands

### View All Services Status

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps
```

### View Service Logs

```bash
# Traefik
docker logs compose-traefik-1 -f

# Portainer
docker logs compose-portainer-1 -f

# n8n
docker logs compose-n8n-1 -f

# Grafana
docker logs compose-grafana-1 -f

# Inlock AI
docker logs compose-inlock-ai-1 -f

# Prometheus
docker logs compose-prometheus-1 -f
```

### Restart Services

```bash
cd /home/comzis/inlock-infra

# Restart specific service
docker compose -f compose/stack.yml --env-file .env restart traefik

# Restart all services
docker compose -f compose/stack.yml --env-file .env restart
```

### Access Service Shell

```bash
# Traefik
docker exec -it compose-traefik-1 sh

# Portainer
docker exec -it compose-portainer-1 sh

# n8n
docker exec -it compose-n8n-1 sh
```

---

## 🔑 Password Management

### View Passwords

All passwords are stored in `/home/comzis/apps/secrets-real/`:

```bash
# Traefik Dashboard
cat /home/comzis/apps/secrets-real/traefik-dashboard-users.htpasswd

# Portainer
cat /home/comzis/apps/secrets-real/portainer-admin-password

# Grafana
cat /home/comzis/apps/secrets-real/grafana-admin-password

# Database passwords
cat /home/comzis/apps/secrets-real/inlock-db-password
cat /home/comzis/apps/secrets-real/n8n-db-password
```

### Reset Passwords

See [INGRESS-HARDENING.md](./INGRESS-HARDENING.md#password-recovery) for password reset procedures.

---

## 🌍 DNS Configuration

All services use DNS records in Cloudflare pointing to server IP: `156.67.29.52`

**DNS Records:**
- `inlock.ai` → `156.67.29.52` (A record)
- `www.inlock.ai` → `156.67.29.52` (A record)
- `traefik.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)
- `portainer.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)
- `n8n.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)
- `grafana.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)
- `deploy.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)
- `dashboard.inlock.ai` → `156.67.29.52` (A record, Proxy: OFF)

**Important:** Admin services should have **Proxy OFF** (gray cloud) for IP allowlist to work correctly.

---

## 🔒 Security Features

### Applied to All Admin Services

1. **IP Allowlist** - Only accessible from approved IPs
2. **Security Headers** - HSTS, CSP, frame protection
3. **Rate Limiting** - 50 req/s average, 100 burst
4. **HTTPS Only** - All traffic encrypted with TLS
5. **Authentication** - Service-level auth (Basic Auth, service login)

### Middleware Stack

- `secure-headers` - Security headers (all services)
- `allowed-admins` - IP allowlist (admin services)
- `mgmt-ratelimit` - Rate limiting (admin services)
- `dashboard-auth` - Basic Auth (Traefik dashboard only)

---

## 📊 Quick Access Table

| Service | URL | IP Restriction | Auth Type | Status |
|---------|-----|----------------|-----------|--------|
| Inlock AI | [https://inlock.ai](https://inlock.ai) | ❌ Public | Service login | ✅ Live |
| Traefik Dashboard | [https://traefik.inlock.ai/dashboard/](https://traefik.inlock.ai/dashboard/) | ✅ Yes | Basic Auth | ✅ Live |
| Portainer | [https://portainer.inlock.ai](https://portainer.inlock.ai) | ✅ Yes | Service login | ✅ Live |
| n8n | [https://n8n.inlock.ai](https://n8n.inlock.ai) | ✅ Yes | Service login | ✅ Live |
| Grafana | [https://grafana.inlock.ai](https://grafana.inlock.ai) | ✅ Yes | Service login | ✅ Live |
| Coolify | [https://deploy.inlock.ai](https://deploy.inlock.ai) | ✅ Yes | Service login | ✅ Live |
| Homarr | [https://dashboard.inlock.ai](https://dashboard.inlock.ai) | ✅ Yes | Service login | ✅ Live |
| Prometheus | Internal only | ✅ Yes | N/A | ✅ Live |
| cAdvisor | Internal only | ✅ Yes | N/A | ✅ Live |

---

## 🚨 Troubleshooting Access

### 403 Forbidden Error

**Symptoms:** Getting 403 when accessing admin services

**Solutions:**
1. **Check your IP is in allowlist:**
   ```bash
   grep -A 10 "allowed-admins:" /home/comzis/inlock-infra/traefik/dynamic/middlewares.yml
   ```

2. **Check your current IP:**
   ```bash
   curl -s https://api.ipify.org
   ```

3. **Verify DNS proxy status:**
   - DNS record should have Proxy OFF (gray cloud)
   - If Proxy ON, Traefik sees Cloudflare IPs, not your IP

4. **Check Traefik logs:**
   ```bash
   docker logs compose-traefik-1 | grep -i "403\|forbidden\|allowed"
   ```

### Service Not Loading

1. **Check service is running:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env ps
   ```

2. **Check service logs:**
   ```bash
   docker logs compose-<service-name>-1 --tail 50
   ```

3. **Check Traefik routing:**
   ```bash
   grep "<service>" /home/comzis/inlock-infra/traefik/dynamic/routers.yml
   ```

4. **Restart Traefik:**
   ```bash
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

### SSL Certificate Issues

1. **Check certificate status:**
   ```bash
   openssl s_client -connect <domain>:443 -servername <domain> </dev/null 2>/dev/null | openssl x509 -noout -dates
   ```

2. **Verify certificate in Traefik:**
   - Check Traefik dashboard → HTTP → Routers
   - Verify TLS configuration

---

## 📝 Maintenance Tasks

### Regular Checks

- **Weekly:** Review service logs for errors
- **Monthly:** Update passwords and secrets
- **Quarterly:** Review and update IP allowlist
- **As needed:** Update service configurations

### Health Monitoring

Monitor service health via:
- Grafana dashboards
- Prometheus metrics
- Docker health checks
- Service-specific health endpoints

---

## 🔗 Quick Links Summary

### Production
- 🌐 [Inlock AI](https://inlock.ai) - Main application

### Admin Services
- 🚦 [Traefik Dashboard](https://traefik.inlock.ai/dashboard/) - Reverse proxy management
- 🐳 [Portainer](https://portainer.inlock.ai) - Container management
- 🔄 [n8n](https://n8n.inlock.ai) - Workflow automation
- 📊 [Grafana](https://grafana.inlock.ai) - Metrics and dashboards
- 🚀 [Coolify](https://deploy.inlock.ai) - Deployment management
- 📱 [Homarr Dashboard](https://dashboard.inlock.ai) - Unified dashboard

### Internal Services
- 📈 Prometheus - Metrics collection (via Grafana)
- 📦 cAdvisor - Container metrics (via Grafana)
- 💾 PostgreSQL (n8n) - Database (internal)
- 💾 PostgreSQL (Inlock) - Database (internal)

---

**Last Updated:** 2025-12-09  
**Maintainer:** Inlock Infrastructure Team

