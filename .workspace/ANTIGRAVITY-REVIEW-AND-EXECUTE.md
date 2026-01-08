# Antigravity Prompt: Review and Execute Security Recommendations

**Copy and paste this entire prompt to Antigravity:**

---

```markdown
You are tasked with reviewing and executing security recommendations for the Inlock AI infrastructure project. Please follow the Git workflow and contributing guidelines strictly.

### Project Context

- **Repository**: `git@github.com:comzis/inlock-ai-mvp.git`
- **Working Directory**: `/home/comzis/inlock`
- **Current Branch**: Check with `git branch --show-current`
- **Documentation**: 
  - Git Workflow: `/home/comzis/inlock/docs/GIT-WORKFLOW.md`
  - Contributing Guidelines: `/home/comzis/inlock/CONTRIBUTING.md`
  - Security Audit Fixes: `/home/comzis/inlock/docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md`
  - Antigravity Rules: `/home/comzis/antigravity/antigravity-rules.md`

### Task Description

**Review Security Audit Recommendations and Execute Pending Items**

1. **Review the security audit fixes document** at `/home/comzis/inlock/docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md`
2. **Identify remaining recommendations** that have not been implemented
3. **Execute pending recommendations** following security best practices
4. **Document all changes** with proper commit messages
5. **Verify no secrets** are committed before pushing

### Review Checklist

**Review the following areas:**

1. ✅ **Security Audit Fixes Status** (`docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md`)
   - Check which items are marked as fixed (✅)
   - Identify items marked as "Action Required" or "Recommendation"
   - Note any remaining TODO items

2. **Credential Rotation** (if applicable)
   - Review if any secrets in `env.example` or documentation were ever real credentials
   - If yes, document rotation steps needed
   - Check git history for exposed credentials (if needed)

3. **Remove "Update to Latest" Scripts**
   - Search for scripts that automatically update Docker images to `:latest`
   - Review and remove or disable such scripts
   - Document why they're removed

4. **Verify Current Security Posture**
   - Check all scripts for token leakage (should redact sensitive output)
   - Verify Docker image versions are pinned (SHA256 digests preferred)
   - Verify no `:latest` tags in production compose files
   - Check lockfiles exist for Node.js projects
   - Verify Ansible collections are pinned to exact versions

5. **Documentation Updates**
   - Ensure security implications are documented in Traefik configs
   - Verify security best practices are documented
   - Update documentation if any changes are made

### Execution Requirements

1. **Follow Git Workflow** (`docs/GIT-WORKFLOW.md`):
   - Create appropriate branch: `security/` or `chore/` prefix recommended
   - Use Conventional Commits format
   - Never commit secrets, keys, or credentials

2. **Branch Creation**:
   ```bash
   cd /home/comzis/inlock
   git checkout main && git pull origin main
   git checkout -b security/audit-recommendations
   # OR for chores: git checkout -b chore/security-improvements
   ```

3. **Pre-Commit Security Check** (CRITICAL):
   ```bash
   # ALWAYS check for secrets before committing
   git diff --cached | grep -i "password\|secret\|key\|token"
   
   # If found, DO NOT COMMIT - use environment variables or Docker secrets instead
   ```

4. **Commit Format**: Use `security:` prefix for security-related changes
   ```
   security: Remove auto-update scripts to prevent drift
   security: Document security tradeoffs in Traefik config
   chore: Review and clean up legacy update scripts
   ```

5. **Testing** (if applicable):
   ```bash
   # Validate Docker Compose configs
   docker compose -f compose/services/stack.yml config
   
   # Check for syntax errors in scripts
   find scripts/ -name "*.sh" -exec bash -n {} \;
   ```

### Specific Actions to Review/Execute

#### 1. Review "Update to Latest" Scripts

**Action:**
```bash
# Search for scripts that update to latest
cd /home/comzis/inlock
grep -r "latest" scripts/ --include="*.sh" | grep -i "update\|pull\|upgrade"
grep -r ":latest" compose/ --include="*.yml" | grep -v "local\|dev"

