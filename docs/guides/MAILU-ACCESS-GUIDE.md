# Mailu Email Access Guide

**Date:** December 11, 2025  
**Purpose:** Guide for accessing Mailu webmail and setting up admin@inlock.ai account

---

## 🔐 Accessing Mailu Admin Interface

### Step 1: Access Admin UI via Browser

1. **Navigate to:** `https://mail.inlock.ai/admin`
2. **Authentication Flow:**
   - You'll first be redirected to Auth0 (OAuth2) for authentication
   - After Auth0 authentication, you'll access the Mailu admin interface
   - The admin interface requires the Mailu admin password (stored in secrets)

### Step 2: Get Mailu Admin Password

The Mailu admin password is stored in a Docker secret. To retrieve it:

```bash
# View the admin password
cat /home/comzis/apps/secrets-real/mailu-admin-password

# Or if you need to set a new password, edit the file:
# nano /home/comzis/apps/secrets-real/mailu-admin-password
# Then restart Mailu admin service:
# docker compose -f compose/mailu.yml restart mailu-admin
```

**Note:** The admin user is configured as `admin` (see `ADMIN_USER=admin` in compose file).

### Step 3: Login to Mailu Admin

1. After Auth0 authentication, you'll see the Mailu admin login page
2. **Username:** `admin`
3. **Password:** (from the secret file above)
4. Click "Login"

---

## 👤 Creating admin@inlock.ai Account

### Option 1: Via Mailu Admin Web Interface (Recommended)

1. **Access Admin UI:** `https://mail.inlock.ai/admin` (after Auth0 auth)
2. **Login** with admin credentials (see above)
3. **Navigate to:** "Users" → "Add User"
4. **Fill in the form:**
   - **Email:** `admin@inlock.ai`
   - **Password:** (choose a strong password)
   - **Quota:** Set mailbox quota (e.g., 10GB)
   - **Features:** Enable IMAP, SMTP, etc.
   - **Admin:** Check "Admin" checkbox if you want this user to have admin privileges
5. **Click "Save"**

### Option 2: Via Mailu Admin API (Command Line)

```bash
# Get the admin password from secrets
ADMIN_PW=$(cat /home/comzis/apps/secrets-real/mailu-admin-password)

# Create admin@inlock.ai user via API
docker exec compose-mailu-admin-1 \
  flask mailu admin admin inlock.ai admin@inlock.ai \
  --password "YOUR_PASSWORD_HERE" \
  --quota 10737418240
```

### Option 3: Via Docker Exec (Direct Database)

```bash
# Access Mailu admin container
docker exec -it compose-mailu-admin-1 bash

# Inside the container, use Mailu CLI
flask mailu admin admin inlock.ai admin@inlock.ai \
  --password "YOUR_PASSWORD_HERE" \
  --quota 10737418240
```

---

## 📧 Accessing Webmail Client

### Webmail Access

1. **Navigate to:** `https://mail.inlock.ai`
2. **Login with:**
   - **Email:** `admin@inlock.ai`
   - **Password:** (the password you set when creating the account)
3. **Features Available:**
   - Send/receive emails
   - Manage folders
   - Configure settings
   - Access calendar (if enabled)

**Note:** Webmail is publicly accessible (no OAuth2 required) but is rate-limited for security.

---

## 📱 Configuring Email Clients (IMAP/SMTP)

### For admin@inlock.ai Account

Use these settings in your email client (Thunderbird, Outlook, Apple Mail, etc.):

#### **IMAP Settings (Incoming Mail)**
- **Server:** `mail.inlock.ai`
- **Port:** `993` (IMAPS - SSL/TLS)
- **Security:** SSL/TLS (or STARTTLS on port 143)
- **Username:** `admin@inlock.ai`
- **Password:** (your account password)
- **Authentication:** Normal password

#### **SMTP Settings (Outgoing Mail)**
- **Server:** `mail.inlock.ai`
- **Port:** `587` (Submission - STARTTLS) or `465` (SMTPS - SSL/TLS)
- **Security:** STARTTLS (port 587) or SSL/TLS (port 465)
- **Username:** `admin@inlock.ai`
- **Password:** (your account password)
- **Authentication:** Required

