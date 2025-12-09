# Inlock AI Deployment - Quick Start

**Full Guide:** See `INLOCK-AI-DEPLOYMENT.md` for detailed instructions.

## Prerequisites Check

✅ Positive SSL certificate is installed  
✅ App code is in `/opt/inlock-ai-secure-mvp`

## Quick Deployment Steps

### 1. Generate Database Password

```bash
openssl rand -base64 32 | tr -d '\n' > /home/comzis/apps/secrets-real/inlock-db-password
chmod 600 /home/comzis/apps/secrets-real/inlock-db-password
chown comzis:comzis /home/comzis/apps/secrets-real/inlock-db-password
DB_PASSWORD=$(cat /home/comzis/apps/secrets-real/inlock-db-password)
echo "Database password: $DB_PASSWORD"
```

### 2. Generate Session Secret

```bash
AUTH_SECRET=$(openssl rand -base64 32)
echo "Auth secret: $AUTH_SECRET"
```

### 3. Create Environment File

```bash
cat > /opt/inlock-ai-secure-mvp/.env.production << EOF
DATABASE_URL=postgresql://inlock:${DB_PASSWORD}@inlock-db:5432/inlock?sslmode=disable
AUTH_SESSION_SECRET=${AUTH_SECRET}
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
EOF

chmod 600 /opt/inlock-ai-secure-mvp/.env.production
```

### 4. Build Docker Image

```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
```

### 5. Add Database to Stack

Edit `/home/comzis/inlock-infra/compose/stack.yml` and add after line 10:

```yaml
include:
  - compose/inlock-db.yml
```

### 6. Add Service to Stack

Edit `/home/comzis/inlock-infra/compose/stack.yml` and add after the `grafana` service (around line 242):

```yaml
  inlock-ai:
    image: inlock-ai:latest
    restart: always
    env_file:
      - /opt/inlock-ai-secure-mvp/.env.production
    networks:
      - edge
      - internal
    depends_on:
      inlock-db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3040/api/readiness"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    cap_drop:
      - ALL
    user: "1001:1001"
    <<: [*hardening, *default-logging, *resource-hints]
```

### 7. Update Traefik Router

Edit `/home/comzis/inlock-infra/traefik/dynamic/routers.yml` and change the `homepage` router:

```yaml
    homepage:
      entryPoints:
        - websecure
      rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
      middlewares:
        - secure-headers
      service: inlock-ai
      tls:
        options: default
```

### 8. Add Service to Traefik

Edit `/home/comzis/inlock-infra/traefik/dynamic/services.yml` and add:

```yaml
    inlock-ai:
      loadBalancer:
        servers:
          - url: http://inlock-ai:3040
```

### 9. Deploy

```bash
cd /home/comzis/inlock-infra

# Start database
docker compose -f compose/stack.yml --env-file .env up -d inlock-db

# Wait for database to be healthy (check with: docker compose ps inlock-db)

# Start application
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai

# Restart Traefik to pick up new routing
docker compose -f compose/stack.yml --env-file .env restart traefik
```

### 10. Verify

```bash
# Check services
docker compose -f compose/stack.yml ps

# Check logs
docker logs compose-inlock-ai-1 --tail 50

# Test HTTPS
curl -I https://inlock.ai

# Test health endpoint
curl https://inlock.ai/api/readiness
```

## Rollback (if needed)

```bash
# Stop app
docker compose -f compose/stack.yml stop inlock-ai

# Restore homepage in routers.yml (change service back to "homepage")
# Then restart Traefik
docker compose -f compose/stack.yml restart traefik
```

## Important Notes

- ⚠️ **Database password** is stored in `/home/comzis/apps/secrets-real/inlock-db-password`
- ⚠️ **Environment file** is at `/opt/inlock-ai-secure-mvp/.env.production`
- ✅ **Positive SSL** is already configured in Traefik
- ✅ **Security headers** are applied via Traefik middleware

## Troubleshooting

See `INLOCK-AI-DEPLOYMENT.md` for detailed troubleshooting steps.

