# Browser E2E Test Checklist & Harness Commands

**Agent:** Browser E2E Support (Agent 4)  
**Date:** 2025-12-13  
**Purpose:** Complete checklist and commands for browser end-to-end testing

---

## Pre-Test Environment Setup

### 1. Service Health Check

```bash
# Verify OAuth2-Proxy is running
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env ps oauth2-proxy

# Expected output: Status should be "Up"
# Container name: compose-oauth2-proxy-1

# Check recent logs for errors
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 50 | grep -i -E "error|warning|fatal"

# Expected: No critical errors (some expected 403s from curl tests are OK)

# Verify health endpoint
curl -s https://auth.inlock.ai/ping

# Expected: HTTP 200 or health check response
```

### 2. Clear Browser State (Manual Steps)

**Chrome/Edge:**
1. Open DevTools (F12)
2. Application tab → Storage → Clear site data
3. Select domain: `*.inlock.ai` and `auth.inlock.ai`
4. Clear data

**Firefox:**
1. Open DevTools (F12)
2. Storage tab → Cookies → Right-click → Delete All
3. Filter by domain: `inlock.ai`

**Safari:**
1. Develop → Show Web Inspector
2. Storage → Cookies → Select all → Delete

### 3. Browser DevTools Setup

**Network Tab:**
- [ ] Open DevTools → Network tab
- [ ] Enable "Preserve log"
- [ ] Enable "Disable cache" (optional but recommended)
- [ ] Filter set to "All" or "XHR/Fetch"

**Console Tab:**
- [ ] Console tab open
- [ ] Log level: All (Verbose, Info, Warnings, Errors)

**Application Tab:**
- [ ] Application → Cookies ready for inspection
- [ ] Storage → Local Storage ready

---

## Test Execution Checklist

### Test 1: Initial Authentication Flow

**Objective:** Complete authentication from protected service to Auth0 and back

- [ ] **Step 1:** Navigate to `https://grafana.inlock.ai`
  - Expected: Redirect to Auth0 login
  - Actual Result: [ ]
  - Screenshot: [ ]

- [ ] **Step 2:** Verify Auth0 login page loads
  - URL should contain: `comzis.eu.auth0.com`
  - Login form visible
  - Actual Result: [ ]
  - Screenshot: [ ]

- [ ] **Step 3:** Enter credentials and authenticate
  - Username/email entered
  - Password entered
  - MFA completed (if required)
  - Actual Result: [ ]

- [ ] **Step 4:** Verify redirect back to service
  - Redirected to `https://grafana.inlock.ai`
  - Service loads successfully
  - User is authenticated/logged in
  - Actual Result: [ ]
  - Screenshot: [ ]

- [ ] **Step 5:** Check Network tab for callback
  - Request to `https://auth.inlock.ai/oauth2/callback` present
  - Status: 200 or 302 (redirect)
  - No 401/403 errors after callback
  - Actual Result: [ ]

**Test 1 Result:** [PASS / FAIL]  
**Notes:** [Any observations or issues]

---

### Test 2: Cookie Verification

**Objective:** Verify session cookie is set correctly

- [ ] **Step 1:** Check cookie presence
  - Open DevTools → Application → Cookies → `https://grafana.inlock.ai`
  - Cookie name: `inlock_session` exists
  - Actual: [ ]

- [ ] **Step 2:** Verify cookie properties
  - Domain: `.inlock.ai` ✓
  - Path: `/` ✓
  - HttpOnly: ✓ (checked)
  - Secure: ✓ (checked)
  - SameSite: `None` ✓
  - Expires: Future date ✓
  - Actual: [ ]

- [ ] **Step 3:** Cookie value inspection
  - Cookie has non-empty value
  - Value appears to be encrypted/token
  - Actual: [ ]

**Test 2 Result:** [PASS / FAIL]  
**Screenshot:** [Attach screenshot of cookie properties]

---

### Test 3: Cross-Service Access

