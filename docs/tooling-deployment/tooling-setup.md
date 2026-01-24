# Tooling Stack Deployment Guide

Deploy **Strapi CMS** and **PostHog Analytics** for the Inlock AI platform.

## Overview

This stack provides:
- **Strapi**: Headless CMS for content management (`cms.inlock.ai`)
- **PostHog**: Product analytics and user behavior tracking (`analytics.inlock.ai`)

## Prerequisites

- Docker and Docker Compose installed
- Traefik reverse proxy configured with SSL
- Domain names pointing to your server
- At least 4GB RAM available

## Deployment Steps

### 1. Environment Setup

Copy the template and fill in secrets:

```bash
cp infrastructure/env-templates/tooling.env.template .env.tooling
```

Edit `.env.tooling` and set:

```env
# Hostnames
CMS_HOSTNAME=cms.inlock.ai
ANALYTICS_HOSTNAME=analytics.inlock.ai

# Strapi Database
STRAPI_DB_PASSWORD=<generate-strong-password>

# Strapi Secrets (generate with: openssl rand -base64 32)
ADMIN_JWT_SECRET=<random-key>
API_TOKEN_SALT=<random-key>
APP_KEYS=<random-key>
JWT_SECRET=<random-key>
TRANSFER_TOKEN_SALT=<random-key>

# PostHog Database
POSTHOG_DB_PASSWORD=<generate-strong-password>
```

### 2. Deploy with Docker Compose

Ensure the Traefik network exists:

```bash
docker network create traefik_public || true
```

Deploy the stack:

```bash
docker compose -f infrastructure/docker-compose/tooling.yml up -d
```

### 3. Verify Deployment

**Check container status:**
```bash
docker compose -f infrastructure/docker-compose/tooling.yml ps
```

**View logs:**
```bash
docker compose -f infrastructure/docker-compose/tooling.yml logs -f
```

**Access services:**
- **Strapi**: Visit `https://cms.inlock.ai/admin` to create your first admin user
- **PostHog**: Visit `https://analytics.inlock.ai` (initial setup takes 2-3 minutes)

## Next.js Integration

### Strapi Integration

1. **Generate API Token** in Strapi Admin → Settings → API Tokens
   - Create new token with "Full Access" or custom permissions
   
2. **Add to Next.js environment:**
   ```env
   STRAPI_API_URL=https://cms.inlock.ai
   STRAPI_API_TOKEN=your_generated_token_here
   ```

3. **Fetch data in Next.js:**
   ```javascript
   const res = await fetch(`${process.env.STRAPI_API_URL}/api/articles`, {
     headers: { Authorization: `Bearer ${process.env.STRAPI_API_TOKEN}` }
   });
   const data = await res.json();
   ```

### PostHog Integration

1. **Get Project Key** from PostHog → Project Settings → Project API Key

2. **Add to Next.js environment:**
   ```env
   NEXT_PUBLIC_POSTHOG_KEY=phc_your_project_key_here
   NEXT_PUBLIC_POSTHOG_HOST=https://analytics.inlock.ai
   ```

3. **Install and configure:**
   ```bash
   npm install posthog-js
   ```

   ```javascript
   // app/providers.js
   'use client'
   import posthog from 'posthog-js'
   import { PostHogProvider } from 'posthog-js/react'

   if (typeof window !== 'undefined') {
     posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
       api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST,
       capture_pageview: false
     })
   }

   export function CSPostHogProvider({ children }) {
     return <PostHogProvider client={posthog}>{children}</PostHogProvider>
   }
   ```

## Troubleshooting

### Strapi won't start

- **Check database connection**: Ensure `strapi_db` container is running
- **Check logs**: `docker logs strapi_app`
- **Reset database**: If corrupt, remove volume and recreate

### PostHog returns 502

- **Wait for migrations**: Initial deployment takes 2-3 minutes for database setup
- **Check ClickHouse**: `docker logs posthog_clickhouse`
- **Check Kafka**: `docker logs posthog_kafka`

### SSL/TLS errors

- Verify Traefik labels in compose file
- Check DNS is pointing to server
- Review Traefik logs for certificate issues

## Alternative Deployment: Coolify

1. Go to your Coolify project
2. Create new **Docker Compose** resource
3. Paste contents of `infrastructure/docker-compose/tooling.yml`
4. Add environment variables from `.env.tooling` in Coolify's UI
5. Deploy

## Maintenance

**PostHog: Pause / Resume (reduce CPU)**  
To stop only the CPU-heavy PostHog worker and plugins: [POSTHOG-PAUSE-RESUME.md](./POSTHOG-PAUSE-RESUME.md).

**Update images:**
```bash
docker compose -f infrastructure/docker-compose/tooling.yml pull
docker compose -f infrastructure/docker-compose/tooling.yml up -d
```

**Backup volumes:**
```bash
docker run --rm -v strapi_data:/data -v $(pwd):/backup alpine tar czf /backup/strapi-backup.tar.gz /data
docker run --rm -v posthog_pg_data:/data -v $(pwd):/backup alpine tar czf /backup/posthog-backup.tar.gz /data
```
