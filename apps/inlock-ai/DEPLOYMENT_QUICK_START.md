# Deployment Quick Start

## 🚀 One-Command Deployment Check

```bash
npm run deploy:full
```

This validates everything before deployment.

## 📋 Step-by-Step

### 1. Generate Secret (First Time Only)

```bash
npm run deploy:generate-secret
```

Copy the output to:
- Your `.env` file
- Platform environment variables (Inlock AI dashboard)

### 2. Pre-Deployment Validation

```bash
npm run deploy:full
```

Fixes any issues before deploying.

### 3. Deploy

Push to your repository or trigger deployment in your platform dashboard.

### 4. Post-Deployment

```bash
# Run migrations (if database schema changed)
npm run deploy:migrate

# Verify deployment
npm run deploy:verify
```

## 🤖 Automated CI/CD

The repository includes GitHub Actions workflows that automatically:
- ✅ Run tests on every push
- ✅ Build and validate on main branch
- ✅ Deploy to production (when configured)

## 📚 Full Documentation

- **Automated Deployment**: `AUTOMATED_DEPLOYMENT.md`
- **Deployment Guide**: `DEPLOYMENT.md`
- **Inlock AI Guide**: `INLOCK_AI_DEPLOYMENT.md`
- **Scripts Documentation**: `scripts/deploy/README.md`

## ⚡ Quick Commands Reference

```bash
# Pre-deployment
npm run deploy:check          # Run all checks
npm run deploy:validate-env   # Validate environment
npm run deploy:generate-secret # Generate secret
npm run deploy:full           # All of the above + build

# Database
npm run deploy:migrate        # Run migrations

# Post-deployment
npm run deploy:verify         # Verify deployment
```

---

**That's it!** Your deployment is now automated. 🎉

