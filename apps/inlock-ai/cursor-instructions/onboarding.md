# Cursor Onboarding — streamart.ai

## Quick Start

1. **Environment Setup**
   ```bash
   cp .env.example .env
   # Edit .env and set AUTH_SESSION_SECRET (min 20 characters)
   ```

2. **Install & Database**
   ```bash
   npm install
   npx prisma generate
   npx prisma migrate dev --name init
   ```

3. **Seed Data** (optional)
   ```bash
   npm run seed
   # Creates admin user: admin@example.com / Password123!
   ```

4. **Run Development Server**
   ```bash
   npm run dev
   # → http://localhost:3040
   ```

## Key Areas to Learn

### Content System
- `content/` - Markdown files loaded via `src/utils/markdown.ts`
- `src/lib/blog.ts` - Blog post metadata
- `src/lib/docs.ts` - Document metadata (BPG, service catalog, etc.)

### Core Libraries
- `src/lib/auth.ts` - Authentication helpers (createUser, verifyUser, getCurrentUser, sessions)
- `src/lib/db.ts` - Prisma client singleton
- `src/lib/rate-limit.ts` - In-memory rate limiting (30 req/min per IP)
- `src/lib/admin.ts` - Admin dashboard data aggregation

### Example Pages
- `app/consulting/page.tsx` - Marketing page with contact form
- `app/admin/page.tsx` - Protected admin dashboard
- `app/blog/[slug]/page.tsx` - Dynamic blog post rendering

## Architecture Overview

### Tech Stack
- **Framework**: Next.js 15 App Router
- **Language**: TypeScript (strict mode)
- **Database**: Prisma + SQLite
- **Styling**: Tailwind CSS with custom theme
- **Validation**: Zod schemas
- **Auth**: bcrypt + session cookies

### Project Structure
```
app/              # Next.js pages and API routes
components/       # React components (UI primitives, forms, theme)
content/          # Markdown content files
prisma/           # Database schema and migrations
scripts/          # Utility scripts (seed, export-pdf)
src/lib/          # Core utilities (auth, db, rate-limit)
src/utils/        # Helper functions (markdown loader)
tests/            # Vitest test files
```

### API Routes
- `/api/auth/*` - Authentication (login, register, logout)
- `/api/contact` - Contact form submission (Zod + rate limit)
- `/api/lead` - Lead capture (Zod + rate limit)
- `/api/readiness` - Readiness assessment (5 questions, scored 0-10)
- `/api/blueprint` - AI blueprint generator
- `/api/email` - Email placeholder (ready for integration)

### Database Models
- `User` - User accounts (email, password hash, role)
- `Session` - Active sessions (token, expiration)
- `Contact` - Contact form submissions
- `Lead` - Lead capture data
- `ReadinessAssessment` - Assessment results with scores
- `Blueprint` - AI transformation blueprints

## Development Patterns

### API Route Pattern
```typescript
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/src/lib/db";
import { rateLimit } from "@/src/lib/rate-limit";

const schema = z.object({ /* ... */ });

export async function POST(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") || req.ip || "unknown";
  if (!rateLimit(`endpoint:${ip}`)) {
    return NextResponse.json({ error: "Rate limit exceeded" }, { status: 429 });
  }
  
  // Validate with Zod
  // Use Prisma for database operations
  // Return JSON with proper status codes
}
```

### Authentication Pattern
```typescript
import { getCurrentUser } from "@/src/lib/auth";
import { redirect } from "next/navigation";

export default async function ProtectedPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/auth/login");
  // ... rest of page
}
```

### Component Pattern
- Use server components by default
- Use `"use client"` only when needed (forms, interactivity)
- Reuse UI components from `components/ui/`
- Follow Tailwind design tokens from `tailwind.config.ts`

## Testing

Run tests:
```bash
npm test              # Run once
npm run test:watch    # Watch mode
```

Current test coverage:
- `tests/smoke.test.ts` - Content loading sanity checks
- `tests/content.test.ts` - Blog post content validation

## Smoke Tests

After seeding and starting dev server:

```bash
# Test login API
curl -X POST http://localhost:3040/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin@example.com&password=Password123!"

# Test lead API
curl -X POST http://localhost:3040/api/lead \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test User","company":"Test Corp"}'
```

## Important Notes

### Security
- Rate limiting is in-memory (resets on server restart, not suitable for serverless)
- `AUTH_SESSION_SECRET` is required but not currently used for HMAC/encryption
- All API inputs are validated with Zod
- Passwords hashed with bcrypt (12 rounds)
- Sessions use HTTP-only, secure cookies

### Content Files
All markdown files referenced in `src/lib/docs.ts` now exist in `content/`:
- ✅ consulting-section-bpg.md
- ✅ consulting-standalone-bpg.md
- ✅ service-catalog.md
- ✅ linkedin-positioning-strategy.md
- ✅ cold-email-script.md
- ✅ sales-funnel.md

## Quick Reference

- **Layout/Nav**: `app/layout.tsx`
- **Home Page**: `app/page.tsx`
- **Forms**: `components/readiness/`, `components/blueprint/`, `components/auth/`
- **Theme Config**: `tailwind.config.ts`
- **Database Schema**: `prisma/schema.prisma`
- **Environment**: `.env.example` → `.env`
