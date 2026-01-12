# Cursor Workflow Guide - With Antigravity Integration

**Comprehensive workflow for using Cursor and Antigravity together for infrastructure management and feature development.**

---

## Overview

This guide covers the complete workflow for using **Cursor** (infrastructure/ops) and **Antigravity** (feature development/testing) together in the Inlock AI project.

### Tool Roles

| Tool | Purpose | Workspace | Repository |
|------|---------|-----------|------------|
| **Cursor** | Infrastructure management, safeguards, ops rules | Control workspace (`home-comzis-inlock`) | Not a git repo |
| **Antigravity** | Feature development, testing, code changes | Main project (`inlock-ai-mvp`) | Git repository |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Mac (Local)                          │
│                                                          │
│  ┌──────────────┐              ┌──────────────┐        │
│  │   Cursor     │              │  Antigravity │        │
│  │              │              │              │        │
│  │ Infrastructure│             │   Features   │        │
│  │   Management │              │  Development │        │
│  └──────┬───────┘              └──────┬───────┘        │
│         │                              │                │
│         │ SSH                          │ SSH            │
│         │                              │                │
└─────────┼──────────────────────────────┼────────────────┘
          │                              │
          │                              │
┌─────────┼──────────────────────────────┼────────────────┐
│         │        Remote Server         │                │
│         │                              │                │
│  ┌──────▼──────────┐        ┌─────────▼──────────┐    │
│  │ Control         │        │ Main Project       │    │
│  │ Workspace       │        │ Repository         │    │
│  │                 │        │                    │    │
│  │ home-comzis-    │        │ inlock-ai-mvp      │    │
│  │ inlock          │        │ (Git Repo)         │    │
│  │                 │        │                    │    │
│  │ • Rules         │        │ • Application Code │    │
│  │ • Scripts       │        │ • Configs          │    │
│  │ • Safeguards    │        │ • Services         │    │
│  │ • Runbooks      │        │ • Features         │    │
│  └─────────────────┘        └────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Part 1: Cursor Workflow (Infrastructure Management)

### 1.1 Connecting to Cursor Control Workspace

**Command** (from Mac):
```bash
cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
```

**Purpose**: Connect to the control workspace for infrastructure rules, safeguards, and operational procedures.

**What you'll see**:
- `.cursorrules` - Certificate and service safeguards
- `rules/` - Health check scripts and safeguards
- `scripts/` - Preflight/postflight scripts
- `runbooks/` - Operational procedures
- `reports/` - Status reports
- `docs/` - Documentation and analysis

---

### 1.2 Cursor Workflow: Infrastructure Changes

When making infrastructure changes (certificates, services, Docker Compose, Traefik, DNS):

#### Step 1: Pre-Change (Preflight)

```bash
# Run preflight checks
cd /home/comzis/.cursor/projects/home-comzis-inlock
bash scripts/preflight.sh
```

**What preflight checks**:
- Certificate health
- Service configuration
- Database connections
- HTTPS connectivity

**Review safeguards**:
- `rules/certificate-safeguards.md` - SSL/TLS certificate rules
- `rules/service-configuration-safeguards.md` - Service config rules

#### Step 2: Backup Configuration

Before making changes, backup critical files:
```bash
# Backup Traefik config
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  cp traefik/dynamic/routers.yml traefik/dynamic/routers.yml.backup && \
  cp traefik/dynamic/tls.yml traefik/dynamic/tls.yml.backup"
```

#### Step 3: Make Changes

**Important**: Code/config changes go in the **main project repository**, not the control workspace:

```bash
# Changes go here (NOT in control workspace)
/home/comzis/projects/inlock-ai-mvp/
```

**Protected values** (NEVER change without verification):
- Positive SSL certificate (inlock.ai, www.inlock.ai)
- Coolify DB_PASSWORD with default fallback
- Grafana domain (hardcoded, NOT `${DOMAIN}`)
- Traefik router TLS configs

#### Step 4: Post-Change (Postflight)

```bash
# Run postflight checks
cd /home/comzis/.cursor/projects/home-comzis-inlock
bash scripts/postflight.sh
```

**If HTTPS issues appear**:
```bash
bash scripts/diagnose_https.sh
```

#### Step 5: Record Changes

Create a report in `reports/`:
```markdown
# YYYY-MM-DD Change Report

## Scope
- What changed

## Verification
- Preflight: pass/fail
- Postflight: pass/fail
- Notes

## Rollback Plan
- If needed
```

---

## Part 2: Antigravity Workflow (Feature Development)

### 2.1 Connecting to Antigravity

**Command** (from Mac):
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

**Purpose**: Connect to the main project repository for feature development and testing.

**Note**: Antigravity connects to the currently checked-out branch on the remote server.

---

### 2.2 Antigravity Workflow: Feature Development

#### Step 1: Choose/Checkout Branch

**For new features**:
```bash
# Switch to main and pull latest
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout main && git pull"

# Create feature branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout -b feature/my-new-feature"
```

