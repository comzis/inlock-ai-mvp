# Auth0 Authentication - Ready to Test ✅

**Date:** December 10, 2025  
**Status:** All systems ready for manual browser testing

---

## ✅ Pre-Flight Checklist

- [x] Environment variables configured (OAuth2-Proxy + NextAuth.js)
- [x] Services healthy (inlock-ai, oauth2-proxy, traefik)
- [x] Configuration verified (`./scripts/check-auth-config.sh`)
- [x] Documentation complete
- [x] Helper scripts ready

---

## 🚀 Quick Start Testing

### 1. Start Log Monitoring (Optional but Recommended)

```bash
cd /home/comzis/inlock-infra
./scripts/test-auth-flow.sh all
```

Keep this running in a terminal to watch authentication flows in real-time.

### 2. Test Admin Authentication

**URL:** `https://traefik.inlock.ai/dashboard/`

**What to expect:**
- Browser redirects to Auth0 login
- After login, redirects back to Traefik dashboard
- Dashboard loads successfully

**Success indicators:**
- ✅ Dashboard accessible
- ✅ No redirect loops
- ✅ Can navigate dashboard features

### 3. Test Frontend Authentication

**URL:** `https://inlock.ai/auth/signin`

**What to expect:**
- NextAuth.js sign-in page appears
- Click "Sign in with Auth0"
- Auth0 login completes
- Redirects back to app with session

**Verify session in browser console:**
```javascript
// After login, in browser console:
import { useSession } from "next-auth/react";
const { data: session } = useSession();
console.log("User:", session?.user);
console.log("Roles:", session?.user?.roles);
```

### 4. Verify Role Claims

**Prerequisites:**
- Auth0 Action deployed (see setup guide)
- User has assigned roles in Auth0

**Expected result:**
```javascript
session.user.roles // Should be: ['admin'] or ['developer'] etc.
```

---

## 📊 Quick Commands

### Monitor Authentication
```bash
# All services
./scripts/test-auth-flow.sh all

# Just OAuth2-Proxy (admin auth)
./scripts/test-auth-flow.sh oauth2-proxy

# Just NextAuth.js (frontend auth)
./scripts/test-auth-flow.sh nextauth
```

### Check Configuration
```bash
./scripts/check-auth-config.sh
```

### View Logs
```bash
# OAuth2-Proxy
docker logs compose-oauth2-proxy-1 --tail 50

# NextAuth.js
docker logs compose-inlock-ai-1 --tail 50

# Traefik
docker logs compose-traefik-1 --tail 50
```

---

## 🔍 Troubleshooting

### Redirect Loop
```bash
# Check for repeated redirects
docker logs compose-oauth2-proxy-1 | grep -c "302"
# High count (>10) indicates loop
```

### 401 After Login
- Check Auth0 callback URLs match exactly
- Verify cookie domain settings
- Check OAuth2-Proxy logs for cookie errors

### Roles Not Appearing
- Verify Auth0 Action is deployed and active
- Check user has assigned roles in Auth0
- Check NextAuth.js logs for token parsing errors

---

## 📚 Documentation

- **Complete Setup:** `docs/AUTH0-NEXTAUTH-SETUP.md`
- **Testing Guide:** `docs/AUTH0-TESTING-GUIDE.md`
- **Quick Reference:** `docs/AUTH0-QUICK-REFERENCE.md`

---

## ✅ Expected Test Results

After completing all tests:

- [ ] Admin services accessible after Auth0 login
- [ ] Frontend app shows authenticated state
- [ ] Session contains user data
- [ ] Roles array populated correctly
- [ ] No redirect loops or errors

---

**Ready to test!** 🚀

If you encounter any issues, use the troubleshooting commands above or refer to the detailed testing guide.

