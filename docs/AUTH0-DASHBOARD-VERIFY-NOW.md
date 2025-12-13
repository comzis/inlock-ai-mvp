# Auth0 Dashboard Verification - DO THIS NOW

**Time:** 5 minutes  
**Priority:** 🔴 **CRITICAL**

---

## Step-by-Step Instructions

### Step 1: Access Auth0 Dashboard

1. Open browser
2. Navigate to: **https://manage.auth0.com/**
3. Log in with your Auth0 credentials
4. Select tenant: `comzis.eu.auth0.com` (if prompted)

### Step 2: Navigate to Application

1. In left sidebar, click: **Applications**
2. Click: **Applications** (submenu)
3. Find and click: **`inlock-admin`**
4. You should now see the application settings page

### Step 3: Verify Callback URL

1. Scroll down to **Settings** section
2. Find field: **"Allowed Callback URLs"**
3. **CHECK:** Does it contain exactly: `https://auth.inlock.ai/oauth2/callback`?

**Expected Value:**
```
https://auth.inlock.ai/oauth2/callback
```

**If Missing or Different:**
- [ ] Click in the field
- [ ] Add or update to: `https://auth.inlock.ai/oauth2/callback`
- [ ] Ensure no trailing slashes or extra spaces
- [ ] If multiple URLs, separate with commas
- [ ] Click **Save Changes** at bottom of page
- [ ] Wait for confirmation message

### Step 4: Verify Web Origins

1. Find field: **"Allowed Web Origins (CORS)"**
2. **CHECK:** Does it contain: `https://auth.inlock.ai`?

**Expected Value:**
```
https://auth.inlock.ai
```

**If Missing or Different:**
- [ ] Add: `https://auth.inlock.ai`
- [ ] No trailing slash
- [ ] Click **Save Changes**

### Step 5: Verify Logout URLs (Optional but Recommended)

1. Find field: **"Allowed Logout URLs"**
2. **CHECK:** Does it contain service URLs or is it properly configured?

**Recommended Value:**
```
https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
```

### Step 6: Capture Evidence

**Take Screenshot:**
- [ ] Screenshot of "Allowed Callback URLs" field (zoomed/clear)
- [ ] Save as: `auth0-callback-url-verification-$(date +%Y%m%d-%H%M%S).png`

**Document Result:**
```
Date: $(date)
Verified By: [Your Name]
Callback URL: [Paste exact value from field]
Match Expected: [YES / NO]
Web Origins: [Paste exact value]
Match Expected: [YES / NO]
Changes Made: [List any changes or "None"]
Result: [PASS / FAIL]
```

---

## Quick Verification Checklist

- [ ] Callback URL field contains: `https://auth.inlock.ai/oauth2/callback`
- [ ] No typos (especially check `.ai` not `.com`)
- [ ] No trailing slashes
- [ ] Web Origins contains: `https://auth.inlock.ai`
- [ ] Changes saved (if any made)
- [ ] Screenshot captured
- [ ] Result documented

---

## If Callback URL Was Wrong

**After Fixing:**
1. Wait 30 seconds for changes to propagate
2. Proceed to browser E2E test (next step)
3. Authentication should now work

**Expected Result:** Users can now authenticate successfully

---

## If Callback URL Was Correct

**Still proceed to browser E2E test** to verify end-to-end flow. Issue may be elsewhere (cookies, CORS, etc.)

---

**Time Taken:** [Record actual time]  
**Next Step:** Run browser E2E test (see `docs/BROWSER-E2E-TEST-NOW.md`)

