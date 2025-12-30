# Blog Content Management Guide
**Date:** December 28, 2025  
**Purpose:** Step-by-step guide for updating and managing blog posts on inlock.ai

---

## 📍 Blog Content Structure

### Where Blog Content Lives

**Content Files:** `/opt/inlock-ai-secure-mvp/content/*.md`
- Actual blog post markdown files
- Each blog post is a separate `.md` file

**Metadata:** `/opt/inlock-ai-secure-mvp/src/lib/blog.ts`
- Defines blog post metadata (title, date, excerpt, etc.)
- Links markdown files to the blog system

**Current Blog Posts:**
- `local-vs-cloud-ai.md`
- `on-premise-llm-deployment.md`
- `rag-implementation-best-practices.md`
- `ai-security-compliance-checklist.md`
- `cost-comparison-local-vs-cloud-ai.md`
- `building-private-ai-assistants.md`
- And more...

---

## ✏️ How to Edit an Existing Blog Post

### Step 1: Navigate to Content Directory

```bash
cd /opt/inlock-ai-secure-mvp/content
```

### Step 2: List Available Blog Posts

```bash
ls -la *.md
```

### Step 3: Edit the Blog Post

```bash
# Edit using nano (or your preferred editor)
nano rag-implementation-best-practices.md

# Or using vim
vim rag-implementation-best-practices.md
```

**Blog Post Format:**
- Standard Markdown format
- First line is usually the title as `# Title`
- Followed by excerpt/description
- Then the main content with markdown formatting

**Example Structure:**
```markdown
# Blog Post Title

Brief excerpt or introduction paragraph.

## Section 1

Content here...

## Section 2

More content...
```

### Step 4: Update Metadata (If Needed)

If you changed the title or want to update metadata, edit the blog metadata file:

```bash
cd /opt/inlock-ai-secure-mvp
nano src/lib/blog.ts
```

Find the entry for your blog post and update:
- `title` - Blog post title
- `excerpt` - Short description
- `readTime` - Estimated reading time
- `date` - Publication date
- `pillars` - Array of pillar tags
- `productAngle` - Product positioning text

**Example Entry:**
```typescript
{
  slug: "rag-implementation-best-practices",
  title: "RAG Implementation Best Practices for Enterprise",
  date: "2025-01-20",
  readTime: "15 min read",
  excerpt: "Learn how to build production-ready RAG systems...",
  file: "rag-implementation-best-practices.md",
  pillars: ["Knowledge & data layer", "RAG quality", "Provenance"],
  productAngle: "Aligns with unified indexing..."
}
```

### Step 5: Rebuild and Deploy

```bash
# Build the new Docker image
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .

# Deploy to production
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Step 6: Verify Changes

```bash
# Check container is running
docker ps --filter "name=inlock-ai"

# View logs for any errors
docker logs services-inlock-ai-1 --tail 50

# Test the website
curl -I https://inlock.ai/blog
```

---

## ➕ How to Add a New Blog Post

### Step 1: Create the Markdown File

```bash
cd /opt/inlock-ai-secure-mvp/content

# Create a new blog post file
nano my-new-blog-post.md
```

**File Naming Convention:**
- Use lowercase
- Use hyphens for spaces
- Example: `my-new-blog-post.md`

**Content Template:**
```markdown
# Your Blog Post Title

A compelling excerpt that summarizes the blog post and entices readers to continue reading.

## Introduction

Start with an engaging introduction that hooks the reader.

## Main Section 1

Your content here...

### Subsection

More detailed content...

## Main Section 2

Additional content...

## Conclusion

Wrap up with key takeaways and next steps.
```

### Step 2: Add Metadata Entry

```bash
cd /opt/inlock-ai-secure-mvp
nano src/lib/blog.ts
```

Add a new entry to the `blogPosts` array:

```typescript
{
  slug: "my-new-blog-post",                    // URL-friendly identifier
  title: "My New Blog Post Title",             // Display title
  date: "2025-12-28",                          // Publication date (YYYY-MM-DD)
  readTime: "8 min read",                      // Estimated reading time
  excerpt: "A brief description of the blog post...",  // Short summary
  file: "my-new-blog-post.md",                // Filename in content/
  pillars: ["Deployment flexibility", "Security"],     // Array of pillar tags
  productAngle: "How this relates to Inlock products..."  // Product positioning
}
```

**Important Fields:**
- `slug`: Must match the URL path (e.g., `my-new-blog-post` → `/blog/my-new-blog-post`)
- `file`: Must match the actual filename in `content/`
- `date`: Use format `YYYY-MM-DD`
- `readTime`: Estimate based on word count (average 200-250 words per minute)

### Step 3: Rebuild and Deploy

```bash
# Build the new Docker image
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .

# Deploy to production
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Step 4: Verify New Blog Post

```bash
# Check the blog listing page
curl -I https://inlock.ai/blog

# Check the specific blog post
curl -I https://inlock.ai/blog/my-new-blog-post
```

---

## 🗑️ How to Delete a Blog Post

### Step 1: Remove from Metadata

```bash
cd /opt/inlock-ai-secure-mvp
nano src/lib/blog.ts
```

Remove the entry from the `blogPosts` array.

### Step 2: Delete the Markdown File (Optional)

```bash
cd /opt/inlock-ai-secure-mvp/content
rm old-blog-post.md
```

