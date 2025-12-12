# Coolify Setup and Usage Guide

**Date:** December 11, 2025  
**Access URL:** `https://deploy.inlock.ai/`

---

## 🎯 What is Coolify?

Coolify is a self-hosted deployment platform that automates:
- **Application Deployment**: Deploy apps from Git repositories
- **Database Management**: Provision and manage databases
- **Server Management**: Manage multiple servers and deploy across them
- **CI/CD Automation**: Automatic deployments on Git pushes

Think of it as your own self-hosted Platform-as-a-Service (PaaS).

---

## 🔧 Current Status

### Service Health
- **Coolify**: Running but unhealthy (cron expression error)
- **PostgreSQL**: ✅ Healthy
- **Redis**: ✅ Healthy
- **Soketi**: Unhealthy (WebSocket server)

### Known Issues
1. **Cron Expression Error**: `translate_cron_expression(): Return value must be of type string, null returned`
   - **Fix**: Run `./scripts/fix-coolify-cron.sh` to clean up invalid cron entries
   - **Impact**: Prevents health check from passing, but core functionality may work

2. **502 Bad Gateway**: Traefik returns 502 when accessing `https://deploy.inlock.ai`
   - **Cause**: Coolify health check failing
   - **Workaround**: Access may work despite health check failure

---

## 🚀 First-Time Setup

### Step 1: Fix Cron Expression Error

```bash
cd /home/comzis/inlock-infra
./scripts/fix-coolify-cron.sh
```

This script will:
- Connect to Coolify's PostgreSQL database
- Find and fix invalid cron expressions
- Restart Coolify service

### Step 2: Access Coolify

1. **Via Browser**: Navigate to `https://deploy.inlock.ai/`
2. **Authentication**: Access is restricted via Tailscale/VPN (IP allowlist)
3. **First Login**: You'll need to create an admin account on first access

### Step 3: Initial Configuration

After logging in:

1. **Add Your First Server**:
   - Go to "Servers" → "Add Server"
   - Coolify can manage the current server or add remote servers
   - For local server, use Docker socket access (already configured)

2. **Connect Git Provider** (Optional):
   - Go to "Settings" → "Git Providers"
   - Add GitHub/GitLab/Bitbucket for automatic deployments

3. **Configure Docker**:
   - Coolify already has access to Docker socket (`/var/run/docker.sock`)
   - Verify Docker connection in Settings

---

## 📦 Using Coolify

### Deploy a New Application

1. **Create New Application**:
   - Click "Applications" → "New Application"
   - Choose application type (Docker, Static Site, etc.)

2. **Connect Git Repository**:
   - Enter repository URL
   - Select branch (usually `main` or `master`)
   - Configure build settings

3. **Configure Environment**:
   - Set environment variables
   - Configure build commands
   - Set port mappings

4. **Deploy**:
   - Click "Deploy"
   - Coolify will:
     - Clone the repository
     - Build the Docker image
     - Start the container
     - Configure Traefik routing (if enabled)

### Manage Databases

1. **Create Database**:
   - Go to "Databases" → "New Database"
   - Choose database type (PostgreSQL, MySQL, MongoDB, etc.)
   - Configure credentials

2. **Backup Management**:
   - Coolify automatically manages backups
   - View backups in the database details page
   - Restore from backups as needed

### Monitor Applications

- **Logs**: View real-time application logs
- **Metrics**: Monitor resource usage (CPU, memory, network)
- **Health Checks**: Configure health check endpoints
- **Alerts**: Set up notifications for deployment failures

---

## 🔐 Security Considerations

### Current Security Setup

1. **Network Isolation**:
   - Coolify is on `mgmt` network (not `edge`)
   - Access only via Traefik reverse proxy

2. **IP Allowlist**:
   - Access restricted to Tailscale/VPN IPs
   - Configured via `allowed-admins` middleware

3. **Docker Socket Access**:
   - ⚠️ **Security Risk**: Coolify has direct Docker socket access
   - Consider using Docker socket proxy in the future
   - Current: `/var/run/docker.sock:/var/run/docker.sock`

### Recommendations

1. **Enable OAuth2 Authentication**:
   - Add `portainer-auth` middleware to Coolify router
   - Requires OAuth2-Proxy to be running

2. **Review Docker Permissions**:
   - Consider restricting Docker socket access
   - Use Docker socket proxy for better security

