# Deployment Automation Scripts

This directory contains automated scripts for deployment preparation, validation, and verification.

## Available Scripts

### Pre-Deployment

#### `pre-deploy-check.ts`
Comprehensive pre-deployment validation that checks:
- Node.js version (>=18)
- Dependencies installed
- Environment variables configured
- TypeScript compilation
- Linting
- Unit tests
- Production build
- Git status

**Usage:**
```bash
npm run deploy:check
```

#### `validate-env.ts`
Validates all environment variables (required and optional):
- Checks for required variables
- Validates format and constraints
- Warns about missing optional variables
- Verifies at least one AI provider is configured

**Usage:**
```bash
npm run deploy:validate-env
```

#### `generate-secret.ts`
Generates a cryptographically secure `AUTH_SESSION_SECRET`.

**Usage:**
```bash
npm run deploy:generate-secret
```

### Database

#### `migrate-db.ts`
Runs Prisma migrations for production PostgreSQL database.
- Validates PostgreSQL connection string
- Generates Prisma Client
- Runs migrations
- Verifies database connection

**Usage:**
```bash
npm run deploy:migrate
```

**Note:** Requires `DATABASE_URL` environment variable set to PostgreSQL connection string.

### Post-Deployment

#### `post-deploy-verify.ts`
Verifies deployment by testing key endpoints:
- Homepage
- Blog page
- Authentication pages
- API endpoints

**Usage:**
```bash
npm run deploy:verify
# Or with custom URL:
DEPLOYMENT_URL=https://your-app.inlock.ai npm run deploy:verify
```

## Complete Deployment Workflow

### 1. Pre-Deployment (Local)

```bash
# Generate secure secret (if needed)
npm run deploy:generate-secret

# Run all pre-deployment checks
npm run deploy:check

# Validate environment variables
npm run deploy:validate-env
```

### 2. Deploy to Platform

Follow your platform's deployment process (Inlock AI, Vercel, etc.)

### 3. Post-Deployment

```bash
# Run database migrations
npm run deploy:migrate

# Verify deployment
npm run deploy:verify
```

## Automated Workflow

Use the full deployment check before pushing:

```bash
npm run deploy:full
```

This runs:
1. Pre-deployment checks
2. Environment validation
3. Production build

## CI/CD Integration

These scripts are integrated into GitHub Actions workflows:
- `.github/workflows/ci.yml` - Runs on every push/PR
- `.github/workflows/deploy.yml` - Runs on main branch or manual trigger

## Environment Variables

All scripts respect environment variables from:
1. `.env` file (if exists)
2. System environment variables
3. CI/CD secrets (in GitHub Actions)

## Troubleshooting

### Script fails with "Cannot find module"
Ensure dependencies are installed:
```bash
npm install
```

### Database migration fails
- Verify `DATABASE_URL` is set correctly
- Ensure database is accessible
- Check Prisma schema uses `postgresql` provider

### Environment validation fails
- Check `.env` file exists
- Verify all required variables are set
- Ensure `AUTH_SESSION_SECRET` is at least 20 characters

## Next Steps

1. **Before first deployment:**
   - Run `npm run deploy:generate-secret`
   - Add secret to `.env` and platform environment variables
   - Update Prisma schema to use PostgreSQL

2. **Before each deployment:**
   - Run `npm run deploy:check`
   - Fix any issues
   - Push to repository

3. **After deployment:**
   - Run `npm run deploy:migrate` (if schema changed)
   - Run `npm run deploy:verify`

