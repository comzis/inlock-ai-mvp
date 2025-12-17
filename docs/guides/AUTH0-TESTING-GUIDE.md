# Auth0 Authentication - Testing Guide

**Date:** December 10, 2025  
**Status:** Ready for Manual Testing

---

## 🧪 Test Flow Checklist

### Test 1: Admin Authentication (OAuth2-Proxy)

**Endpoint:** `https://traefik.inlock.ai/dashboard/`

**Expected Flow:**
1. ✅ Browser requests Traefik dashboard
2. ✅ Traefik forward-auth calls OAuth2-Proxy
3. ✅ OAuth2-Proxy returns 401 (unauthenticated)
4. ✅ Browser redirects to Auth0 login
5. ✅ User authenticates with Auth0
6. ✅ Auth0 redirects to `https://auth.inlock.ai/oauth2/callback`
7. ✅ OAuth2-Proxy validates token and sets cookie
8. ✅ Browser redirects back to Traefik dashboard
9. ✅ Dashboard loads with authenticated session

**Verification:**
- [ ] Traefik dashboard loads after authentication
- [ ] User can access dashboard features
- [ ] No redirect loops
- [ ] Session persists across page refreshes

**Troubleshooting:**
```bash
# Check OAuth2-Proxy logs
docker logs compose-oauth2-proxy-1 --tail 50

# Check Traefik logs
docker logs compose-traefik-1 --tail 50

# Check for redirect loops
docker logs compose-oauth2-proxy-1 | grep -i "redirect\|302\|loop"
```

---

### Test 2: Frontend Authentication (NextAuth.js)

**Endpoint:** `https://inlock.ai/auth/signin`

**Expected Flow:**
1. ✅ NextAuth.js sign-in page loads
2. ✅ User clicks "Sign in with Auth0"
3. ✅ Browser redirects to Auth0 login
4. ✅ User authenticates with Auth0
5. ✅ Auth0 redirects to `https://inlock.ai/api/auth/callback/auth0`
6. ✅ NextAuth.js completes session setup
7. ✅ Browser redirects to app with authenticated session

**Verification:**
- [ ] Sign-in page loads correctly
- [ ] Auth0 login appears after clicking button
- [ ] After login, user is redirected back to app
- [ ] Session is available: `useSession()` returns user data
- [ ] Roles are present: `session.user.roles` contains array

**Check Session in Browser:**
```javascript
// In browser console (on inlock.ai):
import { useSession } from "next-auth/react";
const { data: session } = useSession();
console.log("User:", session?.user);
console.log("Roles:", session?.user?.roles);
```

**Troubleshooting:**
```bash
# Check NextAuth.js logs
docker logs compose-inlock-ai-1 --tail 50 | grep -i "auth\|error"

# Check for callback errors
docker logs compose-inlock-ai-1 | grep -i "callback\|auth0"
```

---

### Test 3: Role Claims Verification

**Prerequisites:**
- [ ] Auth0 Action created to inject roles into token
- [ ] User assigned roles in Auth0 (admin, developer, or viewer)

**Auth0 Action Setup:**
1. Go to: Auth0 Dashboard → Actions → Flows → Login
2. Create new Action: "Add Roles to Token"
3. Code:
   ```javascript
   exports.onExecutePostLogin = async (event, api) => {
     const namespace = 'https://inlock.ai';
     if (event.authorization) {
       api.idToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
     }
   };
   ```
4. Deploy Action
5. Add to Login flow (drag to flow)

**Assign Roles:**
1. Auth0 Dashboard → User Management → Users
2. Select test user
3. Roles tab → Assign Roles
4. Select: `admin`, `developer`, or `viewer`
5. Save

**Verification:**
- [ ] After login, check `session.user.roles` in app
- [ ] Roles array contains assigned roles: `['admin']` or similar
- [ ] Roles persist across page refreshes

**Check Roles:**
```javascript
// In app component or browser console:
const { data: session } = useSession();
if (session?.user?.roles) {
  console.log("User roles:", session.user.roles);
  // Should output: ['admin'] or ['developer', 'viewer'] etc.
}
```

---

