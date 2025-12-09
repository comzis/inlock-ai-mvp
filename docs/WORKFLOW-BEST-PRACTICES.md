# Workflow Best Practices - Inlock AI

## Architecture Overview

The Inlock AI deployment uses a **two-layer architecture** with clear separation of concerns:

### Layer 1: Application Repository
**Location:** `/opt/inlock-ai-secure-mvp/`

**Contains:**
- React/Next.js application source code
- UI components (`app/`, `components/`)
- Content files (markdown, blog posts)
- Application configuration
- Application-level tests

**Purpose:** All application code, content, and UI changes

### Layer 2: Infrastructure Repository
**Location:** `/home/comzis/inlock-infra/`

**Contains:**
- Docker Compose configurations
- Traefik routing configuration
- Service definitions
- Deployment scripts
- Infrastructure secrets management
- Monitoring and admin tooling

**Purpose:** Infrastructure orchestration and deployment

---

## Workflow: Making Application Changes

### Step 1: Edit Application Code

```bash
cd /opt/inlock-ai-secure-mvp

# Make your changes to:
# - app/*.tsx (React components)
# - components/*.tsx (UI components)
# - content/*.md (Blog posts, documents)
# - src/lib/*.ts (Application logic)
```

### Step 2: Preview Locally (Optional)

```bash
# Install dependencies (if needed)
npm install

# Start development server
npm run dev
# Visit: http://localhost:3040
```

### Step 3: Quality Checks

```bash
# Linting
npm run lint

# Tests
npm run test

# Build verification
npm run build
```

### Step 4: Build Docker Image

```bash
# Build the new image
docker build -t inlock-ai:latest .
```

### Step 5: Deploy to Infrastructure

```bash
cd /home/comzis/inlock-infra

# Redeploy with new image
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai

# Verify deployment
docker logs compose-inlock-ai-1 --tail 50
```

### Step 6: Verify

```bash
# Check service is healthy
docker compose -f compose/stack.yml --env-file .env ps inlock-ai

# Test production URL
curl -I https://inlock.ai
```

---

## Workflow: Making Infrastructure Changes

### When to Edit Infrastructure Repository

Edit `/home/comzis/inlock-infra/` when you need to:

1. **Update Traefik routing:**
   - Add/modify routes in `traefik/dynamic/routers.yml`
   - Change service definitions in `traefik/dynamic/services.yml`
   - Update middlewares in `traefik/dynamic/middlewares.yml`

2. **Modify Docker Compose:**
   - Add/remove services in `compose/stack.yml`
   - Update service configurations
   - Change networks or volumes

3. **Update Secrets:**
   - Change secret file locations
   - Update environment variables
   - Modify secret management scripts

4. **Infrastructure Scripts:**
   - Deployment scripts
   - Backup/restore procedures
   - Infrastructure automation

### Infrastructure Change Workflow

```bash
cd /home/comzis/inlock-infra

# 1. Make infrastructure changes
# - Edit compose files
# - Update Traefik config
# - Modify scripts

# 2. Apply changes
docker compose -f compose/stack.yml --env-file .env up -d

# 3. Restart affected services
docker compose -f compose/stack.yml --env-file .env restart traefik

# 4. Verify
docker compose -f compose/stack.yml --env-file .env ps
```

---

## Clear Separation of Concerns

### ✅ Application Repository (Do Here)

- Edit React components and pages
- Update content (markdown files)
- Change UI/styling
- Modify application logic
- Update tests
- Change application configuration
- Update package.json dependencies

### ✅ Infrastructure Repository (Do Here)

- Configure Traefik routing
- Manage Docker Compose services
- Update middleware configurations
- Manage secrets and environment files
- Infrastructure deployment scripts
- Monitoring and logging setup

### ❌ Don't Mix

- **Don't edit app code in infra repo** (except deployment-related scripts)
- **Don't edit infrastructure config in app repo** (except app-level config)
- **Don't commit app code to infra repo**
- **Don't commit infra config to app repo**