**For testing** (using Antigravity test branch):
```bash
# Switch to test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout antigravity/test-features && git pull"
```

**For existing features**:
```bash
# Switch to existing branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout feature/existing-feature && git pull"
```

#### Step 2: Connect Antigravity

```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

Antigravity will connect to the branch you just checked out.

#### Step 3: Develop with Antigravity

**Work with Antigravity**:
- Request feature implementations
- Ask for code changes
- Get explanations and suggestions
- Use branch workflow documentation: `docs/antigravity-git-branch-workflow.md`

**Example prompts**:
- "Add a new API endpoint for user authentication"
- "Refactor this component to use TypeScript"
- "Fix the bug in the login flow"
- "Write tests for this feature"

#### Step 4: Commit Changes

**After Antigravity makes changes**:

```bash
# Check what changed
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git status"

# Review changes
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git diff"

# Stage and commit
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git add . && \
  git commit -m 'feat: Description of changes'"

# Push branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git push -u origin feature/my-new-feature"
```

#### Step 5: Create Pull Request

Create PR on GitHub:
1. Go to: `https://github.com/comzis/inlock-ai-mvp/pulls`
2. Click "New Pull Request"
3. Select base: `main`, compare: `feature/my-new-feature`
4. Fill in description
5. Request review

---

## Part 3: Combined Workflow (Cursor + Antigravity)

### 3.1 Feature Development Workflow

**Complete workflow for developing new features with both tools**:

#### Phase 1: Planning (Cursor)

1. **Connect to Cursor** (control workspace):
   ```bash
   cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
   ```

2. **Review infrastructure impact**:
   - Check if feature requires infrastructure changes
   - Review safeguards: `rules/certificate-safeguards.md`, `rules/service-configuration-safeguards.md`
   - Check existing runbooks: `runbooks/`

3. **Run preflight** (if infrastructure changes needed):
   ```bash
   bash scripts/preflight.sh
   ```

#### Phase 2: Development (Antigravity)

1. **Create feature branch** (on remote):
   ```bash
   ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
     git checkout main && git pull && \
     git checkout -b feature/my-feature"
   ```

2. **Connect Antigravity**:
   ```bash
   /Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
   ```

3. **Develop feature**:
   - Work with Antigravity on code changes
   - Reference docs: `docs/antigravity-git-branch-workflow.md`
   - Make incremental commits

4. **Commit and push**:
   ```bash
   ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
     git add . && \
     git commit -m 'feat: Add my feature' && \
     git push -u origin feature/my-feature"
   ```

#### Phase 3: Testing (Antigravity)

1. **Switch to test branch** (if using dedicated test branch):
   ```bash
   ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
     git checkout antigravity/test-features && \
     git merge feature/my-feature && \
     git push"
   ```

2. **Connect Antigravity to test branch**:
   ```bash
   /Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
   ```

3. **Test feature**:
   - Run tests
   - Manual testing
   - Integration testing

#### Phase 4: Infrastructure Verification (Cursor)

1. **If feature affects infrastructure**:
   - Connect to Cursor
   - Run postflight: `bash scripts/postflight.sh`
   - Check certificates: `bash scripts/check_subdomains.sh`
   - Diagnose issues: `bash scripts/diagnose_https.sh`

2. **Create report**:
   - Document in `reports/`
   - Note any infrastructure impacts

#### Phase 5: Merge (GitHub)

1. **Create PR**:
   - Base: `main`
   - Compare: `feature/my-feature`

2. **Review and merge**

---

### 3.2 Infrastructure Change Workflow

**For infrastructure-only changes (certificates, services, configs)**:

#### Use Cursor Only

1. **Connect to Cursor**:
   ```bash
   cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
   ```

2. **Run preflight**:
   ```bash
   bash scripts/preflight.sh
   ```

3. **Make changes** (in main project, but manage from Cursor):
   ```bash
   # Edit files in: /home/comzis/projects/inlock-ai-mvp
   # But work from Cursor control workspace context
   ```

4. **Run postflight**:
   ```bash
   bash scripts/postflight.sh
   ```

5. **Commit changes** (if needed):
   ```bash
   ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
     git add . && \
     git commit -m 'chore: Infrastructure update' && \
     git push"
   ```

---

## Part 4: Branch Management Strategy

### 4.1 Branch Types

| Branch | Purpose | Tool | Workflow |
|--------|---------|------|----------|
| `main` | Production code | Both | Protected, merge via PR |
| `antigravity/test-features` | Antigravity testing | Antigravity | Test branch for features |
| `feature/*` | New features | Antigravity | Development branches |
| `cursor/*` | Cursor-specific work | Cursor | Infrastructure branches |
| `bugfix/*` | Bug fixes | Antigravity | Fix branches |
| `hotfix/*` | Urgent fixes | Both | Emergency fixes |

### 4.2 Branch Workflow

