# Contributing to Inlock AI Infrastructure

Thank you for your interest in contributing! This document provides guidelines and best practices for contributing to this project.

## Getting Started

1. **Fork the Repository** (if applicable)
2. **Clone Locally**:
   ```bash
   git clone git@github.com:comzis/inlock-ai-mvp.git
   cd inlock
   ```

3. **Set Up Your Environment**:
   - Ensure Docker and Docker Compose are installed
   - Copy `.env.example` to `.env` and configure (never commit `.env`)
   - Review the [Git Workflow](docs/GIT-WORKFLOW.md) documentation

## Development Workflow

### 1. Create a Feature Branch

Always create a feature branch from `main`:

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

**Branch Naming:**
- `feature/<name>` - New features
- `bugfix/<name>` - Bug fixes
- `hotfix/<name>` - Urgent production fixes
- `docs/<name>` - Documentation updates
- `refactor/<name>` - Code refactoring
- `chore/<name>` - Maintenance tasks

### 2. Make Your Changes

- Write clear, maintainable code
- Follow existing code style and patterns
- Add/update documentation as needed
- Update tests if applicable

### 3. Commit Your Changes

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
git add .
git commit -m "feat: Add Antigravity testing support"
```

**Commit Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style (formatting, etc.)
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `security:` - Security-related changes

### 4. Push and Create Pull Request

```bash
git push -u origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title following commit message format
- Detailed description of changes
- Reference to related issues (if any)
- Testing notes

### 5. Testing

Before creating a PR, ensure:
- ✅ All services start correctly
- ✅ No configuration errors
- ✅ Documentation is updated
- ✅ No sensitive data is committed

```bash
# Test deployment
docker compose -f compose/services/stack.yml config
docker compose -f compose/services/stack.yml up -d

# Check logs
docker compose logs

# Verify no secrets in diff
git diff main..HEAD | grep -i "password\|secret\|key\|token"
```

## Code Standards

### Security

- **Never commit secrets, keys, or credentials**
- Use Docker secrets or environment variables
- Check `git diff` before committing
- Redact sensitive information in logs

### Docker Compose

- Pin image versions (use SHA256 digests for production)
- Use absolute paths for `env_file`
- Document all environment variables

### Configuration Files

- Use consistent YAML formatting
- Add comments for complex configurations
- Document security implications

### Scripts

- Use `#!/bin/bash` shebang
- Add error handling
- Redact sensitive output
- Include usage documentation

## Pull Request Guidelines

### PR Title
Follow conventional commit format:
```
feat: Add Antigravity testing branch
fix: Resolve n8n encryption key mismatch
```

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Security fix

## Testing
- [ ] Tested locally
- [ ] Verified no secrets committed
- [ ] Checked service health
- [ ] Updated documentation

## Checklist
- [ ] Code follows project style
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
```

## Review Process

1. **Self-Review**: Review your own PR before requesting review
2. **Wait for Review**: All PRs require at least one approval
3. **Address Feedback**: Respond to review comments
4. **Merge**: Once approved, squash merge into `main`

## Antigravity Workspace Integration

When working with Antigravity workspace artifacts:

```bash
# Copy artifacts from Antigravity brain
cp ~/.gemini/antigravity/brain/<id>/*.md .workspace/

# Commit workspace updates
git add .workspace/
git commit -m "docs: Update Antigravity workspace artifacts"
```

## Questions?

- Review [Git Workflow](docs/GIT-WORKFLOW.md) for detailed branching strategy
- Check existing documentation in `docs/`
- Review previous PRs for examples

## Code of Conduct

- Be respectful and professional
- Provide constructive feedback
- Focus on code, not individuals
- Maintain security best practices

---

*Thank you for contributing!*
