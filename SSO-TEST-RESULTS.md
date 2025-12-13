# Cross-Subdomain SSO Test Results

**Date:** 2025-12-13  
**Tester:** Follow-up Squad  
**Browser:** [To be filled during test]  
**Test Duration:** [Start time] - [End time]

---

## Test Procedure Summary

Following `docs/CROSS-SUBDOMAIN-SSO-TEST.md`:
1. Clear cookies for `*.inlock.ai`
2. Login on initial subdomain (grafana.inlock.ai)
3. Visit other subdomains without closing browser
4. Verify no re-prompt for authentication

---

## Test Results by Subdomain

### Test 1: Initial Authentication
- **Subdomain:** grafana.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Notes:** [Authentication prompt expected on first visit]
- **Timestamp:** [Time of first visit]
- **Cookie Present After Auth:** [Yes/No]
- **Cookie Attributes:**
  - Domain: [actual value]
  - SameSite: [actual value]
  - Secure: [Yes/No]
  - Path: [actual value]

### Test 2: Cross-Subdomain SSO

#### Subdomain: portainer.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: n8n.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: dashboard.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: traefik.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: deploy.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: cockpit.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

#### Subdomain: auth.inlock.ai
- **Result:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **Authentication Prompted:** [Yes/No]
- **Access Granted:** [Yes/No]
- **Timestamp:** [Time of visit]
- **Notes:** [Any issues, redirect loops, errors]

---

## OAuth2-Proxy Log Evidence

### Log Snippets Captured During Test

#### Initial Authentication (grafana.inlock.ai)
```
[Log lines will be captured here]
```

#### Subsequent Subdomain Visits
```
[Log lines will be captured here]
```

### Key Log Events

- **[AuthSuccess] Messages:** [Count and timestamps]
- **[No valid authentication] Messages:** [Count and timestamps - should only be on first auth]
- **Cookie-related errors:** [Any errors found]
- **Redirect loops:** [Any detected]

---

## Cookie Verification

### Cookie Details (from Browser DevTools)
- **Cookie Name:** inlock_session
- **Domain:** [actual value - should be `.inlock.ai`]
- **Path:** [actual value - should be `/`]
- **Expires:** [date/time]
- **Size:** [bytes]
- **HttpOnly:** [Yes/No]
- **Secure:** [Yes/No - should be Yes]
- **SameSite:** [actual value - should be `None`]

### Cookie Visibility Check
- ✅ Cookie visible in DevTools for `.inlock.ai` domain
- ✅ Cookie accessible across subdomains
- ❌ Cookie not visible (if checked)

---

## Overall Test Result

### Summary
- **Overall Status:** ⏳ PENDING / ✅ PASS / ❌ FAIL
- **First Authentication:** ⏳ / ✅ / ❌
- **Cross-Subdomain SSO:** ⏳ / ✅ / ❌
- **Cookie Configuration:** ⏳ / ✅ / ❌

### Issues Found
[List any issues discovered during testing]

### Anomalies
[Document any unexpected behavior, redirect loops, re-prompts, etc.]

---

## Recommendations

[Based on test results, provide recommendations]

---

## Next Steps

[If all tests pass:]
- ✅ Update AUTH0-FIX-STATUS.md with "Cross-subdomain SSO verified"
- ✅ Update STRIKE-TEAM-FINAL-SUMMARY.md with "Cross-subdomain SSO verified"
- ✅ Close session

[If any tests fail:]
- ❌ Document specific subdomain and symptom
- ❌ Include log snippets
- ❌ Do NOT change config - report findings only

---

**Test Completed:** [Date/Time]  
**Verified By:** [Name]

