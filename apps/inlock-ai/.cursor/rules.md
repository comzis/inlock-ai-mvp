# Cursor Rules for streamart.ai

## Core Principles

1. **TypeScript First** - Use TypeScript everywhere, no `any` types unless absolutely necessary
2. **Next.js App Router** - Use App Router patterns, server components by default
3. **Security First** - Validate inputs, use secure defaults, avoid logging sensitive data
4. **Type Safety** - Leverage TypeScript and Zod for runtime validation

## Code Standards

### API Routes
- Always validate inputs with Zod schemas
- Return proper HTTP status codes (400, 401, 429, 500)
- Use rate limiting on public endpoints
- Handle errors gracefully with JSON responses

### Database
- Use Prisma via `src/lib/db.ts` (never create new PrismaClient instances)
- Keep all schema changes in migrations
- Use transactions for multi-step operations
- Never expose raw database errors to clients

### Authentication
- Use helpers from `src/lib/auth.ts`
- Check authentication with `getCurrentUser()` in server components
- Protect routes with redirects or middleware
- Never log passwords or session tokens

### Components
- Prefer server components (default)
- Use `"use client"` only for interactivity (forms, state, browser APIs)
- Reuse UI components from `components/ui/`
- Follow Tailwind design tokens

### Imports
- Use `@/` aliases in app code
- Use relative imports in scripts (`../src/lib/db`)
- Group imports: external → internal → relative

### Error Handling
- Use try/catch in async functions
- Return appropriate error responses
- Log errors server-side (never expose stack traces)
- Use Zod's `safeParse` for validation

## File Organization

- `app/` - Next.js pages and API routes
- `components/` - React components (grouped by feature)
- `src/lib/` - Core utilities (auth, db, etc.)
- `src/utils/` - Helper functions
- `prisma/` - Database schema and migrations
- `scripts/` - Utility scripts (use relative imports)

## Testing

- Write tests for critical paths
- Use Vitest for unit/integration tests
- Test API endpoints with proper fixtures
- Keep tests in `tests/` directory

## Git Conventions

- Use descriptive commit messages
- Keep commits focused (one feature/fix per commit)
- Reference issues/PRs when applicable

## Security Checklist

- ✅ All API inputs validated with Zod
- ✅ Rate limiting on public endpoints
- ✅ Passwords hashed with bcrypt
- ✅ Sessions use HTTP-only cookies
- ✅ Security headers in middleware
- ✅ No sensitive data in logs
- ✅ Environment variables for secrets
