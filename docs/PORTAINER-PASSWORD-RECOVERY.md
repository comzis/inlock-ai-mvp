# Portainer Password Recovery

**Date:** 2025-12-13  
**Container:** `compose-portainer-1`  
**Status:** Running

---

## Method 1: Check Stored Password (If Available)

### Check Secret File

```bash
# Check if password is stored in secrets
cat /home/comzis/apps/secrets-real/portainer-admin-password
```

**If file exists and contains password:** Use that password to log in.

---

## Method 2: Reset Admin Password via Container

### Option A: Reset via Portainer API (Recommended)

**Step 1: Stop Portainer**

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env stop portainer
```

**Step 2: Remove Admin User Data**

```bash
# Portainer stores admin data in /data/portainer.db
# Remove the admin user record to force re-initialization

docker run --rm \
  -v /home/comzis/apps/traefik/portainer_data:/data \
  portainer/portainer-ce:latest \
  sh -c "rm -f /data/portainer.db && echo 'Admin data removed'"
```

**Step 3: Restart Portainer**

```bash
docker compose -f compose/stack.yml --env-file .env up -d portainer
```

**Step 4: Access Portainer**

1. Navigate to: `https://portainer.inlock.ai`
2. You'll be prompted to create a new admin account
3. Set your new password

---

## Method 3: Reset via SQLite (If Portainer Data Exists)

### Step 1: Access Portainer Data Volume

```bash
# Check where Portainer data is stored
docker inspect compose-portainer-1 --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' | grep data
```

### Step 2: Reset Admin Password in Database

```bash
# Install sqlite3 if needed
# sudo apt install sqlite3

# Access the database
sqlite3 /home/comzis/apps/traefik/portainer_data/portainer.db

# In sqlite prompt:
# .tables
# SELECT * FROM user;
# UPDATE user SET password='$2a$10$...' WHERE username='admin';
# .quit
```

**Note:** This requires generating a bcrypt hash, which is complex. Method 2 is easier.

---

## Method 4: Quick Reset (Delete Admin Data)

**Fastest method - removes admin user, forces re-initialization:**

```bash
cd /home/comzis/inlock-infra

# Stop Portainer
docker compose -f compose/stack.yml --env-file .env stop portainer

# Remove admin user data (keeps other data)
docker run --rm \
  -v /home/comzis/apps/traefik/portainer_data:/data \
  alpine:latest \
  sh -c "if [ -f /data/portainer.db ]; then sqlite3 /data/portainer.db 'DELETE FROM user WHERE username=\"admin\";' || rm -f /data/portainer.db; fi"

# Restart Portainer
docker compose -f compose/stack.yml --env-file .env up -d portainer
```

**After restart:**
1. Go to `https://portainer.inlock.ai`
2. Create new admin account
3. Set new password

---

## Method 5: Complete Reset (Delete All Data)

**⚠️ WARNING: This deletes ALL Portainer data (containers, stacks, etc.)**

```bash
cd /home/comzis/inlock-infra

# Stop Portainer
docker compose -f compose/stack.yml --env-file .env stop portainer

# Remove all Portainer data
rm -rf /home/comzis/apps/traefik/portainer_data/*

# Restart Portainer
docker compose -f compose/stack.yml --env-file .env up -d portainer
```

**After restart:**
1. Go to `https://portainer.inlock.ai`
2. Create new admin account
3. Set new password

---

## Recommended Approach

**Use Method 2 (Reset via Container) or Method 4 (Quick Reset)**

Both methods will:
- Preserve your Portainer configuration
- Force admin account re-initialization
- Allow you to set a new password

---

## After Password Reset

1. **Log in** with new password
2. **Update secret file** (optional):
   ```bash
   echo "your-new-password" > /home/comzis/apps/secrets-real/portainer-admin-password
   ```
3. **Verify access** to all features

---

## Troubleshooting

### If Portainer Won't Start After Reset

```bash
# Check logs
docker compose -f compose/stack.yml --env-file .env logs portainer --tail 50

# Check permissions
ls -la /home/comzis/apps/traefik/portainer_data/

# Fix permissions if needed
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data/
```

### If You Can't Access Portainer UI

1. Check if service is running:
   ```bash
   docker compose -f compose/stack.yml --env-file .env ps portainer
   ```

2. Check if accessible via OAuth2-Proxy:
   - Portainer is protected by OAuth2-Proxy
   - You need to authenticate via Auth0 first
   - Then access Portainer

---

**Quick Command Reference:**

```bash
# Check current password (if stored)
cat /home/comzis/apps/secrets-real/portainer-admin-password

# Quick reset (recommended)
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env stop portainer
docker run --rm -v /home/comzis/apps/traefik/portainer_data:/data alpine:latest sh -c "rm -f /data/portainer.db"
docker compose -f compose/stack.yml --env-file .env up -d portainer
```

