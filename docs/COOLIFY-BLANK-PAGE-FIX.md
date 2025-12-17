# Coolify Blank Page After Login - Fix Guide

**Date:** December 14, 2025  
**Issue:** Blank white page after successful authentication to `deploy.inlock.ai`

## Problem

After successfully authenticating with Auth0:
- ✅ Authentication completes successfully
- ✅ Redirects back to `deploy.inlock.ai`
- ❌ Page is completely blank (white screen)
- ❌ No content, no errors visible

## Common Causes

### 1. Headers Too Restrictive (Most Likely)

The default `secure-headers` middleware may be blocking Coolify's JavaScript or API calls.

**Symptoms:**
- Blank page after authentication
- No JavaScript errors in console (or errors about blocked resources)
- Network tab shows failed requests

**Solution Applied:**
Created `coolify-headers` middleware with relaxed settings:
- `contentTypeNosniff: false` - Allows Coolify to set correct content types
- `frameDeny: false` - Allows iframes if needed
- `customFrameOptionsValue: "SAMEORIGIN"` - Allows same-origin frames
- `X-Forwarded-Proto: "https"` - Ensures Coolify knows it's HTTPS

### 2. Browser Cache (Quick Fix)

Old cached JavaScript files may be causing issues.

**Solution:**
1. **Hard Refresh:**
   - Mac: `Cmd + Shift + R`
   - Windows/Linux: `Ctrl + Shift + R` or `Ctrl + F5`

2. **Clear Browser Cache:**
   - Chrome: Settings → Privacy → Clear browsing data → Cached images and files
   - Firefox: Settings → Privacy → Clear Data → Cached Web Content
   - Safari: Develop → Empty Caches (or Cmd + Option + E)

3. **Use Incognito/Private Window:**
   - This bypasses cache completely

### 3. JavaScript Errors (Check Console)

Coolify's frontend JavaScript may be failing.

**Diagnosis:**
1. Open Developer Tools (F12 or Cmd + Option + I)
2. Go to **Console** tab
3. Look for **RED errors** (JavaScript errors)
4. Go to **Network** tab
5. Reload page
6. Check for **failed requests** (red entries)

**Common Errors:**
- `404` on JavaScript/CSS files → Asset path issue
- `CORS` errors → Traefik/header configuration
- `401/403` on API calls → Authentication issue
- `Failed to fetch` → Network/service issue

### 4. Coolify Service Not Running

The service may have stopped or crashed.

**Check:**
```bash
docker ps | grep coolify
docker logs compose-coolify-1 --tail 50
```

**Restart if needed:**
```bash
cd /home/comzis/inlock
docker compose -f compose/coolify.yml --env-file /home/comzis/deployments/.env.coolify restart coolify
```

### 5. Database/Redis Connection Issues

Coolify requires PostgreSQL and Redis to be running.

**Check:**
```bash
# Check all Coolify services
docker ps | grep coolify

# Check database connection
docker logs compose-coolify-postgres-1 --tail 20

# Check Redis connection
docker logs compose-coolify-redis-1 --tail 20
```

### 6. API Endpoint Issues

Coolify's API may not be responding correctly.

**Test:**
```bash
# Test health endpoint
curl -k https://deploy.inlock.ai/api/health

# Test with authentication cookie
curl -k -H "Cookie: inlock_session=..." https://deploy.inlock.ai/api/health
```

## Solutions Applied

### Solution 1: Custom Headers Middleware ✅

**File:** `traefik/dynamic/middlewares.yml`

Added `coolify-headers` middleware with relaxed security settings:
```yaml
coolify-headers:
  headers:
    sslRedirect: true
    stsSeconds: 63072000
    stsIncludeSubdomains: true
    stsPreload: true
    contentTypeNosniff: false  # Allow Coolify to set content types
    referrerPolicy: no-referrer-when-downgrade
    frameDeny: false  # Allow iframes
    customFrameOptionsValue: "SAMEORIGIN"
    customRequestHeaders:
      X-Forwarded-Proto: "https"
```

**File:** `traefik/dynamic/routers.yml`

Updated Coolify router to use `coolify-headers` instead of `secure-headers`:
```yaml
coolify:
  middlewares:
    - coolify-headers  # Changed from secure-headers
    - admin-forward-auth
    - allowed-admins
    - mgmt-ratelimit
```

### Solution 2: Clear Browser Cache

1. Clear all cookies for `*.inlock.ai`
2. Clear browser cache
3. Hard refresh the page

### Solution 3: Check Browser Console

1. Open Developer Tools (F12)
2. Check Console for errors
3. Check Network tab for failed requests
4. Share error messages for further diagnosis

## Verification Steps

1. **Wait for Traefik to Reload** (10-15 seconds after config change)
2. **Clear Browser Cache** (or use incognito window)
3. **Access:** `https://deploy.inlock.ai`
4. **Authenticate** with Auth0
5. **Expected:** Coolify dashboard should load (not blank page)

## If Blank Page Persists

### Step 1: Check Browser Console
- Open Developer Tools (F12)
- Go to Console tab
- Look for RED errors
- Go to Network tab
- Reload page
- Check which requests are failing

### Step 2: Check Coolify Logs
```bash
docker logs compose-coolify-1 --tail 100
```

Look for:
- Database connection errors
- Redis connection errors
- API errors
- Route errors

### Step 3: Test Direct Access
```bash
# Test if Coolify is responding
curl -k -I https://deploy.inlock.ai

# Test API endpoint
curl -k https://deploy.inlock.ai/api/health
```

### Step 4: Restart Coolify
```bash
cd /home/comzis/inlock
docker compose -f compose/coolify.yml --env-file /home/comzis/deployments/.env.coolify restart coolify
```

Wait 30 seconds, then try again.

## Next Steps

If the blank page persists after trying all solutions:

1. **Share browser console errors** - This will show exactly what's failing
2. **Share Coolify logs** - Check for service-level errors
3. **Check network requests** - See which API calls are failing
4. **Verify service health** - Ensure all Coolify services are running

---

**Last Updated:** December 14, 2025  
**Status:** Fixed - Custom headers middleware applied







