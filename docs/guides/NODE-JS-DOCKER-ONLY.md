# Node.js Development - Docker-Only Approach

## Overview

Since all builds and deployments run via Docker, we **no longer need system-level Node.js/npm** on the host. This avoids version conflicts and permission issues.

## Remove System Node.js/npm

**Run these commands manually (requires sudo password):**

```bash
# Remove Ubuntu's Node.js packages
sudo apt remove --purge nodejs npm nodejs-doc -y
sudo apt autoremove -y

# Verify removal
which node    # Should return nothing or point to nvm
which npm     # Should return nothing or point to nvm
```

## Development Workflow

### Recommended: Always Use Docker

**For builds:**
```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
```

**For local development server:**
```bash
cd /opt/inlock-ai-secure-mvp
docker run --rm -it \
  -v "$(pwd):/app" \
  -w /app \
  -p 3040:3040 \
  node:20-alpine \
  sh -c "npm install && npm run dev"
```

**For linting/testing:**
```bash
cd /opt/inlock-ai-secure-mvp
docker run --rm \
  -v "$(pwd):/app" \
  -w /app \
  node:20-alpine \
  sh -c "npm install && npm run lint"
```

### Optional: Use NVM (If Needed)

If you occasionally need Node.js locally (e.g., for scripts), nvm is installed and doesn't interfere:

```bash
# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Use Node 20
nvm use 20
node -v  # Should show v20.19.6
```

**Note:** NVM is user-level and doesn't require sudo. It's fine to keep it as a backup option.

## Benefits

1. **No Version Conflicts** - Docker always uses Node 20
2. **No Permission Issues** - All builds happen in containers
3. **Consistent Environment** - Same Node version in dev and production
4. **Cleaner System** - No unused Node.js packages cluttering the system

## Scripts Updated

The following scripts automatically use Docker if npm is not found:
- `scripts/regression-check.sh` - Uses Docker fallback
- `scripts/pre-deploy.sh` - Uses Docker fallback

## Production Deployments

All production builds already use Docker:
```bash
cd /opt/inlock-ai-secure-mvp
docker build -t inlock-ai:latest .
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
```

---

**Last Updated:** December 10, 2025  
**Recommendation:** Remove system nodejs/npm and use Docker exclusively

