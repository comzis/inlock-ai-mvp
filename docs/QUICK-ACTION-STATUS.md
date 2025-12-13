# Quick Action Status Tracker

**Started:** 2025-12-13 02:10 UTC  
**Goal:** Restore usable auth flow  
**ETA:** 15 minutes total

---

## Progress Checklist

### ✅ Step 1: Auth0 Dashboard Verification (5 min)

- [ ] Access Auth0 Dashboard: https://manage.auth0.com/
- [ ] Navigate to: Applications → Applications → `inlock-admin`
- [ ] Verify: "Allowed Callback URLs" = `https://auth.inlock.ai/oauth2/callback`
- [ ] Verify: "Allowed Web Origins" = `https://auth.inlock.ai`
- [ ] Screenshot captured
- [ ] Result documented

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE  
**Result:** [ ] PASS / [ ] FAIL  
**Time Taken:** _____ minutes  
**Notes:** _______________________________________

---

### ✅ Step 2: Browser E2E Test (10 min)

- [ ] Browser cookies cleared
- [ ] DevTools opened (Network + Console)
- [ ] Navigate to: https://grafana.inlock.ai
- [ ] Auth0 login reached
- [ ] Login completed
- [ ] Access granted
- [ ] Cookie verified (inlock_session)
- [ ] Cross-service access tested
- [ ] Evidence captured

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE  
**Result:** [ ] PASS / [ ] FAIL  
**Time Taken:** _____ minutes  
**Notes:** _______________________________________

---

## Results Summary

### Auth0 Dashboard Check Result

```
Callback URL: [paste value]
Match Expected: [YES / NO]
Web Origins: [paste value]
Match Expected: [YES / NO]
Changes Made: [list changes or "None"]
```

### Browser E2E Test Result

```
Test Status: [PASS / FAIL]
Issues Found: [list or "None"]
Cookie Present: [YES / NO]
Cookie Domain: [actual domain]
Cookie SameSite: [actual value]
```

---

## Next Actions Based on Results

### If Both Pass ✅

- [ ] Document results
- [ ] Update status documents
- [ ] Mark incident resolved
- [ ] Optional: Setup Management API
- [ ] Optional: Import Grafana dashboard

### If Auth0 Dashboard Failed ❌

- [ ] Fix callback URL in Auth0 Dashboard
- [ ] Wait 30 seconds
- [ ] Re-run browser E2E test
- [ ] Should now pass

### If Browser E2E Failed (but Auth0 correct) ❌

- [ ] Check logs: `docker compose -f compose/stack.yml --env-file .env logs oauth2-proxy --tail 100 -f`
- [ ] Review error details from test
- [ ] Apply config fix if needed
- [ ] Restart OAuth2-Proxy if needed:
  ```bash
  docker compose -f compose/stack.yml --env-file .env up -d --force-recreate oauth2-proxy
  ```
- [ ] Re-test

### If Still Failing ❌

- [ ] Consider activating fallback (Keycloak)
- [ ] See: `docs/STRIKE-TEAM-DELIVERABLES.md` section 4
- [ ] Fallback activation time: ~45 minutes

---

## Evidence Files

- [ ] Auth0 Dashboard screenshot: `auth0-callback-url-verification-*.png`
- [ ] Browser test screenshots: `browser-test-*.png`
- [ ] HAR export: `test-har-*.har` (if issues)
- [ ] Log export: `oauth2-proxy-logs-*.txt` (if issues)

---

**Current Status:** ✅ COMPLETE (Configuration) / ⚠️ PENDING (Manual Testing)  
**Overall Result:** ✅ PASS (Configuration) / ⚠️ PENDING (Browser Test)  
**Resolution Time:** 15 minutes (configuration)

**Note (2025-12-13):** Cross-subdomain SSO configuration completed. All subdomains whitelisted, cookie settings verified. Manual browser testing pending (see `docs/CROSS-SUBDOMAIN-SSO-TEST.md`).

