# Docker Cleanup Analysis - Production Environment

**Date:** 2026-01-08  
**Status:** ⚠️ PRODUCTION ENVIRONMENT - Proceed with Extreme Caution

## ⚠️ CRITICAL WARNING

**This is a PRODUCTION environment.** Any cleanup must be carefully reviewed to avoid:
- Breaking running services
- Removing images needed for rollbacks
- Deleting parent/base images of running containers

## Current Production Status

### Running Containers (DO NOT AFFECT)

**Active Services:**
- ✅ `services-inlock-ai-1` - Production application
- ✅ `services-traefik-1` - Reverse proxy
- ✅ `services-n8n-1` - Workflow automation (⚠️ currently restarting)
- ✅ `services-prometheus-1` - Monitoring (⚠️ currently restarting)
- ✅ `services-inlock-db-1` - Database
- ✅ `services-grafana-1` - Dashboards
- ✅ `services-portainer-1` - Container management
- ✅ `services-coolify-*` - Deployment tools
- ✅ Mailcow services - Email server

**Total Running Containers:** 18+ containers

### Images Currently in Use (DO NOT REMOVE)

**Production Images:**
- `inlock-ai:latest` / `inlock-ai@sha256:152076b99ff9...` - **PRODUCTION APP**
- `traefik:v3.6.4` - **Reverse Proxy**
- `postgres@sha256:a5074487380d...` - **Database**
- `n8nio/n8n:1.123.5` - **Workflow** (running version)
- `grafana/grafana:latest` - **Monitoring**
- `portainer/portainer-ce:2.33.5` - **Management**
- All Mailcow images - **Email Server**
- All monitoring stack images

## Cleanup Analysis

### ✅ SAFE TO CLEAN (Low Risk)

#### 1. Build Cache (SAFE - Recommended)

**What it is:** Build cache from Docker builds  
**Risk:** LOW - Can be rebuilt if needed  
**Space Savings:** Varies (typically 1-5GB)  
**Command:**
```bash
# Preview what would be removed (DRY RUN)
docker builder prune --dry-run

# Clean build cache (SAFE)
docker builder prune -f
```

**Recommendation:** ✅ **SAFE TO EXECUTE**

#### 2. Dangling Images (Already Clean)

**Status:** ✅ **No dangling images found**  
**Action:** None needed

### ⚠️ CAUTION - Review Before Cleaning

#### 1. Unused Images (Potential Savings: ~10GB)

**Found Unused Images:**
- `n8nio/n8n:2.2.3` (1.75GB) - **CAUTION:** May be needed for rollback
- `n8nio/n8n:latest` (1.75GB) - **CAUTION:** Same as above
- `n8nio/n8n:<none>` (1.83GB) - **CAUTION:** Old version, may be parent image
- `compose-e2e:latest` (3.18GB) - **LOW RISK:** Test image, likely safe
- `tooling-strapi:latest` (973MB) - **LOW RISK:** Tooling, likely safe
- `posthog/posthog:<none>` (13GB) - **CAUTION:** Large image, check if needed
- `ghcr.io/coollabsio/coolify:<none>` (584MB) - **CAUTION:** May be parent image
- Various old pinned versions - **CAUTION:** May be needed for rollbacks

**Total Potential Savings:** ~22GB

**Risk Assessment:**
- ⚠️ **HIGH RISK:** Old n8n versions (may be needed for rollback)
- ⚠️ **MEDIUM RISK:** PostHog image (large, check if service exists)
- ✅ **LOW RISK:** Test/tooling images (compose-e2e, tooling-strapi)

**Recommendation:**
1. **DO NOT remove** n8n images (currently have restarting container)
2. **Review** posthog image - check if service is deployed
3. **Consider removing** test images only after confirming they're not needed

#### 2. Stopped Containers

**Action:** Review manually
```bash
docker ps -a --filter "status=exited"
```

**Recommendation:** Review each stopped container before removal

### ❌ DO NOT REMOVE

