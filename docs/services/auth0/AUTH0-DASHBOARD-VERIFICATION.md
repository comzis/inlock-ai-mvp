# Auth0 Dashboard Callback URL Verification Guide

**Date:** 2025-12-13  
**Purpose:** Manual verification of Auth0 Dashboard callback URL configuration  
**Priority:** 🔴 **CRITICAL**

## Overview

The OAuth2-Proxy service requires the callback URL to be configured in the Auth0 Dashboard. Without this configuration, authentication will fail after users complete the Auth0 login.

**Required Callback URL:** `https://auth.inlock.ai/oauth2/callback`

## Verification Steps

### Step 1: Access Auth0 Dashboard

1. Navigate to: **https://manage.auth0.com/**
2. Log in with your Auth0 account credentials
3. Select your tenant: `comzis.eu.auth0.com` (if prompted)

### Step 2: Navigate to Application Settings

1. In the left sidebar, click: **Applications** → **Applications**
2. Find and click on the application: **`inlock-admin`**
3. You should see the application settings page

### Step 3: Verify Callback URL Configuration

1. Scroll down to the **Settings** section
2. Find the field: **Allowed Callback URLs**

**Expected Configuration:**
```
https://auth.inlock.ai/oauth2/callback
```

**Verification Checklist:**
- [ ] Callback URL field contains: `https://auth.inlock.ai/oauth2/callback`
- [ ] URL matches exactly (no typos, no trailing slashes)
- [ ] No additional spaces or characters
- [ ] Multiple URLs separated by commas if present

### Step 4: Verify Logout URLs (Optional but Recommended)

1. Find the field: **Allowed Logout URLs**

**Recommended Configuration:**
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

**Verification Checklist:**
- [ ] Logout URLs contain service URLs users may access
- [ ] URLs are comma-separated
- [ ] No trailing slashes

### Step 5: Verify Web Origins (CORS)

1. Find the field: **Allowed Web Origins (CORS)**

**Required Configuration:**
```
https://auth.inlock.ai
```

**Verification Checklist:**
- [ ] Web Origins contains: `https://auth.inlock.ai`
- [ ] No trailing slashes

### Step 6: Save Changes

1. If you made any changes, scroll to the bottom of the page
2. Click: **Save Changes**
3. Wait for confirmation that changes were saved

## Current Configuration Reference

### Application Details
- **Application Name:** `inlock-admin`
- **Client ID:** `aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o`
- **Application Type:** Regular Web Application
- **Grant Types:** Authorization Code, Refresh Token

### Required URLs
- **Callback URL:** `https://auth.inlock.ai/oauth2/callback`
- **Web Origin:** `https://auth.inlock.ai`
- **Logout URLs:** (see Step 4)

## Verification Result Template

```
Date: [DATE]
Verified By: [NAME]
Auth0 Tenant: comzis.eu.auth0.com
Application: inlock-admin

Callback URL Verification:
[ ] Present and correct: https://auth.inlock.ai/oauth2/callback
[ ] Missing or incorrect (describe issue)

Logout URLs Verification:
[ ] Present and correct
[ ] Missing or needs update (describe)

Web Origins Verification:
[ ] Present and correct: https://auth.inlock.ai
[ ] Missing or incorrect (describe)

Changes Made:
[List any changes made]

Result: [PASS/FAIL]
Notes:
[Any additional notes]
```

## Troubleshooting

### Issue: Callback URL Not Found

**Symptom:** Field is empty or contains different URL

**Solution:**
1. Add: `https://auth.inlock.ai/oauth2/callback`
2. Click **Save Changes**
3. Test authentication flow

### Issue: Multiple Callback URLs

**Symptom:** Field contains multiple URLs

**Action:** Ensure `https://auth.inlock.ai/oauth2/callback` is included in the list

### Issue: Cannot Save Changes

**Possible Causes:**
- Insufficient permissions (need admin access)
- Auth0 tenant limitations
- Network issues

**Solution:**
- Verify account has admin permissions
- Try refreshing the page
- Contact Auth0 support if issue persists

## Post-Verification Steps

After verifying the callback URL:

1. **Document Result:** Fill out verification result template above
2. **Test Authentication:** Follow `docs/AUTH0-TESTING-PROCEDURE.md` for end-to-end testing
3. **Update Status:** Update `AUTH0-FIX-STATUS.md` with verification result
4. **Monitor Logs:** Check OAuth2-Proxy logs for authentication attempts

## Automated Verification (Future)

Once Management API credentials are configured, use:
```bash
./scripts/test-auth0-api.sh
```

This will verify callback URL configuration programmatically.

## Related Documentation

- `AUTH0-FIX-STATUS.md` - Overall Auth0 integration status
- `docs/AUTH0-TESTING-PROCEDURE.md` - Browser testing guide
- `scripts/setup-auth0-management-api.sh` - Management API setup for automation

