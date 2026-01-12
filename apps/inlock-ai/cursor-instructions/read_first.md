# Read First — streamart.ai

Welcome! Start here to get oriented with the codebase.

## Quick Setup

1. Copy `.env.example` to `.env` and set `AUTH_SESSION_SECRET`
2. Run `npm install && npx prisma generate && npx prisma migrate dev --name init`
3. Optionally seed: `npm run seed`
4. Start dev server: `npm run dev` (port 3040)

## Essential Learning Path

Run `/learn` in Cursor on these areas:

1. **Content System**: `content/` and `src/utils/markdown.ts`
2. **Core Libraries**: `src/lib/` (auth, db, rate-limit, admin)
3. **Example Page**: `app/consulting/page.tsx`
4. **Documentation**: `cursor-instructions/` folder

## Project Conventions

See `.cursor/rules.md` for coding standards:
- TypeScript everywhere
- Next.js App Router
- Zod validation
- Prisma via `src/lib/db.ts`
- Security-first approach

## Next Steps

- Read `cursor-instructions/onboarding.md` for detailed architecture
- Check `README.md` for full project documentation
- Review `cursor-instructions/deploy_guide.md` for deployment
