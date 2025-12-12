# Container Hardening

## Overview

All containers are hardened with security best practices:
- **Image pinning** to specific digests (prevents supply chain attacks)
- **Non-root users** where possible
- **Capability dropping** (remove unnecessary privileges)
- **Read-only filesystems** where applicable
- **Temporary filesystems** (tmpfs) for writable temp directories
- **No new privileges** (prevents privilege escalation)

## Current Hardening Status

### Fully Hardened Services

| Service | Image Digest | User | cap_drop | read_only | tmpfs |
|---------|-------------|------|----------|-----------|-------|
| Traefik | ✅ Pinned | Root* | ✅ ALL | ❌ (needs ACME write) | ✅ /tmp, /var/run |
| Portainer | ✅ Pinned | Root* | ✅ ALL | ❌ (needs data write) | ❌ |
| n8n | ✅ Pinned | ✅ 1000:1000 | ✅ ALL | ❌ (needs data write) | ✅ /tmp |
| Postgres | ✅ Pinned | ✅ postgres (70) | ✅ ALL | ❌ (needs data write) | ✅ /tmp, /var/run/postgresql |
| cAdvisor | ✅ Pinned | Root* | ✅ ALL | ✅ | ❌ |
| Docker Socket Proxy | ✅ Pinned | Root* | ✅ ALL | ❌ (needs /tmp) | ❌ |
| Homepage (nginx) | ✅ Pinned | Root* | ⚠️ Partial | ❌ (relaxed) | ❌ |

*Root required for binding to privileged ports (<1024) or system access

## Hardening Details

### Image Pinning

**All images are pinned to specific digests:**

```yaml
# Good: Pinned to digest
image: traefik@sha256:c5bd185c41ba3dbb42cf8a1b9fbdc368bdc96f90c8e598134879935f64e7a7f1

# Bad: Using tags (can change)
image: traefik:latest
image: traefik:v3.0
```

**Benefits:**
- Prevents supply chain attacks
- Ensures reproducible deployments
- Avoids unexpected updates

**Updating Images:**
```bash
# Pull new image and get digest
docker pull traefik:latest
docker images traefik --format "{{.Digest}}"

# Update compose file with new digest
# Test thoroughly before deploying
```

### Non-Root Users

**Services running as non-root:**

- **n8n:** `user: "1000:1000"` (node user)
- **Postgres:** Runs as `postgres` user (UID 70) by default

**Services requiring root:**
- **Traefik:** Needs `NET_BIND_SERVICE` to bind to ports 80/443
- **Portainer:** Minimal container, runs as root
- **cAdvisor:** Needs system access for metrics
- **Docker Socket Proxy:** Needs Docker socket access

### Capability Dropping

**All services drop ALL capabilities, then add only what's needed:**

```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # Only if needed for privileged ports
```

**Traefik:**
- Drops: ALL
- Adds: `NET_BIND_SERVICE` (for ports 80/443)

**Postgres:**
- Drops: ALL
- Adds: `CHOWN`, `SETGID`, `SETUID` (for data directory)

**n8n:**
- Drops: ALL
- Adds: None (runs as non-root user)

### Read-Only Filesystems

**Services with read-only root filesystem:**
- **cAdvisor:** Full read-only (monitoring only, no writes needed)

**Services that cannot be read-only:**
- **Traefik:** Needs to write ACME certificates
- **Portainer:** Needs to write database and config
- **n8n:** Needs to write workflows and data
- **Postgres:** Needs to write database files
- **Homepage:** Temporarily relaxed (nginx user issue)

### Temporary Filesystems (tmpfs)

**Services using tmpfs for temporary files:**

```yaml
tmpfs:
  - /tmp          # Temporary files
  - /var/run      # Runtime files (if needed)
```

**Benefits:**
- No disk writes for temporary data
- Faster I/O
- Automatic cleanup on container restart

**Services with tmpfs:**
- **Traefik:** `/tmp`, `/var/run`
- **n8n:** `/tmp`
- **Postgres:** `/tmp`, `/var/run/postgresql`

### No New Privileges

**All services have `no-new-privileges:true`:**

```yaml
security_opt:
  - no-new-privileges:true
```

**Benefits:**
- Prevents privilege escalation attacks
- Container cannot gain additional privileges
- Applied via `x-hardening` anchor

## Hardening Checklist

When adding a new service:

- [ ] Pin image to digest
- [ ] Run as non-root user (if possible)
- [ ] Drop ALL capabilities, add only what's needed
- [ ] Use read-only filesystem (if no writes needed)
- [ ] Use tmpfs for temporary files
- [ ] Enable `no-new-privileges`
- [ ] Set resource limits
- [ ] Configure healthchecks
- [ ] Use secrets for sensitive data
- [ ] Document any exceptions

