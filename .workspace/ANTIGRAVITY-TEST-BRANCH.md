# Antigravity Test Branch - Usage Guide

## Branch Purpose

**Branch:** `antigravity/test-features`  
**Purpose:** Dedicated branch for Antigravity to test new features and changes before merging to main

## Workflow

### For Antigravity Testing

1. **Start from Main**: Always ensure branch is up-to-date with main
   ```bash
   git checkout antigravity/test-features
   git pull origin main
   git merge main  # or git rebase main
   ```

2. **Test Features**: Make changes and test them
   ```bash
   # Make your changes...
   git add .
   git commit -m "feat: Add new feature for testing"
   ```

3. **Test in Environment**: Deploy and test changes
   ```bash
   docker compose -f compose/services/stack.yml up -d
   # Test functionality...
   ```

4. **Verify**: Ensure everything works correctly
   - Services start successfully
   - No errors in logs
   - Features work as expected
   - No security issues

5. **When Ready for Main**:
   - Create PR from `antigravity/test-features` to `main`
   - Or merge directly if approved

### Branch Management

**Branch Protection:**
- This branch is for testing only
- Changes should be tested before merging to main
- Regular sync with main is recommended

**Cleanup:**
- After features are merged to main, reset branch to main:
  ```bash
  git checkout antigravity/test-features
  git reset --hard main
  git push origin antigravity/test-features --force
  ```

## Usage Guidelines

1. **Always test before merge**
2. **Follow Git workflow** (`docs/GIT-WORKFLOW.md`)
3. **Use Conventional Commits**
4. **Verify no secrets** before committing
5. **Document changes** clearly

## Quick Start for Antigravity

```bash
# Switch to test branch
cd /home/comzis/inlock
git checkout antigravity/test-features
git pull origin main
git merge main

# Make and test your changes
# ... implement feature ...

# Commit and test
git add .
git commit -m "feat: Description of feature"
git push origin antigravity/test-features

# Test in environment
docker compose -f compose/services/stack.yml up -d
# ... verify functionality ...

# When ready, create PR or merge to main
```

---

*This branch is dedicated to Antigravity for testing features before production deployment.*
