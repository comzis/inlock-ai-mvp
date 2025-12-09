# Publish to Git - Inlock AI

Quick reference for publishing both repositories to Git.

## ✅ Status

### Application Repository
**Location:** `/opt/inlock-ai-secure-mvp`  
**Status:** ✅ Committed and ready to push  
**Commit:** `Rebrand from StreamArt to Inlock AI`  
**Remote:** `https://github.com/comzis/streamart-ai-secure-mvp.git`

### Infrastructure Repository
**Location:** `/home/comzis/inlock-infra`  
**Status:** ✅ Initial commit completed  
**Commit:** `Initial commit: Inlock Infrastructure`  
**Remote:** Not configured yet

---

## 🚀 Push to Git

### 1. Application Repository (Inlock AI)

```bash
cd /opt/inlock-ai-secure-mvp

# Verify commit
git log --oneline -1

# Push to remote
git push origin main
```

**What will be pushed:**
- ✅ All rebranding changes (StreamArt → Inlock)
- ✅ Updated package.json
- ✅ Fixed ESLint errors
- ✅ All application code

### 2. Infrastructure Repository (Inlock Infrastructure)

**First, create a new repository on GitHub/GitLab:**
- Repository name: `inlock-infra` (recommended)
- Description: "Inlock Infrastructure - Hardened Docker Compose stack"
- Visibility: Private (recommended)
- Initialize: Don't initialize with README (we already have one)

**Then push:**

```bash
cd /home/comzis/inlock-infra

# Add remote (replace with your actual repo URL)
git remote add origin https://github.com/comzis/inlock-infra.git

# Verify remote
git remote -v

# Push to remote
git push -u origin main
```

**What will be pushed:**
- ✅ Complete infrastructure configuration
- ✅ Docker Compose files
- ✅ Traefik configuration
- ✅ All documentation
- ✅ Deployment scripts
- ✅ Admin access guide

---

## 📋 Pre-Push Verification

### Application Repository

```bash
cd /opt/inlock-ai-secure-mvp

# Check no sensitive files
git ls-files | grep -E "\.env$|password|secret" | grep -v ".example"

# Should return nothing (or only example files)

# Verify commit
git log --oneline -3
```

### Infrastructure Repository

```bash
cd /home/comzis/inlock-infra

# Check no secrets committed
git ls-files | grep -E "\.env$|secrets-real|password|\.key$|\.crt$" | grep -v ".example"

# Should return nothing

# Verify commit
git log --oneline -1
```

---

## 🔐 Security Checklist

Before pushing, ensure:

- [ ] No `.env` files committed (only `.env.example`)
- [ ] No password files committed
- [ ] No SSL private keys committed
- [ ] No API tokens or secrets in code
- [ ] `.gitignore` properly configured
- [ ] All secrets in `secrets-real/` are excluded

---

## 📝 Repository Configuration

### Application Repository

**After pushing, update GitHub repository:**

1. Go to repository settings
2. Update description: "Inlock AI - Privacy-first, local-first AI consulting platform"
3. Add topics: `inlock`, `ai`, `nextjs`, `typescript`, `docker`, `privacy-first`
4. Update repository name (optional): Consider renaming to `inlock-ai`

### Infrastructure Repository

**After creating and pushing:**

1. Update description: "Inlock Infrastructure - Hardened Docker Compose stack for Inlock AI"
2. Add topics: `docker`, `traefik`, `infrastructure`, `devops`, `inlock`
3. Set visibility: Private (recommended)
4. Add branch protection rules (if using GitOps)

---

## 🎯 Quick Commands

### Application Repo
```bash
cd /opt/inlock-ai-secure-mvp
git push origin main
```

### Infrastructure Repo
```bash
cd /home/comzis/inlock-infra
git remote add origin <your-repo-url>
git push -u origin main
```

---

**Ready to publish!** Both repositories are committed and ready to push.

