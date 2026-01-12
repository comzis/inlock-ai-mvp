# Antigravity Workflow Guide

**Complete guide for using Antigravity with Cursor for Inlock AI development.**

---

## Quick Start

1. **Read the Cursor workflow guide first**: `@docs/cursor-workflow-guide.md`
   - This document explains how Cursor and Antigravity work together
   - Understand the tool roles and combined workflows

2. **For branch-specific workflows**: `@docs/antigravity-git-branch-workflow.md`
   - How to switch branches before connecting
   - Branch management strategies

3. **For Git workflow**: `@docs/GIT-WORKFLOW.md`
   - Branch naming conventions
   - Commit message format
   - PR process

---

## Overview

Antigravity is used for **feature development and testing**, while Cursor handles **infrastructure management and safeguards**.

### Tool Roles

- **Antigravity**: Feature development, code changes, testing (main project repository)
- **Cursor**: Infrastructure safeguards, health checks, operational procedures (control workspace)

**Important**: Always coordinate with Cursor workflow for infrastructure-impacting changes.

---

## Connection

### Basic Connection

```bash
# Connect to main project (current branch)
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

### Working with Branches

**Antigravity connects to whatever branch is checked out on the remote server.**

**To work on a specific branch**:

1. Switch branch first:
   ```bash
   ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout <branch-name> && git pull"
   ```

2. Then connect:
   ```bash
   /Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
   ```

See `docs/antigravity-git-branch-workflow.md` for detailed branch workflows.

---

## Development Workflow

### 1. Feature Development

**Step 1: Create/Checkout Branch**
```bash
# Create new feature branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout main && git pull && \
  git checkout -b feature/my-feature"

# Or checkout existing branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout feature/my-feature && git pull"
```

**Step 2: Connect Antigravity**
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

**Step 3: Develop Feature**
- Ask Antigravity to implement features
- Reference documentation: `@docs/cursor-workflow-guide.md`
- Follow project conventions and patterns

**Step 4: Commit Changes**
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git add . && \
  git commit -m 'feat: Description of feature' && \
  git push -u origin feature/my-feature"
```

**Step 5: Create Pull Request**
- Go to GitHub: `https://github.com/comzis/inlock-ai-mvp/pulls`
- Create PR: base `main` ← compare `feature/my-feature`
- Fill in description and request review

### 2. Testing Workflow

**Use dedicated test branch for testing**:

```bash
# Switch to test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git checkout antigravity/test-features && git pull"

# Merge feature into test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git merge feature/my-feature && git push"

# Connect Antigravity to test branch
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

**Then test the feature** with Antigravity's help.

---

## Important Rules and Guidelines

### Infrastructure-Impacting Changes

**If your feature affects infrastructure** (certificates, services, Docker Compose, Traefik, DNS):

1. **Read Cursor workflow**: `@docs/cursor-workflow-guide.md`
2. **Check safeguards**: Ask about certificate and service safeguards
3. **Coordinate with Cursor workflow**:
   - Preflight checks must run (Cursor control workspace)
   - Postflight checks must run (Cursor control workspace)
   - Protected values must not be changed

### Protected Values (NEVER Change Without Verification)

- **Positive SSL certificate** (inlock.ai, www.inlock.ai)
- **Coolify DB_PASSWORD** (must have default fallback)
- **Grafana domain** (must be hardcoded, NOT `${DOMAIN}`)
- **Traefik router TLS configs** (inlock.ai/www.inlock.ai use Positive SSL)

If you need to change infrastructure, coordinate with Cursor workflow first.

### Code Changes

- Follow project conventions and patterns
- Use TypeScript for new code
- Write tests for new features
- Follow commit message format: `feat:`, `fix:`, `docs:`, etc.
- See `docs/GIT-WORKFLOW.md` for conventions

---

## Documentation References

When working with Antigravity, reference these documents:

1. **Cursor Workflow Guide**: `@docs/cursor-workflow-guide.md`
   - Complete workflow for Cursor + Antigravity
   - Infrastructure safeguards
   - Combined workflows

2. **Antigravity Git Branch Workflow**: `@docs/antigravity-git-branch-workflow.md`
   - Branch management
   - Switching branches
   - Branch-specific workflows

3. **Git Workflow**: `@docs/GIT-WORKFLOW.md`
   - Branch naming conventions
   - Commit message format
   - PR process

4. **Project README**: `README.md`
   - Project overview
   - Quick start
   - Core documentation links

---

## Common Prompts for Antigravity

### Starting Work

```
Read @docs/cursor-workflow-guide.md to understand the workflow with Cursor, then help me develop feature X.
```

```
I'm working on feature/my-feature branch. Read @docs/antigravity-git-branch-workflow.md and help me implement feature X.
```

### Infrastructure Concerns

```
This feature might affect infrastructure. Read @docs/cursor-workflow-guide.md and check if we need to coordinate with Cursor workflow for any safeguards.
```

### Code Changes

```
Follow the patterns in this codebase and implement feature X. Reference @docs/GIT-WORKFLOW.md for commit message format.
```

### Testing

```
Help me test this feature. We're on the antigravity/test-features branch. See @docs/antigravity-git-branch-workflow.md for branch workflow.
```

---

## Best Practices

1. **Always read relevant docs first**: Use `@docs/filename.md` to reference documentation
2. **Work on feature branches**: Never develop directly on `main`
3. **Commit frequently**: Use clear commit messages
4. **Check infrastructure impact**: Use Cursor workflow guide to verify
5. **Test on dedicated branch**: Use `antigravity/test-features` for testing
6. **Create PRs**: Always create PRs for code review
7. **Follow conventions**: Use project patterns and conventions

---

## Quick Reference

### Connection Command
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

### Switch Branch
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout <branch> && git pull"
```

### Check Current Branch
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git branch --show-current"
```

### Commit and Push
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && \
  git add . && git commit -m 'feat: Description' && git push"
```

---

## Summary

- **Antigravity** = Feature development and testing
- **Cursor** = Infrastructure management and safeguards
- **Work together**: Use Cursor workflow guide to coordinate infrastructure-impacting changes
- **Documentation**: Always reference relevant docs with `@docs/filename.md`
- **Branches**: Work on feature branches, test on test branch, merge via PR

For complete workflow details, see: `@docs/cursor-workflow-guide.md`

---

## Deployment Protocol (CRITICAL)

To prevent deployment failures, strictly follow these rules:

### 1. Source of Truth
*   **Workspace**: `/home/comzis/projects/inlock-ai-mvp`
*   **App Source**: All application code modifications must be committed to `apps/inlock-ai`. The deployment script expects this structure.
*   **Do NOT** modify files directly in `/opt/inlock-ai-secure-mvp`. That is a deployment target, not a workspace.

### 2. Production Services
*   **Stack Configuration**: Production services are defined in `compose/services/stack.yml`.
*   **Service Name**: `inlock-ai` (part of the `services` stack).
*   **Do NOT** use `compose/services/inlock-ai.yml` standalone for production updates. It lacks dependencies.

### 3. Deployment Commands
**Manual Update (Fallback)**:
If the automated script fails, use this exact command sequence to update the production service:
```bash
cd /home/comzis/projects/inlock-ai-mvp/compose/services
docker compose -p services -f stack.yml up -d --force-recreate inlock-ai
```