**Objective:** Verify cookie works across all protected services

**Test each service (without re-authenticating):**

- [ ] `https://portainer.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://grafana.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://n8n.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://deploy.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://dashboard.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://traefik.inlock.ai` - Accessible: [YES / NO]
- [ ] `https://cockpit.inlock.ai` - Accessible: [YES / NO]

**Test 3 Result:** [PASS / FAIL - All services accessible]  
**Notes:** [List any services that required re-authentication]

---

### Test 4: Logout Flow

**Objective:** Verify logout clears session

- [ ] **Step 1:** Initiate logout
  - Navigate to logout endpoint or service logout
  - Or visit: `https://auth.inlock.ai/oauth2/sign_out`
  - Actual: [ ]

- [ ] **Step 2:** Verify redirect
  - Redirected to signout redirect URL: `https://deploy.inlock.ai`
  - Actual: [ ]

- [ ] **Step 3:** Verify cookie cleared
  - Check Application → Cookies
  - `inlock_session` cookie removed or expired
  - Actual: [ ]

- [ ] **Step 4:** Verify re-authentication required
  - Navigate to protected service
  - Redirected to Auth0 login again
  - Actual: [ ]

**Test 4 Result:** [PASS / FAIL]  
**Notes:** [ ]

---

### Test 5: Error Scenarios

**Objective:** Test error handling

- [ ] **5a: Invalid Auth0 Credentials**
  - Attempt login with wrong password
  - Expected: Auth0 shows error, no redirect
  - Actual: [ ]

- [ ] **5b: Cancel Authentication**
  - Start auth flow, then cancel/close
  - Expected: Redirected back with error or stays on Auth0
  - Actual: [ ]

- [ ] **5c: Expired Session**
  - Wait for session to expire (or manually expire cookie)
  - Access protected service
  - Expected: Redirect to Auth0 for re-authentication
  - Actual: [ ]

- [ ] **5d: Network Issues During Auth**
  - (Simulate by blocking network during callback)
  - Expected: Error handling, retry possible
  - Actual: [ ]

**Test 5 Result:** [PASS / FAIL]  
**Notes:** [ ]

---

## Browser Harness Commands (Headless Testing)

### Using Playwright (if installed)

```bash
# Install Playwright (if not installed)
# npm install -g playwright
# playwright install chromium

# Create test script (example)
cat > /tmp/test-auth0-e2e.js << 'EOF'
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('Navigating to protected service...');
  await page.goto('https://grafana.inlock.ai');
  
  console.log('Waiting for Auth0 redirect...');
  await page.waitForURL(/comzis.eu.auth0.com/, { timeout: 10000 });
  
  console.log('Auth0 login page loaded');
  
  // Note: Cannot automate actual login (credentials required)
  // User must complete login manually
  
  await page.waitForTimeout(30000); // Wait for manual login
  
  const url = page.url();
  console.log('Final URL:', url);
  
  const cookies = await context.cookies();
  const sessionCookie = cookies.find(c => c.name === 'inlock_session');
  
  if (sessionCookie) {
    console.log('✓ Session cookie found');
    console.log('  Domain:', sessionCookie.domain);
    console.log('  SameSite:', sessionCookie.sameSite);
    console.log('  Secure:', sessionCookie.secure);
  } else {
    console.log('✗ Session cookie not found');
  }
  
  await browser.close();
})();
EOF

# Run test (requires manual login)
# node /tmp/test-auth0-e2e.js
```

### Using curl for Basic Flow Test (Limited)

```bash
# Note: curl cannot fully test browser flow, but can verify endpoints

# Test callback endpoint (should return 403 without OAuth params)
curl -v https://auth.inlock.ai/oauth2/callback

# Expected: HTTP 403 "Invalid authentication via OAuth2"

# Test health endpoint
curl -v https://auth.inlock.ai/ping

# Expected: HTTP 200 or health response

# Test protected service redirect (should redirect to Auth0)
curl -v -L https://grafana.inlock.ai 2>&1 | grep -i "location:"

# Expected: Location header pointing to Auth0 login
```

