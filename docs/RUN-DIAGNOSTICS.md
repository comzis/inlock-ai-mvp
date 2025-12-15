# Running Diagnostics - Quick Guide

**Date:** December 14, 2025

## Option 1: Run Remotely from MacBook (Easiest)

If you have SSH access to the server, run:

```bash
cd /Users/comzis/GitHub/inlock-ai-mvp
./scripts/run-diagnostics-remote.sh
```

This will:
- Connect to the server via SSH
- Copy the diagnostic scripts if needed
- Run both diagnostics
- Display the results

## Option 2: SSH to Server and Run Manually

### Step 1: SSH to Server

```bash
ssh comzis@100.83.222.69
```

### Step 2: Navigate to Directory

```bash
cd /home/comzis/inlock
```

### Step 3: Run n8n Diagnostics

```bash
./scripts/check-n8n-workflow-logs.sh
```

This checks:
- n8n container status
- Recent logs for errors
- Database connectivity
- Workflow execution issues

### Step 4: Run Blog Content Diagnostics

```bash
./scripts/check-blog-content.sh
```

This checks:
- Inlock AI container status
- Content files existence
- Database blog posts
- Blog endpoint accessibility

## Option 3: Quick Manual Checks

### Check n8n Workflows

```bash
# SSH to server
ssh comzis@100.83.222.69

# Check n8n logs
docker logs compose-n8n-1 --tail 50

# Check for stuck workflows
docker logs compose-n8n-1 --tail 200 | grep -iE "(error|exception|failed|stuck|timeout|execution)"
```

**Or check via UI:**
1. Visit: https://n8n.inlock.ai
2. Go to: **Executions** (left sidebar)
3. Look for workflows with status "Running" or "Error"

### Check Blog Content

```bash
# SSH to server
ssh comzis@100.83.222.69

# Check content files
ls -la /opt/inlock-ai-secure-mvp/content/*.md

# Check blog metadata
cat /opt/inlock-ai-secure-mvp/src/lib/blog.ts

# Check database
docker exec -it compose-inlock-db-1 psql -U inlock -d inlock -c "SELECT COUNT(*) FROM posts;"
```

## What to Look For

### n8n Workflow Issues

**Common signs:**
- Workflows stuck in "Running" status
- Error messages in logs
- Database connection failures
- API timeout errors

**Quick fixes:**
- Stop stuck execution in n8n UI
- Restart n8n: `docker compose -f compose/n8n.yml --env-file .env restart n8n`
- Check database: `docker logs compose-postgres-1 --tail 20`

### Blog Content Issues

**Common signs:**
- No `.md` files in `/opt/inlock-ai-secure-mvp/content/`
- Empty `blogPosts` array in `src/lib/blog.ts`
- Database has 0 posts
- Blog page returns 404 or empty

**Quick fixes:**
- Restore from git: `git checkout HEAD -- content/`
- Rebuild application: `cd /opt/inlock-ai-secure-mvp && docker build -t inlock-ai:latest .`
- Restart service: `docker compose -f compose/stack.yml --env-file .env up -d inlock-ai`

## Sharing Results

After running diagnostics, share:

1. **n8n workflow output** - Especially any errors
2. **Blog content output** - File counts and database status
3. **Specific error messages** - From logs or UI

This will help identify the exact issues and provide targeted fixes.

---

**Last Updated:** December 14, 2025





