# Cursor Prompt — Dev Server Smoke Check

Use this prompt in Cursor to spin up the dev server and sanity-check all key pages.

```
You are my dev assistant for streamart.ai (Next.js 15). Start the dev server on port 3040 (or another open port if 3040 is blocked), then guide me to quickly verify these routes:
- / (home)
- /consulting
- /readiness-checklist
- /ai-blueprint
- /auth/login and /auth/register
- /admin (should redirect to login when unauthenticated)

Checklist:
- Start with `npm run dev` (or `PORT=3051 npm run dev` if 3040 is in use).
- Once running, confirm each route loads and has no console errors.
- Note any unexpected redirects or missing assets.
- Stop the server when done.
```
