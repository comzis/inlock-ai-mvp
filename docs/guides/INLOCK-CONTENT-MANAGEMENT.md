# Inlock Content Management Guide

This guide explains how to manage and update content on the Inlock platform after the StreamArt → Inlock rebrand.

## Content Structure

### Page Routes (React Components)

Every route in `/opt/inlock-ai-secure-mvp/app` maps one-to-one with a page:

| Route | File | Purpose |
|-------|------|---------|
| `/` | `app/page.tsx` | Homepage hero and features |
| `/consulting` | `app/consulting/page.tsx` | Consulting services page |
| `/readiness-checklist` | `app/readiness-checklist/page.tsx` | AI readiness assessment |
| `/blog` | `app/blog/page.tsx` | Blog listing page |
| `/blog/[slug]` | `app/blog/[slug]/page.tsx` | Individual blog post |
| `/workspace/[id]` | `app/workspace/[id]/layout.tsx` | Workspace interface |
| `/chat` | `app/chat/page.tsx` | Chat interface |

**To update page content:**
1. Edit the corresponding `.tsx` file
2. Test locally: `npm run dev` (runs on http://localhost:3040)
3. Build and deploy: `npm run build && docker build -t inlock-ai:latest .`

### Global Layout & Branding

**File:** `app/layout.tsx`

Controls:
- Page metadata (title, description)
- Navigation bar brand name
- Footer text
- Global header/footer structure

**Key sections:**
- Line 9-12: Metadata (SEO)
- Line 29-30: Navigation brand name
- Line 77-78: Footer copyright

### Centralized Content Sources

#### 1. Blog Posts

**Metadata:** `src/lib/blog.ts` (lines 12-63)
- Defines blog post metadata (title, date, excerpt, etc.)
- References markdown files in `content/` directory

**Content:** `content/*.md`
- Actual blog post markdown files
- Stored in `content/` directory

**To add a blog post:**
1. Create a new `.md` file in `content/`
2. Add entry to `blogPosts` array in `src/lib/blog.ts`
3. Include: `slug`, `title`, `date`, `excerpt`, `readTime`, `pillars`, `productAngle`

#### 2. Documents

**Metadata:** `src/lib/docs.ts` (lines 7-42)
- Defines downloadable documents and strategy decks
- Maps to markdown files in `content/`

**Content:** `content/*.md`
- Shared markdown files used by both blog and docs

#### 3. Static Assets

**Public files:** `public/website/`
- Standalone HTML embeds
- Static marketing snippets
- Example: `consulting-website.html`

### Styling & Branding

#### Brand Colors & Theme

**File:** `app/globals.css`
- Defines CSS variables for colors
- Theme tokens (primary, accent, background, etc.)

**File:** `tailwind.config.ts`
- Tailwind configuration
- Extends default theme with custom colors

**To change brand colors:**
1. Update CSS variables in `globals.css`
2. Update Tailwind config if needed
3. Rebuild: `npm run build`

### Form Components

**Location:** `components/auth/`, `components/contact-form.tsx`

Forms that display brand text:
- `register-form.tsx` - Newsletter subscription text
- `contact-form.tsx` - Contact form

### Internal Workspace Text

**Files:**
- `app/workspace/[id]/layout.tsx` - Workspace header version info
- `app/workspace/[id]/query/chat-interface.tsx` - Chat welcome message

## Rebranding Status

✅ **Completed:**
- `app/layout.tsx` - Metadata, navigation, footer
- `app/page.tsx` - Homepage hero
- `app/consulting/page.tsx` - Consulting page
- `app/blog/page.tsx` - Blog masthead
- `app/blog/[slug]/page.tsx` - Blog post badges
- `app/workspace/[id]/layout.tsx` - Version info
- `app/workspace/[id]/query/chat-interface.tsx` - Welcome message
- `components/auth/register-form.tsx` - Newsletter text
- `components/blog/security-checklist.tsx` - Checklist header
- `package.json` - Package name
- `public/website/consulting-website.html` - HTML embed

⚠️ **May need updates:**
- `content/*.md` files - May contain "StreamArt" references
- `src/lib/blog.ts` - Blog post metadata (if any references exist)
- `src/lib/docs.ts` - Document metadata (if any references exist)

## Content Update Workflow

### 1. Local Development

```bash
cd /opt/inlock-ai-secure-mvp

# Install dependencies
npm install

# Run development server
npm run dev
# Visit: http://localhost:3040
```

### 2. Quality Checks

Before deploying, run:

```bash
# Linting
npm run lint

# Tests
npm run test

# Build verification
npm run build
```

### 3. Deploy Changes

```bash
# Build Docker image
docker build -t inlock-ai:latest .

# Deploy to production
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai

# Verify
docker logs compose-inlock-ai-1 --tail 50
curl -I https://inlock.ai
```

## Common Content Updates

### Update Homepage Hero

**File:** `app/page.tsx` (lines 9-28)
- Change headline text
- Update description paragraph
- Modify CTA buttons

### Add/Edit Blog Post

1. **Create markdown file:** `content/new-post.md`
2. **Add metadata:** Edit `src/lib/blog.ts`:
   ```typescript
   {
     slug: "new-post",
     title: "New Post Title",
     date: "2025-12-09",
     excerpt: "Post excerpt...",
     readTime: "5 min read",
     pillars: ["Security", "RAG"],
     productAngle: "How Inlock addresses...",
     file: "content/new-post.md"
   }
   ```

### Update Consulting Services

**File:** `app/consulting/page.tsx`
- Hero section (lines 9-27)
- Services grid (lines 34-177)
- Contact form section (lines 181-191)

### Change Navigation Menu

**File:** `app/layout.tsx` (lines 32-70)
- Add/remove navigation links
- Modify link text or URLs

## Search for Remaining References

To find any remaining "StreamArt" references:

```bash
cd /opt/inlock-ai-secure-mvp
grep -r "streamart\|StreamArt" --include="*.tsx" --include="*.ts" --include="*.md" --include="*.json" . | grep -v node_modules
```

## Content File Locations Summary

```
/opt/inlock-ai-secure-mvp/
├── app/                          # Page routes (React components)
│   ├── layout.tsx               # Global layout, nav, footer
│   ├── page.tsx                 # Homepage
│   ├── consulting/page.tsx      # Consulting page
│   ├── blog/page.tsx            # Blog listing
│   └── workspace/[id]/          # Workspace pages
├── components/                   # Reusable components
│   ├── auth/                    # Authentication forms
│   └── blog/                    # Blog-specific components
├── content/                      # Markdown content files
│   └── *.md                     # Blog posts and documents
├── src/lib/
│   ├── blog.ts                  # Blog metadata registry
│   └── docs.ts                  # Document metadata registry
├── public/website/               # Static HTML files
└── app/globals.css              # Global styles & brand colors
```

## Best Practices

1. **Always test locally first** - Use `npm run dev` before deploying
2. **Run quality checks** - Lint and test before building
3. **Keep branding consistent** - Use "Inlock" consistently (not "inlock" or "INLOCK")
4. **Update metadata** - When adding content, update relevant registry files
5. **Rebuild after changes** - Always rebuild Docker image after content changes

## Quick Reference

| Task | Command |
|------|---------|
| Start dev server | `npm run dev` |
| Run linting | `npm run lint` |
| Run tests | `npm run test` |
| Build locally | `npm run build` |
| Build Docker image | `docker build -t inlock-ai:latest .` |
| Deploy to production | `cd /home/comzis/inlock-infra && docker compose -f compose/stack.yml --env-file .env up -d inlock-ai` |
| View logs | `docker logs compose-inlock-ai-1 -f` |
| Test production | `curl -I https://inlock.ai` |

---

**Last Updated:** 2025-12-09  
**Status:** Rebranding completed, content management active

