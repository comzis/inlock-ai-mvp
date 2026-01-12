# Inlock AI Deployment - Quick Reference

This is a quick reference guide for deploying StreamArt.ai to Inlock AI.

## 🚀 Quick Start

### 1. Prepare Your Code
```bash
# Ensure everything is committed
git add .
git commit -m "Prepare for deployment"
git push origin main
```

### 2. Connect Repository to Inlock AI
1. Log into Inlock AI dashboard
2. Create a new project
3. Connect your GitHub/GitLab repository
4. Select the `streamart-ai-secure-mvp` repository

### 3. Configure Build Settings

**Build Configuration:**
- **Framework**: Next.js (should auto-detect)
- **Build Command**: `npm run build`
- **Install Command**: `npm install`
- **Output Directory**: `.next`
- **Node Version**: 18.x or higher

### 4. Set Environment Variables

In the Inlock AI dashboard, add these environment variables:

#### Required
```
DATABASE_URL=postgresql://user:password@host:port/database?sslmode=require
AUTH_SESSION_SECRET=<generate-strong-secret-min-20-chars>
NODE_ENV=production
```

#### Recommended (for AI features)
```
GOOGLE_AI_API_KEY=your-google-ai-api-key
```

#### Optional
```
UPSTASH_REDIS_REST_URL=your-redis-url
UPSTASH_REDIS_REST_TOKEN=your-redis-token
SENTRY_DSN=your-sentry-dsn
SENTRY_ORG=your-org
SENTRY_PROJECT=your-project
```

**Generate AUTH_SESSION_SECRET:**
```bash
openssl rand -base64 32
```

### 5. Database Setup

**Important**: You must use PostgreSQL for production (not SQLite).

1. **Provision PostgreSQL Database**
   - Use Inlock AI's database service (if available)
   - Or use external PostgreSQL (AWS RDS, Supabase, etc.)

2. **Update Prisma Schema** (if not already done)
   ```prisma
   datasource db {
     provider = "postgresql"  // Change from "sqlite"
     url      = env("DATABASE_URL")
   }
   ```

3. **Run Migrations**
   - After first deployment, run:
   ```bash
   npx prisma migrate deploy
   ```
   - Or add to build command: `npm run build && npx prisma migrate deploy`

### 6. Deploy

1. Click "Deploy" in Inlock AI dashboard
2. Monitor build logs
3. Wait for deployment to complete
4. Note your deployment URL

### 7. Post-Deployment

**Run Database Migrations:**
```bash
# Connect to your deployment or use Inlock AI's CLI/terminal
npx prisma migrate deploy
```

**Verify Deployment:**
- [ ] Homepage loads: `https://your-domain.inlock.ai`
- [ ] Registration works: `/auth/register`
- [ ] Login works: `/auth/login`
- [ ] Admin dashboard accessible: `/admin`
- [ ] Chat works (if AI keys configured): `/chat`

## 🔧 Common Issues

### Build Fails
- **Check Node version**: Ensure 18.x or higher
- **Check build logs**: Look for specific error messages
- **Verify dependencies**: Ensure `package.json` is correct

### Database Connection Errors
- **Verify DATABASE_URL**: Check connection string format
- **Check SSL**: Add `?sslmode=require` if needed
- **Verify credentials**: Ensure database user has proper permissions
- **Check network**: Ensure database is accessible from Inlock AI

### Authentication Not Working
- **Verify AUTH_SESSION_SECRET**: Must be at least 20 characters
- **Check HTTPS**: Ensure SSL/HTTPS is enabled
- **Check cookies**: Verify secure cookie settings

### AI Chat Not Working
- **Verify API keys**: Check at least one AI provider key is set
- **Check API quotas**: Ensure API keys have credits/quota
- **Review logs**: Check server logs for API errors

## 📝 Environment Variables Reference

See `.env.example` for complete list of all environment variables.

**Minimum Required:**
- `DATABASE_URL` - PostgreSQL connection string
- `AUTH_SESSION_SECRET` - Secure random string (min 20 chars)
- `NODE_ENV=production`

**Recommended:**
- `GOOGLE_AI_API_KEY` - For chat features

## 🔄 Updates & Maintenance

### Deploy Updates
1. Push changes to repository
2. Inlock AI should auto-deploy (if configured)
3. Or manually trigger deployment in dashboard

### Database Migrations
After code updates that include schema changes:
```bash
npx prisma migrate deploy
```

### Environment Variable Updates
1. Update variables in Inlock AI dashboard
2. Redeploy application (or restart if supported)

## 🤖 CI/CD Automation (Docker Hub + GitHub Actions)

This repo includes `.github/workflows/deploy.yml` and `scripts/deploy/remote-deploy.sh` to automate container builds and server redeploys.

### 1) One-time server setup
```bash
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER && newgrp docker
mkdir -p /opt/streamart-ai-secure-mvp && cd /opt/streamart-ai-secure-mvp
git clone <repo-url> .          # or copy files manually
cp .env.example .env            # set AUTH_SESSION_SECRET, DATABASE_URL, API keys
chmod +x scripts/deploy/remote-deploy.sh
```
Expose/route ports 3040 (app) and 5432 (db) or front with a reverse proxy (nginx/Traefik).

### 2) GitHub Secrets (required)
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (Docker Hub PAT)
- `SSH_HOST` (server hostname/IP)
- `SSH_USER` (SSH user)
- `SSH_KEY` (private key for that user)
- `DEPLOY_DIR` (e.g., `/opt/streamart-ai-secure-mvp`)

### 3) What the workflow does (on push to `main`)
1. Build + push Docker image to Docker Hub: `${DOCKERHUB_USERNAME}/streamart-ai-secure-mvp:latest` and `:<git-sha>`
2. SSH to the server, `cd $DEPLOY_DIR`, set `DOCKER_IMAGE=<sha>`, then run:
   ```bash
   docker compose pull web
   docker compose up -d
   docker image prune -f
   ```

### 4) Manual redeploy on the server (optional)
```bash
cd /opt/streamart-ai-secure-mvp
DOCKER_IMAGE=youruser/streamart-ai-secure-mvp:latest ./scripts/deploy/remote-deploy.sh
```

## 📞 Support

If you encounter issues:
1. Check Inlock AI documentation
2. Review deployment logs
3. Verify environment variables
4. Test locally with production settings

## 🔗 Related Documentation

- **Full Deployment Guide**: See `DEPLOYMENT.md`
- **Deployment Checklist**: See `DEPLOYMENT_CHECKLIST.md`
- **Environment Variables**: See `.env.example`
- **Project README**: See `README.md`

---

**Platform**: Inlock AI
**Last Updated**: 2024-01-XX
