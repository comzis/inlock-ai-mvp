# Troubleshooting Guide - n8n Workflows & Blog Content

**Date:** December 14, 2025

## Issue 1: n8n Workflow Stuck at Executing

### Quick Check

Run the diagnostic script:
```bash
cd /home/comzis/inlock
./scripts/check-n8n-workflow-logs.sh
```

### Manual Checks

1. **Check n8n UI:**
   - Visit: https://n8n.inlock.ai
   - Go to: **Executions** (left sidebar)
   - Look for workflows with status:
     - **Running** (stuck)
     - **Error** (failed)
   - Click on the execution to see details

2. **Check n8n Logs:**
```bash
# Recent logs (last 50 lines)
docker logs compose-n8n-1 --tail 50

# Look for execution errors
docker logs compose-n8n-1 --tail 200 | grep -iE "(error|exception|failed|stuck|timeout|execution)"

# Check database connection
docker logs compose-n8n-1 --tail 100 | grep -iE "(database|postgres|db.*connect)"
```

3. **Check PostgreSQL:**
```bash
# Check if database is running
docker ps | grep postgres

# Check database logs
docker logs compose-postgres-1 --tail 20
```

### Common Causes

1. **Database Connection Issues**
   - PostgreSQL not running
   - Wrong credentials
   - Network connectivity problems

2. **Workflow Node Errors**
   - API endpoint unreachable
   - Authentication failures
   - Timeout errors
   - Invalid node configuration

3. **Resource Constraints**
   - Memory limits
   - CPU limits
   - Container restarting

### Solutions

**If workflow is stuck:**
1. Go to n8n UI → Executions
2. Find the stuck execution
3. Click **Stop** button
4. Check the execution details for error messages
5. Fix the issue and re-run

**If n8n is not responding:**
```bash
# Restart n8n
cd /home/comzis/inlock
docker compose -f compose/n8n.yml --env-file .env restart n8n

# Wait 30 seconds, then check again
docker logs compose-n8n-1 --tail 20
```

**If database connection fails:**
```bash
# Restart PostgreSQL
docker compose -f compose/postgres.yml --env-file .env restart postgres

# Wait 10 seconds, then restart n8n
docker compose -f compose/n8n.yml --env-file .env restart n8n
```

---

## Issue 2: Blog Content Lost

### Quick Check

Run the diagnostic script:
```bash
cd /home/comzis/inlock
./scripts/check-blog-content.sh
```

### Manual Checks

1. **Check Content Files:**
```bash
# List blog markdown files
ls -la /opt/inlock-ai-secure-mvp/content/*.md

# Check blog metadata
cat /opt/inlock-ai-secure-mvp/src/lib/blog.ts | grep -A 5 "slug:"
```

2. **Check Database:**
```bash
# Connect to database
docker exec -it compose-inlock-db-1 psql -U inlock -d inlock

# Check if posts table exists
\dt

# Count blog posts
SELECT COUNT(*) FROM posts;

# List recent posts
SELECT title, created_at FROM posts ORDER BY created_at DESC LIMIT 10;
```

3. **Check Inlock AI Container:**
```bash
# Check if container is running
docker ps | grep inlock-ai

# Check logs for errors
docker logs compose-inlock-ai-1 --tail 50 | grep -iE "(error|blog|content|database)"
```

4. **Test Blog Endpoint:**
```bash
# Test blog page
curl -k -I https://inlock.ai/blog

# Should return HTTP 200
```

### Common Causes

1. **Content Files Missing**
   - Files deleted from `/opt/inlock-ai-secure-mvp/content/`
   - Files not committed to git
   - Wrong file paths

2. **Database Issues**
   - Database reset/migration
   - Data not migrated
   - Connection issues

3. **Application Not Loading Content**
   - Build issues
   - Configuration errors
   - File path mismatches

### Solutions

**If content files are missing:**
```bash
# Check git history for deleted files
cd /opt/inlock-ai-secure-mvp
git log --all --full-history -- content/
git log --all --full-history -- src/lib/blog.ts

# Restore from git if needed
git checkout HEAD -- content/
git checkout HEAD -- src/lib/blog.ts
```

**If database is empty:**
```bash
# Check if there are backups
ls -la /data/backups/  # if backup directory exists

# Check database volume
docker volume inspect compose_inlock_db_data

# Check if database was reset
docker logs compose-inlock-db-1 | grep -iE "(init|reset|migration)"
```

**If application not loading:**
```bash
# Rebuild and restart
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .

cd /home/comzis/inlock
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai

# Check logs
docker logs compose-inlock-ai-1 --tail 50
```

**If blog metadata is missing:**
```bash
# Check blog.ts file
cat /opt/inlock-ai-secure-mvp/src/lib/blog.ts

# Should contain blogPosts array with entries like:
# {
#   slug: "post-slug",
#   title: "Post Title",
#   date: "2025-12-14",
#   file: "content/post-slug.md"
# }
```

---

## Quick Commands Reference

### n8n Workflow Issues
```bash
# Check n8n status
docker ps | grep n8n

# View n8n logs
docker logs compose-n8n-1 --tail 50

# Restart n8n
docker compose -f compose/n8n.yml --env-file .env restart n8n

# Check workflow executions (via UI)
# Visit: https://n8n.inlock.ai → Executions
```

### Blog Content Issues
```bash
# Check content files
ls -la /opt/inlock-ai-secure-mvp/content/

# Check blog metadata
cat /opt/inlock-ai-secure-mvp/src/lib/blog.ts

# Check database
docker exec -it compose-inlock-db-1 psql -U inlock -d inlock -c "SELECT COUNT(*) FROM posts;"

# Rebuild application
cd /opt/inlock-ai-secure-mvp && docker build -t inlock-ai:latest .
cd /home/comzis/inlock && docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

---

**Last Updated:** December 14, 2025