**Critical Images:**
- ✅ All images currently running
- ✅ All images with SHA256 digests (pinned versions)
- ✅ All images referenced in compose files
- ✅ Parent/base images of running containers
- ✅ Images used for rollback scenarios

## Current Issues to Address First

### ⚠️ Services Restarting

**Before any cleanup, address:**
1. **n8n-1** - Currently restarting (check logs)
2. **prometheus-1** - Currently restarting (check logs)

**Action Required:**
```bash
# Check logs
docker logs services-n8n-1 --tail 50
docker logs services-prometheus-1 --tail 50

# Verify configuration
docker compose -f compose/services/stack.yml ps n8n prometheus
```

**Recommendation:** Fix these issues before cleanup

## Recommended Cleanup Strategy (Conservative)

### Phase 1: Safe Cleanup (Execute Now)

1. **Clean Build Cache:**
   ```bash
   docker builder prune -f
   ```
   **Risk:** ✅ Low  
   **Savings:** 1-5GB estimated

### Phase 2: Review Before Cleaning (Manual Review)

2. **Review Unused Images:**
   ```bash
   # List unused images with details
   docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -v "REPOSITORY"
   ```

3. **Check PostHog Service:**
   ```bash
   # Check if posthog service exists
   docker ps -a | grep posthog
   docker compose -f compose/services/stack.yml config | grep posthog
   ```

4. **Remove Test Images (If Confirmed Safe):**
   ```bash
   # Only after confirming not needed
   docker rmi compose-e2e:latest
   docker rmi tooling-strapi:latest
   ```
   **Savings:** ~4GB

### Phase 3: After Service Stability (Future)

5. **Review Old Image Versions:**
   - Wait until services are stable
   - Ensure no rollback needed
   - Then review old n8n versions

## Cleanup Commands (Safe Only)

### ✅ Safe Commands

```bash
# 1. Clean build cache (SAFE)
docker builder prune -f

# 2. Preview what would be removed (DRY RUN)
docker image prune -a --dry-run

# 3. Check disk usage
docker system df -v

# 4. Check stopped containers
docker ps -a --filter "status=exited"
```

### ⚠️ Caution Commands (Review First)

```bash
# Remove specific unused image (review first!)
docker rmi <image_id>

# Remove all unused images (DANGEROUS - review first!)
docker image prune -a -f
```

## Space Usage Summary

**Total Docker Space:** 40.31GB  
**Reclaimable (conservative):** ~5-10GB (build cache + test images)  
**Reclaimable (aggressive):** ~30GB (includes unused images - **NOT RECOMMENDED**)

## Recommendations

### ✅ Immediate Actions (Safe)

1. **Clean build cache** - Safe, immediate space savings
2. **Fix restarting services** - Address n8n and prometheus before cleanup
3. **Review stopped containers** - Manual review recommended

### ⏳ Future Actions (After Stability)

1. **Review unused test images** - Remove if confirmed not needed
2. **Review old versions** - After confirming no rollback needed
3. **Monitor space usage** - Regular cleanup to prevent issues

### ❌ Do NOT Do

1. **Do NOT remove** images currently running
2. **Do NOT remove** images with SHA256 digests
3. **Do NOT remove** parent/base images
4. **Do NOT do** aggressive cleanup in production
5. **Do NOT remove** images needed for rollbacks

## Verification After Cleanup

After any cleanup, verify:

```bash
# 1. Check all services running
docker compose -f compose/services/stack.yml ps

# 2. Check no services were affected
docker ps | wc -l  # Should match pre-cleanup count

# 3. Verify critical services
curl -I https://inlock.ai  # Production app
curl -I https://traefik.inlock.ai  # Traefik
```

## Emergency Rollback

If cleanup causes issues:

1. **Stop cleanup immediately**
2. **Check service status:** `docker compose -f compose/services/stack.yml ps`
3. **Restart affected services:** `docker compose -f compose/services/stack.yml restart <service>`
4. **Restore from backup if needed**

---

**Status:** Ready for conservative cleanup (build cache only)  
**Next Steps:** Fix restarting services, then clean build cache

*Last updated: 2026-01-08*