# Review each found script and either:
# - Remove if dangerous (update all to latest)
# - Disable with clear comments explaining why
# - Document if acceptable (local dev only)
```

**If found:**
- Document the risk
- Remove or disable the script
- Commit with: `security: Remove dangerous auto-update script`

#### 2. Verify Credential Safety

**Action:**
```bash
# Check env.example for placeholder-only values
cat /home/comzis/inlock/.env.example | grep -i "secret\|token\|key\|password"

# Verify all are clear placeholders, not real credentials
# If any look suspicious, document for rotation review
```

#### 3. Verify Image Pinning

**Action:**
```bash
# Check production compose files for :latest tags
find /home/comzis/inlock/compose -name "*.yml" -exec grep -l ":latest" {} \;

# Should only find docker-compose.local.yml (local dev is OK)
# If others found, pin to specific version or SHA256 digest
```

#### 4. Verify Lockfiles

**Action:**
```bash
# Check all Node.js projects have lockfiles
find /home/comzis/inlock -name "package.json" -exec dirname {} \; | while read dir; do
  if [ ! -f "$dir/package-lock.json" ] && [ ! -f "$dir/yarn.lock" ] && [ ! -f "$dir/pnpm-lock.yaml" ]; then
    echo "Missing lockfile in: $dir"
  fi
done

# Generate lockfiles for any missing (if needed)
```

#### 5. Verify Ansible Collection Pinning

**Action:**
```bash
# Check ansible/requirements.yml uses exact versions, not ranges
cat /home/comzis/inlock/ansible/requirements.yml | grep "version:"

# Should see exact versions like "12.1.0", not ranges like ">=7.0.0"
```

### Expected Deliverables

1. ✅ **Review report** of current security audit status
2. ✅ **Action items** identified (if any remaining)
3. ✅ **Changes implemented** for any pending recommendations
4. ✅ **Documentation updated** (if needed)
5. ✅ **Committed changes** with proper commit messages using `security:` or `chore:` prefix
6. ✅ **Branch pushed** to remote for PR
7. ✅ **No sensitive data committed** (verified with security check)

### Commit Message Examples

```
security: Remove auto-update script that could introduce drift
security: Document insecureSkipVerify security implications
chore: Review and disable legacy update automation
docs: Update security audit status with completed items
security: Verify no :latest tags in production compose files
```

### Files to Review

- `/home/comzis/inlock/docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md` - Main audit document
- `/home/comzis/inlock/.env.example` - Check for placeholder-only values
- `/home/comzis/inlock/compose/` - Check for :latest tags
- `/home/comzis/inlock/scripts/` - Search for dangerous update scripts
- `/home/comzis/inlock/ansible/requirements.yml` - Verify exact version pinning
- `/home/comzis/inlock/e2e/package-lock.json` - Verify lockfile exists

### Security Checklist (Before Every Commit)

- [ ] No secrets/credentials in diff: `git diff --cached | grep -i "password\|secret\|key\|token"`
- [ ] Docker Compose configs are valid: `docker compose config`
- [ ] Image versions are pinned (SHA256 for production)
- [ ] Lockfiles exist for Node.js projects
- [ ] Ansible collections use exact versions
- [ ] Security implications documented

### Execution Steps

1. **Read** `/home/comzis/inlock/docs/security/SECURITY-AUDIT-FIXES-2026-01-06.md`
2. **Check current branch**: `git branch --show-current`
3. **Create branch** if not already on appropriate branch
4. **Review** each recommendation in the audit document
5. **Identify** pending items (not marked ✅)
6. **Execute** pending recommendations one by one
7. **Test** changes (validate compose configs, check scripts)
8. **Verify** no secrets before each commit
9. **Commit** with appropriate conventional commit format
10. **Push** branch for PR when complete

**Start execution by**: Reading the security audit fixes document, then systematically reviewing and executing each pending recommendation.
```

---

## How to Use This Prompt

1. **Copy the entire markdown block** above (from the first ``` to the last ```)
2. **Paste** directly into Antigravity
3. **Antigravity will**:
   - Review the security audit fixes document
   - Identify pending recommendations
   - Execute them following Git workflow
   - Commit with proper security: prefix
   - Push for PR review

---

*Ready to use - copy and paste to Antigravity to execute security recommendations!*