---

## Common Workflows

### Adding a New Page to the Application

```bash
# 1. Edit in app repo
cd /opt/inlock-ai-secure-mvp

# 2. Create new page
# Create: app/new-page/page.tsx

# 3. Test locally
npm run dev

# 4. Build and deploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

**Note:** No infrastructure changes needed - Traefik will automatically route to the new page.

### Adding a New Admin Service

```bash
# 1. Edit in infra repo
cd /home/comzis/inlock-infra

# 2. Add service to compose/stack.yml
# 3. Add router to traefik/dynamic/routers.yml
# 4. Add service to traefik/dynamic/services.yml

# 5. Deploy
docker compose -f compose/stack.yml --env-file .env up -d new-service
docker compose -f compose/stack.yml --env-file .env restart traefik
```

**Note:** This is infrastructure change, not application change.

### Updating Blog Content

```bash
# 1. Edit in app repo
cd /opt/inlock-ai-secure-mvp

# 2. Edit content/*.md files
# 3. Update src/lib/blog.ts if adding new post

# 4. Rebuild and deploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

---

## Image Management

### Building Images

**Always build from app repository:**
```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
```

### Tagging Versions

For production deployments, consider versioned tags:

```bash
# Build with version tag
docker build -t inlock-ai:v1.0.0 .
docker build -t inlock-ai:latest .

# Deploy specific version
cd /home/comzis/inlock-infra
# Edit compose/inlock-ai.yml: image: inlock-ai:v1.0.0
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

---

## Environment Files

### Application Environment

**Location:** `/opt/inlock-ai-secure-mvp/.env.production`

**Contains:**
- `DATABASE_URL` - Application database connection
- `AUTH_SESSION_SECRET` - Application auth secret
- Application-specific API keys

**Managed in:** Application repository (but not committed to git)

### Infrastructure Environment

**Location:** `/home/comzis/inlock-infra/.env`

**Contains:**
- `DOMAIN` - Domain name
- `CLOUDFLARE_API_TOKEN` - DNS API token
- Infrastructure-level variables

**Managed in:** Infrastructure repository (but not committed to git)

---

## Version Control

### Application Repository

```bash
cd /opt/inlock-ai-secure-mvp

# Commit application changes
git add app/ components/ content/
git commit -m "Update: [description]"

# Push to remote
git push origin main
```

### Infrastructure Repository

```bash
cd /home/comzis/inlock-infra

# Commit infrastructure changes
git add compose/ traefik/ scripts/
git commit -m "Infrastructure: [description]"

# Push to remote
git push origin main
```

---

## Quick Reference

| Task | Repository | Command |
|------|------------|---------|
| **Edit UI/Content** | App repo | Edit files, `npm run dev` |
| **Build Image** | App repo | `docker build -t inlock-ai:latest .` |
| **Deploy Application** | Infra repo | `docker compose up -d inlock-ai` |
| **Change Routing** | Infra repo | Edit `traefik/dynamic/routers.yml` |
| **Add Service** | Infra repo | Edit `compose/stack.yml` |
| **Update Content** | App repo | Edit `content/*.md` |
| **Change Styling** | App repo | Edit `app/globals.css` |

---

## Best Practices Summary

1. ✅ **Application changes → App repo** (`/opt/streamart-ai-secure-mvp/`)
2. ✅ **Infrastructure changes → Infra repo** (`/home/comzis/inlock-infra/`)
3. ✅ **Always test locally** before deploying
4. ✅ **Run quality checks** (lint, test, build) before building image
5. ✅ **Build image from app repo** before deploying
6. ✅ **Deploy from infra repo** using Docker Compose
7. ✅ **Keep repositories separate** - don't mix concerns
8. ✅ **Version control both repos** independently

---

**Last Updated:** 2025-12-09  
**Architecture:** Two-layer separation (Application + Infrastructure)

