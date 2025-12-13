# Browser E2E Test - DO THIS NOW

**Time:** 10 minutes  
**Priority:** 🔴 **CRITICAL**

---

## Pre-Test Setup

### 1. Clear Browser Cookies

**Chrome/Edge:**
1. Press `F12` to open DevTools
2. Go to **Application** tab
3. Left sidebar: **Storage** → **Cookies**
4. Select domains: `*.inlock.ai` and `auth.inlock.ai`
5. Right-click → **Clear**

**Firefox:**
1. Press `F12` to open DevTools
2. Go to **Storage** tab
3. Expand **Cookies**
4. Select all cookies for `inlock.ai` domains
5. Delete

**Safari:**
1. **Develop** menu → **Show Web Inspector**
2. **Storage** tab → **Cookies**
3. Select all → Delete

### 2. Open DevTools

1. Open DevTools (`F12` or `Cmd+Option+I`)
2. Go to **Network** tab
3. Check: **Preserve log**
4. Check: **Disable cache** (optional)
5. Go to **Console** tab
6. Clear console

---

## Test Procedure

### Test 1: Initial Authentication Flow

**Step 1: Navigate to Protected Service**

1. In browser, navigate to: **https://grafana.inlock.ai**
2. **Watch DevTools Network tab**

**Expected Behavior:**
- Browser redirects to Auth0 login page
- URL should contain: `comzis.eu.auth0.com`
- Auth0 login form visible

**Actual Result:**
- [ ] ✅ Redirected to Auth0 login → **GOOD**
- [ ] ❌ Shows error page → **PROBLEM** (capture screenshot)
- [ ] ❌ Redirect loop (continuous redirects) → **PROBLEM** (check console)
- [ ] ❌ Stays on service with error → **PROBLEM** (capture screenshot)

**If Error:**
- [ ] Capture screenshot
- [ ] Note error message
- [ ] Check Console tab for errors
- [ ] Continue to troubleshoot

**Step 2: Complete Login**

1. Enter your Auth0 credentials
2. Complete login (MFA if required)
3. **Watch for redirect back**

**Expected Behavior:**
- Redirected back to `https://grafana.inlock.ai`
- Grafana dashboard loads
- User is authenticated/logged in
- Can access Grafana features

**Actual Result:**
- [ ] ✅ Redirected back, access granted → **SUCCESS**
- [ ] ❌ Redirected back but "Access Denied" → **PROBLEM** (check cookies)
- [ ] ❌ Redirect loop → **PROBLEM** (check logs)
- [ ] ❌ Stays on Auth0 with error → **PROBLEM** (capture error)

**Step 3: Verify Cookie**

1. In DevTools, go to **Application** tab
2. Left sidebar: **Cookies** → `https://grafana.inlock.ai`
3. Look for cookie: **`inlock_session`**

**Cookie Properties Check:**
- [ ] Cookie exists: **`inlock_session`**
- [ ] Domain: **`.inlock.ai`** (should match)
- [ ] SameSite: **`None`** (should match)
- [ ] Secure: **`true`** (should be checked)
- [ ] HttpOnly: Checked (should be checked)
- [ ] Has value (not empty)

**If Cookie Missing or Wrong:**
- [ ] Note actual domain/SameSite values
- [ ] This indicates configuration issue
- [ ] Document for troubleshooting

---

### Test 2: Cross-Service Access

**Test Without Re-authenticating:**

1. Open new tab
2. Navigate to: **https://portainer.inlock.ai**
3. **Expected:** Should load without asking for login again

**Test Services:**
- [ ] `https://portainer.inlock.ai` → Accessible: [YES / NO]
- [ ] `https://n8n.inlock.ai` → Accessible: [YES / NO]
- [ ] `https://deploy.inlock.ai` → Accessible: [YES / NO]
- [ ] `https://dashboard.inlock.ai` → Accessible: [YES / NO]

**If Any Fail:**
- [ ] Note which services fail
- [ ] Check if cookie is present
- [ ] Check Console for errors

