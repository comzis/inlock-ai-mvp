# Browser E2E Test Setup Guide

**Created:** 2025-12-13 01:20 UTC  
**Agent:** Browser E2E Support (Agent 4)  
**Purpose:** Headless browser setup and failure signature catalog.
**Status:** ✅ Implemented in `e2e/` directory and active in CI/CD pipeline.

---

## Current Implementation (Dec 2025)
The active test suite is located in `e2e/` and runs via Playwright.

**To Run Locally:**
```bash
cd e2e
npm install
npx playwright test
```

**CI/CD Integration:**
Tests run automatically in the `.github/workflows/deploy.yml` pipeline (job: `e2e-test`) after every deployment verification.

---

## Test Harness Options (Reference)

### Option 1: Playwright (Recommended)

**Installation:**
```bash
npm install -g @playwright/test
playwright install chromium
```

**Test Script:**
```javascript
// test/auth0-e2e.spec.js
const { test, expect } = require('@playwright/test');

test('Auth0 authentication flow', async ({ page, context }) => {
  // Clear cookies
  await context.clearCookies();
  
  // Navigate to protected service
  await page.goto('https://grafana.inlock.ai');
  
  // Should redirect to Auth0
  await page.waitForURL(/auth0\.com\/authorize/);
  
  // Fill login form (adjust selectors for your Auth0 form)
  await page.fill('input[name="username"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  // Should redirect back to service
  await page.waitForURL(/grafana\.inlock\.ai/);
  
  // Verify access
  await expect(page).toHaveURL(/grafana\.inlock\.ai/);
  
  // Check for session cookie
  const cookies = await context.cookies();
  const sessionCookie = cookies.find(c => c.name === 'inlock_session');
  expect(sessionCookie).toBeDefined();
  expect(sessionCookie.domain).toContain('.inlock.ai');
});
```

### Option 2: Puppeteer

**Installation:**
```bash
npm install -g puppeteer
```

**Test Script:**
```javascript
// test/auth0-e2e.js
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();
  
  // Clear cookies
  const client = await page.target().createCDPSession();
  await client.send('Network.clearBrowserCookies');
  
  // Navigate to protected service
  await page.goto('https://grafana.inlock.ai');
  
  // Wait for Auth0 redirect
  await page.waitForNavigation({ waitUntil: 'networkidle0' });
  
  // Verify Auth0 login page
  const url = page.url();
  if (!url.includes('auth0.com')) {
    throw new Error('Did not redirect to Auth0');
  }
  
  // Fill login (adjust selectors)
  await page.type('input[name="username"]', 'test@example.com');
  await page.type('input[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  // Wait for callback
  await page.waitForNavigation({ waitUntil: 'networkidle0' });
  
  // Verify redirect back
  if (!page.url().includes('grafana.inlock.ai')) {
    throw new Error('Did not redirect back to service');
  }
  
  // Check cookies
  const cookies = await page.cookies();
  const sessionCookie = cookies.find(c => c.name === 'inlock_session');
  if (!sessionCookie) {
    throw new Error('Session cookie not set');
  }
  
  await browser.close();
})();
```

### Option 3: Selenium

**Installation:**
```bash
pip install selenium
# Download ChromeDriver
```

**Test Script:**
```python
# test/auth0_e2e.py
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

driver = webdriver.Chrome()
driver.delete_all_cookies()

try:
    # Navigate to protected service
    driver.get('https://grafana.inlock.ai')
    
    # Wait for Auth0 redirect
    WebDriverWait(driver, 10).until(
        lambda d: 'auth0.com' in d.current_url
    )
    
    # Fill login form
    driver.find_element(By.NAME, 'username').send_keys('test@example.com')
    driver.find_element(By.NAME, 'password').send_keys('password')
    driver.find_element(By.CSS_SELECTOR, 'button[type="submit"]').click()
    
    # Wait for callback
    WebDriverWait(driver, 10).until(
        lambda d: 'grafana.inlock.ai' in d.current_url
    )
    
    # Verify cookie
    cookies = driver.get_cookies()
    session_cookie = next((c for c in cookies if c['name'] == 'inlock_session'), None)
    assert session_cookie is not None, 'Session cookie not set'
    
finally:
    driver.quit()
```

---

## Common Failure Signatures

### 1. CSRF Cookie Not Present

**Symptom:**
```
Error while loading CSRF cookie: http: named cookie not present
```

**Causes:**
- SameSite cookie issue (✅ fixed - using SameSite=None)
- Cookie domain mismatch
- Browser blocking cookies

**Fix:**
- ✅ Already fixed: SameSite=None configured
- Verify cookie domain: `.inlock.ai`
- Check browser cookie settings

**Test:**
```javascript
// Check cookie is set after redirect to Auth0
const cookies = await page.context().cookies();
const csrfCookie = cookies.find(c => c.name.includes('csrf'));
expect(csrfCookie).toBeDefined();
```

### 2. Invalid Redirect URI

**Symptom:**
```
Invalid redirect_uri
```

**Causes:**
- Callback URL not in Auth0 allowed list
- Typo in callback URL
- Protocol mismatch (http vs https)

