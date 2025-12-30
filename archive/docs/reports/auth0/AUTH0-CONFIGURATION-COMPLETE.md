# Auth0 Configuration - Complete Setup Guide

**Date:** 2025-12-13  
**Status:** ✅ Callback URL Verified → Configuring Remaining Settings

---

## Current Status

✅ **Callback URL:** Verified and present  
⏳ **Web Origins:** Needs configuration  
⏳ **Logout URLs:** Needs configuration  

---

## Step-by-Step Configuration

### Step 1: Configure Web Origins (CORS)

**Field:** Allowed Web Origins (CORS)

**Action:**
1. Find the "Allowed Web Origins (CORS)" field in the application settings
2. If empty, add:
   ```
   https://auth.inlock.ai
   ```
3. If it already has values, add to the list (comma-separated)

**Important Notes:**
- ✅ NO trailing slash
- ✅ Just the base domain: `https://auth.inlock.ai`
- ✅ Required for CORS requests to work

---

### Step 2: Configure Logout URLs

**Field:** Allowed Logout URLs

**Action:**
1. Find the "Allowed Logout URLs" field
2. Paste this entire string (comma-separated, no spaces between commas):

```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

**Or add one URL per line if the field supports it:**

```
https://auth.inlock.ai/oauth2/callback
https://traefik.inlock.ai
https://portainer.inlock.ai
https://grafana.inlock.ai
https://n8n.inlock.ai
https://deploy.inlock.ai
https://dashboard.inlock.ai
https://cockpit.inlock.ai
```

**What These Are For:**
- Allows users to log out from any of these services
- Ensures proper logout redirect behavior
- Supports single sign-out across services

---

### Step 3: Save Changes

**Critical:** After making changes:

1. **Scroll to bottom** of the settings page
2. **Click "Save Changes"** button
3. **Wait for confirmation:**
   - Green success message appears at top of page
   - Message: "Settings updated successfully"
4. **Changes take effect immediately** (no restart needed)

---

## Complete Configuration Summary

### Allowed Callback URLs
```
https://auth.inlock.ai/oauth2/callback
```
✅ **Status:** Verified and present

### Allowed Web Origins (CORS)
```
https://auth.inlock.ai
```
⏳ **Status:** Needs to be configured

### Allowed Logout URLs
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```
⏳ **Status:** Needs to be configured

---

## Field Locations in Auth0 Dashboard

### Quick Reference:

1. **Navigate to:** Applications → Applications → `inlock-admin`
2. **Scroll to Settings section**
3. **Fields appear in this order:**
   - Application Type
   - Token Endpoint Authentication Method
   - Allowed Callback URLs ← **Already verified** ✅
   - Allowed Logout URLs ← **Configure this**
   - Allowed Web Origins ← **Configure this**
   - ... (other settings)

---

## Verification Checklist

After configuration, verify:

- [ ] **Callback URL:** `https://auth.inlock.ai/oauth2/callback` present
- [ ] **Web Origin:** `https://auth.inlock.ai` present (no trailing slash)
- [ ] **Logout URLs:** All 8 service URLs present
- [ ] **Save Changes:** Clicked and confirmed
- [ ] **Success message:** Appeared after save

---

## Troubleshooting

### Issue: Field doesn't accept input
- **Solution:** Make sure you're in edit mode (not read-only)
- **Check:** You have admin permissions

### Issue: Multiple URLs - Format
- **Format:** Comma-separated, no spaces: `url1,url2,url3`
- **Example:** `https://auth.inlock.ai,https://example.com`

### Issue: Changes not saving
- **Check:** Are you on the correct application (`inlock-admin`)?
- **Check:** Do you have admin permissions?
- **Try:** Refresh page and try again

### Issue: Don't see "Allowed Web Origins" field
- **Note:** Some Auth0 applications may have this field named differently
- **Look for:** "CORS", "Web Origins", or "Allowed Origins"
- **If missing:** It may not be required for your application type

---

## After Configuration

Once all fields are configured:

1. ✅ **Document Results:**
   - Update `AUTH0-CALLBACK-VERIFICATION-RESULTS.md`
   - Note all configured URLs

2. ✅ **Test Authentication:**
   - Follow `docs/AUTH0-TESTING-PROCEDURE.md`
   - Verify login/logout works

3. ✅ **Update Status:**
   - Update `AUTH0-FIX-STATUS.md`
   - Mark Auth0 Dashboard configuration as complete

---

## Quick Copy-Paste Values

### For "Allowed Web Origins (CORS)" field:
```
https://auth.inlock.ai
```

### For "Allowed Logout URLs" field:
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

---

**Next Step:** After configuring, click "Save Changes" and report back!

