# Antigravity Quick Start Guide

Quick reference for using Antigravity with the Inlock AI infrastructure project.

## Basic Workflow

### 1. Start with the Prompt Template

```bash
# Open the task prompt template
cat /home/comzis/inlock/.workspace/ANTIGRAVITY-TASK-PROMPT.md
```

### 2. Create Task Prompt

Copy the template from `ANTIGRAVITY-TASK-PROMPT.md` and fill in:
- Task description
- Branch type and name
- Commit type
- Requirements
- Testing steps

### 3. Provide to Antigravity

Paste the filled template into Antigravity with:
- Reference to project documentation
- Clear task description
- Checklist of requirements

## Common Tasks

### Feature Development

```markdown
### Task: [Feature Name]
**Branch**: feature/[name]
**Type**: feat:

Steps:
1. git checkout main && git pull
2. git checkout -b feature/[name]
3. Implement feature
4. Test changes
5. git add . && git commit -m "feat: [description]"
6. git push -u origin feature/[name]
```

### Bug Fix

```markdown
### Task: [Bug Description]
**Branch**: bugfix/[name]
**Type**: fix:

Steps:
1. git checkout main && git pull
2. git checkout -b bugfix/[name]
3. Fix issue
4. Verify fix works
5. git add . && git commit -m "fix: [description]"
6. git push -u origin bugfix/[name]
```

### Documentation Update

```markdown
### Task: [Doc Update]
**Branch**: docs/[name]
**Type**: docs:

Steps:
1. git checkout main && git pull
2. git checkout -b docs/[name]
3. Update documentation
4. Review for accuracy
5. git add . && git commit -m "docs: [description]"
6. git push -u origin docs/[name]
```

## Essential Commands

```bash
# Check current status
cd /home/comzis/inlock
git status
git branch --show-current

# Verify no secrets before commit
git diff --cached | grep -i "password\|secret\|key\|token"

# Test Docker Compose
docker compose -f compose/services/stack.yml config

# Check service health
docker compose ps
docker compose logs
```

## Security Checklist

Before committing, verify:
- [ ] No `.env` files in diff
- [ ] No `secrets-real/` files
- [ ] No private keys (`.key`, `.pem`, `.crt`)
- [ ] No hardcoded passwords/tokens
- [ ] Sensitive output redacted in scripts

## Reference Documents

- **Git Workflow**: `/home/comzis/inlock/docs/GIT-WORKFLOW.md`
- **Contributing**: `/home/comzis/inlock/CONTRIBUTING.md`
- **Full Prompt Template**: `/home/comzis/inlock/.workspace/ANTIGRAVITY-TASK-PROMPT.md`

## Antigravity Integration

### Sync Workspace Artifacts

```bash
# After Antigravity creates artifacts
cp ~/.gemini/antigravity/brain/<id>/*.md /home/comzis/inlock/.workspace/

# Commit workspace updates
cd /home/comzis/inlock
git add .workspace/
git commit -m "docs: Update Antigravity workspace artifacts"
git push origin [branch-name]
```

---

*Quick reference - see full template for detailed instructions*
