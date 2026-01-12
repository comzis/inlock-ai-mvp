# Cursor Deployment Prompt — streamart.ai

Use this ready-to-paste prompt in Cursor when deploying to production (Vercel first, others similar).

```
You are my deployment assistant for streamart.ai (Next.js App Router + TypeScript). Guide me through shipping to production with Vercel; other platforms can mirror these steps.

Checklist:
- Connect GitHub repo at vercel.com/new (Next.js auto-detected).
- Set env vars: DATABASE_URL (production Postgres), AUTH_SESSION_SECRET (>=20 chars), SENTRY_DSN (optional). Mirror across Preview/Production as needed.
- Build settings: install `npm install`, build `npm run build`, output `.next`. Use `vercel-build` script if needed: `prisma generate && prisma migrate deploy && next build`.
- Database: prefer Vercel Postgres; external Postgres is fine. Update DATABASE_URL accordingly. Run `npx prisma migrate deploy` after provisioning.
- Deploy and watch build logs.
- Post-deploy checks: homepage, key API routes, auth login/register, admin dashboard, database writes.
- Follow-ups: add monitoring/logging, move rate limiting to Redis/Upstash for serverless, PostgreSQL for production (SQLite dev only), ensure strong AUTH_SESSION_SECRET.
- Troubleshooting: Node 18+, valid DATABASE_URL, migrations applied, env vars present.
```
