# Inlock.ai Webpage Management Guide
**Date:** December 28, 2025  
**Purpose:** Complete guide for managing the inlock.ai website

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Quick Reference](#quick-reference)
3. [Deployment Process](#deployment-process)
4. [Content Management](#content-management)
5. [Configuration Management](#configuration-management)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
7. [Common Tasks](#common-tasks)
8. [Best Practices](#best-practices)

---

## 🏗️ Architecture Overview

### Two-Layer Architecture

The inlock.ai website uses a **separation of concerns** between application and infrastructure:

#### Layer 1: Application Repository
**Location:** `/opt/inlock-ai-secure-mvp/`

**Contains:**
- Next.js/React application source code
- UI components (`app/`, `components/`)
- Content files (markdown, blog posts)
- Application configuration
- Application-level tests
- `Dockerfile` for building the image

**Purpose:** All application code, content, and UI changes happen here

#### Layer 2: Infrastructure Repository
**Location:** `/home/comzis/inlock/` (this repo)

**Contains:**
- Docker Compose configurations (`compose/services/inlock-ai.yml`)
- Traefik routing configuration (`traefik/dynamic/routers.yml`)
- Service definitions (`traefik/dynamic/services.yml`)
- Deployment scripts (`scripts/deployment/deploy-inlock.sh`)
- Environment variables (`.env`)
- Infrastructure secrets management

**Purpose:** Infrastructure orchestration, routing, and deployment

### Current Configuration

**Container:**
- **Name:** `services-inlock-ai-1`
- **Image:** `inlock-ai:latest`
- **Status:** Running (healthy)
- **Port:** 3040 (internal only)
- **Health Check:** `http://localhost:3040/api/readiness`

**Traefik Routing:**
- **Domain:** `inlock.ai` and `www.inlock.ai`
- **Entry Point:** `websecure` (HTTPS)
- **TLS:** Positive SSL certificate
- **Middleware:** `secure-headers` only
- **Service:** `http://inlock-ai:3040`

**Networks:**
- `edge` - External-facing network
- `internal` - Internal service communication
- `mail` - Email service communication

---

## ⚡ Quick Reference

### Most Common Tasks

```bash
# 1. Deploy new version
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai

# 2. Check status
docker ps --filter "name=inlock-ai"

# 3. View logs
docker logs services-inlock-ai-1 --tail 50 -f

# 4. Restart service
docker compose -f compose/services/stack.yml restart inlock-ai

# 5. Verify deployment
./scripts/verify-inlock-deployment.sh
```

---

## 🚀 Deployment Process

### Automated Deployment (Recommended)

Use the deployment script for a complete pipeline:

```bash
cd /home/comzis/inlock
./scripts/deployment/deploy-inlock.sh
```

**What it does:**
1. Runs pre-deployment checks in application repo
2. Builds Docker image (`inlock-ai:latest`)
3. Deploys via Docker Compose
4. Verifies deployment

### Manual Deployment

#### Step 1: Update Application Code

```bash
cd /opt/inlock-ai-secure-mvp

# Make your changes:
# - Edit React components in app/ or components/
# - Update content in content/ or public/
# - Modify configuration files

# Test locally (optional)
npm run dev
# Visit: http://localhost:3040
```

#### Step 2: Quality Checks

```bash
cd /opt/inlock-ai-secure-mvp

# Linting
npm run lint

# Tests (if available)
npm run test

# Build verification
npm run build
```

#### Step 3: Build Docker Image

```bash
cd /opt/inlock-ai-secure-mvp

# Build the new image
docker build -t inlock-ai:latest .

# Verify image was created
docker images | grep inlock-ai
```

#### Step 4: Deploy to Infrastructure

```bash
cd /home/comzis/inlock

# Deploy with new image
docker compose -f compose/services/stack.yml up -d inlock-ai

# Or use the stack file directly
docker compose -f compose/services/stack.yml --env-file .env up -d inlock-ai
```

#### Step 5: Verify Deployment

```bash
cd /home/comzis/inlock

# Check service status
docker compose -f compose/services/stack.yml ps inlock-ai

# View logs
docker logs services-inlock-ai-1 --tail 50

# Test production URL
curl -I https://inlock.ai

# Run verification script
./scripts/verify-inlock-deployment.sh
```

### Deployment Checklist

- [ ] Application code updated and tested
- [ ] Docker image built successfully
- [ ] Container deployed and running
- [ ] Health check passing
- [ ] Website accessible at https://inlock.ai
- [ ] No errors in logs
- [ ] SSL certificate valid
- [ ] Traefik routing working

---

## 📝 Content Management

### Where Content Lives

**Application Repository:** `/opt/inlock-ai-secure-mvp/`

**Common Content Locations:**
- **Blog Posts:** `content/blog/` or `app/blog/`
- **Pages:** `app/*/page.tsx` or `pages/`
- **Markdown:** `content/` or `public/`
- **Images:** `public/images/` or `public/assets/`
- **Static Files:** `public/`

### Updating Content

#### Method 1: Direct File Edit

```bash
cd /opt/inlock-ai-secure-mvp

# Edit content files
nano content/blog/my-post.md
# or
nano app/about/page.tsx

# Rebuild and deploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

#### Method 2: Git Workflow (If Using Git)

```bash
cd /opt/inlock-ai-secure-mvp

# Make changes
git add .
git commit -m "Update content"
git push

# Build and deploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Content Types

#### Blog Posts
- Usually in Markdown format
- May use frontmatter for metadata
- Location: `content/blog/` or `app/blog/`

#### Pages
- React components (`.tsx` or `.jsx`)
- Next.js App Router structure
- Location: `app/*/page.tsx`

#### Static Assets
- Images, PDFs, etc.
- Location: `public/`
- Accessible at: `https://inlock.ai/images/...`

---

## ⚙️ Configuration Management

### Application Configuration

**Location:** `/opt/inlock-ai-secure-mvp/.env.production`

**Key Variables:**
```bash
# Auth0 (NextAuth.js)
AUTH0_ISSUER=https://comzis.eu.auth0.com/
AUTH0_WEB_CLIENT_ID=...
AUTH0_WEB_CLIENT_SECRET=...
NEXTAUTH_SECRET=...
NEXTAUTH_URL=https://inlock.ai

# Database
DATABASE_URL=postgresql://...

# Application Settings
NODE_ENV=production
PORT=3040
```

**To Update:**
```bash
cd /opt/inlock-ai-secure-mvp
nano .env.production
# Rebuild and redeploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Infrastructure Configuration

**Location:** `/home/comzis/inlock/`

**Key Files:**
- `.env` - Infrastructure environment variables
- `compose/services/inlock-ai.yml` - Container configuration
- `traefik/dynamic/routers.yml` - Traefik routing rules
- `traefik/dynamic/services.yml` - Service definitions

**To Update Routing:**
```bash
cd /home/comzis/inlock

# Edit routing configuration
nano traefik/dynamic/routers.yml

# Reload Traefik (no restart needed for file provider)
docker compose -f compose/services/stack.yml restart traefik
```

**To Update Container Config:**
```bash
cd /home/comzis/inlock

# Edit compose file
nano compose/services/inlock-ai.yml

# Apply changes
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Environment Variables

**Application Environment:**
- Managed in `/opt/inlock-ai-secure-mvp/.env.production`
- Loaded by Docker Compose via `env_file`

**Infrastructure Environment:**
- Managed in `/home/comzis/inlock/.env`
- Used for infrastructure services

**Note:** Never commit `.env` files to Git!

---

## 📊 Monitoring & Troubleshooting

### Health Checks

#### Container Health

```bash
# Check container status
docker ps --filter "name=inlock-ai"

# Check health check endpoint
docker exec services-inlock-ai-1 wget -qO- http://localhost:3040/api/readiness

# View health check logs
docker inspect services-inlock-ai-1 | grep -A 10 Health
```

#### Website Accessibility

```bash
# Test HTTPS access
curl -I https://inlock.ai

# Test specific endpoint
curl https://inlock.ai/api/readiness

# Check SSL certificate
openssl s_client -connect inlock.ai:443 -servername inlock.ai < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

### Logs

#### Application Logs

```bash
# View recent logs
docker logs services-inlock-ai-1 --tail 50

# Follow logs in real-time
docker logs services-inlock-ai-1 -f

# Search logs
docker logs services-inlock-ai-1 2>&1 | grep -i error

# Export logs
docker logs services-inlock-ai-1 > inlock-ai-logs.txt
```

#### Traefik Logs

```bash
# View routing logs
docker logs services-traefik-1 --tail 50 | grep inlock.ai

# Check for errors
docker logs services-traefik-1 2>&1 | grep -i error
```

### Common Issues

#### Issue: Website Not Accessible

**Symptoms:**
- 502 Bad Gateway
- Connection timeout
- SSL errors

**Troubleshooting:**
```bash
# 1. Check container status
docker ps --filter "name=inlock-ai"

# 2. Check container logs
docker logs services-inlock-ai-1 --tail 50

# 3. Check Traefik routing
docker logs services-traefik-1 --tail 50 | grep inlock

# 4. Test internal connectivity
docker exec services-traefik-1 wget -qO- http://inlock-ai:3040/api/readiness

# 5. Check DNS
nslookup inlock.ai

# 6. Verify SSL certificate
curl -vI https://inlock.ai 2>&1 | grep -i ssl
```

**Solutions:**
- Restart container: `docker compose -f compose/services/stack.yml restart inlock-ai`
- Check Traefik config: `cat traefik/dynamic/routers.yml | grep inlock-ai`
- Verify service definition: `cat traefik/dynamic/services.yml | grep inlock-ai`

#### Issue: Authentication Not Working

**Symptoms:**
- Login redirects fail
- Session not persisting
- Auth0 errors

**Troubleshooting:**
```bash
# 1. Check Auth0 configuration
docker exec services-inlock-ai-1 env | grep -i auth

# 2. Check NextAuth.js logs
docker logs services-inlock-ai-1 2>&1 | grep -i "nextauth\|auth0"

# 3. Verify callback URL
# Should be: https://inlock.ai/api/auth/callback/auth0
curl -I https://inlock.ai/api/auth/callback/auth0

# 4. Check Auth0 Dashboard
# Verify callback URL is configured correctly
```

**Solutions:**
- Verify `NEXTAUTH_URL` matches domain
- Check Auth0 callback URLs in dashboard
- Verify `AUTH0_ISSUER` is correct
- Check `NEXTAUTH_SECRET` is set

#### Issue: Build Fails

**Symptoms:**
- Docker build errors
- TypeScript errors
- Missing dependencies

**Troubleshooting:**
```bash
cd /opt/inlock-ai-secure-mvp

# 1. Check for syntax errors
npm run lint

# 2. Try building locally
npm run build

# 3. Check Dockerfile
cat Dockerfile

# 4. Build with verbose output
docker build -t inlock-ai:latest . --progress=plain
```

**Solutions:**
- Fix linting errors
- Install missing dependencies: `npm install`
- Update Dockerfile if needed
- Check Node.js version compatibility

#### Issue: Slow Performance

**Symptoms:**
- Slow page loads
- Timeouts
- High resource usage

**Troubleshooting:**
```bash
# 1. Check container resources
docker stats services-inlock-ai-1

# 2. Check memory limits
docker inspect services-inlock-ai-1 | grep -i memory

# 3. Check database performance
docker logs services-inlock-db-1 --tail 50

# 4. Check network latency
docker exec services-inlock-ai-1 ping -c 3 inlock-db
```

**Solutions:**
- Increase memory limits in `compose/services/inlock-ai.yml`
- Optimize database queries
- Enable caching
- Check for memory leaks

---

## 🔧 Common Tasks

### Restart Service

```bash
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml restart inlock-ai
```

### View Real-Time Logs

```bash
docker logs services-inlock-ai-1 -f
```

### Access Container Shell

```bash
docker exec -it services-inlock-ai-1 /bin/sh
# or
docker exec -it services-inlock-ai-1 /bin/bash
```

### Update Environment Variables

```bash
# 1. Edit application .env
cd /opt/inlock-ai-secure-mvp
nano .env.production

# 2. Rebuild and redeploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Rollback to Previous Version

```bash
# 1. List available images
docker images | grep inlock-ai

# 2. Tag previous image
docker tag inlock-ai:previous-tag inlock-ai:latest

# 3. Redeploy
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Backup Application Data

```bash
# Backup database (if applicable)
docker exec services-inlock-db-1 pg_dump -U postgres inlock > backup-$(date +%Y%m%d).sql

# Backup volumes (if any)
docker run --rm -v inlock-ai-data:/data -v $(pwd):/backup alpine tar czf /backup/inlock-ai-data-$(date +%Y%m%d).tar.gz /data
```

### Check SSL Certificate Expiry

```bash
echo | openssl s_client -connect inlock.ai:443 -servername inlock.ai 2>/dev/null | openssl x509 -noout -dates
```

---

## ✅ Best Practices

### Development Workflow

1. **Always test locally first**
   ```bash
   cd /opt/inlock-ai-secure-mvp
   npm run dev
   ```

2. **Run quality checks before deployment**
   ```bash
   npm run lint
   npm run test
   npm run build
   ```

3. **Use version tags for images** (optional but recommended)
   ```bash
   docker build -t inlock-ai:v1.2.3 .
   docker tag inlock-ai:v1.2.3 inlock-ai:latest
   ```

4. **Verify deployment after changes**
   ```bash
   ./scripts/verify-inlock-deployment.sh
   ```

### Security

1. **Never commit secrets**
   - Keep `.env` files out of Git
   - Use Docker secrets for sensitive data

2. **Keep dependencies updated**
   ```bash
   cd /opt/inlock-ai-secure-mvp
   npm audit
   npm update
   ```

3. **Regular backups**
   - Database backups
   - Volume backups
   - Configuration backups

### Monitoring

1. **Set up alerts** (if using monitoring)
   - Container health
   - Website availability
   - Error rates

2. **Regular log reviews**
   ```bash
   docker logs services-inlock-ai-1 --since 24h | grep -i error
   ```

3. **Performance monitoring**
   ```bash
   docker stats services-inlock-ai-1
   ```

### Documentation

1. **Document changes**
   - Update changelog
   - Document configuration changes
   - Note breaking changes

2. **Keep deployment notes**
   - Deployment date
   - Changes made
   - Issues encountered

---

## 📚 Related Documentation

- **Authentication:** `docs/services/inlock-ai/AUTHENTICATION-REVIEW-2025-12-28.md`
- **Deployment Scripts:** `scripts/deployment/deploy-inlock.sh`
- **Verification:** `scripts/verify-inlock-deployment.sh`
- **Traefik Routing:** `traefik/dynamic/routers.yml`
- **Service Definition:** `traefik/dynamic/services.yml`
- **Container Config:** `compose/services/inlock-ai.yml`

---

## 🆘 Getting Help

### Quick Diagnostics

```bash
# Run full diagnostics
cd /home/comzis/inlock
./scripts/verify-inlock-deployment.sh

# Check all services
docker compose -f compose/services/stack.yml ps

# View all logs
docker compose -f compose/services/stack.yml logs --tail 50
```

### Useful Commands Reference

```bash
# Service management
docker compose -f compose/services/stack.yml ps inlock-ai
docker compose -f compose/services/stack.yml restart inlock-ai
docker compose -f compose/services/stack.yml stop inlock-ai
docker compose -f compose/services/stack.yml start inlock-ai

# Logs
docker logs services-inlock-ai-1 --tail 100 -f
docker logs services-inlock-ai-1 --since 1h

# Container inspection
docker inspect services-inlock-ai-1
docker exec services-inlock-ai-1 env
docker exec services-inlock-ai-1 ps aux

# Network debugging
docker network inspect edge
docker network inspect internal
docker exec services-inlock-ai-1 ping inlock-db
```

---

**Last Updated:** December 28, 2025  
**Maintained By:** Infrastructure Team  
**Status:** ✅ Active and Documented













