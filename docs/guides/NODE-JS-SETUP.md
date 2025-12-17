# Node.js Development Setup

## Overview

While Docker is the recommended approach for consistency, local Node.js installation enables faster development iteration and pre-commit hooks.

## Installation

### Option 1: NVM (Recommended)

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc  # or restart terminal
```

**Use Node 20:**
```bash
nvm install 20
nvm use 20
nvm alias default 20
```

**Verify:**
```bash
node -v  # Should show v20.x.x
npm -v   # Should show 10.x.x
```

### Option 2: NodeSource Repository

**Install:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

**Verify:**
```bash
node -v
npm -v
```

## Development Workflow

### Local Development (Fast Iteration)

```bash
cd /opt/inlock-ai-secure-mvp
npm install
npm run dev
```

**Benefits:**
- Faster startup (no Docker overhead)
- Hot reload works better
- Direct access to Node.js debugger
- Pre-commit hooks work

### Docker Development (CI Parity)

```bash
cd /opt/inlock-ai-secure-mvp
docker run --rm -it \
  -v "$(pwd):/app" \
  -w /app \
  -p 3040:3040 \
  node:20-alpine \
  sh -c "npm install && npm run dev"
```

**Benefits:**
- Matches production environment exactly
- No host Node.js version conflicts
- Isolated dependencies

## Pre-commit Hooks

### Setup Husky

```bash
cd /opt/inlock-ai-secure-mvp
npm install --save-dev husky lint-staged
npx husky init
```

### Configure Pre-commit

Edit `.husky/pre-commit`:
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Run lint-staged (runs linters on staged files)
npx lint-staged

# Run tests
npm test -- --bail --findRelatedTests

# Security audit (non-blocking)
npm audit --audit-level=moderate || echo "⚠️  Audit warnings found - review manually"
```

### Configure lint-staged

Edit `package.json`:
```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ]
  }
}
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
      - run: npm audit --audit-level=high
```

## Security Scanning

### npm audit

```bash
# Check for vulnerabilities
npm audit

# Auto-fix where possible
npm audit fix

# Check only high/critical
npm audit --audit-level=high
```

### Snyk (Optional)

```bash
npm install -g snyk
snyk auth
snyk test
snyk monitor
```

## Version Consistency

### .nvmrc File

Create `/opt/inlock-ai-secure-mvp/.nvmrc`:
```
20
```

Then:
```bash
cd /opt/inlock-ai-secure-mvp
nvm use  # Automatically uses .nvmrc version
```

### Dockerfile Alignment

Ensure `Dockerfile` uses same Node version:
```dockerfile
FROM node:20-alpine AS builder
# ...
```

## Troubleshooting

### Permission Issues

If `npm install` fails with permission errors:
```bash
# Fix npm global directory permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

### Version Conflicts

If you see version mismatch errors:
```bash
# Use nvm to switch versions
nvm use 20

# Or use Docker for consistent environment
docker run --rm -v "$PWD:/app" -w /app node:20-alpine npm install
```

### Pre-commit Hooks Not Running

```bash
# Reinstall hooks
npx husky install

# Make sure .husky/pre-commit is executable
chmod +x .husky/pre-commit
```

## Comparison: Local vs Docker

| Aspect | Local Node.js | Docker |
|--------|--------------|--------|
| **Speed** | Faster startup | Slower (image pull) |
| **Debugging** | Direct access | Requires port forwarding |
| **Pre-commit** | Works natively | Requires Docker setup |
| **Consistency** | Depends on host | Always consistent |
| **CI/CD** | Requires Node setup | Already containerized |

**Recommendation:** Use local Node.js for development, Docker for CI/CD and production.

---

**Last Updated:** December 10, 2025  
**Related:** `docs/NODE-JS-DOCKER-ONLY.md`

