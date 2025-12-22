# n8n Blank Page - Root Cause Analysis

## Problem
n8n shows blank page (sidebar visible, but no content) even after:
- Clearing browser cache
- Fixing encryption keys
- Adding N8N_TRUSTED_PROXIES
- Database has 0 users

## Root Cause
The frontend JavaScript is trying to call API endpoints that return 404:
- `/api/v1/owner/setup` → 404 Not Found
- `/rest/owner/setup` → 404 Not Found

The frontend can't determine if it should show:
- Setup page (0 users)
- Login page (users exist)

So it shows a blank page.

## Why This Happens
n8n v1.123.5 (latest) may have changed API endpoint paths. The frontend JavaScript is calling endpoints that don't exist in this version.

## Solutions

### Solution 1: Check Browser Console (Most Important)
1. Open Developer Tools (F12)
2. Go to Console tab
3. Look for RED errors mentioning:
   - `Failed to fetch`
   - `404 Not Found`
   - `/api/v1/owner/setup`
   - `/rest/owner/setup`
4. Go to Network tab
5. Reload page
6. Find failed API requests (RED entries)
7. Check which endpoint is being called and what error it returns

### Solution 2: Check n8n Logs for API Errors
```bash
docker logs compose-n8n-1 --tail 100 | grep -i -E "(error|404|route|endpoint)"
```

### Solution 3: Try Direct API Access
```bash
# Test various endpoints
curl -k https://n8n.inlock.ai/api/v1/owner/setup
curl -k https://n8n.inlock.ai/rest/owner/setup
curl -k https://n8n.inlock.ai/rest/owner/exists
curl -k https://n8n.inlock.ai/api/v1/users
```

### Solution 4: Downgrade to Known Working Version
If the API endpoints changed in v1.123.5, you could try a previous version:
```yaml
# In compose/n8n.yml
image: n8nio/n8n:1.64.2  # Previous stable version
```

### Solution 5: Check n8n Documentation
Check n8n v1.123.5 release notes for API changes:
- https://github.com/n8n-io/n8n/releases
- Look for breaking changes in API endpoints

## Debugging Steps

1. **Check browser console** - This will show the exact API call failing
2. **Check Network tab** - See which requests return 404
3. **Check n8n logs** - Look for route/endpoint errors
4. **Test API directly** - Try different endpoint paths
5. **Check n8n version** - Verify API compatibility

## Most Likely Fix

The browser console will show the exact error. Common issues:
1. **API endpoint changed** - Frontend calling wrong endpoint
2. **CORS issue** - API calls blocked
3. **Proxy header issue** - N8N_TRUSTED_PROXIES not working
4. **Authentication required** - Endpoint needs auth first

## Next Steps

1. **Open browser console (F12)**
2. **Copy the RED error message**
3. **Check Network tab for failed requests**
4. **Share the error details** - This will help identify the exact issue

The blank page is caused by the frontend JavaScript failing to call the correct API endpoint. The browser console will show exactly which endpoint is failing and why.