## Service-Specific Hardening

### Traefik

**Hardening Applied:**
- ✅ Image pinned to digest
- ✅ `cap_drop: ALL`, `cap_add: NET_BIND_SERVICE`
- ✅ `no-new-privileges: true`
- ✅ tmpfs for `/tmp`, `/var/run`
- ❌ Cannot be read-only (needs ACME write)
- ❌ Runs as root (needs port binding)

**Why Root:**
- Must bind to ports 80/443 (privileged ports)
- `NET_BIND_SERVICE` capability allows this without full root, but image runs as root

### Portainer

**Hardening Applied:**
- ✅ Image pinned to digest
- ✅ `cap_drop: ALL`
- ✅ `no-new-privileges: true`
- ❌ Cannot be read-only (needs data write)
- ❌ No tmpfs (minimal container)
- ❌ Runs as root (minimal container)

**Limitations:**
- Minimal container (no shell, limited tools)
- Requires root for Docker socket access
- Cannot easily run as non-root

### n8n

**Hardening Applied:**
- ✅ Image pinned to digest
- ✅ Runs as `1000:1000` (non-root)
- ✅ `cap_drop: ALL`
- ✅ `no-new-privileges: true`
- ✅ tmpfs for `/tmp`
- ❌ Cannot be read-only (needs data write)

**Best Practices:**
- Runs as non-root user
- No additional capabilities needed
- Temporary files in tmpfs

### Postgres

**Hardening Applied:**
- ✅ Image pinned to digest
- ✅ Runs as `postgres` user (non-root)
- ✅ `cap_drop: ALL`, `cap_add: CHOWN, SETGID, SETUID`
- ✅ `no-new-privileges: true`
- ✅ tmpfs for `/tmp`, `/var/run/postgresql`
- ❌ Cannot be read-only (needs data write)

**Why Additional Capabilities:**
- `CHOWN`: Change ownership of data files
- `SETGID`, `SETUID`: Set process user/group

### cAdvisor

**Hardening Applied:**
- ✅ Image pinned to digest
- ✅ `cap_drop: ALL`
- ✅ `read_only: true` (full read-only)
- ✅ `no-new-privileges: true`
- ❌ Runs as root (needs system access)

**Why Root:**
- Needs access to `/`, `/sys`, `/var/run` for metrics
- Read-only filesystem prevents writes

### Homepage (nginx)

**Hardening Status:**
- ✅ Image pinned to digest
- ⚠️ Hardening temporarily relaxed
- ❌ No `cap_drop` (nginx user 101 issue)
- ❌ Not read-only (nginx chown issue)

**TODO:**
- Fix nginx user 101 chown issue
- Add `cap_drop: ALL`
- Consider read-only with tmpfs for cache

## Hardening Verification

**Check Service Hardening:**
```bash
# Check image digests
grep -E "image:|@sha256" compose/*.yml

# Check user settings
grep "user:" compose/*.yml

# Check capability drops
grep -A 2 "cap_drop:" compose/*.yml

# Check read-only
grep "read_only:" compose/*.yml

# Check tmpfs
grep -A 2 "tmpfs:" compose/*.yml
```

**Inspect Running Container:**
```bash
# Check user
docker inspect compose-traefik-1 --format '{{.Config.User}}'

# Check capabilities
docker inspect compose-traefik-1 --format '{{.HostConfig.CapDrop}}'

# Check read-only
docker inspect compose-traefik-1 --format '{{.HostConfig.ReadonlyRootfs}}'

# Check security options
docker inspect compose-traefik-1 --format '{{.HostConfig.SecurityOpt}}'
```

## Hardening Script

**Verify Hardening:**
```bash
./scripts/verify-container-hardening.sh
```

This script checks:
- All images pinned to digests
- Non-root users where applicable
- Capability dropping
- Read-only filesystems
- tmpfs usage
- No new privileges

## Future Improvements

**Planned:**
- [ ] Fix homepage nginx hardening
- [ ] Add AppArmor/SELinux profiles
- [ ] Implement seccomp profiles
- [ ] Add network policies
- [ ] Implement pod security policies (if using Kubernetes)

**Consider:**
- [ ] gVisor/runsc for additional isolation
- [ ] Kata containers for VM-level isolation
- [ ] Rootless Docker (experimental)

## References

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Traefik Security](https://doc.traefik.io/traefik/operations/security/)










