# n8n Complete Fix Guide

## Problem
n8n shows login page instead of setup page, or has authentication/encryption issues.

## Root Causes

1. **Encryption Key Mismatch** - Config file has different key than environment variable
2. **Browser Cache** - Old JavaScript files cached
3. **Database State** - Users exist when they shouldn't (or vice versa)
4. **Configuration Issues** - Wrong paths or settings

## Complete Fix Script

Run this to fix ALL issues at once:

```bash
sudo ./scripts/fix-n8n-complete.sh
```

This script will:
1. ✅ Fix encryption key mismatch
2. ✅ Update config file with correct key
3. ✅ Clear database users (optional, to show setup page)
4. ✅ Pull latest n8n image
5. ✅ Restart n8n with correct configuration
6. ✅ Verify everything works

## Manual Fix Steps

If you prefer to fix manually:

### 1. Fix Encryption Key

```bash
# Stop n8n
docker compose -f compose/n8n.yml --env-file .env stop n8n

# Get encryption key
ENCRYPTION_KEY=$(cat /home/comzis/apps/secrets-real/n8n-encryption-key | tr -d '\n\r')

# Update config file
VOLUME_PATH=$(docker volume inspect compose_n8n_data | grep Mountpoint | awk '{print $2}' | tr -d '",')
sudo sh -c "echo '{\"encryptionKey\": \"'$ENCRYPTION_KEY'\"}' > $VOLUME_PATH/config"
sudo chmod 600 $VOLUME_PATH/config
sudo chown 1000:1000 $VOLUME_PATH/config

# Start n8n
docker compose -f compose/n8n.yml --env-file .env up -d n8n
```

### 2. Clear Database Users (to show setup page)

```bash
# Delete all users
docker exec compose-postgres-1 psql -U n8n -d n8n <<EOF
DELETE FROM workflow_entity WHERE "ownerId" IN (SELECT id FROM "user");
DELETE FROM credentials_entity WHERE "userId" IN (SELECT id FROM "user");
DELETE FROM execution_entity WHERE "workflowId" IN (SELECT id FROM workflow_entity WHERE "ownerId" IN (SELECT id FROM "user"));
DELETE FROM "user";
EOF
```

### 3. Clear Browser Cache

- **Hard refresh**: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
- **Clear cache**: Settings → Clear browsing data → Cached files
- **Incognito window**: Try in private/incognito mode

### 4. Verify Configuration

```bash
# Check encryption key path
grep N8N_ENCRYPTION_KEY_FILE compose/n8n.yml
# Should show: N8N_ENCRYPTION_KEY_FILE=/run/secrets/n8n-encryption-key

# Check image tag
grep "image:" compose/n8n.yml
# Should show: image: n8nio/n8n:latest

# Check database users
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT COUNT(*) FROM \"user\";"
# 0 = setup page, >0 = login page
```

## Expected Behavior

### Setup Page (0 users)
- Shows "Create your account" form
- Fields: Email, First Name, Last Name, Password
- Appears when database has 0 users

### Login Page (users exist)
- Shows "Sign in" form
- Fields: Email, Password
- Appears when database has users

## Troubleshooting

### Still seeing login page with 0 users?

1. **Hard refresh browser** (most common fix)
   ```bash
   # In browser: Ctrl+Shift+R or Cmd+Shift+R
   ```

2. **Clear browser cache completely**
   - Chrome: Settings → Privacy → Clear browsing data
   - Firefox: Settings → Privacy → Clear Data

3. **Check n8n logs**
   ```bash
   docker logs compose-n8n-1 --tail 50
   ```

4. **Verify database is actually empty**
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email FROM \"user\";"
   ```

5. **Restart n8n**
   ```bash
   docker compose -f compose/n8n.yml --env-file .env restart n8n
   ```

### Encryption key errors?

1. **Check secret file exists**
   ```bash
   cat /home/comzis/apps/secrets-real/n8n-encryption-key
   ```

2. **Verify secret is mounted**
   ```bash
   docker exec compose-n8n-1 cat /run/secrets/n8n-encryption-key
   ```

3. **Check config file matches**
   ```bash
   docker exec compose-n8n-1 cat /home/node/.n8n/config
   ```

### Database connection issues?

1. **Check PostgreSQL is running**
   ```bash
   docker ps | grep postgres
   ```

2. **Test connection**
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT 1;"
   ```

3. **Check credentials**
   ```bash
   docker exec compose-n8n-1 env | grep DB_
   ```

## Verification

After running the fix script:

1. **Check n8n is running**
   ```bash
   docker ps | grep n8n
   # Should show: Up ... (healthy)
   ```

2. **Check database users**
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT COUNT(*) FROM \"user\";"
   ```

3. **Test access**
   ```bash
   curl -k -I https://n8n.inlock.ai
   # Should return: HTTP/2 200
   ```

4. **Visit in browser**
   - Go to: https://n8n.inlock.ai
   - Should see setup page (if 0 users) or login page (if users exist)

## Prevention

To avoid these issues in the future:

1. **Keep encryption key consistent**
   - Don't change it unless necessary
   - Always update both config file and secret file

2. **Use latest image tag**
   - Keep `image: n8nio/n8n:latest` in compose file
   - Run `docker compose pull n8n` regularly

3. **Document password changes**
   - Keep track of user accounts
   - Use password manager

4. **Regular backups**
   - Backup database: `docker exec compose-postgres-1 pg_dump -U n8n n8n > backup.sql`
   - Backup config: `docker volume inspect compose_n8n_data`

## Quick Reference

```bash
# Complete fix
sudo ./scripts/fix-n8n-complete.sh

# Check status
docker ps | grep n8n
docker logs compose-n8n-1 --tail 20

# Check database
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email FROM \"user\";"

# Restart
docker compose -f compose/n8n.yml --env-file .env restart n8n

# Clear users (show setup page)
./scripts/force-n8n-setup-mode.sh
```

