# Orphan Container Cleanup

## What Are Orphan Containers?

Orphan containers are Docker containers that were created by previous Docker Compose configurations but are no longer defined in your current `compose/stack.yml` file.

**Common causes:**
- Services removed from stack.yml
- Services moved to separate compose files
- Services renamed

## Quick Cleanup

### Option 1: Use the Cleanup Script

```bash
cd /home/comzis/inlock-infra
./scripts/cleanup-orphan-containers.sh
```

### Option 2: Use Docker Compose Flag

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans
```

The `--remove-orphans` flag automatically removes containers that are not defined in your compose file.

### Option 3: Manual Cleanup

```bash
# List orphan containers
docker ps -a --filter "name=compose-" | grep -E "homarr|n8n|postgres|cockpit"

# Stop and remove specific containers
docker stop compose-homarr-1 compose-n8n-1 compose-postgres-1 compose-cockpit-1
docker rm compose-homarr-1 compose-n8n-1 compose-postgres-1 compose-cockpit-1
```

## Current Status

After cleanup, your stack should only contain services defined in `compose/stack.yml`:

**Active Services:**
- ✅ `traefik` - Reverse proxy
- ✅ `docker-socket-proxy` - Docker socket proxy
- ✅ `homepage` - Homepage service
- ✅ `portainer` - Container management
- ✅ `grafana` - Metrics dashboard
- ✅ `cadvisor` - Container metrics
- ✅ `prometheus` - Metrics collection
- ✅ `inlock-ai` - Main application
- ✅ `inlock-db` - Application database

**Removed Orphans:**
- ❌ `compose-homarr-1` - Removed (not in stack.yml)
- ❌ `compose-n8n-1` - Removed (not in stack.yml)
- ❌ `compose-postgres-1` - Removed (replaced by inlock-db)
- ❌ `compose-cockpit-1` - Removed (not in stack.yml)

## If You Need These Services Back

If you need any of the removed services, you can add them back:

### Option 1: Add to stack.yml

Edit `compose/stack.yml` and add the service definition, or include the compose file:

```yaml
include:
  - inlock-db.yml
  - inlock-ai.yml
  - n8n.yml        # Add this
  - homarr.yml     # Add this
```

### Option 2: Run Separately

Run services from their own compose files:

```bash
# Run n8n separately
docker compose -f compose/n8n.yml -f compose/postgres.yml --env-file .env up -d

# Run homarr separately
docker compose -f compose/homarr.yml --env-file .env up -d
```

## Prevention

To prevent orphan warnings in the future:

1. **Always use --remove-orphans** when removing services:
   ```bash
   docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans
   ```

2. **Keep compose files in sync** - If you remove a service, remove its compose file or ensure it's not included

3. **Use a cleanup script** - Run the cleanup script periodically

## Cleanup Script

The cleanup script is located at:
- `/home/comzis/inlock-infra/scripts/cleanup-orphan-containers.sh`

**Usage:**
```bash
cd /home/comzis/inlock-infra
./scripts/cleanup-orphan-containers.sh
```

The script will:
1. Identify orphan containers
2. Show what will be removed
3. Ask for confirmation
4. Remove the containers
5. Verify cleanup

---

**Last Updated:** 2025-12-09  
**Status:** Orphan containers cleaned up

