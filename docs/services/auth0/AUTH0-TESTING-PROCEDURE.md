# Auth0 Real Browser Testing Procedure

**Last Updated:** 2025-12-13  
**Purpose:** End-to-end authentication flow testing with real browser

## Prerequisites

- Access to Tailscale VPN or authorized IP
- Valid Auth0 account credentials
- Browser with developer tools enabled

## Pre-Test Setup

### 1. Clear Browser State
```bash
# Clear cookies for all inlock.ai domains
# In Chrome/Edge: Settings → Privacy → Clear browsing data → Cookies
# Or use browser extension to clear specific domain cookies
```

**Domains to clear cookies for:**
- `*.inlock.ai`
- `auth.inlock.ai`
- `comzis.eu.auth0.com`

### 2. Enable Browser Developer Tools
- Open Developer Tools (F12 or Cmd+Option+I)
- Go to **Network** tab
- Check **Preserve log** option
- Open **Console** tab to view errors

### 3. Verify Service Access
```bash
# Verify OAuth2-Proxy is running
docker compose -f compose/stack.yml --env-file .env ps oauth2-proxy

# Check recent logs
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 20
```

## Test Procedure

### Test 1: Initial Authentication Flow

**Objective:** Verify complete authentication flow from protected service to Auth0 and back

1. **Navigate to Protected Service**
   - URL: `https://grafana.inlock.ai` (or any protected service)
   - Expected: Redirect to Auth0 login

2. **Auth0 Login**
   - Verify Auth0 login page loads
   - Enter valid credentials
   - Complete authentication (MFA if required)
   - Expected: Redirect back to service

3. **Verify Success**
   - Check service loads correctly
   - Verify user is logged in
   - Check browser cookies:
     - Name: `inlock_session`
     - Domain: `.inlock.ai`
     - SameSite: `None`
     - Secure: `true`

4. **Check Network Tab**
   - Verify successful 200 responses
   - No 401/403 errors after authentication
   - Callback URL accessed: `https://auth.inlock.ai/oauth2/callback`

### Test 2: Cookie Verification

**Objective:** Verify session cookie is set correctly

1. **Check Browser Cookies**
   - Open Developer Tools → Application → Cookies
   - Find `inlock_session` cookie
   - Verify properties:
     ```
     Name: inlock_session
     Domain: .inlock.ai
     Path: /
     Expires: [future date]
     HttpOnly: ✓
     Secure: ✓
     SameSite: None
     ```

### Test 3: Cross-Service Access

**Objective:** Verify cookie works across all protected services

1. **Access Multiple Services** (without re-authenticating):
   - `https://portainer.inlock.ai`
   - `https://n8n.inlock.ai`
   - `https://grafana.inlock.ai`
   - `https://deploy.inlock.ai`
   
2. **Expected:** All services accessible without re-login

### Test 4: Logout Flow

**Objective:** Verify logout clears session

1. **Logout from Service**
   - Find logout button/link
   - Click logout

2. **Verify Logout**
   - Check `inlock_session` cookie is removed
   - Attempt to access protected service
   - Expected: Redirect to Auth0 login again

### Test 5: Session Expiry

**Objective:** Test behavior with expired/invalid session

1. **Manually Delete Cookie**
   - Remove `inlock_session` cookie from browser
   - Attempt to access protected service
   - Expected: Redirect to Auth0 login

### Test 6: Error Scenarios

**Objective:** Verify error handling

1. **Invalid Credentials**
   - Enter wrong password on Auth0 login
   - Expected: Auth0 shows error, no redirect

2. **Cancel Auth0 Login**
   - Start login flow, then cancel
   - Expected: No cookie set, redirected appropriately

## Verification Checklist

- [ ] Auth0 login page loads correctly
- [ ] Successful login redirects back to service
- [ ] Session cookie (`inlock_session`) is set with correct properties
- [ ] Protected service is accessible after login
- [ ] Cookie works across all protected services
- [ ] Logout removes session cookie
- [ ] No CSRF cookie errors in OAuth2-Proxy logs
- [ ] No authentication errors in browser console
- [ ] Network requests show successful authentication flow

## Log Checking

### OAuth2-Proxy Logs
```bash
# Watch logs during testing
docker compose -f compose/stack.yml --env-file .env logs -f oauth2-proxy

# Check for errors
docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 | grep -i "error\|fail\|csrf"
```

### Expected Log Entries
- ✅ Authentication success messages
- ✅ Cookie settings logged at startup
- ❌ No CSRF cookie errors (after fix)
- ❌ No authentication failures

### Traefik Logs
```bash
# Check Traefik logs for forward-auth
docker compose -f compose/stack.yml --env-file .env logs traefik --tail 100 | grep -i "oauth2\|auth"
```

## Troubleshooting

### Issue: Redirect Loop
**Symptom:** Page keeps redirecting between Auth0 and service

**Check:**
- Auth0 callback URL configured correctly
- Cookie domain matches (`.inlock.ai`)
- SameSite=None and Secure=true set

### Issue: Cookie Not Set
**Symptom:** Cookie not present after authentication

**Check:**
- Browser allows third-party cookies
- Cookie domain is correct
- HTTPS is used (required for Secure cookies)

### Issue: CSRF Cookie Error
**Symptom:** Authentication fails with CSRF error

**Check:**
- SameSite=None configured in OAuth2-Proxy
- Secure=true set
- Browser supports SameSite=None

### Issue: Service Not Accessible After Login
**Symptom:** Auth0 login succeeds but service shows 403

**Check:**
- Forward-auth middleware configured correctly
- OAuth2-Proxy service healthy
- Traefik routing correct

## Test Results Template

```
Date: [DATE]
Tester: [NAME]
Browser: [BROWSER/VERSION]

Test 1 - Initial Authentication: [PASS/FAIL]
Test 2 - Cookie Verification: [PASS/FAIL]
Test 3 - Cross-Service Access: [PASS/FAIL]
Test 4 - Logout Flow: [PASS/FAIL]
Test 5 - Session Expiry: [PASS/FAIL]
Test 6 - Error Scenarios: [PASS/FAIL]

Issues Found:
- [List any issues]

Logs Checked:
- OAuth2-Proxy: [CLEAN/HAS ERRORS]
- Traefik: [CLEAN/HAS ERRORS]
```

## Next Steps After Testing

1. Document any issues found
2. Update AUTH0-FIX-STATUS.md with test results
3. If issues found, create tickets/action items
4. Verify fixes in subsequent test cycles

