# Deployment Guide - StreamArt.ai

This guide covers deploying the StreamArt.ai platform to production environments, including Inlock AI and other hosting platforms.

## 📋 Pre-Deployment Checklist

### 1. Code Preparation
- [ ] All tests pass: `npm test && npm run test:e2e`
- [ ] Production build succeeds: `npm run build`
- [ ] No linting errors: `npm run lint`
- [ ] Database migrations are up to date
- [ ] Environment variables documented in `.env.example`

### 2. Database Setup
- [ ] **Production Database**: Switch from SQLite to PostgreSQL
  - Update `prisma/schema.prisma` datasource provider to `postgresql`
  - Update `DATABASE_URL` environment variable
  - Run migrations: `npx prisma migrate deploy`

### 3. Environment Variables
- [ ] All required variables set (see `.env.example`)
- [ ] `AUTH_SESSION_SECRET` is strong (min 20 chars, use `openssl rand -base64 32`)
- [ ] `DATABASE_URL` points to production database
- [ ] At least one AI provider API key configured
- [ ] Optional: Redis credentials for rate limiting
- [ ] Optional: Sentry DSN for error monitoring

### 4. Security
- [ ] Strong `AUTH_SESSION_SECRET` generated
- [ ] HTTPS enabled (required for secure cookies)
- [ ] Environment variables secured (not in git)
- [ ] Database credentials secured
- [ ] API keys secured

## 🚀 Deployment Steps

### Step 1: Build Verification

```bash
# Verify production build works locally
npm run build

# Test production server locally
npm start
```

### Step 2: Database Migration

**Important**: For production, you must use PostgreSQL (not SQLite).

1. Update `prisma/schema.prisma`:
   ```prisma
   datasource db {
     provider = "postgresql"  // Change from "sqlite"
     url      = env("DATABASE_URL")
   }
   ```

2. Set production `DATABASE_URL`:
   ```bash
   DATABASE_URL="postgresql://user:password@host:port/database?sslmode=require"
   ```

3. Run migrations:
   ```bash
   npx prisma generate
   npx prisma migrate deploy
   ```

### Step 3: Environment Configuration

Set all required environment variables in your hosting platform:

**Required:**
- `DATABASE_URL` - PostgreSQL connection string
- `AUTH_SESSION_SECRET` - Secure random string (min 20 chars)

**Recommended:**
- `GOOGLE_AI_API_KEY` - For chat features
- `NODE_ENV=production` - Set to production

**Optional:**
- `UPSTASH_REDIS_REST_URL` & `UPSTASH_REDIS_REST_TOKEN` - For distributed rate limiting
- `SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT` - For error monitoring
- Other AI provider keys as needed

### Step 4: Deploy to Inlock AI

Since Inlock AI is a specific platform, follow these general steps and adapt based on their documentation:

1. **Connect Repository**
   - Link your GitHub/GitLab repository to Inlock AI
   - Ensure the repository is accessible

2. **Configure Build Settings**
   - **Build Command**: `npm run build`
   - **Install Command**: `npm install`
   - **Output Directory**: `.next`
   - **Node Version**: 18.x or higher

3. **Set Environment Variables**
   - Add all required variables from `.env.example`
   - Ensure `NODE_ENV=production`
   - Set production `DATABASE_URL`

4. **Database Setup**
   - Provision PostgreSQL database (if not included)
   - Update `DATABASE_URL` with production credentials
   - Run migrations: `npx prisma migrate deploy`

5. **Deploy**
   - Trigger deployment
   - Monitor build logs for errors
   - Verify deployment success

### Step 5: Post-Deployment Verification

After deployment, verify the following:

1. **Homepage**: Visit the root URL, should load without errors
2. **Authentication**: 
   - Visit `/auth/register` - form should load
   - Visit `/auth/login` - form should load
3. **API Routes**: Test key endpoints
   - `/api/providers` - Should return available AI providers
   - `/api/contact` - Should accept POST requests
4. **Database**: 
   - Register a new user
   - Verify user appears in database
