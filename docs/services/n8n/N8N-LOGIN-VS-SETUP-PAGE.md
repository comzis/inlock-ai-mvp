# n8n: Login Page vs Setup Page

## Problem
You see the **login page** but the database has **0 users**, so you should see the **setup page** instead.

## Root Cause
**Browser cache** - Your browser has cached the old JavaScript files that show the login page. The backend knows there are no users and wants to show the setup page, but the cached frontend code is overriding it.

## Solution

### Method 1: Hard Refresh (Fastest)
1. **Open Developer Tools**: Press `F12`
2. **Right-click the refresh button** (next to address bar)
3. **Select "Empty Cache and Hard Reload"**

Or use keyboard shortcut:
- **Windows/Linux**: `Ctrl + Shift + R` or `Ctrl + F5`
- **Mac**: `Cmd + Shift + R`

### Method 2: Clear Browser Cache
1. **Chrome/Edge**:
   - Settings → Privacy → Clear browsing data
   - Select "Cached images and files"
   - Time range: "Last hour" or "All time"
   - Click "Clear data"

2. **Firefox**:
   - Settings → Privacy → Clear Data
   - Check "Cached Web Content"
   - Click "Clear Now"

### Method 3: Incognito/Private Window
1. Open a new **incognito/private window**
2. Visit: `https://n8n.inlock.ai`
3. Should show setup page immediately

### Method 4: Clear Site Data (Most Thorough)
1. **Open Developer Tools**: `F12`
2. **Application tab** (Chrome) or **Storage tab** (Firefox)
3. **Clear storage** → **Clear site data**
4. **Refresh the page**

## Verification

After clearing cache, you should see:

**Setup Page** (when 0 users):
- Title: "Create your account" or "Welcome to n8n"
- Fields: Email, First Name, Last Name, Password
- Button: "Create account" or "Get started"

**Login Page** (when users exist):
- Title: "Sign in"
- Fields: Email, Password
- Button: "Sign in"
- Link: "Forgot my password"

## Why This Happens

n8n v1.123.5 (latest) has a completely rewritten frontend. When you:
1. Updated from an old version
2. Had users before (now deleted)
3. Browser cached the old login page JavaScript

The browser serves the cached login page, but the backend API knows there are no users and wants to show the setup page.

## Prevention

After fixing:
1. **Bookmark the setup page** once you create your account
2. **Use incognito** for testing
3. **Clear cache regularly** during development

## Still Not Working?

If you still see login page after clearing cache:

1. **Verify database is empty**:
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT COUNT(*) FROM \"user\";"
   # Should show: 0
   ```

2. **Check n8n logs**:
   ```bash
   docker logs compose-n8n-1 --tail 50
   ```

3. **Restart n8n**:
   ```bash
   docker compose -f compose/n8n.yml --env-file .env restart n8n
   ```

4. **Try different browser**:
   - If Chrome doesn't work, try Firefox or Edge
   - This confirms it's a cache issue

5. **Check API directly**:
   ```bash
   curl -k https://n8n.inlock.ai/api/v1/owner/setup
   # Should return setup data if 0 users
   ```

## Quick Reference

```bash
# Check users in database
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT COUNT(*) FROM \"user\";"

# If 0 users but see login page = browser cache
# Fix: Hard refresh (Ctrl+Shift+R) or clear cache

# If >0 users = login page is correct
# Use existing credentials or reset password
```