### Port Summary
- **IMAP:** 143 (STARTTLS) or 993 (SSL/TLS)
- **SMTP:** 25 (SMTP), 465 (SMTPS), or 587 (Submission)

**Recommended:** Use ports 993 (IMAP) and 587 (SMTP) for best compatibility.

---

## 🔧 Troubleshooting

### Cannot Access Admin UI

1. **Check if Mailu services are running:**
   ```bash
   docker compose -f compose/mailu.yml ps
   ```

2. **Check Mailu logs:**
   ```bash
   docker compose -f compose/mailu.yml logs mailu-front
   docker compose -f compose/mailu.yml logs mailu-admin
   ```

3. **Verify Traefik routing:**
   ```bash
   curl -I https://mail.inlock.ai/admin
   ```

4. **Check Auth0 configuration:**
   - Ensure OAuth2-Proxy is running
   - Verify Auth0 client is configured correctly

### Cannot Create User

1. **Verify domain is configured:**
   - In Mailu admin UI, go to "Domains"
   - Ensure `inlock.ai` domain exists
   - If not, create it first

2. **Check database connection:**
   ```bash
   docker compose -f compose/mailu.yml logs mailu-postgres
   docker compose -f compose/mailu.yml logs mailu-admin
   ```

3. **Verify admin password:**
   - Ensure the admin password secret file exists and is readable
   - Check file permissions: `ls -la /home/comzis/apps/secrets-real/mailu-admin-password`

### Cannot Access Webmail

1. **Check if webmail service is running:**
   ```bash
   docker compose -f compose/mailu.yml ps mailu-front
   ```

2. **Test webmail endpoint:**
   ```bash
   curl -I https://mail.inlock.ai
   ```

3. **Check DNS:**
   ```bash
   dig A mail.inlock.ai
   ```

### Email Client Connection Issues

1. **Verify ports are accessible:**
   ```bash
   # Test IMAP
   telnet mail.inlock.ai 993
   # Test SMTP
   telnet mail.inlock.ai 587
   ```

2. **Check firewall rules:**
   - Ensure ports 25, 465, 587, 143, 993 are open
   - Verify firewall allowlists are configured correctly

3. **Test with openssl:**
   ```bash
   # Test IMAPS
   openssl s_client -connect mail.inlock.ai:993
   
   # Test SMTPS
   openssl s_client -connect mail.inlock.ai:465
   ```

---

## 📋 Quick Reference

### URLs
- **Admin UI:** `https://mail.inlock.ai/admin`
- **Webmail:** `https://mail.inlock.ai`
- **SMTP:** `mail.inlock.ai:587` (STARTTLS) or `:465` (SSL)
- **IMAP:** `mail.inlock.ai:993` (SSL) or `:143` (STARTTLS)

### Default Admin Credentials
- **Username:** `admin` (Mailu admin user)
- **Password:** (stored in `/home/comzis/apps/secrets-real/mailu-admin-password`)

### First User Account
- **Email:** `admin@inlock.ai`
- **Password:** (set when creating the account)
- **Created via:** Mailu Admin UI or CLI

---

## 🔄 Changing Admin Password

### Change Mailu Admin Password

```bash
# Edit the secret file
nano /home/comzis/apps/secrets-real/mailu-admin-password

# Restart Mailu admin service
docker compose -f compose/mailu.yml restart mailu-admin
```

### Change User Account Password

1. **Via Admin UI:**
   - Login to `https://mail.inlock.ai/admin`
   - Go to "Users" → Select user → "Edit" → Change password

2. **Via CLI:**
   ```bash
   docker exec compose-mailu-admin-1 \
     flask mailu user admin inlock.ai admin@inlock.ai \
     --password "NEW_PASSWORD"
   ```

---

## 📚 Additional Resources

- **Mailu Documentation:** https://mailu.io/2.0/
- **Mailu Admin Guide:** https://mailu.io/2.0/user/admin.html
- **Email Client Configuration:** https://mailu.io/2.0/user/clients.html

---

**Last Updated:** December 11, 2025
