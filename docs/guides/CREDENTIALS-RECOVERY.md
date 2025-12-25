# Credentials Recovery Guide

## Quick Reset

**Interactive reset script:**
```bash
./scripts/reset-all-credentials.sh
```

**Individual resets:**
```bash
# Reset n8n password
./scripts/reset-n8n-password.sh milorad@inlock.ai

# Reset Cockpit password
sudo ./scripts/reset-cockpit-password.sh comzis
```

## Delete and Recreate n8n User

**To delete existing user and create a new one:**

```bash
# Interactive (recommended)
./scripts/recreate-n8n-user.sh

# Or direct deletion
./scripts/delete-n8n-user.sh milorad@inlock.ai
```

After deletion:
1. Go to: `https://n8n.inlock.ai`
2. You'll see a setup screen (no users exist)
3. Enter your new email, name, and password
4. Click "Create Account"
5. The new user becomes the owner/admin

## n8n Credentials

### How n8n Authentication Works

n8n uses **email-based authentication**. There is no default username/password. The **first user to access n8n** becomes the owner/admin.

### Finding Your n8n Account

1. **Check database for registered users:**
   ```bash
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, first_name, last_name FROM \"user\";"
   ```

2. **If you see users listed**, use that email address to log in.

3. **If no users exist**, the first person to access `https://n8n.inlock.ai` will create the owner account.

### Resetting n8n Password

If you've forgotten your password:

1. **Access n8n directly** (bypass Traefik if needed):
   ```bash
   # Port forward to access locally
   docker port compose-n8n-1 5678
   ```

2. **Use password reset**:
   - Go to `https://n8n.inlock.ai`
   - Click "Forgot Password"
   - Enter your email address
   - Check email for reset link

3. **If email doesn't work**, you can reset via database:
   ```bash
   # WARNING: This will reset the password hash
   # You'll need to set a new password on next login
   docker exec compose-postgres-1 psql -U n8n -d n8n -c "UPDATE \"user\" SET password = NULL WHERE email = 'your-email@example.com';"
   ```

### Creating First n8n User

If n8n has no users yet:

1. Visit: `https://n8n.inlock.ai`
2. You'll see a setup screen
3. Enter:
   - **Email**: Your email address
   - **First Name**: Your first name
   - **Last Name**: Your last name
   - **Password**: Choose a strong password
4. Click "Create Account"

## Cockpit Credentials

### How Cockpit Authentication Works

Cockpit uses **Linux system user authentication**. You log in with your **Linux system username and password** (the same credentials you use for SSH).

### Finding Your Cockpit Credentials

1. **Check available system users:**
   ```bash
   cat /etc/passwd | grep -E "/bin/bash|/bin/sh" | cut -d: -f1
   ```

2. **Common usernames:**
   - `ubuntu` (default on Ubuntu servers)
   - `comzis` (if that's your user)
   - `root` (if enabled, but not recommended)

3. **Password**: Use the same password you use for SSH login to this server.

### Resetting Cockpit Password

If you've forgotten your system password:

1. **Reset via SSH** (if you have SSH key access):
   ```bash
   # SSH into the server
   ssh user@156.67.29.52
   
   # Change your password
   passwd
   ```

2. **Or reset root password** (if you have sudo access):
   ```bash
   sudo passwd username
   ```

3. **Then use the new password** to log into Cockpit at `https://cockpit.inlock.ai`

### Creating New Cockpit User

To create a new system user for Cockpit:

```bash
# Create new user
sudo adduser newusername

# Add to sudo group (optional, for admin access)
sudo usermod -aG sudo newusername

# Then log into Cockpit with: newusername / password
```

## Quick Reference

### n8n
- **URL**: `https://n8n.inlock.ai`
- **Authentication**: Email + Password (first user becomes owner)
- **Reset**: Use "Forgot Password" or database reset
- **First Setup**: Visit URL and create account

### Cockpit
- **URL**: `https://cockpit.inlock.ai`
- **Authentication**: Linux system username + password
- **Common Username**: `ubuntu` or your SSH username
- **Password**: Same as your SSH password

## Troubleshooting

### n8n: "No users found"
- Visit `https://n8n.inlock.ai` to create the first account
- Check database: `docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT * FROM \"user\";"`

### Cockpit: "Authentication failed"
- Verify user exists: `id username`
- Reset password: `sudo passwd username`
- Check Cockpit is running: `systemctl status cockpit.socket`

### Both: Can't access via URL
- Check IP allowlist: You must access from allowed IP (Tailscale or server IP)
- Check Traefik: `docker logs compose-traefik-1 | grep -i cockpit`
- Check service status: `docker ps | grep -E "(n8n|cockpit)"`