5. **Admin Dashboard**: 
   - Login with admin credentials
   - Visit `/admin` - should display dashboard
6. **Chat Feature** (if AI keys configured):
   - Login and visit `/chat`
   - Should show provider selector and chat interface

## 🔧 Platform-Specific Notes

### Inlock AI

If Inlock AI has specific requirements:

1. **Check Documentation**: Review Inlock AI's deployment documentation
2. **Build Configuration**: Verify build command and output directory
3. **Environment Variables**: Use their dashboard to set variables
4. **Database**: Check if they provide managed PostgreSQL or require external
5. **Custom Domain**: Configure if needed
6. **SSL/HTTPS**: Ensure HTTPS is enabled (required for secure cookies)

### Vercel (Alternative)

If deploying to Vercel instead:

1. Connect GitHub repo at [vercel.com/new](https://vercel.com/new)
2. Next.js auto-detected
3. Set environment variables in dashboard
4. Use Vercel Postgres or external PostgreSQL
5. Deploy automatically on push

### Other Platforms

For other platforms (Railway, Render, Fly.io, etc.):

1. Follow their Next.js deployment guides
2. Ensure Node.js 18+ support
3. Configure PostgreSQL database
4. Set all environment variables
5. Run `prisma migrate deploy` after first deployment

## 🐛 Troubleshooting

### Build Fails

- Check Node.js version (requires 18+)
- Verify all dependencies install: `npm install`
- Check for TypeScript errors: `npm run lint`
- Review build logs for specific errors

### Database Connection Errors

- Verify `DATABASE_URL` is correct
- Check database is accessible from hosting platform
- Ensure SSL mode is set if required: `?sslmode=require`
- Verify database user has proper permissions

### Authentication Not Working

- Verify `AUTH_SESSION_SECRET` is set and strong (min 20 chars)
- Check HTTPS is enabled (required for secure cookies)
- Verify cookie settings in `src/lib/auth.ts`
- Check browser console for cookie errors

### AI Chat Not Working

- Verify at least one AI provider API key is set
- Check API key is valid and has credits/quota
- Review server logs for API errors
- Test provider availability: `/api/providers`

### Rate Limiting Issues

- If using Redis: verify `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`
- If not using Redis: in-memory fallback should work (per-instance limits)
- Check rate limit logs in server output

## 📊 Monitoring

### Recommended Setup

1. **Error Monitoring**: Configure Sentry
   - Set `SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT`
   - Errors will be tracked automatically

2. **Logging**: Use platform's logging service
   - Monitor application logs
   - Set up alerts for errors

3. **Database Monitoring**: Monitor database performance
   - Check connection pool usage
   - Monitor query performance

4. **Uptime Monitoring**: Use external service
   - Monitor homepage availability
   - Set up alerts for downtime

## 🔄 Continuous Deployment

### Recommended Workflow

1. **Development**: Work on feature branches
2. **Testing**: Run tests before merging
3. **Staging**: Deploy to staging environment first
4. **Production**: Merge to main triggers production deploy
5. **Verification**: Run post-deployment checks

### Git Workflow

```bash
# Feature branch
git checkout -b feature/new-feature
# ... make changes ...
git commit -m "Add new feature"
git push origin feature/new-feature

# After review, merge to main
git checkout main
git merge feature/new-feature
git push origin main  # Triggers deployment
```

## 📝 Maintenance

### Regular Tasks

- **Weekly**: Review error logs and fix issues
- **Monthly**: Update dependencies (`npm update`)
- **Quarterly**: Review and rotate API keys
- **As Needed**: Database backups and migrations

### Updates

```bash
# Update dependencies
npm update

# Run tests
npm test

# Build and verify
npm run build

# Deploy after verification
```

## 🆘 Support

If you encounter issues:

1. Check this deployment guide
2. Review platform-specific documentation
3. Check application logs
4. Verify environment variables
5. Test locally with production settings

---

**Last Updated**: 2024-01-XX
**Platform**: Inlock AI / General Next.js Deployment

