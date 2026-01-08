# Example Antigravity Task Prompt

This is a ready-to-use example prompt you can copy and provide to Antigravity for task execution.

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

**[REPLACE WITH YOUR TASK DESCRIPTION]**

Example tasks:
- Add new service to Docker Compose stack
- Fix service configuration issue
- Update documentation for deployment process
- Refactor configuration structure
- Add monitoring or health checks

### Requirements

1. **Follow Git Workflow** (`docs/GIT-WORKFLOW.md`):
   - ✅ Create appropriate branch: `feature/`, `bugfix/`, `hotfix/`, `docs/`, `refactor/`, or `chore/`
   - ✅ Use Conventional Commits format: `feat:`, `fix:`, `docs:`, etc.
   - ✅ Keep branches focused on single task
   - ✅ Never commit secrets, keys, or credentials

2. **Branch Creation**:
   ```bash
   # Ensure you're on main and up to date
   cd /home/comzis/inlock
   git checkout main
   git pull origin main
   
   # Create appropriate branch (e.g., feature/task-name, bugfix/issue-name)
   git checkout -b <branch-type>/<descriptive-name>
   ```

3. **Implementation Checklist**:
   - [ ] Follow existing code patterns and style
   - [ ] Update documentation as needed
   - [ ] Add comments for complex logic
   - [ ] Check for sensitive data before committing
   - [ ] Pin Docker image versions (SHA256 digests for production)
   - [ ] Use absolute paths for `env_file` in Docker Compose

4. **Pre-Commit Security Check**:
   ```bash
   # Verify no secrets/credentials in diff
   git diff --cached | grep -i "password\|secret\|key\|token"
   
   # If found, DO NOT COMMIT - use environment variables or Docker secrets instead
   ```

5. **Commit Message Format** (Conventional Commits):
   ```
   <type>: <short description>
   
   <optional detailed explanation>
   <optional reference to issues>
   ```

   **Commit Types**:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style (formatting)
   - `refactor:` - Code refactoring
   - `perf:` - Performance improvements
   - `test:` - Adding/updating tests
   - `chore:` - Maintenance tasks
   - `security:` - Security-related changes

6. **Testing** (if applicable):
   ```bash
   # Validate Docker Compose configs
   docker compose -f compose/services/stack.yml config
   
   # Check service health (if services are running)
   docker compose ps
   docker compose logs
   ```

7. **Push and Prepare Pull Request**:
   ```bash
   # Push branch to remote
   git push -u origin <branch-name>
   ```

8. **Pull Request Requirements**:
   - **Title**: Follow commit message format (e.g., `feat: Add monitoring health checks`)
   - **Description**: 
     - Detailed explanation of changes
     - Reference to related issues (if any)
     - Testing notes
     - Checklist from CONTRIBUTING.md
   - **Type**: Feature, Bug Fix, Documentation, etc.

### Security Requirements

**CRITICAL - NEVER COMMIT**:
- ❌ Environment files (`.env`, `.env.*`)
- ❌ Secrets directory (`secrets-real/`)
- ❌ Private keys (`.key`, `.pem`, `.crt`)
- ❌ Passwords or tokens in plain text
- ❌ API keys or credentials

**ALWAYS**:
- ✅ Use Docker secrets or environment variables
- ✅ Redact sensitive output in scripts
- ✅ Check `git diff` before committing
- ✅ Verify `.gitignore` excludes sensitive files

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
│   └── auth/           # Auth0 scripts (redact tokens!)
├── docs/               # Documentation
│   ├── GIT-WORKFLOW.md # Git workflow guide
│   └── security/       # Security documentation
└── e2e/                # End-to-end tests
```

### Antigravity Workspace Integration

If creating documentation or artifacts:
1. Work in `/home/comzis/inlock`
2. Copy to `.workspace/` if needed: `cp <file> .workspace/`
3. Commit workspace updates: 
   ```bash
   git add .workspace/
   git commit -m "docs: Update workspace artifacts"
   ```

### Expected Deliverables

1. ✅ Code/config changes (if applicable)
2. ✅ Documentation updates (if applicable)
3. ✅ Committed changes with proper commit messages
4. ✅ Branch pushed to remote (ready for PR)
5. ✅ Testing verification (if applicable)
6. ✅ **No sensitive data committed**

### Execution Steps

1. **Read and understand** the task description above
2. **Review** the Git workflow guide (`docs/GIT-WORKFLOW.md`)
3. **Create branch** from main using appropriate naming
4. **Implement changes** following project standards
5. **Verify security** - check for secrets before committing
6. **Test changes** (if applicable)
7. **Commit** with conventional commit format
8. **Push** branch to remote
9. **Document** any additional steps needed for review

### Questions to Consider Before Starting

- Does this change affect security? → Document risks
- Does this require Docker Compose changes? → Test configs
- Does this need documentation? → Update docs/
- Is this a breaking change? → Document migration steps
- Are dependencies updated? → Pin versions

---

**Start execution by**: Reading the task description, then following the Git workflow step-by-step.
```

---

## How to Use This Example

1. **Copy the prompt above** (the entire markdown block)
2. **Replace** `[REPLACE WITH YOUR TASK DESCRIPTION]` with your actual task
3. **Customize** branch type, commit type, and requirements as needed
4. **Provide** to Antigravity to execute

## Quick Task Template

For quick tasks, you can simplify:

```markdown
### Task: [Brief Description]
**Branch**: [feature|bugfix|docs|chore]/[name]
**Type**: [feat|fix|docs|chore]
**Description**: [Detailed description]

**Steps**:
1. Create branch from main
2. Implement changes
3. Verify no secrets committed
4. Test (if applicable)
5. Commit with conventional format
6. Push to remote

**Files**: [If known]
**Testing**: [What to test]
```

---

*Copy and customize this template for your tasks*