## 🔍 Troubleshooting Commands

### Quick Log Checks

```bash
# OAuth2-Proxy logs (admin auth)
docker logs compose-oauth2-proxy-1 --tail 50 --follow

# NextAuth.js logs (frontend auth)
docker logs compose-inlock-ai-1 --tail 50 --follow

# Traefik logs (routing)
docker logs compose-traefik-1 --tail 50 --follow

# All auth-related logs
docker logs compose-oauth2-proxy-1 compose-inlock-ai-1 compose-traefik-1 --tail 20
```

### Common Issues

**Issue: Redirect Loop**
```bash
# Check for repeated redirects
docker logs compose-oauth2-proxy-1 | grep -c "302\|redirect"
# If count is very high (>10), there's a loop
```

**Issue: 401 Unauthorized After Login**
```bash
# Check cookie settings
docker logs compose-oauth2-proxy-1 | grep -i "cookie\|domain"

# Verify Auth0 callback URL matches
grep "OAUTH2_PROXY_REDIRECT_URL" /home/comzis/inlock-infra/compose/stack.yml
```

**Issue: Roles Not Appearing**
```bash
# Check NextAuth.js token processing
docker logs compose-inlock-ai-1 | grep -i "role\|claim\|token"

# Verify Auth0 Action is deployed
# Check Auth0 Dashboard → Actions → Flows → Login
```

**Issue: Callback URL Mismatch**
- Verify in Auth0 Dashboard:
  - `inlock-admin`: Callback = `https://auth.inlock.ai/oauth2/callback`
  - `inlock-web`: Callback = `https://inlock.ai/api/auth/callback/auth0`
- Check browser console for redirect errors
- Check network tab for failed requests

---

## 📊 Expected Log Patterns

### Successful OAuth2-Proxy Flow

```
[timestamp] traefik.inlock.ai GET "/oauth2/auth" 401
[timestamp] Performing OIDC Discovery...
[timestamp] Redirecting to https://comzis.eu.auth0.com/authorize...
[timestamp] auth.inlock.ai GET "/oauth2/callback?code=..." 302
[timestamp] traefik.inlock.ai GET "/dashboard/" 200
```

### Successful NextAuth.js Flow

```
[timestamp] GET /auth/signin 200
[timestamp] GET /api/auth/signin/auth0 302
[timestamp] GET /api/auth/callback/auth0?code=... 200
[timestamp] Session created for user: ...
```

---

## ✅ Success Criteria

**Admin Authentication:**
- [x] Traefik dashboard accessible after Auth0 login
- [x] No redirect loops
- [x] Session persists
- [x] Can access other admin services (Portainer, Grafana, n8n)

**Frontend Authentication:**
- [x] NextAuth.js sign-in page works
- [x] Auth0 login completes successfully
- [x] Session object contains user data
- [x] Roles array is populated correctly

**Role Claims:**
- [x] Auth0 Action deployed and active
- [x] User has assigned roles
- [x] Roles appear in `session.user.roles`
- [x] Roles can be used for authorization checks

---

## 🚨 If Tests Fail

1. **Capture Logs:**
   ```bash
   docker logs compose-oauth2-proxy-1 --tail 100 > /tmp/oauth2-proxy.log
   docker logs compose-inlock-ai-1 --tail 100 > /tmp/nextauth.log
   docker logs compose-traefik-1 --tail 100 > /tmp/traefik.log
   ```

2. **Check Browser Console:**
   - Open DevTools → Console
   - Look for JavaScript errors
   - Check Network tab for failed requests

3. **Verify Configuration:**
   ```bash
   # Check environment variables
   docker exec compose-oauth2-proxy-1 env | grep AUTH0
   docker exec compose-inlock-ai-1 env | grep AUTH0
   ```

4. **Test Auth0 Connection:**
   - Verify Auth0 tenant is accessible
   - Check application settings in Auth0 Dashboard
   - Verify callback URLs match exactly

---

**Last Updated:** December 10, 2025  
**Related:** `docs/AUTH0-NEXTAUTH-SETUP.md`, `docs/AUTH0-QUICK-REFERENCE.md`