**Note:** You can keep the file for backup, but it won't appear on the website if removed from `blog.ts`.

### Step 3: Rebuild and Deploy

```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

---

## 🔄 Complete Workflow Example

### Example: Updating an Existing Blog Post

```bash
# 1. Navigate to content directory
cd /opt/inlock-ai-secure-mvp/content

# 2. Edit the blog post
nano rag-implementation-best-practices.md

# 3. Make your changes, save and exit

# 4. (Optional) Update metadata if title/excerpt changed
cd /opt/inlock-ai-secure-mvp
nano src/lib/blog.ts

# 5. Build new image
docker build -t inlock-ai:latest .

# 6. Deploy
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai

# 7. Verify
docker logs services-inlock-ai-1 --tail 20
curl -I https://inlock.ai/blog/rag-implementation-best-practices
```

### Example: Adding a New Blog Post

```bash
# 1. Create new markdown file
cd /opt/inlock-ai-secure-mvp/content
nano enterprise-ai-security-guide.md

# 2. Write your content (see template above)

# 3. Add metadata entry
cd /opt/inlock-ai-secure-mvp
nano src/lib/blog.ts
# Add new entry to blogPosts array

# 4. Build and deploy
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai

# 5. Verify
curl -I https://inlock.ai/blog/enterprise-ai-security-guide
```

---

## 📝 Blog Post Best Practices

### Content Guidelines

1. **Title:** Clear, descriptive, SEO-friendly
2. **Excerpt:** 1-2 sentences that summarize the post
3. **Structure:** Use clear headings (##, ###)
4. **Length:** Aim for 1000-3000 words for comprehensive posts
5. **Formatting:** Use markdown properly (bold, lists, code blocks)

### Metadata Guidelines

1. **Slug:** 
   - URL-friendly (lowercase, hyphens)
   - Descriptive but concise
   - Example: `local-vs-cloud-ai` not `local_vs_cloud_ai`

2. **Date:**
   - Use `YYYY-MM-DD` format
   - Use publication date, not edit date

3. **Read Time:**
   - Estimate: ~200-250 words per minute
   - Round to nearest minute
   - Format: `"X min read"`

4. **Pillars:**
   - Use existing pillar categories when possible
   - Common pillars: "Deployment flexibility", "Security baseline", "Knowledge & data layer", "RAG quality", "Governance & RBAC"

5. **Product Angle:**
   - How the blog post relates to Inlock products
   - Keep it concise (1-2 sentences)

---

## 🛠️ Quick Reference Commands

### View All Blog Posts

```bash
cd /opt/inlock-ai-secure-mvp/content
ls -la *.md
```

### View Blog Metadata

```bash
cd /opt/inlock-ai-secure-mvp
cat src/lib/blog.ts | grep -A 10 "slug:"
```

### Edit a Blog Post

```bash
cd /opt/inlock-ai-secure-mvp/content
nano blog-post-name.md
```

### Rebuild and Deploy

```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d inlock-ai
```

### Check Blog Post Online

```bash
# List all blog posts
curl -s https://inlock.ai/blog | grep -o '/blog/[^"]*' | head -10

# Check specific post
curl -I https://inlock.ai/blog/your-slug-here
```

---

## 🔍 Troubleshooting

### Blog Post Not Appearing

**Check:**
1. Is the file in `content/` directory?
2. Is the entry in `src/lib/blog.ts`?
3. Does the `file` field match the actual filename?
4. Did you rebuild and redeploy?

```bash
# Verify file exists
ls -la /opt/inlock-ai-secure-mvp/content/your-post.md

# Verify metadata entry
grep -A 5 "your-slug" /opt/inlock-ai-secure-mvp/src/lib/blog.ts

# Check container logs
docker logs services-inlock-ai-1 --tail 50 | grep -i error
```

### Build Errors

**Common Issues:**
- Syntax errors in `blog.ts` (missing commas, brackets)
- File not found (check filename matches)
- TypeScript errors

```bash
# Check for syntax errors
cd /opt/inlock-ai-secure-mvp
npm run lint

# Try building locally
npm run build
```

### Content Not Updating

**Solution:**
- Ensure you rebuilt the Docker image
- Clear browser cache
- Check container is using latest image

```bash
# Verify image was rebuilt
docker images | grep inlock-ai

# Force recreate container
cd /home/comzis/inlock
docker compose -f compose/services/stack.yml up -d --force-recreate inlock-ai
```

---

## 📚 Related Documentation

- **Webpage Management:** `docs/services/inlock-ai/WEBPAGE-MANAGEMENT-GUIDE.md`
- **Deployment:** `scripts/deployment/deploy-inlock.sh`
- **Verification:** `scripts/verify-inlock-deployment.sh`

---

## ✅ Quick Checklist

When editing a blog post:

- [ ] Edited the markdown file in `content/`
- [ ] Updated metadata in `src/lib/blog.ts` (if needed)
- [ ] Built new Docker image: `docker build -t inlock-ai:latest .`
- [ ] Deployed: `docker compose up -d inlock-ai`
- [ ] Verified: Checked https://inlock.ai/blog
- [ ] Tested: Viewed the blog post in browser

---

**Last Updated:** December 28, 2025  
**Location:** `/opt/inlock-ai-secure-mvp/content/` and `src/lib/blog.ts`





