# Antigravity Test Branch Prompt Template

**Copy and paste this prompt to Antigravity for testing features:**

---

```markdown
You are tasked with testing new features on the Antigravity test branch for the Inlock AI infrastructure project. Please follow the Git workflow and contributing guidelines strictly.

### Project Context

- **Repository**: `git@github.com:comzis/inlock-ai-mvp.git`
- **Working Directory**: `/home/comzis/inlock`
- **Test Branch**: `antigravity/test-features`
- **Documentation**: 
  - Git Workflow: `/home/comzis/inlock/docs/GIT-WORKFLOW.md`
  - Contributing Guidelines: `/home/comzis/inlock/CONTRIBUTING.md`
  - Test Branch Guide: `/home/comzis/inlock/.workspace/ANTIGRAVITY-TEST-BRANCH.md`
  - Antigravity Rules: `/home/comzis/antigravity/antigravity-rules.md`

### Task Description

**Test New Feature on Antigravity Test Branch**

1. **Switch to test branch** (`antigravity/test-features`)
2. **Sync with main** (pull latest changes)
3. **Implement feature** following project standards
4. **Test thoroughly** before considering merge
5. **Document changes** with proper commit messages

### Feature to Test

**[DESCRIBE THE FEATURE TO TEST HERE]**

### Requirements

1. **Use Test Branch**: Work on `antigravity/test-features`, not main
   ```bash
   cd /home/comzis/inlock
   git checkout antigravity/test-features
   git pull origin main
   git merge main  # Ensure up-to-date
   ```

2. **Follow Git Workflow** (`docs/GIT-WORKFLOW.md`):
   - Use Conventional Commits format
   - Never commit secrets, keys, or credentials
   - Keep commits focused and clear

3. **Pre-Commit Security Check** (CRITICAL):
   ```bash
   # ALWAYS check for secrets before committing
   git diff --cached | grep -i "password\|secret\|key\|token"
   
   # If found, DO NOT COMMIT - use environment variables or Docker secrets instead
   ```

4. **Commit Format**: Use appropriate prefix
   ```
   feat: Description of new feature
   fix: Description of bug fix
   test: Description of test changes
   ```

5. **Testing Checklist**:
   - [ ] Services start successfully
   - [ ] No errors in Docker logs
   - [ ] Features work as expected
   - [ ] No breaking changes to existing functionality
   - [ ] Security checks pass
   - [ ] Documentation updated (if needed)

### Testing Steps

1. **Sync Branch**:
   ```bash
   git checkout antigravity/test-features
   git pull origin main
   git merge main
   ```

2. **Implement Feature**:
   - Make your changes
   - Follow existing patterns
   - Add comments for complex logic

3. **Verify Security**:
   ```bash
   git diff --cached | grep -i "password\|secret\|key\|token"
   # Should be empty
   ```

4. **Test Deployment**:
   ```bash
   # Validate Docker Compose configs
   docker compose -f compose/services/stack.yml config
   
   # Deploy and test
   docker compose -f compose/services/stack.yml up -d
   
   # Check service health
   docker compose -f compose/services/stack.yml ps
   
   # Review logs
   docker compose -f compose/services/stack.yml logs --tail 50
   ```

5. **Commit and Push**:
   ```bash
   git add .
   git commit -m "feat: Description of feature"
   git push origin antigravity/test-features
   ```

### Expected Deliverables

1. ✅ **Feature implemented** on test branch
2. ✅ **Tested thoroughly** (services working, no errors)
3. ✅ **Committed changes** with proper commit messages
4. ✅ **Pushed to remote** for review
5. ✅ **No sensitive data committed** (verified)
6. ✅ **Documentation updated** (if applicable)

### Testing Checklist

- [ ] Branch synced with main
- [ ] Feature implemented correctly
- [ ] No secrets committed
- [ ] Docker Compose configs valid
- [ ] Services start successfully
- [ ] No errors in logs
- [ ] Features work as expected
- [ ] Existing functionality not broken
- [ ] Documentation updated (if needed)
- [ ] Ready for PR or merge to main

### After Testing

**If Tests Pass:**
- Create PR from `antigravity/test-features` to `main`
- Or merge directly if approved
- Document any deployment steps needed

**If Tests Fail:**
- Fix issues on test branch
- Re-test until passing
- Document any issues found

**Start execution by**: Switching to test branch, syncing with main, then implementing the feature.
```

---

## Quick Copy Instructions

1. **Copy the markdown block above** (from the first ``` to the last ```)
2. **Replace** `[DESCRIBE THE FEATURE TO TEST HERE]` with your feature description
3. **Paste** to Antigravity and execute

## Branch Information

- **Branch Name**: `antigravity/test-features`
- **Purpose**: Testing features before merge to main
- **Workflow**: Test → Verify → PR/Merge to main

---

*Ready to use - copy and paste to Antigravity for feature testing!*
