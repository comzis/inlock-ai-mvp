# n8n Blank Page After Login - Fix Guide

## Issue
After logging into n8n, you see a blank page instead of the workflow interface.

## Common Causes

1. **Browser Cache**: Old JavaScript files cached
2. **API Path Changes**: New n8n version uses different API paths
3. **Static Assets**: JavaScript/CSS files not loading
4. **Encryption Key**: Issues with encryption key configuration

## Quick Fixes

### 1. Clear Browser Cache (Most Common)

**Hard Refresh:**
- Windows/Linux: `Ctrl + Shift + R` or `Ctrl + F5`
- Mac: `Cmd + Shift + R`

**Or Clear Cache:**
- Chrome: Settings → Privacy → Clear browsing data → Cached images and files
- Firefox: Settings → Privacy → Clear Data → Cached Web Content

**Or Use Incognito/Private Window:**
- This bypasses cache completely

### 2. Check Browser Console

1. Open Developer Tools (F12)
2. Go to Console tab
3. Look for JavaScript errors (red text)
4. Go to Network tab
5. Reload page
6. Check for failed requests (red entries)

Common errors:
- `404` on JavaScript files → Asset path issue
- `CORS` errors → Traefik configuration
- `401/403` on API calls → Authentication issue

### 3. Verify n8n is Running

```bash
docker ps | grep n8n
docker logs compose-n8n-1 --tail 50
```

### 4. Check API Endpoints

The new n8n version (1.123.5) may use different API paths:

```bash
# Test API
curl -k https://n8n.inlock.ai/api/v1/me
curl -k https://n8n.inlock.ai/rest/login
```

### 5. Restart n8n

```bash
docker compose -f compose/n8n.yml --env-file .env restart n8n
```

Wait 30 seconds, then try again.

### 6. Check Encryption Key

```bash
# Verify encryption key exists
cat /home/comzis/apps/secrets-real/n8n-encryption-key

# Should NOT be "replace-with-strong-key"
```

If it's the default, generate a new one:
```bash
openssl rand -base64 32 > /home/comzis/apps/secrets-real/n8n-encryption-key
chmod 600 /home/comzis/apps/secrets-real/n8n-encryption-key
docker compose -f compose/n8n.yml --env-file .env restart n8n
```

## Version-Specific Issues

### n8n 1.123.5 (Latest)

This is a major version update from 1.64.2. Changes include:

1. **New API structure** - May use `/api/v1/` instead of `/rest/`
2. **Task runners** - New feature, may need configuration
3. **UI changes** - Frontend completely rewritten

### If Blank Page Persists

1. **Check n8n logs for errors:**
   ```bash
   docker logs compose-n8n-1 --tail 100 | grep -i error
   ```

2. **Verify database migrations completed:**
   ```bash
   docker logs compose-n8n-1 | grep -i migration
   ```

3. **Check if user exists:**
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email FROM \"user\";"
   ```

4. **Try accessing directly (bypass Traefik):**
   ```bash
   docker port compose-n8n-1 5678
   # Then access: http://YOUR_IP:PORT
   ```

5. **Delete user and recreate:**
   ```bash
   ./scripts/delete-n8n-user.sh your-email@example.com
   # Then visit https://n8n.inlock.ai to create new account
   ```

## Script to Diagnose

Run the diagnostic script:
```bash
./scripts/fix-n8n-blank-page.sh
```

This will check:
- Encryption key
- Service status
- Database connection
- API endpoints
- Static assets

## Most Likely Solution

**For n8n 1.123.5 blank page:**

1. **Hard refresh browser** (Ctrl+Shift+R)
2. **Clear browser cache** for n8n.inlock.ai
3. **Check browser console** for JavaScript errors
4. **Try incognito window**

The new version has a completely rewritten frontend, so old cached files will cause issues.

