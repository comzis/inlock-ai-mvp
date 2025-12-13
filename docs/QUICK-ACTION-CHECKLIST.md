# Quick Action Checklist - Auth0 Recovery

**Use this checklist for immediate action.**

## 5-Minute Auth0 Dashboard Check

- [ ] Go to: https://manage.auth0.com/
- [ ] Applications → Applications → `inlock-admin`
- [ ] Check "Allowed Callback URLs": Should be `https://auth.inlock.ai/oauth2/callback`
- [ ] Check "Allowed Web Origins": Should be `https://auth.inlock.ai`
- [ ] If missing/wrong: Update and Save
- [ ] Screenshot: [capture callback URL field]

## 10-Minute Browser Test

- [ ] Clear cookies for `*.inlock.ai`
- [ ] Open DevTools (Network + Console)
- [ ] Go to: https://grafana.inlock.ai
- [ ] What happens?
  - [ ] Redirects to Auth0 login → ✅ Good
  - [ ] Shows error → ❌ Problem
  - [ ] Redirect loop → ❌ Problem
- [ ] Complete login
- [ ] What happens?
  - [ ] Access granted → ✅ Good
  - [ ] Access denied → ❌ Problem
- [ ] Check cookie: `inlock_session` present?
- [ ] Screenshot: [capture final state]

## If Problem Found

1. **Auth0 Dashboard Issue:**
   - Fix callback URL
   - Wait 30 seconds
   - Test again

2. **Cookie Issue:**
   - Check cookie domain, SameSite, Secure
   - Verify: Should be `.inlock.ai`, `None`, `true`

3. **Redirect Loop:**
   - Check OAuth2-Proxy logs
   - Verify callback URL matches Auth0
   - Restart OAuth2-Proxy if needed

## If Still Broken

Activate fallback (see `docs/STRIKE-TEAM-DELIVERABLES.md` section 4)