**Fix:**
- Verify callback URL in Auth0 Dashboard
- Ensure exact match: `https://auth.inlock.ai/oauth2/callback`

**Test:**
```javascript
// Verify redirect_uri in Auth0 URL
const auth0Url = await page.url();
expect(auth0Url).toContain('redirect_uri=https%3A%2F%2Fauth.inlock.ai%2Foauth2%2Fcallback');
```

### 3. Authentication Loop

**Symptom:**
- Continuous redirects between Auth0 and service
- Never reaches protected resource

**Causes:**
- Cookie not being set
- Cookie domain mismatch
- Session validation failing

**Fix:**
- Check cookie domain: `.inlock.ai`
- Verify SameSite=None, Secure=true
- Check OAuth2-Proxy logs

**Test:**
```javascript
// Count redirects (should be limited)
let redirectCount = 0;
page.on('response', response => {
  if (response.status() === 302 || response.status() === 301) {
    redirectCount++;
  }
});
// After test, verify redirectCount < 5
```

### 4. Token Exchange Failure

**Symptom:**
- Redirects to Auth0
- Login succeeds
- Redirects back but authentication fails

**Causes:**
- Invalid client secret
- Token endpoint error
- PKCE code verifier mismatch

**Fix:**
- Verify client secret in `.env`
- Check OAuth2-Proxy logs for token errors
- Verify PKCE configuration

**Test:**
```javascript
// Monitor network requests for token exchange
page.on('request', request => {
  if (request.url().includes('/oauth/token')) {
    console.log('Token request:', request.url());
  }
});
```

### 5. CORS Errors

**Symptom:**
```
Access to fetch at 'https://auth0.com/...' from origin 'https://auth.inlock.ai' has been blocked by CORS policy
```

**Causes:**
- Web Origins not configured in Auth0
- Missing CORS headers

**Fix:**
- Add `https://auth.inlock.ai` to Allowed Web Origins in Auth0

**Test:**
```javascript
// Check for CORS errors in console
const errors = [];
page.on('console', msg => {
  if (msg.text().includes('CORS')) {
    errors.push(msg.text());
  }
});
```

---

## Fix Playbook

### Issue: Authentication Fails After Login

**Step 1: Check OAuth2-Proxy Logs**
```bash
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 50
```

**Step 2: Check Browser Console**
- Open DevTools → Console
- Look for JavaScript errors
- Check Network tab for failed requests

**Step 3: Verify Cookies**
```javascript
// In browser console:
document.cookie.split(';').forEach(c => console.log(c.trim()));
// Should see: inlock_session=...
```

**Step 4: Check Auth0 Dashboard**
- Verify callback URL is configured
- Check application settings

**Step 5: Test Callback Endpoint**
```bash
curl -I https://auth.inlock.ai/oauth2/callback
# Should return 403 (expected without OAuth params)
```

### Issue: Infinite Redirect Loop

**Step 1: Clear All Cookies**
```javascript
// In browser console:
document.cookie.split(";").forEach(c => {
  document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
});
```

**Step 2: Check Cookie Domain**
- Verify cookie domain is `.inlock.ai`
- Check SameSite setting

**Step 3: Verify Whitelist Domains**
- Check OAuth2-Proxy whitelist configuration
- Ensure service domain is whitelisted

### Issue: PKCE Errors

**Symptom:**
```
Invalid code_verifier
```

**Fix:**
- ✅ Already fixed: `--code-challenge-method=S256` enabled
- Verify in container: `docker inspect compose-oauth2-proxy-1`

---

## Test Scenarios

### Scenario 1: Happy Path
1. Clear cookies
2. Navigate to protected service
3. Redirect to Auth0
4. Login successfully
5. Redirect back to service
6. Access granted

### Scenario 2: Token Expiry
1. Authenticate successfully
2. Wait for token expiry (or force expiry)
3. Access protected resource
4. Should redirect to Auth0 for re-authentication

### Scenario 3: Logout Flow
1. Authenticate successfully
2. Access logout endpoint
3. Should clear session cookie
4. Next access should require re-authentication

### Scenario 4: Multiple Services
1. Authenticate on service A
2. Access service B
3. Should use same session (SSO)
4. No re-authentication required

### Scenario 5: Blocked Cookies
1. Disable cookies in browser
2. Attempt authentication
3. Should fail gracefully
4. Error message should be clear

---

## Monitoring During Tests

### Network Tab
- Monitor all requests
- Check for 401/403 responses
- Verify redirect chains

### Application Tab
- Check cookies
- Verify session storage
- Check local storage

### Console Tab
- Watch for JavaScript errors
- Check for CORS errors
- Monitor authentication events

---

## Automated Test Suite

### Run All Tests
```bash
# Playwright
npx playwright test test/auth0-e2e.spec.js

# Puppeteer
node test/auth0-e2e.js

# Selenium
pytest test/auth0_e2e.py
```

### CI/CD Integration
```yaml
# .github/workflows/auth0-e2e.yml
name: Auth0 E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - run: npm install -g @playwright/test
      - run: playwright install chromium
      - run: npx playwright test test/auth0-e2e.spec.js
```

---

**Last Updated:** 2025-12-13 01:20 UTC  
**Status:** Ready for Primary Team Use

