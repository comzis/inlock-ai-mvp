# Antigravity Task Execution Prompt Template

This document provides a standardized prompt template for Antigravity AI to execute tasks following the Inlock AI infrastructure Git workflow and contributing guidelines.

## Usage

Copy this template, fill in the task details, and provide it to Antigravity to execute tasks consistently with project standards.

---

## Task Execution Prompt for Antigravity

```markdown
You are tasked with executing the following work on the Inlock AI infrastructure project. Please follow the Git workflow and contributing guidelines strictly.

### Project Context

- **Repository**: `git@github.com:comzis/inlock-ai-mvp.git`
- **Working Directory**: `/home/comzis/inlock`
- **Current Branch**: Check with `git branch --show-current`
- **Documentation**: 
  - Git Workflow: `/home/comzis/inlock/docs/GIT-WORKFLOW.md`
  - Contributing Guidelines: `/home/comzis/inlock/CONTRIBUTING.md`

### Task Description

**[DESCRIBE THE TASK HERE]**

### Requirements

1. **Follow Git Workflow** (`docs/GIT-WORKFLOW.md`):
   - Create appropriate branch type: `feature/`, `bugfix/`, `hotfix/`, `docs/`, `refactor/`, or `chore/`
   - Use Conventional Commits format for commit messages
   - Keep branches focused on single task
   - Never commit secrets, keys, or credentials

2. **Branch Creation**:
   ```bash
   # Ensure you're on main and up to date
   git checkout main
   git pull origin main
   
   # Create appropriate branch (e.g., feature/task-name)
   git checkout -b <branch-type>/<descriptive-name>
   ```

3. **Implementation**:
   - Follow existing code patterns and style
   - Update documentation as needed
   - Add comments for complex logic
   - Check for sensitive data before committing

4. **Pre-Commit Checklist**:
   - [ ] Verify no secrets/credentials in diff: `git diff --cached | grep -i "password\|secret\|key\|token"`
   - [ ] Check Docker Compose configs are valid
   - [ ] Ensure image versions are pinned (SHA256 digests preferred)
   - [ ] Update relevant documentation
   - [ ] Test locally if applicable

5. **Commit Message Format**:
   ```
   <type>: <description>
   
   - Detailed explanation if needed
   - Reference related issues if applicable
   ```

   **Types**: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`, `security:`

6. **Testing** (if applicable):
   ```bash
   # Validate Docker Compose configs
   docker compose -f compose/services/stack.yml config
   
   # Check service health
   docker compose ps
   
   # Review logs for errors
   docker compose logs
   ```

7. **Push and Prepare PR**:
   ```bash
   git push -u origin <branch-name>
   ```

8. **Pull Request**:
   - Title: Follow commit message format
   - Description: Detailed explanation of changes
   - Testing: Document what was tested
   - Checklist: Use PR template from CONTRIBUTING.md

### Security Requirements

- **NEVER** commit:
  - Environment files (`.env`, `.env.*`)
  - Secrets directory (`secrets-real/`)
  - Private keys (`.key`, `.pem`, `.crt`)
  - Passwords or tokens in plain text
  
- **ALWAYS**:
  - Use Docker secrets or environment variables
  - Redact sensitive output in scripts
  - Check git diff before committing
  - Verify `.gitignore` excludes sensitive files

### Project Structure Reference

```
inlock/
├── .gitignore          # Git ignore rules
├── .workspace/         # Antigravity workspace artifacts
├── CONTRIBUTING.md     # Contributing guidelines
├── compose/            # Docker Compose files
│   └── services/       # Service definitions
├── traefik/            # Traefik configuration
│   └── dynamic/        # Dynamic configs
├── ansible/            # Ansible playbooks
├── scripts/            # Utility scripts
├── docs/               # Documentation
│   ├── GIT-WORKFLOW.md # Git workflow guide
│   └── security/       # Security documentation
└── e2e/                # End-to-end tests
```

### Antigravity Workspace Integration

If creating documentation or artifacts:
1. Work in `/home/comzis/inlock`
2. Copy to `.workspace/` if needed: `cp <file> .workspace/`
3. Commit workspace updates: `git add .workspace/ && git commit -m "docs: Update workspace artifacts"`

### Expected Deliverables

1. ✅ Code/config changes (if applicable)
2. ✅ Documentation updates (if applicable)
3. ✅ Committed changes with proper commit messages
4. ✅ Branch pushed to remote
5. ✅ Testing verification (if applicable)
6. ✅ No sensitive data committed

### Questions to Consider

- Does this change affect security? (document risks)
- Does this require Docker Compose changes? (test configs)
- Does this need documentation? (update docs/)
- Is this breaking change? (document migration steps)
- Are dependencies updated? (pin versions)

---

**Start by**: Reading the task description above, then execute step-by-step following the Git workflow.
```

---

## Quick Reference Template

For quick tasks, use this simplified version:

```markdown
### Task: [BRIEF DESCRIPTION]

**Branch**: `[feature|bugfix|docs|chore]/[name]`
**Type**: `[feat|fix|docs|chore]`
**Description**: [DETAILED DESCRIPTION]

**Steps**:
1. Create branch from main
2. Implement changes
3. Verify no secrets committed
4. Test (if applicable)
5. Commit with conventional format
6. Push to remote

**Files Changed**: [LIST IF KNOWN]
**Testing**: [WHAT TO TEST]
```

---

## Example Usage

### Example 1: Feature Implementation

```markdown
You are tasked with executing the following work on the Inlock AI infrastructure project...

### Task Description

Add monitoring endpoint health checks to the Traefik configuration.

### Requirements

1. **Branch**: `feature/traefik-health-checks`
2. **Type**: `feat:`
3. **Changes**: Add health check endpoints to Traefik dynamic config
4. **Documentation**: Update docs if new endpoints are exposed

[Continue with full template...]
```

### Example 2: Bug Fix

```markdown
### Task Description

Fix n8n encryption key mismatch error causing container restarts.

### Requirements

1. **Branch**: `bugfix/n8n-encryption-key`
2. **Type**: `fix:`
3. **Priority**: High (service unavailable)
4. **Testing**: Verify n8n container starts successfully

[Continue with full template...]
```

### Example 3: Documentation Update

```markdown
### Task Description

Update deployment documentation with new service configuration steps.

### Requirements

1. **Branch**: `docs/deployment-update`
2. **Type**: `docs:`
3. **Files**: `docs/DEPLOYMENT.md`
4. **Review**: Ensure accuracy with current setup

[Continue with full template...]
```

---

## Integration with Existing Workflow

This prompt template integrates with:
- **Git Workflow** (`docs/GIT-WORKFLOW.md`) - Branching and commit standards
- **Contributing Guidelines** (`CONTRIBUTING.md`) - PR process and code standards
- **Antigravity Workspace** (`.workspace/README.md`) - Artifact management

---

*Last updated: 2026-01-06*
*Template version: 1.0*