```
main (production)
  │
  ├── feature/my-feature (Antigravity)
  │     │
  │     └── antigravity/test-features (Antigravity)
  │           │
  │           └── PR to main
  │
  ├── cursor/infrastructure-update (Cursor)
  │     │
  │     └── PR to main
  │
  └── hotfix/urgent-fix (Either)
        │
        └── PR to main (fast-track)
```

---

## Part 5: Best Practices

### 5.1 When to Use Which Tool

**Use Cursor for**:
- ✅ Infrastructure changes (certificates, services, Traefik)
- ✅ Safeguard reviews before changes
- ✅ Health checks (preflight/postflight)
- ✅ Operational procedures (runbooks)
- ✅ Infrastructure documentation
- ✅ Certificate and service configuration

**Use Antigravity for**:
- ✅ Feature development
- ✅ Code changes and refactoring
- ✅ Testing on dedicated branches
- ✅ Application code updates
- ✅ Feature documentation
- ✅ Code reviews and improvements

### 5.2 Workflow Best Practices

1. **Always run preflight before infrastructure changes** (Cursor)
2. **Always run postflight after infrastructure changes** (Cursor)
3. **Use feature branches for new development** (Antigravity)
4. **Test on dedicated test branches** (Antigravity)
5. **Commit frequently with clear messages**
6. **Review safeguards before infrastructure changes**
7. **Create reports for significant changes**
8. **Keep branches in sync with main**

### 5.3 Safeguards to Remember

**Certificate Safeguards** (Cursor):
- Positive SSL for inlock.ai/www.inlock.ai (NEVER change)
- Certificate fingerprint: `FB:FD:85:7E:20:F0:E3:9C:79:D4:0D:BC:7B:7F:5A:2C:5F:E9:1D:39:BF:08:41:C4:53:A4:06:D5:E4:D2:2B:E8`
- All other subdomains use Let's Encrypt

**Service Safeguards** (Cursor):
- Coolify DB_PASSWORD must have default fallback
- Grafana domain must be hardcoded (NOT `${DOMAIN}`)
- APP_URL must be `https://deploy.inlock.ai`

### 5.4 Documentation

**Cursor Control Workspace**:
- `docs/workspace-structure-analysis.md` - Workspace structure
- `docs/cursor-workflow-guide.md` - This guide
- `docs/remote-connection-troubleshooting.md` - Connection issues
- `rules/certificate-safeguards.md` - Certificate rules
- `rules/service-configuration-safeguards.md` - Service rules

**Main Project Repository**:
- `docs/GIT-WORKFLOW.md` - Git workflow
- `docs/antigravity-git-branch-workflow.md` - Antigravity branch workflow
- `docs/index.md` - Documentation index

---

## Part 6: Common Workflows

### 6.1 New Feature Development

```bash
# 1. Cursor: Review infrastructure impact
cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
# Review safeguards, run preflight if needed

# 2. Antigravity: Create feature branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout main && git pull && \
  git checkout -b feature/new-feature"

# 3. Antigravity: Develop
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp

# 4. Commit and push
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git add . && git commit -m 'feat: New feature' && \
  git push -u origin feature/new-feature"

# 5. Create PR on GitHub
```

### 6.2 Testing Feature

```bash
# 1. Switch to test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout antigravity/test-features && git pull"

# 2. Merge feature into test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git merge feature/new-feature && git push"

# 3. Connect Antigravity to test branch
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp

# 4. Test feature

# 5. If infrastructure impacted, verify with Cursor
cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
bash scripts/postflight.sh
```

### 6.3 Infrastructure Update

```bash
# 1. Cursor: Preflight
cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
bash scripts/preflight.sh

# 2. Make changes (edit files in main project)
# Review safeguards before changes

# 3. Cursor: Postflight
bash scripts/postflight.sh

# 4. Commit if needed
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git add . && git commit -m 'chore: Infrastructure update' && \
  git push"

# 5. Create report
# Document in reports/
```

---

## Part 7: Quick Reference

### 7.1 Connection Commands

**Cursor**:
```bash
cursor --remote ssh-remote+comzis@100.83.222.69 /home/comzis/.cursor/projects/home-comzis-inlock
```

**Antigravity**:
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

### 7.2 Key Scripts (Cursor)

```bash
# Preflight (before changes)
bash scripts/preflight.sh

# Postflight (after changes)
bash scripts/postflight.sh

# Check subdomains
bash scripts/check_subdomains.sh

# Diagnose HTTPS
bash scripts/diagnose_https.sh
```

### 7.3 Git Commands (Remote)

```bash
# Switch branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout <branch> && git pull"

# Check current branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git branch --show-current"

# List branches
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git branch -a"
```

---

## Summary

**Cursor** = Infrastructure management, safeguards, operational procedures
**Antigravity** = Feature development, testing, code changes

**Key Principle**: Cursor manages infrastructure safety, Antigravity develops features. They work together by:
1. Cursor ensures infrastructure is safe before/after changes
2. Antigravity develops features in isolation on branches
3. Changes merge to main after testing
4. Infrastructure changes are always verified with Cursor safeguards

This workflow ensures safe infrastructure while enabling rapid feature development.
