# Server Directory Structure Analysis

## Current State

### Key Directories

**`/home/comzis/`**
```
├── inlock-infra/          # OLD infrastructure (seems like pre-reorganization)
├── projects/
│   └── inlock-ai-mvp/    # GitHub repo clone
├── inlock-tooling/        # Standalone tooling deployment
├── apps/                  # Application deployments
│   ├── traefik/
│   └── secrets-real/      # Secrets storage
├── backups/               # System backups
├── scripts/               # Utility scripts
├── logs/                  # Application logs
├── docs/                  # Documentation
└── grafana/               # Grafana configs
```

### Detailed Analysis

#### 1. `/home/comzis/inlock-infra/` (320 files)
**Status**: OLD - Appears to be pre-reorganization state
- Contains similar structure to GitHub repo but OLDER
- Has scattered status reports in root (AUTH0-*, MAILU-*, etc.)
- compose/, traefik/, ansible/, scripts/, docs/

**Issues**:
- Duplicate of GitHub repo but outdated
- Same messy structure we just cleaned up
- Not synced with latest GitHub

#### 2. `/home/comzis/projects/inlock-ai-mvp/` 
**Status**: Our clean GitHub repo
- Latest organized structure
- Clean root directory
- All reports in docs/reports/

**Good**: This is the authoritative source!

#### 3. `/home/comzis/inlock-tooling/`
**Status**: Standalone tooling deployment
- .env.tooling
- Dockerfile.strapi  
- docker-compose.tooling.yml

**Issue**: Isolated from main repo, manual management

#### 4. `/home/comzis/apps/traefik/`
- portainer_data/
- configs/
- scripts/
- docs/

**Issue**: Separate Traefik config from main repo

---

## Problems Identified

### 1. Duplication
- `inlock-infra/` duplicates `projects/inlock-ai-mvp/`
- Separate `inlock-tooling/` vs repo's `compose/tooling.yml`
- Multiple Traefik configs (apps/traefik vs inlock-infra/traefik)

### 2. Outdated Content
- `inlock-infra/` has old structure (pre-cleanup)
- Not synced with GitHub repo
- Messy status reports in root

### 3. Fragmentation
- Configurations scattered across multiple directories
- No single source of truth for deployments
- Hard to maintain consistency

---

## Recommended Structure

### Option A: GitHub Repo as Single Source of Truth

```
/home/comzis/
├── inlock-ai-mvp/                 # MAIN - GitHub repo (authoritative)
│   ├── compose/                   # All Docker Compose files
│   ├── traefik/                   # All Traefik configs
│   ├── scripts/                   # All scripts
│   ├── docs/                      # All documentation
│   └── ...
├── deployments/                   # Active deployment data
│   ├── .env.production            # Production environment
│   ├── .env.tooling               # Tooling environment
│   └── volumes/                   # Docker volumes
├── apps/                          
│   └── secrets-real/              # Secrets (keep secure)
├── backups/                       # Backups
└── logs/                          # Logs

REMOVE:
├── inlock-infra/                  # DELETE (outdated duplicate)
└── inlock-tooling/                # MERGE into main repo
```

### Deployment Workflow
```bash
# From GitHub repo
cd /home/comzis/inlock-ai-mvp

# Deploy tooling
docker compose -f compose/tooling.yml \
  --env-file /home/comzis/deployments/.env.tooling up -d

# Deploy main stack
docker compose -f compose/stack.yml \
  --env-file /home/comzis/deployments/.env.production up -d
```

---

## Migration Plan

### Phase 1: Backup Current State
```bash
# Backup inlock-infra
tar czf /home/comzis/backups/inlock-infra-$(date +%Y%m%d).tar.gz /home/comzis/inlock-infra/

# Backup inlock-tooling
tar czf /home/comzis/backups/inlock-tooling-$(date +%Y%m%d).tar.gz /home/comzis/inlock-tooling/
```

### Phase 2: Consolidate Configurations
```bash
# Create deployments directory
mkdir -p /home/comzis/deployments

# Move env files
mv /home/comzis/inlock-tooling/.env.tooling /home/comzis/deployments/
```

### Phase 3: Update Repo
```bash
cd /home/comzis/projects/inlock-ai-mvp
git pull origin main  # Get latest organized structure
```

### Phase 4: Remove Duplicates
```bash
# After verifying everything works
rm -rf /home/comzis/inlock-infra
rm -rf /home/comzis/inlock-tooling
```

### Phase 5: Symlink for Convenience
```bash
# Make main repo easily accessible
ln -s /home/comzis/projects/inlock-ai-mvp /home/comzis/inlock
```

---

## Benefits

### ✅ Single Source of Truth
- GitHub repo is the authoritative source
- All changes go through Git
- Version controlled

### ✅ Clean Organization
- No duplication
- No scattered configs
- Clear structure

### ✅ Easy Updates
- `git pull` to get latest
- Deploy from one location
- Consistent across team

### ✅ Proper Separation
- Code/configs in Git repo
- Secrets in secure location
- Runtime data in deployments/

---

## Next Steps

1. Review this analysis
2. Backup current state
3. Test deployments from GitHub repo
4. Migrate env files to deployments/
5. Remove old directories
6. Update documentation

