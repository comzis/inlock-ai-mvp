# Git Publishing Guide - Inlock AI

Guide for publishing the Inlock AI codebase to Git repositories.

## Repository Status

### Application Repository
**Location:** `/opt/inlock-ai-secure-mvp`  
**Remote:** `https://github.com/comzis/inlock-ai.git`  
**Branch:** `main`

### Infrastructure Repository
**Location:** `/home/comzis/inlock-infra`  
**Remote:** Not configured (new repository)  
**Branch:** `main`

---

## Publishing Steps

### 1. Application Repository (Inlock AI)

**Current Status:** Changes committed, ready to push

**To push changes:**
```bash
cd /opt/inlock-ai-secure-mvp
git push origin main
```

**Recent Commits:**
- Rebrand from StreamArt to Inlock AI
- All branding updates completed

**To verify before pushing:**
```bash
cd /opt/inlock-ai-secure-mvp
git status
git log --oneline -5
```

### 2. Infrastructure Repository

**Current Status:** New repository, ready for initial commit

**To publish infrastructure:**
```bash
cd /home/comzis/inlock-infra

# Stage all files
git add -A

# Create initial commit
git commit -m "Initial commit: Inlock Infrastructure

- Complete Docker Compose infrastructure stack
- Traefik reverse proxy with Positive SSL
- Admin services: Portainer, Grafana, n8n, Coolify, Homarr
- Monitoring: Prometheus, cAdvisor
- Inlock AI application deployment configuration
- Complete documentation and deployment guides"

# Add remote (if needed)
git remote add origin <your-repo-url>

# Push to remote
git push -u origin main
```

**Recommended Repository Name:** `inlock-infra` or `inlock-infrastructure`

---

## Repository Configuration

### Application Repository

If you want to rename or update the repository:

**Option 1: Keep existing repo, update description**
- Repository: `inlock-ai`
- Update description to "Inlock AI - Secure AI Consulting Platform"
- Update repository topics/tags

**Option 2: Create new repository**
- Create new repo: `inlock-ai` or `inlock`
- Update remote:
  ```bash
  git remote set-url origin https://github.com/comzis/inlock-ai.git
  git push -u origin main
  ```

### Infrastructure Repository

**Recommended Setup:**
```bash
cd /home/comzis/inlock-infra

# Create new repository on GitHub/GitLab first, then:
git remote add origin https://github.com/comzis/inlock-infra.git
git branch -M main
git push -u origin main
```

---

## Files to Exclude

### Application Repository

Already excluded via `.gitignore`:
- `node_modules/`
- `.next/`
- `.env*` (except `.env.example`)
- `*.log`
- Build artifacts

### Infrastructure Repository

Should exclude:
- `.env` (environment variables)
- `secrets-real/` (actual secrets)
- `*.log` files
- Backup files

**Create `.gitignore` for infrastructure:**
```bash
cd /home/comzis/inlock-infra
cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local

# Secrets
secrets-real/
**/secrets-real/
*.key
*.crt
*.pem

# Logs
*.log
logs/
**/logs/

# Backups
*.backup
backups/
**/*.backup-*

# Docker volumes data
**/data/
**/_data/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
```

---

## Commit Messages

### Application Repository

**Commit Message Format:**
```
Rebrand from StreamArt to Inlock AI

- Update all branding references
- Update package.json name
- Fix ESLint errors
- Maintain functionality
```

### Infrastructure Repository

**Initial Commit:**
```
Initial commit: Inlock Infrastructure

- Complete Docker Compose stack
- Traefik reverse proxy configuration
- Admin services configuration
- Monitoring stack
- Deployment documentation
```

**Subsequent Commits:**
```
Add [feature]: [description]

- Change 1
- Change 2
```

---

## Pre-Push Checklist

### Application Repository

- [ ] All tests pass: `npm run test`
- [ ] Linting passes: `npm run lint`
- [ ] Build succeeds: `npm run build`
- [ ] No sensitive data in commits (check `.env` files)
- [ ] Commit message describes changes clearly

### Infrastructure Repository

- [ ] `.gitignore` configured properly
- [ ] No secrets in repository
- [ ] No `.env` files committed
- [ ] Documentation is complete
- [ ] All services documented in ADMIN-ACCESS-GUIDE.md

---

## Publishing Commands

### Application Repository

```bash
cd /opt/inlock-ai-secure-mvp

# Check status
git status

# Review changes
git diff

# Stage all changes
git add -A

# Commit
git commit -m "Your commit message"

# Push to remote
git push origin main
```

### Infrastructure Repository

```bash
cd /home/comzis/inlock-infra

# Create .gitignore (if not exists)
# See above for contents

# Stage all files
git add -A

# Review what will be committed
git status

# Initial commit
git commit -m "Initial commit: Inlock Infrastructure"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/comzis/inlock-infra.git

# Push
git push -u origin main
```

---

## Repository Settings

### GitHub Repository Settings

**For Application Repository:**
- Description: "Inlock AI - Privacy-first, local-first AI consulting and transformation platform"
- Topics: `inlock`, `ai`, `nextjs`, `typescript`, `docker`, `privacy-first`
- Visibility: Private (recommended for production)

**For Infrastructure Repository:**
- Description: "Inlock Infrastructure - Hardened Docker Compose stack for Inlock AI"
- Topics: `docker`, `traefik`, `infrastructure`, `devops`, `inlock`
- Visibility: Private (recommended - contains infrastructure details)

---

## Security Considerations

1. **Never commit secrets:**
   - `.env` files
   - Password files
   - SSL private keys
   - API tokens

2. **Use environment variables:**
   - Reference `.env.example` files
   - Document required variables in README

3. **Review before committing:**
   ```bash
   git diff --cached
   ```

4. **Use `.gitignore` properly:**
   - Verify sensitive files are excluded
   - Test with `git check-ignore <file>`

---

## Next Steps After Publishing

1. **Update repository description** on GitHub/GitLab
2. **Add repository topics/tags**
3. **Create releases/tags** for major versions
4. **Set up branch protection** (if using GitOps)
5. **Configure CI/CD** (if needed)

---

**Last Updated:** 2025-12-09  
**Status:** Ready for publishing

