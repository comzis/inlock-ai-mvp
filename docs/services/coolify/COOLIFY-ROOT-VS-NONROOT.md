# Coolify: Root vs Non-Root User Decision

**Date:** 2025-12-28  
**Status:** Decision Needed

---

## The Situation

Coolify's validation is failing because it requires passwordless sudo access, and based on research:

1. **Coolify is designed for root user** - This is the recommended approach
2. **Non-root user is experimental** - Requires `NOPASSWD: ALL` (full passwordless sudo)
3. **Even with full NOPASSWD: ALL, users report issues** with non-root users

---

## Option 1: Use Root User (Recommended by Coolify)

### Pros
- ✅ Fully supported and tested by Coolify
- ✅ No sudo configuration needed
- ✅ Most reliable and stable
- ✅ Coolify's official recommendation

### Cons
- ⚠️ Root login enabled (but with key-only authentication)
- ⚠️ Less secure than non-root user

### Security Measures if Using Root
- ✅ Root login only via SSH key (password disabled)
- ✅ Key-only authentication (prohibit-password)
- ✅ Tailscale network only (internal access)
- ✅ Firewall restrictions in place

### Implementation
We have a script ready: `scripts/infrastructure/enable-root-for-coolify.sh`

---

## Option 2: Use Non-Root User (Experimental)

### Pros
- ✅ More secure (no root login)
- ✅ Better audit trail
- ✅ Aligns with security best practices

### Cons
- ⚠️ **Requires `NOPASSWD: ALL`** (full passwordless sudo - security risk)
- ⚠️ Experimental feature in Coolify
- ⚠️ Users report issues and failures
- ⚠️ Not officially recommended

### What's Required
```bash
# In /etc/sudoers.d/coolify-comzis
comzis ALL=(ALL) NOPASSWD: ALL
```

This is **less secure** than limited sudo commands, but Coolify may need it.

---

## Recommendation

Based on Coolify's design and documentation, **Option 1 (Root User) is recommended** because:

1. Coolify is designed for root access
2. Non-root is experimental and problematic
3. With key-only root access, the security risk is manageable
4. It's the most reliable option

---

## Next Steps

**If choosing Root:**
```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/enable-root-for-coolify.sh
```

**If choosing Non-Root (full NOPASSWD):**
We can create a script with `NOPASSWD: ALL` instead of limited commands.

---

## Your Decision

Which do you prefer?
1. **Root user** (recommended by Coolify, more reliable)
2. **Non-root with NOPASSWD: ALL** (experimental, less reliable)