3. **Regular Backups**:
   - Coolify data is stored in `/data/coolify`
   - Ensure backups are configured

---

## 🛠️ Troubleshooting

### Coolify Returns 502

**Symptoms**: `https://deploy.inlock.ai/` returns 502 Bad Gateway

**Causes**:
1. Coolify container is unhealthy (cron error)
2. Coolify service is not responding
3. Traefik routing issue

**Solutions**:
```bash
# Check Coolify logs
docker compose -f compose/coolify.yml --env-file .env logs coolify

# Restart Coolify
docker compose -f compose/coolify.yml --env-file .env restart coolify

# Fix cron errors
./scripts/fix-coolify-cron.sh
```

### Cannot Access Coolify

**Symptoms**: Connection refused or timeout

**Causes**:
1. Not connected to Tailscale/VPN
2. IP not in allowlist
3. Traefik not routing correctly

**Solutions**:
1. Connect to Tailscale VPN
2. Verify your IP is in `allowed-admins` middleware
3. Check Traefik logs: `docker compose -f compose/stack.yml --env-file .env logs traefik`

### Database Connection Issues

**Symptoms**: Coolify cannot connect to PostgreSQL

**Solutions**:
```bash
# Check PostgreSQL is healthy
docker compose -f compose/coolify.yml --env-file .env ps coolify-postgres

# Check connection from Coolify container
docker compose -f compose/coolify.yml --env-file .env exec coolify psql -h coolify-postgres -U coolify -d coolify

# Verify environment variables
docker compose -f compose/coolify.yml --env-file .env config | grep DB_
```

### Deployment Failures

**Common Issues**:
1. **Git Authentication**: Ensure Git credentials are configured
2. **Build Errors**: Check application build logs in Coolify UI
3. **Port Conflicts**: Ensure ports are not already in use
4. **Resource Limits**: Check Docker resource limits

**Debug Steps**:
1. View deployment logs in Coolify UI
2. Check Docker logs: `docker logs <container-name>`
3. Verify network connectivity
4. Check Traefik routing configuration

---

## 📚 Useful Commands

### Service Management

```bash
# Start Coolify stack
docker compose -f compose/coolify.yml --env-file .env up -d

# Stop Coolify stack
docker compose -f compose/coolify.yml --env-file .env down

# Restart Coolify
docker compose -f compose/coolify.yml --env-file .env restart coolify

# View logs
docker compose -f compose/coolify.yml --env-file .env logs -f coolify

# Check status
docker compose -f compose/coolify.yml --env-file .env ps
```

### Database Management

```bash
# Access PostgreSQL
docker compose -f compose/coolify.yml --env-file .env exec coolify-postgres psql -U coolify -d coolify

# Backup database
docker compose -f compose/coolify.yml --env-file .env exec coolify-postgres pg_dump -U coolify coolify > coolify-backup.sql

# View database size
docker compose -f compose/coolify.yml --env-file .env exec coolify-postgres psql -U coolify -d coolify -c "SELECT pg_size_pretty(pg_database_size('coolify'));"
```

### Fix Common Issues

```bash
# Fix cron expression errors
./scripts/fix-coolify-cron.sh

# Clear Redis cache
docker compose -f compose/coolify.yml --env-file .env exec coolify-redis redis-cli -a ${REDIS_PASSWORD} FLUSHALL

# Reset Coolify (⚠️ destructive)
docker compose -f compose/coolify.yml --env-file .env down -v
# Then restart and reconfigure
```

---

## 🔗 Related Documentation

- **Traefik Configuration**: `traefik/dynamic/routers.yml`
- **Docker Compose**: `compose/coolify.yml`
- **Environment Variables**: `.env` (COOLIFY_APP_KEY, PUSHER_APP_KEY, etc.)
- **Security**: `docs/CURRENT-SECURITY-STATUS.md`

---

## 📝 Next Steps

1. ✅ Healthcheck endpoint fixed (port 8080)
2. ✅ Database migrated to PostgreSQL
3. ⏳ Access Coolify UI and create admin account (if not done)
4. ⏳ Configure Git provider (optional)
5. ⏳ Deploy first application
6. ⏳ Set up automated backups
7. ⏳ Enable OAuth2 authentication (security improvement)
8. ⏳ Fix Coolify Soketi healthcheck (non-critical)

---

**Last Updated:** December 11, 2025  
**Status:** Core service healthy - Web interface may need time to fully initialize

