# Docker Deployment Guide

Complete guide for running StreamArt.ai with Docker and PostgreSQL.

## 🚀 Quick Start

```bash
# 1. Setup environment
cp .env.example .env
# Edit .env: set AUTH_SESSION_SECRET and AI provider keys

# 2. Start everything
docker compose up --build

# 3. Visit http://localhost:3040
```

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- `.env` file with required variables

### Important: Prisma Schema

For PostgreSQL deployment, update `prisma/schema.prisma`:

```prisma
datasource db {
  provider = "postgresql"  // Change from "sqlite"
  url      = env("DATABASE_URL")
}
```

**Note:** For local development with SQLite, keep `provider = "sqlite"`. For Docker/PostgreSQL, use `provider = "postgresql"`.

## 🏗️ Architecture

The Docker setup includes:

1. **Web Service** (`web`)
   - Next.js application
   - Runs on port 3040
   - Automatically runs migrations on startup
   - Health check endpoint: `/api/readiness`

2. **Database Service** (`db`)
   - PostgreSQL 16
   - Runs on port 5432
   - Persistent volume: `dbdata`
   - Health checks before web service starts

## 🔧 Configuration

### Environment Variables

The `docker-compose.yml` automatically sets:
- `DATABASE_URL=postgresql://postgres:postgres@db:5432/app`
- `NODE_ENV=production`

You still need to set in `.env`:
- `AUTH_SESSION_SECRET` (required)
- AI provider keys (optional but recommended)

### Using External PostgreSQL

If you have an external PostgreSQL instance:

1. Update `.env`:
   ```bash
   DATABASE_URL=postgresql://user:password@host:5432/database?sslmode=require
   ```

2. Remove or comment out the `db` service in `docker-compose.yml`

3. Start only the web service:
   ```bash
   docker compose up web --build
   ```

### Custom Ports

Edit `docker-compose.yml` to change ports:

```yaml
services:
  web:
    ports:
      - "8080:3040"  # Host:Container
  db:
    ports:
      - "5433:5432"  # Host:Container
```

## 🛠️ Docker Commands

### Build

```bash
# Build all services
docker compose build

# Build specific service
docker compose build web

# Build without cache
docker compose build --no-cache
```

### Run

```bash
# Start in foreground
docker compose up

# Start in background
docker compose up -d

# Start specific service
docker compose up web

# Rebuild and start
docker compose up --build
```

### Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f web

# Last 100 lines
docker compose logs --tail=100
```

### Stop

```bash
# Stop services (keeps containers)
docker compose stop

# Stop and remove containers
docker compose down

# Stop and remove volumes (⚠️ deletes database)
docker compose down -v
```

### Database Access

```bash
# Connect to PostgreSQL
docker compose exec db psql -U postgres -d app

# Run Prisma migrations manually
docker compose exec web npx prisma migrate deploy

# Run Prisma Studio
docker compose exec web npx prisma studio
```

## 🔍 Troubleshooting

### Container won't start

**Check logs:**
```bash
docker compose logs web
docker compose logs db
```

**Common issues:**
- Missing `.env` file
- Invalid `AUTH_SESSION_SECRET` (must be 20+ chars)
- Port already in use (change ports in docker-compose.yml)
- Database connection errors (check DATABASE_URL)

### Database migration fails

**Check database is ready:**
```bash
docker compose exec db pg_isready -U postgres
```

**Run migrations manually:**
```bash
docker compose exec web npx prisma migrate deploy
```

**Reset database (⚠️ deletes all data):**
```bash
docker compose down -v
docker compose up -d db
# Wait for db to be healthy, then:
docker compose exec web npx prisma migrate deploy
docker compose up -d
```

### Build fails

**Clear Docker cache:**
```bash
docker compose build --no-cache
```

**Check Node version:**
- Dockerfile uses Node 20
- Ensure compatibility with your code

### Application errors

**Check application logs:**
```bash
docker compose logs -f web
```

**Access container shell:**
```bash
docker compose exec web sh
```

**Check environment variables:**
```bash
docker compose exec web env | grep -E 'DATABASE_URL|AUTH_SESSION_SECRET'
```

## 📊 Production Deployment

### Optimizations

1. **Use standalone output** (optional):
   Update `next.config.mjs`:
   ```js
   const nextConfig = {
     output: 'standalone',
   };
   ```
   Then update Dockerfile to copy `.next/standalone` instead of full `.next`.

2. **Multi-stage build** (already implemented):
   - Separate deps, builder, and runner stages
   - Minimal production image size

3. **Health checks** (already configured):
   - Web service: `/api/readiness`
   - Database: `pg_isready`

### Security

1. **Change default passwords:**
   ```yaml
   # docker-compose.yml
   environment:
     POSTGRES_PASSWORD: your-secure-password
   ```

2. **Use secrets management:**
   - Docker secrets (Docker Swarm)
   - Kubernetes secrets
   - External secret managers (AWS Secrets Manager, etc.)

3. **Network isolation:**
   - Use Docker networks
   - Don't expose database port in production

### Scaling

**Horizontal scaling:**
```bash
# Scale web service
docker compose up -d --scale web=3
```

**Note:** Ensure you're using:
- External PostgreSQL (not containerized)
- Redis for rate limiting (not in-memory)
- Session store (if using external sessions)

## 🔄 CI/CD Integration

### GitHub Actions

Example workflow step:

```yaml
- name: Build Docker image
  run: docker build -t streamart:latest .

- name: Run tests in container
  run: docker run --rm streamart:latest npm test
```

### Docker Hub / Registry

```bash
# Tag image
docker tag streamart:latest your-registry/streamart:latest

# Push to registry
docker push your-registry/streamart:latest

# Pull and run
docker pull your-registry/streamart:latest
docker run -p 3040:3040 --env-file .env your-registry/streamart:latest
```

## 📚 Related Documentation

- **Deployment Guide**: `DEPLOYMENT.md`
- **Automated Deployment**: `AUTOMATED_DEPLOYMENT.md`
- **Environment Variables**: `.env.example`

## 🆘 Support

If you encounter issues:
1. Check logs: `docker compose logs`
2. Verify environment variables
3. Check database connectivity
4. Review this troubleshooting section

---

**Last Updated**: 2024-01-XX