---

### Test 3: Network Tab Analysis

**Check Network Requests:**

1. In **Network** tab, look for request to: `/oauth2/callback`
2. **Check Status Code:**
   - [ ] 200 or 302 → **GOOD**
   - [ ] 401, 403, 500 → **PROBLEM** (capture details)

3. **Check for Callback Request:**
   - [ ] Request to `auth.inlock.ai/oauth2/callback` present
   - [ ] Contains `code=` parameter
   - [ ] Contains `state=` parameter
   - [ ] Response is redirect (302) or success (200)

**Export HAR (if issues):**
1. Right-click in Network tab
2. **Save all as HAR**
3. Save file for analysis

---

### Test 4: Console Errors

**Check Console Tab:**

1. Look for red error messages
2. **Common Errors to Look For:**
   - [ ] CORS errors → Indicates Web Origins issue
   - [ ] Cookie errors → Indicates SameSite/domain issue
   - [ ] Redirect loop → Indicates callback/redirect issue
   - [ ] "Invalid callback" → Auth0 callback URL issue

**Capture Errors:**
- [ ] Screenshot of console
- [ ] Copy error messages

---

## Evidence Collection

### Required Screenshots

1. [ ] Auth0 login page (if reached)
2. [ ] Final state (service loaded or error)
3. [ ] Cookie properties (Application → Cookies → inlock_session)
4. [ ] Console errors (if any)
5. [ ] Network tab showing callback request

### Required Documentation

**Test Result Template:**
```
Date: $(date)
Tester: [Your Name]
Browser: [Chrome/Firefox/Safari] [Version]
OS: [OS Version]

TEST RESULTS:
- Navigate to service: [PASS / FAIL] - Notes: [ ]
- Auth0 login page: [REACHED / NOT REACHED] - Notes: [ ]
- Complete login: [SUCCESS / FAILED] - Notes: [ ]
- Access granted: [YES / NO] - Notes: [ ]
- Cookie present: [YES / NO] - Domain: [ ], SameSite: [ ]
- Cross-service access: [YES / NO] - Services tested: [ ]

ISSUES FOUND:
[List any issues]

ERRORS:
[Paste console errors or "None"]

SCREENSHOTS:
[List filenames]

HAR EXPORT:
[Filename or "None"]

OVERALL RESULT: [PASS / FAIL]
```

---

## If Test Passes ✅

**SUCCESS!** Authentication is working.

**Next Steps:**
- [ ] Document results
- [ ] Update status documents
- [ ] Optional: Run Management API setup
- [ ] Optional: Import Grafana dashboard

---

## If Test Fails ❌

### Issue: Redirect Loop

**Symptoms:** Continuous redirects between service and Auth0

**Troubleshoot:**
1. Check OAuth2-Proxy logs:
   ```bash
   docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 -f
   ```
2. Verify callback URL matches Auth0 Dashboard
3. Check cookie domain configuration
4. Restart OAuth2-Proxy if needed

### Issue: "Invalid Callback URL" Error

**Symptoms:** Error message after Auth0 login

**Troubleshoot:**
1. Verify Auth0 Dashboard callback URL is exact match
2. Check for typos or trailing slashes
3. Wait 30 seconds after Auth0 changes
4. Clear cookies and retry

### Issue: Cookie Not Set

**Symptoms:** Login succeeds but cookie missing

**Troubleshoot:**
1. Check cookie domain in configuration (should be `.inlock.ai`)
2. Check SameSite setting (should be `None`)
3. Verify Secure flag is true
4. Check browser console for cookie errors

### Issue: Access Denied After Login

**Symptoms:** Redirected back but can't access service

**Troubleshoot:**
1. Verify cookie is present and correct
2. Check cookie domain matches service domain
3. Verify OAuth2-Proxy is forwarding auth correctly
4. Check service-specific authentication requirements

---

**Time Taken:** [Record actual time]  
**Result:** [PASS / FAIL]  
**Next:** If fail, proceed to troubleshooting or activate fallback

