# Ready-to-Use Antigravity Prompt

Copy and paste this prompt to Antigravity, replacing `[YOUR TASK HERE]` with your actual task:

---

```markdown
You are tasked with executing the following work on the Inlock AI infrastructure project. Please follow the Git workflow and contributing guidelines strictly.

### Project Context

- **Repository**: `git@github.com:comzis/inlock-ai-mvp.git`
- **Working Directory**: `/home/comzis/inlock`
- **Current Branch**: Check with `git branch --show-current`
- **Documentation**: 
  - Git Workflow: `/home/comzis/inlock/docs/GIT-WORKFLOW.md`
  - Contributing Guidelines: `/home/comzis/inlock/CONTRIBUTING.md`
  - Task Prompt Template: `/home/comzis/inlock/.workspace/ANTIGRAVITY-TASK-PROMPT.md`

### Task Description

[YOUR TASK HERE]

### Requirements

1. **Follow Git Workflow** (`docs/GIT-WORKFLOW.md`):
   - Create appropriate branch: `feature/`, `bugfix/`, `hotfix/`, `docs/`, `refactor/`, or `chore/`
   - Use Conventional Commits format: `feat:`, `fix:`, `docs:`, etc.
   - Never commit secrets, keys, or credentials

2. **Branch Creation**:
   ```bash
   cd /home/comzis/inlock
   git checkout main && git pull origin main
   git checkout -b <branch-type>/<descriptive-name>
   ```

3. **Pre-Commit Security Check**:
   ```bash
   git diff --cached | grep -i "password\|secret\|key\|token"
   ```

4. **Commit Format**: `<type>: <description>`
   - Types: `feat:`, `fix:`, `docs:`, `chore:`, `security:`, etc.

5. **Push and PR**: `git push -u origin <branch-name>`

### Expected Deliverables

1. ✅ Code/config changes (if applicable)
2. ✅ Documentation updates (if applicable)
3. ✅ Committed changes with proper commit messages
4. ✅ Branch pushed to remote (ready for PR)
5. ✅ **No sensitive data committed**

**Start execution by**: Reading the task description, then following the Git workflow step-by-step.
```

---

## Quick Copy Instructions

1. **Copy the markdown block above** (from the first ``` to the last ```)
2. **Replace** `[YOUR TASK HERE]` with your task description
3. **Customize** branch type if needed (feature/bugfix/docs/chore)
4. **Paste** to Antigravity and execute

---

## Example Task

Here's a filled example:

```markdown
### Task Description

Add health check endpoints to Traefik configuration for service monitoring.

### Branch
- Type: `feature`
- Name: `feature/traefik-health-checks`
- Commit: `feat: Add Traefik health check endpoints`

### Testing
- Verify Docker Compose config is valid
- Check Traefik starts correctly
- Verify health endpoints are accessible
```

---

*Ready to use - just copy, customize, and execute!*
