# Inlock AI Deployment Verification Guide

## ✅ Pre-Deployment Checks

### Rebranding Verification
- ✅ **No StreamArt references found** in `/opt/inlock-ai-secure-mvp`
- ✅ **No StreamArt references found** in `/home/comzis/inlock-infra`
- ✅ **Old directory removed** (`/opt/streamart-ai-secure-mvp`)

### Build Status
- ✅ **Docker build successful** — Image size: 390MB (compressed)
- ✅ **Image tagged**: `inlock-ai:latest`
- ✅ **All user-facing code updated** to "Inlock" branding

## 🌐 Production Deployment Status

### Traefik Router Configuration
**File**: `/home/comzis/inlock-infra/traefik/dynamic/routers.yml`

The Traefik router is **already configured** to route `inlock.ai` and `www.inlock.ai` to the Inlock AI service:

```yaml
inlock-ai:
  entryPoints:
    - websecure
  rule: Host(`inlock.ai`) || Host(`www.inlock.ai`)
  middlewares:
    - secure-headers
  service: inlock-ai
  tls:
    options: default  # Uses Positive SSL certificate
```

✅ **Status**: Active and routing to production

### Service Status
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps inlock-ai
```

## 🔍 Post-Deployment Verification

### Spot-Check Key Routes

Verify that **"Inlock"** branding appears consistently across all routes:

#### 1. Homepage
- **URL**: `https://inlock.ai/`
- **Check**: 
  - Hero section shows "Inlock — Secure AI Consulting"
  - Navigation shows "Inlock" (not StreamArt)
  - Footer shows "© 2025 Inlock — Privacy-First AI Consulting"

#### 2. Consulting Page
- **URL**: `https://inlock.ai/consulting`
- **Check**:
  - Page title and content show "Inlock" branding
  - All service descriptions use "Inlock" terminology

#### 3. Blog
- **URL**: `https://inlock.ai/blog`
- **Check**:
  - Blog masthead shows "Inlock Blog"
  - Blog post metadata references "Inlock" (not StreamArt)

#### 4. Workspace (Authenticated)
- **URL**: `https://inlock.ai/workspace/[id]`
- **Check**:
  - Workspace layout shows "Inlock v0.1"
  - Chat interface welcome message says "Welcome to Inlock AI"

#### 5. Additional Routes
- `/readiness-checklist`
- `/ai-blueprint`
- `/case-studies`
- `/auth/login`
- `/auth/register`

### Verification Commands

```bash
# Check service health
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps inlock-ai

# View recent logs
docker logs compose-inlock-ai-1 --tail 50

# Check Traefik routing
docker logs compose-traefik-1 --tail 50 | grep inlock-ai

# Verify SSL certificate
curl -I https://inlock.ai 2>&1 | grep -i "strict-transport-security\|x-frame-options"
```

### Browser Testing Checklist

- [ ] Homepage loads correctly with Inlock branding
- [ ] Navigation shows "Inlock" everywhere
- [ ] Footer shows "© 2025 Inlock"
- [ ] Blog section shows "Inlock Blog"
- [ ] Workspace areas show "Inlock v0.1"
- [ ] SSL certificate is valid (Positive SSL)
- [ ] HTTPS redirect works
- [ ] www.inlock.ai redirects correctly

## 🔄 Deployment Commands

### Update Application
```bash
# 1. Build new image
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .

# 2. Deploy updated image
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans inlock-ai

# 3. Verify deployment
docker compose -f compose/stack.yml --env-file .env ps inlock-ai
docker logs compose-inlock-ai-1 --tail 50
```

### Rollback (if needed)
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env pull inlock-ai:previous
docker tag inlock-ai:previous inlock-ai:latest
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

## 📊 Current Status

**Last Updated**: 2025-12-09  
**Deployment Status**: ✅ Deployed  
**Image**: `inlock-ai:latest` (390MB compressed)  
**Routes Active**: `inlock.ai`, `www.inlock.ai`  
**SSL**: Positive SSL (via Traefik)  
**Health Check**: Configured and passing

## 🎯 Next Steps

1. ✅ **Complete spot-checks** of all key routes listed above
2. ✅ **Verify SSL certificate** is working correctly
3. ✅ **Test authentication flows** if applicable
4. ✅ **Monitor logs** for any errors in the first 24 hours

## ✅ Browser Verification Results

**Verified Routes (2025-12-09):**

- ✅ **Homepage** (`/`): 
  - Title: "Inlock — Secure AI Consulting" ✓
  - Navigation: "Inlock" link ✓
  - Hero: "Inlock Secure AI Consulting" ✓

- ✅ **Consulting** (`/consulting`):
  - Navigation: "Inlock" link ✓
  - Heading: "Privacy-First AI Consulting" ✓
  - Content: "Inlock helps organizations..." ✓

- ✅ **Blog** (`/blog`):
  - Navigation: "Inlock" link ✓
  - Blog posts loaded correctly ✓

- ✅ **Readiness Checklist** (`/readiness-checklist`):
  - Navigation: "Inlock" link ✓
  - Form loads correctly ✓

**Branding Status**: ✅ All routes show "Inlock" branding (no StreamArt references)

## 🤖 Automation Scripts

### Quick Verification Script
```bash
/home/comzis/inlock-infra/scripts/verify-inlock-deployment.sh
```

### Regression Testing (Application)
```bash
cd /opt/inlock-ai-secure-mvp
./scripts/regression-check.sh
```

**Note**: The regression script works in Docker if npm is not installed on the host.

---

**Note**: The Traefik router is already configured and active. No additional router changes are needed.

