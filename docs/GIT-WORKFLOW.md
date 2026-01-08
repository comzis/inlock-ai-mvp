# Git Workflow and Branching Strategy

This document outlines the Git workflow and branching strategy for the Inlock AI infrastructure project.

## Branch Naming Conventions

### Branch Types

- **`main`**: Production-ready code. Protected branch.
- **`feature/<name>`**: New features or enhancements (e.g., `feature/antigravity-testing`)
- **`bugfix/<name>`**: Bug fixes (e.g., `bugfix/n8n-encryption-key`)
- **`hotfix/<name>`**: Urgent production fixes (e.g., `hotfix/certificate-expiry`)
- **`docs/<name>`**: Documentation updates (e.g., `docs/api-documentation`)
- **`refactor/<name>`**: Code refactoring without changing functionality
- **`chore/<name>`**: Maintenance tasks, dependency updates (e.g., `chore/update-traefik`)

## Workflow

### Creating a Feature Branch

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create and switch to a new feature branch
git checkout -b feature/your-feature-name

# Work on your changes...

# Stage and commit changes
git add .
git commit -m "feat: Description of your changes"

# Push branch to remote
git push -u origin feature/your-feature-name
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

- **`feat:`**: New feature
- **`fix:`**: Bug fix
- **`docs:`**: Documentation changes
- **`style:`**: Code style changes (formatting, etc.)
- **`refactor:`**: Code refactoring
- **`perf:`**: Performance improvements
- **`test:`**: Adding or updating tests
- **`chore:`**: Maintenance tasks, dependency updates
- **`security:`**: Security-related changes

**Example:**
```
feat: Add Antigravity testing branch workflow
fix: Resolve n8n encryption key mismatch
docs: Update Git workflow documentation
security: Redact tokens from Auth0 API scripts
```

### Pull Request Process

1. **Create PR Branch**: Create a feature branch from `main`
   ```bash
   git checkout -b feature/antigravity-testing
   ```

2. **Make Changes**: Implement your changes and commit them
   ```bash
   git add .
   git commit -m "feat: Add Antigravity testing support"
   ```

3. **Push Branch**: Push to remote repository
   ```bash
   git push -u origin feature/antigravity-testing
   ```

4. **Create Pull Request**: Open a PR on GitHub with:
   - Clear title following commit message format
   - Detailed description of changes
   - Reference to related issues (if any)
   - Testing notes

5. **Review & Testing**: 
   - Wait for code review
   - Ensure all tests pass
   - Test in staging/test environment if applicable

6. **Merge**: Once approved, merge PR into `main`
   - Prefer squash merge for feature branches
   - Delete branch after merge

### Testing Before Deployment

For testing branches like `feature/antigravity-testing`:

1. **Test Environment Setup**:
   ```bash
   # Deploy to test environment
   docker compose -f compose/services/stack.yml up -d
   ```

2. **Verify Changes**:
   - Check service health
   - Test new features
   - Verify security changes
   - Check logs for errors

3. **Update Documentation**:
   - Update relevant docs if behavior changed
   - Document new features

## Best Practices

### 1. Keep Branches Focused
- One branch = one feature/fix
- Avoid mixing unrelated changes

### 2. Regular Sync with Main
```bash
# Regularly sync your branch with main
git checkout feature/your-branch
git fetch origin
git rebase origin/main  # or: git merge origin/main
```

### 3. Clean Commit History
- Use `git rebase -i` to clean up commits before PR
- Squash related commits together
- Write clear, descriptive commit messages

### 4. Protect Sensitive Data
- Never commit secrets, keys, or credentials
- Use `.gitignore` for sensitive files
- Check `git diff` before committing
- Use environment variables or Docker secrets

### 5. Before Pushing
```bash
# Check what you're about to push
git diff origin/main..HEAD

# Check for sensitive data
git diff --cached | grep -i "password\|secret\|key\|token"
```

### 6. Branch Cleanup
```bash
# After merge, delete local branch
git checkout main
git pull origin main
git branch -d feature/your-branch

# Delete remote branch (usually done via GitHub UI)
git push origin --delete feature/your-branch
```

## Antigravity Workflow Integration

For Antigravity workspace artifacts:

1. **Work on Server**: Make changes via SSH
2. **Sync to Git**: Copy artifacts to `.workspace/`
   ```bash
   cp ~/.gemini/antigravity/brain/<id>/*.md /home/comzis/inlock/.workspace/
   ```
3. **Commit Changes**:
   ```bash
   git add .workspace/
   git commit -m "docs: Update Antigravity workspace artifacts"
   ```
4. **Push to Feature Branch**: Push to your feature branch for review

## Emergency Hotfixes

For urgent production fixes:

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/description

# Make fix and commit
git add .
git commit -m "fix: Urgent fix description"

# Push and create PR
git push -u origin hotfix/description

# After merge, backport to feature branches if needed
```

## Repository Structure

```
inlock/
├── .gitignore          # Git ignore rules
├── .workspace/         # Antigravity workspace artifacts
├── compose/            # Docker Compose files
├── traefik/            # Traefik configuration
├── ansible/            # Ansible playbooks
├── scripts/            # Utility scripts
├── docs/               # Documentation
└── e2e/                # End-to-end tests
```

## Useful Git Commands

```bash
# Check current status
git status

# View commit history
git log --oneline --graph --decorate --all

# Find commits by message
git log --grep="n8n"

# View file history
git log --follow -- filename

# Compare branches
git diff main..feature/your-branch

# Stash changes temporarily
git stash
git stash pop

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

---

*Last updated: 2026-01-06*
