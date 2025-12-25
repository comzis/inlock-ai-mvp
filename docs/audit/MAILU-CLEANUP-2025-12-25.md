# Mailu Cleanup Report

**Date:** December 25, 2025  
**Purpose:** Remove legacy Mailu references after migration to Mailcow

---

## Summary

Mailu has been replaced by Mailcow as the production mail server. This cleanup removes legacy Mailu references from the repository.

---

## ✅ Completed Cleanup

### 1. Configuration Files
- ✅ Removed `compose/config/roundcube-smtp-config.inc.php` (Mailu-specific)

### 2. Cursor Rules
- ✅ Updated `.cursorrules`:
  - Removed Mailu example from duplicate configs rule
  - Removed `mailu-admin-patched` example from Docker persistence
  - Removed `mailu` from config subdirectories list

### 3. Environment Template
- ✅ Updated `env.example`:
  - Removed entire Mailu configuration section
  - Added note pointing to Mailcow deployment docs

### 4. N8N Workflows
- ✅ Updated `compose/n8n/workflows/n8n-mas-health-check.json`:
  - Renamed "Check Mailu" → "Check Mailcow"
  - Updated URL from `/webmail/` to root (Mailcow UI)
  - Updated JavaScript code references
  - Updated email report text

- ✅ Updated `compose/n8n/workflows/n8n-health-check-workflow.json`:
  - Updated SMTP setup instructions (Mailu → Mailcow)

---

## ⚠️ Manual Cleanup Required

The following directories have permission issues (owned by root) and require manual cleanup:

### Directories to Remove
```bash
sudo rm -rf compose/mailu
sudo rm -rf compose/services/config/dovecot.conf
sudo rm -rf compose/services/config/nginx-front.conf
```

**Note:** These directories are empty or contain only legacy Mailu configuration files that are no longer needed.

---

## 📋 Documentation References

The following documentation files still contain Mailu references for historical context:

### Historical References (Keep)
- `docs/deployment/MAILCOW-DEPLOYMENT.md` - Mentions Mailu was replaced (appropriate)
- `docs/audit/CURSOR-RULES-COMPLIANCE-AUDIT-2025-12-25.md` - Documents cleanup (appropriate)
- Various architecture/docs mentioning Mailu in historical context

**Action:** No changes needed - these are appropriate historical references.

### Workflow References
- `compose/n8n/workflows/restore_workflow.sql` - Contains Mailu references in SQL backup
  - **Action:** Update when workflow is restored/imported to n8n

---

## ✅ Verification

After cleanup, verify:
1. No active Mailu compose files remain
2. No Mailu-specific configs in use
3. All workflows reference Mailcow
4. Documentation accurately reflects Mailcow as production mail stack

---

## 📝 Notes

- Mailcow is deployed at `/home/comzis/mailcow` (outside repository)
- Mailcow uses `BLF-CRYPT` password scheme (Dovecot-compatible)
- All mail functionality now handled by Mailcow
- Legacy Mailu directories can be safely removed after permission fix

---

**Last Updated:** December 25, 2025  
**Status:** ✅ Cleanup Complete (pending manual permission fixes)

