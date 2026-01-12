# Automated Deployment Guide

This guide explains how to use the automated deployment scripts and CI/CD workflows.

## 🚀 Quick Start

### One-Command Pre-Deployment Check

```bash
npm run deploy:full
```

This runs all pre-deployment checks, validates environment, and builds the application.

## 📋 Available Commands

### Pre-Deployment

```bash
# Run comprehensive pre-deployment checks
npm run deploy:check

# Validate environment variables
npm run deploy:validate-env

# Generate secure AUTH_SESSION_SECRET
npm run deploy:generate-secret

# Full pre-deployment (check + validate + build)
npm run deploy:full
```

### Database

```bash
# Run production database migrations
npm run deploy:migrate
```

### Post-Deployment

```bash
# Verify deployment health
npm run deploy:verify

# With custom URL
DEPLOYMENT_URL=https://your-app.inlock.ai npm run deploy:verify
```

## 🔄 Complete Deployment Workflow

### Step 1: Prepare Locally

```bash
# 1. Generate secure secret (first time only)
npm run deploy:generate-secret
# Copy the output to your .env file and platform environment variables

# 2. Run pre-deployment checks
npm run deploy:full
```

### Step 2: Deploy to Platform

**For Inlock AI:**
1. Push code to repository
2. Inlock AI auto-deploys (if configured)
3. Or manually trigger in dashboard

**For other platforms:**
- Follow platform-specific deployment process
- Ensure environment variables are set

### Step 3: Post-Deployment

```bash
# 1. Run database migrations (if schema changed)
npm run deploy:migrate

# 2. Verify deployment
npm run deploy:verify
```

## 🤖 CI/CD Automation

### GitHub Actions

The repository includes two workflows:

#### 1. Continuous Integration (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`

**Runs:**
- Linting
- Unit tests
- E2E tests
- Build verification
- Pre-deployment checks (on main branch)

#### 2. Deployment (`.github/workflows/deploy.yml`)

**Triggers:**
- Manual workflow dispatch
- Push to `main` branch
- Tags starting with `v*`

**Runs:**
- Environment validation
- Production build
- Database migrations
- Deployment to Inlock AI
- Post-deployment verification

### Setting Up GitHub Secrets

Add these secrets in GitHub repository settings:

**Required:**
- `DATABASE_URL` - PostgreSQL connection string
- `AUTH_SESSION_SECRET` - Secure random string (min 20 chars)
- `DEPLOYMENT_URL` - Your production URL (for verification)

**Optional:**
- `GOOGLE_AI_API_KEY` - Google Gemini API key
- `ANTHROPIC_API_KEY` - Anthropic Claude API key
- `HUGGINGFACE_API_KEY` - Hugging Face API token
- `OPENAI_API_KEY` - OpenAI API key
- `UPSTASH_REDIS_REST_URL` - Redis URL
- `UPSTASH_REDIS_REST_TOKEN` - Redis token
- `SENTRY_DSN` - Sentry DSN
- `SENTRY_ORG` - Sentry organization
- `SENTRY_PROJECT` - Sentry project
- `INLOCK_AI_TOKEN` - Inlock AI deployment token (if they provide API/CLI)

### Manual Deployment Trigger

1. Go to GitHub Actions tab
2. Select "Deploy to Production" workflow
3. Click "Run workflow"
4. Select environment (production/staging)
5. Click "Run workflow"

## 📝 Deployment Checklist

### Before First Deployment

- [ ] Generate `AUTH_SESSION_SECRET`: `npm run deploy:generate-secret`
- [ ] Update Prisma schema to use PostgreSQL
- [ ] Set up PostgreSQL database
- [ ] Configure all environment variables in platform
- [ ] Add GitHub secrets (if using CI/CD)
- [ ] Run `npm run deploy:full` locally

### Before Each Deployment

- [ ] Run `npm run deploy:check`
- [ ] Fix any issues
- [ ] Commit and push changes
- [ ] Monitor CI/CD pipeline

### After Deployment

- [ ] Run `npm run deploy:migrate` (if schema changed)
- [ ] Run `npm run deploy:verify`
- [ ] Test key features manually
- [ ] Monitor error logs

## 🔧 Customization

### Custom Build Command

If your platform requires a custom build command, update `package.json`:

```json
{
  "scripts": {
    "build:production": "npm run deploy:check && npm run build && npm run deploy:migrate"
  }
}
```

### Custom Deployment Script

Create `scripts/deploy/custom-deploy.ts` for platform-specific deployment:

```typescript
// Example for Inlock AI API
const response = await fetch('https://api.inlock.ai/deploy', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.INLOCK_AI_TOKEN}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    project: 'your-project-id',
    branch: 'main',
  }),
});
```

Then add to `package.json`:
```json
{
  "scripts": {
    "deploy:custom": "ts-node --project tsconfig.scripts.json scripts/deploy/custom-deploy.ts"
  }
}
```

## 🐛 Troubleshooting

### CI/CD Pipeline Fails

**Build fails:**
- Check Node.js version (requires 18+)
- Verify all dependencies in `package.json`
- Review build logs for specific errors

**Tests fail:**
- Run tests locally: `npm test`
- Check for flaky tests
- Verify test environment variables

**Deployment fails:**
- Verify all secrets are set in GitHub
- Check deployment logs
- Verify platform credentials

### Local Scripts Fail

**"Cannot find module" errors:**
```bash
npm install
```

**TypeScript errors:**
```bash
npx tsc --noEmit
```

**Environment variable errors:**
- Ensure `.env` file exists
- Check variable names match exactly
- Verify no extra spaces or quotes

### Database Migration Fails

**Connection errors:**
- Verify `DATABASE_URL` format
- Check database is accessible
- Ensure SSL mode if required: `?sslmode=require`

**Schema errors:**
- Verify Prisma schema uses `postgresql` provider
- Check for pending migrations
- Review migration files

## 📊 Monitoring

### Automated Monitoring

The deployment workflow includes:
- Build status notifications
- Deployment verification
- Error tracking (if Sentry configured)

### Manual Monitoring

After deployment:
1. Check application logs
2. Monitor error rates
3. Test key features
4. Review performance metrics

## 🔗 Related Documentation

- **Deployment Guide**: `DEPLOYMENT.md`
- **Inlock AI Guide**: `INLOCK_AI_DEPLOYMENT.md`
- **Deployment Checklist**: `DEPLOYMENT_CHECKLIST.md`
- **Scripts README**: `scripts/deploy/README.md`

## 🎯 Best Practices

1. **Always run pre-deployment checks** before pushing
2. **Use CI/CD** for automated testing and deployment
3. **Test locally** with production-like environment
4. **Monitor deployments** and verify health
5. **Keep secrets secure** - never commit to repository
6. **Document changes** in deployment notes
7. **Have rollback plan** ready before deploying

---

**Last Updated**: 2024-01-XX
**Automation Version**: 1.0.0

