# Cockpit "Permission Denied" Fix Guide

## Problem
You see "Permission denied" error in Cockpit login even after changing your password.

## Common Causes & Solutions

### 1. Password Not Set Correctly (Most Common)

**Symptoms:**
- Password was just changed
- Still getting "Permission denied"
- Account status shows password is set

**Solution:**
```bash
# Verify password is actually set
sudo passwd -S comzis
# Should show: comzis P ... (P = password set)

# If it shows NP (no password), set it:
sudo passwd comzis
# Enter the password twice when prompted
```

**Important:** Make sure you:
- Type the password correctly (no typos)
- Use the same password in both fields
- Wait a few seconds after setting before trying to login

### 2. Password Has Special Characters

Some special characters can cause issues with web forms.

**Solution:**
- Try a simpler password first (letters and numbers only)
- Avoid: `" ' \ $ ` and other shell special characters
- Test with: `TestPassword123`

### 3. Browser Cache/Cookies

Old authentication cookies can interfere.

**Solution:**
1. Clear browser cache for `cockpit.inlock.ai`
2. Use incognito/private window
3. Try a different browser

### 4. PAM Authentication Delay

Sometimes PAM needs a moment to update.

**Solution:**
```bash
# Restart Cockpit after password change
sudo systemctl restart cockpit.socket
sudo systemctl restart cockpit.service

# Wait 10 seconds, then try again
```

### 5. Account Locked After Failed Attempts

Multiple failed login attempts can lock the account.

**Solution:**
```bash
# Check if account is locked
sudo passwd -S comzis
# If shows 'L' (locked), unlock it:
sudo passwd -u comzis

# Or use pam_tally2 to reset failed attempts
sudo pam_tally2 --user comzis --reset
```

### 6. PAM Configuration Issue

The PAM stack might have an issue.

**Solution:**
```bash
# Test password authentication directly
su - comzis
# Enter password when prompted
# If this works, the password is correct

# Check PAM logs
sudo journalctl -u cockpit.service -n 100 | grep -i auth
```

### 7. User in Disallowed List

User might be explicitly denied access.

**Solution:**
```bash
# Check disallowed users
cat /etc/cockpit/disallowed-users

# If comzis is listed, remove it:
sudo sed -i '/^comzis$/d' /etc/cockpit/disallowed-users
sudo systemctl restart cockpit.socket
```

## Step-by-Step Fix

### Quick Fix Script
```bash
sudo ./scripts/fix-cockpit-password-auth.sh
```

This script will:
1. Check account status
2. Unlock account if locked
3. Set password if missing
4. Remove from disallowed list
5. Restart Cockpit

### Manual Fix

1. **Verify password is set:**
   ```bash
   sudo passwd -S comzis
   ```
   Should show `P` (password set), not `NP` (no password) or `L` (locked)

2. **If password not set or locked:**
   ```bash
   sudo passwd comzis
   # Enter new password twice
   ```

3. **Unlock account if needed:**
   ```bash
   sudo passwd -u comzis
   ```

4. **Check disallowed users:**
   ```bash
   cat /etc/cockpit/disallowed-users
   # If comzis is listed, remove it
   ```

5. **Restart Cockpit:**
   ```bash
   sudo systemctl restart cockpit.socket
   sudo systemctl restart cockpit.service
   ```

6. **Wait 10 seconds, then try login again**

7. **Clear browser cache and try incognito window**

## Testing Password Authentication

### Test 1: Direct PAM Test
```bash
# Try to switch user with password
su - comzis
# Enter password when prompted
# If this works, password is correct
```

### Test 2: Check Password Hash
```bash
# Verify password hash exists
sudo grep "^comzis:" /etc/shadow
# Should show a password hash (not ! or *)
```

### Test 3: Test from SSH
```bash
# If you can SSH with password (if enabled), password works
ssh comzis@localhost
# Enter password
```

## Debugging

### Check Cockpit Logs
```bash
# Real-time logs
sudo journalctl -u cockpit.service -f

# Recent authentication attempts
sudo journalctl -u cockpit.service --since "10 minutes ago" | grep -i auth
```

### Check PAM Logs
```bash
# System auth logs
sudo tail -f /var/log/auth.log
# Or on some systems:
sudo tail -f /var/log/secure
```

### Test PAM Configuration
```bash
# Test PAM stack
pamtester cockpit comzis authenticate
# Enter password when prompted
```

## Common Mistakes

1. **Typo in password** - Double-check what you type
2. **Caps Lock on** - Check keyboard state
3. **Wrong username** - Make sure you're using the correct username
4. **Password not saved** - Some password managers don't save correctly
5. **Special characters** - Try a simple password first to test

## Still Not Working?

If none of the above works:

1. **Create a test user:**
   ```bash
   sudo useradd -m testuser
   sudo passwd testuser
   # Try logging in with testuser
   ```

2. **Check SELinux/AppArmor:**
   ```bash
   sudo getenforce  # Should show Disabled or Permissive
   sudo aa-status   # Check AppArmor status
   ```

3. **Reinstall Cockpit:**
   ```bash
   sudo apt update
   sudo apt install --reinstall cockpit
   sudo systemctl restart cockpit.socket
   ```

4. **Check for other authentication methods:**
   - Try SSH key authentication if configured
   - Check if OAuth/SSO is configured

## Verification

After fixing, verify:

1. **Account status:**
   ```bash
   sudo passwd -S comzis
   # Should show: comzis P ...
   ```

2. **Cockpit accessible:**
   ```bash
   curl -k -I https://cockpit.inlock.ai
   # Should return HTTP 200
   ```

3. **Can login:**
   - Visit https://cockpit.inlock.ai
   - Enter username: `comzis`
   - Enter password
   - Should successfully login

## Prevention

To avoid this in the future:

1. **Use strong, memorable passwords**
2. **Document password changes**
3. **Test login immediately after password change**
4. **Keep account unlocked:**
   ```bash
   sudo passwd -u comzis
   ```

