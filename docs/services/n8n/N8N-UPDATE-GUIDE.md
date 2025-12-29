# n8n Update Guide
**Date:** December 28, 2025  
**Current Version:** 1.123.5  
**Latest Version:** 2.1.4

---

## ⚠️ Important Notice

You are currently running **n8n version 1.123.5**, and the latest version is **2.1.4**. This is a **major version jump** (1.x → 2.x), which may include:

- Breaking changes
- Database schema migrations
- Configuration changes
- API changes

**Recommendation:** Review n8n release notes before updating, especially:
- [n8n 2.0 Release Notes](https://docs.n8n.io/releases/)
- Breaking changes documentation

---

## 📋 Pre-Update Checklist

Before updating n8n:

- [ ] **Backup your workflows** (export from n8n UI)
- [ ] **Backup the database** (if using PostgreSQL)
- [ ] **Backup n8n data volume** (`n8n_data`)
- [ ] **Review release notes** for breaking changes
- [ ] **Test in staging** (if possible)
- [ ] **Check for active workflows** that might be affected

---

## 🔄 Update Methods

### Method 1: Update to Latest Version (Recommended for Testing)

This updates to the latest version (`latest` tag):

```bash
cd /home/comzis/inlock

# 1. Backup current setup
docker exec services-n8n-1 n8n export:workflow --all --output=/tmp/n8n-backup.json || echo "Backup failed, continue anyway"

# 2. Pull latest image
docker pull n8nio/n8n:latest

# 3. Update compose file
sed -i 's|image: n8nio/n8n:1.123.5|image: n8nio/n8n:latest|g' compose/services/n8n.yml

# 4. Stop current container
docker compose -f compose/services/stack.yml stop n8n

# 5. Start with new image
docker compose -f compose/services/stack.yml up -d n8n

# 6. Verify
docker logs services-n8n-1 --tail 50
docker ps --filter "name=n8n"
```

### Method 2: Update to Specific Version

Update to a specific version (e.g., `2.1.4`):

```bash
cd /home/comzis/inlock

# 1. Backup (same as above)
docker exec services-n8n-1 n8n export:workflow --all --output=/tmp/n8n-backup.json || echo "Backup failed"

# 2. Pull specific version
docker pull n8nio/n8n:2.1.4

# 3. Update compose file
sed -i 's|image: n8nio/n8n:1.123.5|image: n8nio/n8n:2.1.4|g' compose/services/n8n.yml

# 4. Restart service
docker compose -f compose/services/stack.yml up -d n8n

# 5. Verify
docker logs services-n8n-1 --tail 50
```

### Method 3: Gradual Update (Recommended for Production)

Update incrementally to avoid major jumps:

```bash
# Step 1: Update to latest 1.x version first
# Check available 1.x versions
docker pull n8nio/n8n:1.123.5  # Current
# Then try: 1.124.0, 1.125.0, etc. (check what's available)

# Step 2: After verifying 1.x works, update to 2.0.0
docker pull n8nio/n8n:2.0.0
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:2.0.0|g' compose/services/n8n.yml
docker compose -f compose/services/stack.yml up -d n8n

# Step 3: Then update to latest 2.x
docker pull n8nio/n8n:latest
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:latest|g' compose/services/n8n.yml
docker compose -f compose/services/stack.yml up -d n8n
```

---

## 📝 Step-by-Step Update Process

### Step 1: Backup Everything

```bash
# Backup workflows (export from UI or use CLI)
# Option A: Manual export from n8n UI
# - Go to https://n8n.inlock.ai
# - Settings → Export Data → Export All Workflows

# Option B: Backup database
docker exec services-inlock-db-1 pg_dump -U n8n n8n > /tmp/n8n-db-backup-$(date +%Y%m%d).sql

# Option C: Backup volume (if needed)
docker run --rm -v inlock_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-data-backup-$(date +%Y%m%d).tar.gz /data
```

### Step 2: Check Current Status

```bash
# Check current version
docker exec services-n8n-1 n8n --version

# Check container status
docker ps --filter "name=n8n"

# Check logs for any issues
docker logs services-n8n-1 --tail 50
```

### Step 3: Pull New Image

```bash
# Pull latest version
docker pull n8nio/n8n:latest

# Or pull specific version
docker pull n8nio/n8n:2.1.4

# Verify image was pulled
docker images | grep n8n
```

### Step 4: Update Compose File

```bash
cd /home/comzis/inlock

# Edit the compose file
nano compose/services/n8n.yml

# Change line 3 from:
#   image: n8nio/n8n:1.123.5
# To:
#   image: n8nio/n8n:latest
# Or:
#   image: n8nio/n8n:2.1.4
```

**Or use sed (automated):**
```bash
# Update to latest
sed -i 's|image: n8nio/n8n:1.123.5|image: n8nio/n8n:latest|g' compose/services/n8n.yml

# Verify the change
grep "image:" compose/services/n8n.yml
```

### Step 5: Restart Service

```bash
# Stop current container
docker compose -f compose/services/stack.yml stop n8n

# Start with new image
docker compose -f compose/services/stack.yml up -d n8n

# Or use restart (pulls new image if changed)
docker compose -f compose/services/stack.yml up -d --pull always n8n
```

### Step 6: Verify Update

```bash
# Check container is running
docker ps --filter "name=n8n"

# Check new version
docker exec services-n8n-1 n8n --version

# Check logs for errors
docker logs services-n8n-1 --tail 100

# Check health
docker exec services-n8n-1 wget -qO- http://127.0.0.1:5678/healthz

# Test web interface
curl -I https://n8n.inlock.ai
```

### Step 7: Verify Workflows

1. **Access n8n UI:** https://n8n.inlock.ai
2. **Check workflows:** Verify all workflows are present
3. **Test workflows:** Run a test workflow to ensure functionality
4. **Check credentials:** Verify credentials are still working
5. **Check executions:** Review recent executions for errors

---

## 🔧 Troubleshooting

### Issue: Container Won't Start

**Symptoms:**
- Container exits immediately
- Health check fails
- Database connection errors

**Solutions:**
```bash
# Check logs
docker logs services-n8n-1 --tail 100

# Check database connection
docker exec services-inlock-db-1 psql -U n8n -d n8n -c "SELECT 1;"

# Verify secrets
docker compose -f compose/services/stack.yml config | grep -A 5 n8n

# Try rolling back
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:1.123.5|g' compose/services/n8n.yml
docker compose -f compose/services/stack.yml up -d n8n
```

### Issue: Database Migration Errors

**Symptoms:**
- Migration errors in logs
- Database schema mismatch

**Solutions:**
```bash
# Check n8n logs for migration errors
docker logs services-n8n-1 | grep -i migration

# Backup database before migration
docker exec services-inlock-db-1 pg_dump -U n8n n8n > /tmp/n8n-pre-migration.sql

# n8n should auto-migrate, but if it fails:
# 1. Roll back to previous version
# 2. Check n8n documentation for manual migration steps
```

### Issue: Workflows Not Working

**Symptoms:**
- Workflows missing
- Execution errors
- Node errors

**Solutions:**
```bash
# Check workflow data
docker exec services-n8n-1 ls -la /home/node/.n8n

# Check logs for workflow errors
docker logs services-n8n-1 | grep -i workflow

# Restore from backup if needed
# Import workflows from backup file via n8n UI
```

### Issue: Version Mismatch

**Symptoms:**
- UI shows different version than expected
- Features not available

**Solutions:**
```bash
# Verify image version
docker images | grep n8n

# Verify container is using correct image
docker inspect services-n8n-1 | grep Image

# Force recreate
docker compose -f compose/services/stack.yml up -d --force-recreate n8n
```

---

## 🔙 Rollback Procedure

If the update causes issues, rollback to previous version:

```bash
cd /home/comzis/inlock

# 1. Stop current container
docker compose -f compose/services/stack.yml stop n8n

# 2. Update compose file to previous version
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:1.123.5|g' compose/services/n8n.yml

# 3. Start with previous version
docker compose -f compose/services/stack.yml up -d n8n

# 4. Verify rollback
docker exec services-n8n-1 n8n --version
docker logs services-n8n-1 --tail 50
```

---

## 📊 Version Information

### Current Setup
- **Version:** 1.123.5
- **Image:** `n8nio/n8n:1.123.5`
- **Container:** `services-n8n-1`
- **Status:** Running (healthy)

### Available Versions
- **Latest:** 2.1.4 (or `latest` tag)
- **Current:** 1.123.5
- **Previous:** 1.64.2 (old image still on system)

### Version Tags
- `latest` - Latest stable release
- `2.1.4` - Specific version (latest 2.x)
- `1.123.5` - Current version
- `2.0.0` - First 2.x release (if doing gradual update)

---

## ✅ Post-Update Checklist

After updating:

- [ ] Container is running and healthy
- [ ] Version matches expected version
- [ ] Web UI is accessible
- [ ] All workflows are present
- [ ] Test workflows execute successfully
- [ ] Credentials are working
- [ ] No errors in logs
- [ ] Database migrations completed (if any)
- [ ] Performance is acceptable

---

## 🔗 Useful Resources

- **n8n Releases:** https://docs.n8n.io/releases/
- **n8n Docker Hub:** https://hub.docker.com/r/n8nio/n8n
- **n8n Documentation:** https://docs.n8n.io/
- **Breaking Changes:** Check release notes for version 2.0.0+

---

## 📝 Quick Reference Commands

```bash
# Check current version
docker exec services-n8n-1 n8n --version

# View logs
docker logs services-n8n-1 --tail 50 -f

# Restart service
docker compose -f compose/services/stack.yml restart n8n

# Update to latest
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:latest|g' compose/services/n8n.yml
docker compose -f compose/services/stack.yml up -d n8n

# Rollback
sed -i 's|image: n8nio/n8n:.*|image: n8nio/n8n:1.123.5|g' compose/services/n8n.yml
docker compose -f compose/services/stack.yml up -d n8n
```

---

**Last Updated:** December 28, 2025  
**Configuration File:** `compose/services/n8n.yml`  
**Current Version:** 1.123.5  
**Recommended:** Review 2.x release notes before updating