---

## Common Failure Signatures & Fixes

### Issue 1: Infinite Redirect Loop

**Symptom:**
- Browser continuously redirects between service and Auth0
- Console shows multiple redirects
- Never reaches service

**Possible Causes:**
- Callback URL misconfigured in Auth0
- Cookie SameSite issue (should be `None`)
- Cookie domain mismatch

**Fix:**
1. Verify callback URL in Auth0 Dashboard
2. Check OAuth2-Proxy logs: `docker compose logs oauth2-proxy --tail 50`
3. Verify cookie settings in `compose/stack.yml`

### Issue 2: CSRF Cookie Error

**Symptom:**
- OAuth2-Proxy logs show: "Error while loading CSRF cookie"
- Authentication fails after Auth0 login
- Redirects back but shows error

**Fix:**
- Verify `OAUTH2_PROXY_COOKIE_SAMESITE=none` in stack.yml
- Verify `--cookie-samesite=none` in command
- Restart container: `docker compose up -d --force-recreate oauth2-proxy`

### Issue 3: Cookie Not Set

**Symptom:**
- Authentication succeeds but no `inlock_session` cookie
- User must re-authenticate for each service
- Cookie domain mismatch in DevTools

**Fix:**
- Verify `OAUTH2_PROXY_COOKIE_DOMAIN=.inlock.ai`
- Verify `--cookie-domain=.inlock.ai` in command
- Check browser console for cookie errors

### Issue 4: 401/403 After Authentication

**Symptom:**
- Auth0 login succeeds
- Redirect back to service
- Service returns 401/403
- Cookie is present but not accepted

**Fix:**
- Check OAuth2-Proxy logs for authentication errors
- Verify cookie secret is correct
- Check service-specific authentication requirements

---

## Evidence Collection

### Screenshots Required

1. [ ] Auth0 login page (showing tenant domain)
2. [ ] Successful redirect back to service after login
3. [ ] Cookie properties in DevTools (Application → Cookies)
4. [ ] Network tab showing callback request (200 status)
5. [ ] Console tab (should be clean, no errors)

### Logs to Capture

```bash
# Capture OAuth2-Proxy logs during test
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 > /tmp/auth0-test-logs-$(date +%Y%m%d-%H%M%S).txt

# Capture Traefik logs (if needed)
docker compose -f compose/stack.yml --env-file .env logs traefik --tail 100 > /tmp/traefik-test-logs-$(date +%Y%m%d-%H%M%S).txt
```

---

## Test Result Summary Template

```
Test Date: [YYYY-MM-DD HH:MM UTC]
Tester: [Name]
Browser: [Chrome/Firefox/Safari] Version [X.X]
OS: [OS Version]

TEST RESULTS:
- Test 1 (Initial Auth): [PASS / FAIL] - Notes: [ ]
- Test 2 (Cookie Verification): [PASS / FAIL] - Notes: [ ]
- Test 3 (Cross-Service): [PASS / FAIL] - Notes: [ ]
- Test 4 (Logout): [PASS / FAIL] - Notes: [ ]
- Test 5 (Error Scenarios): [PASS / FAIL] - Notes: [ ]

OVERALL RESULT: [PASS / FAIL / PARTIAL]

ISSUES IDENTIFIED:
[List any issues found]

BLOCKERS:
[List any blockers]

NEXT STEPS:
[Actions required]

EVIDENCE FILES:
- Logs: [filename]
- Screenshots: [list files]
```

---

## Handoff Notes

**For Primary Team:**
- [ ] All test cases executed
- [ ] Evidence collected
- [ ] Results documented
- [ ] Issues/blockers communicated
- [ ] Status updated in AUTH0-FIX-STATUS.md

**Status:** [READY / NEEDS PRIMARY TEAM ACTION / BLOCKED]

