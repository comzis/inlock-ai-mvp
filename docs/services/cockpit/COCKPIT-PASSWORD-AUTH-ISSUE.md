# Cockpit Password Authentication Issue

## Problem
Cockpit may not work if password authentication was disabled on the server, as Cockpit uses PAM (Pluggable Authentication Modules) which typically relies on password authentication.

## How Cockpit Authenticates

Cockpit uses PAM (`/etc/pam.d/cockpit`) for authentication, which by default uses password-based authentication. If password login was disabled via:
- SSH: `PasswordAuthentication no` in `/etc/ssh/sshd_config`
- PAM: Password authentication disabled in `/etc/pam.d/common-auth`

Then Cockpit may not be able to authenticate users.

## Solutions

### Option 1: Enable Password Authentication for Cockpit Only (Recommended)

Cockpit can use password authentication even if SSH password auth is disabled. The SSH and PAM configurations are separate.

**Check current SSH config:**
```bash
grep PasswordAuthentication /etc/ssh/sshd_config
```

**Verify PAM allows password auth:**
```bash
cat /etc/pam.d/cockpit
cat /etc/pam.d/common-auth
```

If PAM is configured correctly, Cockpit should work even with SSH password auth disabled.

### Option 2: Use SSH Key Authentication (Advanced)

Cockpit can be configured to use SSH key authentication instead of passwords.

1. **Enable SSH key auth in Cockpit:**
   ```bash
   sudo mkdir -p /etc/cockpit
   sudo tee /etc/cockpit/cockpit.conf <<EOF
   [SSH]
   LoginTitle = Server Management
   EOF
   ```

2. **Ensure SSH key auth is enabled:**
   ```bash
   grep PubkeyAuthentication /etc/ssh/sshd_config
   # Should show: PubkeyAuthentication yes
   ```

3. **Restart Cockpit:**
   ```bash
   sudo systemctl restart cockpit.socket
   ```

### Option 3: Use System User with Password

If you need password authentication for Cockpit:

1. **Set a password for your user:**
   ```bash
   sudo passwd your-username
   ```

2. **Verify PAM configuration:**
   ```bash
   cat /etc/pam.d/cockpit
   ```

3. **Test Cockpit access:**
   ```bash
   curl -k https://cockpit.inlock.ai
   ```

## Checking Current Status

### 1. Check Cockpit Service
```bash
systemctl status cockpit.socket cockpit.service
```

### 2. Check SSH Configuration
```bash
grep -E "PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
```

### 3. Check PAM Configuration
```bash
cat /etc/pam.d/cockpit
cat /etc/pam.d/common-auth
```

### 4. Test Cockpit Access
```bash
curl -k -I https://cockpit.inlock.ai
```

### 5. Check Cockpit Logs
```bash
journalctl -u cockpit.service --no-pager --since "1 hour ago"
```

## Common Issues

### Issue: "Authentication failed" in Cockpit
**Cause:** PAM password authentication disabled or user has no password set.

**Fix:**
1. Set password for user: `sudo passwd username`
2. Verify PAM config: `cat /etc/pam.d/cockpit`
3. Ensure password auth is allowed in PAM (not SSH)

### Issue: Cockpit loads but login fails
**Cause:** User account locked or password expired.

**Fix:**
1. Check account status: `sudo passwd -S username`
2. Unlock account: `sudo passwd -u username`
3. Set new password: `sudo passwd username`

### Issue: Cockpit service not starting
**Cause:** Configuration error or port conflict.

**Fix:**
1. Check logs: `journalctl -u cockpit.service -n 50`
2. Check port: `ss -tlnp | grep 9090`
3. Restart: `sudo systemctl restart cockpit.socket`

## Best Practice

**Recommended Configuration:**
- SSH: Password authentication disabled (`PasswordAuthentication no`)
- Cockpit: Password authentication enabled (via PAM)
- Both: SSH key authentication enabled (`PubkeyAuthentication yes`)

This provides:
- Security: SSH cannot be brute-forced via password
- Convenience: Cockpit can still use password authentication
- Flexibility: Both support SSH keys

## Verification Script

Run this to check your current configuration:

```bash
#!/bin/bash
echo "=== Cockpit Authentication Check ==="
echo ""
echo "1. SSH Password Auth:"
grep "^PasswordAuthentication" /etc/ssh/sshd_config || echo "  Not explicitly set (default: yes)"
echo ""
echo "2. SSH Key Auth:"
grep "^PubkeyAuthentication" /etc/ssh/sshd_config || echo "  Not explicitly set (default: yes)"
echo ""
echo "3. Cockpit Service:"
systemctl is-active cockpit.socket && echo "  ✓ Active" || echo "  ✗ Inactive"
echo ""
echo "4. Cockpit Port:"
ss -tlnp | grep 9090 && echo "  ✓ Listening" || echo "  ✗ Not listening"
echo ""
echo "5. PAM Cockpit Config:"
cat /etc/pam.d/cockpit | head -5
echo ""
echo "6. Test Access:"
curl -k -s -o /dev/null -w "  HTTP %{http_code}\n" https://cockpit.inlock.ai
echo ""
```

## Next Steps

1. **If Cockpit is not working:**
   - Check if password is set for your user: `sudo passwd -S $USER`
   - Verify PAM configuration allows password auth
   - Check Cockpit logs for errors

2. **If you want to use SSH keys with Cockpit:**
   - Ensure your SSH key is in `~/.ssh/authorized_keys`
   - Configure Cockpit to use SSH key authentication
   - Test access

3. **If you need password auth for Cockpit:**
   - Set password: `sudo passwd username`
   - Verify PAM config allows it
   - Test login

