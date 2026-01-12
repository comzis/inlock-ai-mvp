# Deployment Checklist - StreamArt.ai

Use this checklist to ensure a smooth deployment to Inlock AI or any production environment.

## Pre-Deployment

### Code Quality
- [ ] All unit tests pass: `npm test`
- [ ] All E2E tests pass: `npm run test:e2e`
- [ ] Production build succeeds: `npm run build`
- [ ] No linting errors: `npm run lint`
- [ ] Code is committed and pushed to repository

### Database
- [ ] `prisma/schema.prisma` uses `postgresql` provider (not `sqlite`)
- [ ] Production PostgreSQL database provisioned
- [ ] `DATABASE_URL` environment variable set with production connection string
- [ ] Database migrations ready: `npx prisma migrate deploy` (dry run)

### Environment Variables
- [ ] `DATABASE_URL` - PostgreSQL connection string
- [ ] `AUTH_SESSION_SECRET` - Strong secret (min 20 chars, use `openssl rand -base64 32`)
- [ ] `NODE_ENV=production`
- [ ] At least one AI provider key configured:
  - [ ] `GOOGLE_AI_API_KEY` (recommended)
  - [ ] `ANTHROPIC_API_KEY` (optional)
  - [ ] `HUGGINGFACE_API_KEY` (optional)
  - [ ] `OPENAI_API_KEY` (optional)
- [ ] Optional: `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`
- [ ] Optional: `SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT`

### Security
- [ ] Strong `AUTH_SESSION_SECRET` generated
- [ ] All API keys secured (not in git)
- [ ] Database credentials secured
- [ ] HTTPS/SSL enabled (required for secure cookies)

## Deployment

### Platform Configuration
- [ ] Repository connected to hosting platform
- [ ] Build command set: `npm run build`
- [ ] Install command set: `npm install`
- [ ] Output directory set: `.next`
- [ ] Node.js version set: 18.x or higher
- [ ] All environment variables configured in platform dashboard

### Database Migration
- [ ] Run migrations: `npx prisma migrate deploy`
- [ ] Verify database schema is correct
- [ ] Seed initial admin user (if needed): `npm run seed`

### Deployment
- [ ] Trigger deployment
- [ ] Monitor build logs
- [ ] Verify deployment completes successfully
- [ ] Note deployment URL

## Post-Deployment

### Functional Testing
- [ ] Homepage loads: `/`
- [ ] Registration page loads: `/auth/register`
- [ ] Login page loads: `/auth/login`
- [ ] Can register new user
- [ ] Can login with registered user
- [ ] Admin dashboard accessible: `/admin` (after login)
- [ ] Blog pages load: `/blog`
- [ ] Contact form works: `/consulting`
- [ ] API endpoints respond: `/api/providers`

### AI Features (if configured)
- [ ] Chat page loads: `/chat`
- [ ] Provider selector shows available providers
- [ ] Can send message and receive response
- [ ] Chat sessions save and load correctly

### Security
- [ ] HTTPS is enabled and working
- [ ] Cookies are secure (httpOnly, secure flags)
- [ ] Protected routes require authentication
- [ ] Rate limiting is working

### Performance
- [ ] Pages load quickly (< 3 seconds)
- [ ] No console errors in browser
- [ ] No server errors in logs
- [ ] Database queries are efficient

## Monitoring Setup

### Error Tracking
- [ ] Sentry configured (if using)
- [ ] Error tracking is working
- [ ] Alerts configured for critical errors

### Logging
- [ ] Application logs accessible
- [ ] Log retention configured
- [ ] Log levels appropriate

### Uptime
- [ ] Uptime monitoring configured
- [ ] Alerts set up for downtime

## Documentation

### Internal
- [ ] Deployment process documented
- [ ] Environment variables documented
- [ ] Database credentials stored securely
- [ ] Team has access to deployment dashboard

### External (if needed)
- [ ] Domain configured (if custom domain)
- [ ] DNS records updated
- [ ] SSL certificate valid

## Rollback Plan

- [ ] Previous deployment version identified
- [ ] Rollback procedure documented
- [ ] Database backup available (if needed)
- [ ] Team knows how to rollback

## Sign-Off

- [ ] All checklist items completed
- [ ] Application tested and working
- [ ] Team notified of deployment
- [ ] Deployment signed off by: ________________

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Platform**: Inlock AI
**Environment**: Production
**Version**: _______________

