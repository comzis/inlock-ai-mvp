# Image Pinning Guide

## Current Status

Images are currently version-pinned (e.g., `traefik:v3.6.4`) but not digest-pinned. Digest pinning provides immutability guarantees and prevents supply chain attacks.

## Why Digest Pinning?

- **Immutability**: Digest references never change, even if tags are updated
- **Supply Chain Security**: Prevents malicious updates to version tags
- **Reproducibility**: Ensures exact same image across environments

## Conversion Process

### Step 1: Inspect Current Images

```bash
# Pull images to get digests
docker pull traefik:v3.6.4
docker pull ghcr.io/tecnativa/docker-socket-proxy:0.2.7
docker pull nginx:1.27-alpine
docker pull portainer/portainer-ce:2.19.5
docker pull n8nio/n8n:1.64.2
docker pull postgres:16-alpine
docker pull gcr.io/cadvisor/cadvisor:v0.49.1
```

### Step 2: Extract Digests

```bash
# For each image, get the digest
docker image inspect traefik:v3.6.4 | jq -r '.[0].RepoDigests[0]'
# Output: traefik@sha256:abc123...

# Or use docker inspect directly
docker inspect --format='{{index .RepoDigests 0}}' traefik:v3.6.4
```

### Step 3: Update Compose Files

Replace version tags with digest references:

**Before:**
```yaml
image: traefik:v3.6.4
```

**After:**
```yaml
image: traefik@sha256:abc123def456...
```

### Step 4: Update All Services

Files to update:
- `compose/stack.yml`: traefik, docker-socket-proxy, homepage, portainer, cadvisor
- `compose/n8n.yml`: n8n
- `compose/postgres.yml`: postgres

### Step 5: Validate

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env config
```

## Automated Conversion Script

Create `scripts/pin-images.sh`:

```bash
#!/bin/bash
set -euo pipefail

IMAGES=(
  "traefik:v3.6.4"
  "ghcr.io/tecnativa/docker-socket-proxy:0.2.7"
  "nginx:1.27-alpine"
  "portainer/portainer-ce:2.19.5"
  "n8nio/n8n:1.64.2"
  "postgres:16-alpine"
  "gcr.io/cadvisor/cadvisor:v0.49.1"
)

echo "Pulling images and extracting digests..."
for img in "${IMAGES[@]}"; do
  echo "Processing $img..."
  docker pull "$img"
  digest=$(docker inspect --format='{{index .RepoDigests 0}}' "$img")
  echo "$img -> $digest"
done
```

## Runtime Restrictions Status

| Service | User | Cap Drop | Read Only | Status |
|---------|------|----------|-----------|--------|
| docker-socket-proxy | root* | - | ✅ | ⚠️ Needs review |
| traefik | root* | - | - | ⚠️ Needs review (requires port binding) |
| homepage | 101 | ALL | ✅ | ✅ Complete |
| portainer | root* | ALL | - | ✅ Cap drop added |
| n8n | 1000:1000 | ALL | - | ✅ Complete |
| postgres | postgres | - | - | ⚠️ Consider restrictions |
| cadvisor | root* | - | ✅ | ⚠️ Needs review |

*Services marked with root may require elevated privileges for port binding or system access. Review on case-by-case basis.

## Recommendations

1. **Traefik**: Keep as root (needs port 80/443 binding) but ensure `no-new-privileges` is set ✅
2. **docker-socket-proxy**: Consider non-root user if socket proxy supports it
3. **Portainer**: Already has cap_drop: ALL ✅
4. **cAdvisor**: Runs read-only ✅, consider non-root if possible
5. **Postgres**: Runs as postgres user ✅, consider read-only root filesystem for data dir

## Next Steps

1. Run digest extraction for all images
2. Update compose files with digest references
3. Test deployment with pinned images
4. Document digest update process for future upgrades
5. Consider automated digest checking in CI/CD

