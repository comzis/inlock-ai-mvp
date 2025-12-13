# Cross-Subdomain SSO Test - Quick Instructions

**Date:** 2025-12-13  
**Status:** Ready for Testing

---

## Pre-Test Setup

✅ **Log Monitoring:** Active in background  
✅ **OAuth2-Proxy Status:** Healthy  
✅ **Configuration:** Verified (cookie domain `.inlock.ai`, SameSite=None, Secure=true)

---

## Test Steps (10-15 minutes)

### Step 1: Clear Browser State (2 min)

**Chrome/Edge:**
1. Open DevTools (F12)
2. Application tab → Cookies → Expand `https://inlock.ai` or `.inlock.ai`
3. Delete ALL cookies for `*.inlock.ai` domains
4. Clear browser cache (Ctrl+Shift+Delete → Cached images and files)

**Firefox:**
1. Open DevTools (F12)
2. Storage tab → Cookies → Expand `.inlock.ai`
3. Delete all cookies
4. Clear cache

---

### Step 2: Initial Authentication (2 min)

1. **Navigate to:**
   ```
   https://grafana.inlock.ai
   ```

2. **Expected:**
   - Redirected to Auth0 login page
   - Complete authentication with your credentials
   - Redirected back to Grafana
   - Cookie `inlock_session` set

3. **Verify Cookie (DevTools → Application/Storage → Cookies):**
   - Should see `inlock_session` cookie for `.inlock.ai`
   - Domain: `.inlock.ai` ✅
   - Path: `/` ✅
   - Secure: Yes ✅
   - SameSite: None ✅

---

### Step 3: Cross-Subdomain SSO Test (5-8 min)

**⚠️ IMPORTANT: Keep browser open, do NOT close tabs/windows**

Visit each subdomain in a NEW TAB and note behavior:

1. **portainer.inlock.ai**
   - Expected: ✅ Immediate access, NO authentication prompt
   - Actual: [Note what happens]

2. **n8n.inlock.ai**
   - Expected: ✅ Immediate access, NO authentication prompt
   - Actual: [Note what happens]

3. **dashboard.inlock.ai**
   - Expected: ✅ Immediate access, NO authentication prompt
   - Actual: [Note what happens]

4. **traefik.inlock.ai**
   - Expected: ✅ Access (may prompt for basic auth), NO OAuth prompt
   - Actual: [Note what happens]

5. **deploy.inlock.ai**
   - Expected: ✅ Immediate access, NO authentication prompt
   - Actual: [Note what happens]

6. **cockpit.inlock.ai**
   - Expected: ✅ Immediate access, NO authentication prompt
   - Actual: [Note what happens]

---

### Step 4: Document Results

For each subdomain, note:
- ✅ PASS: No authentication prompt, direct access
- ❌ FAIL: Authentication prompt appeared (unexpected)
- ❌ FAIL: Redirect loop or error

---

## What to Look For

### ✅ Success Indicators:
- Only first visit (grafana.inlock.ai) prompts for login
- All subsequent subdomains access without re-authentication
- Cookie visible in DevTools for `.inlock.ai` domain
- No errors in browser console

### ❌ Failure Indicators:
- Re-prompted on each subdomain (cookie domain issue)
- Redirect loop (Traefik forward-auth issue)
- CORS errors (Auth0 Web Origins issue)
- Cookie not visible (cookie domain mismatch)

---

## Log Monitoring

Logs are being captured automatically. After test, check:

```bash
# View captured logs
tail -100 /tmp/oauth2-proxy-test.log

# Or view live logs
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env logs -f oauth2-proxy
```

**Look for:**
- `[AuthSuccess]` - Successful authentication
- `No valid authentication` - Should only appear on first auth
- Cookie-related errors
- Redirect patterns

---

## After Test

1. Document results in `SSO-TEST-RESULTS.md`
2. Check logs for evidence
3. If all pass: Update status documents
4. If any fail: Document subdomain, symptom, and log snippets

---

**Ready to test?** Start with Step 1 above.

