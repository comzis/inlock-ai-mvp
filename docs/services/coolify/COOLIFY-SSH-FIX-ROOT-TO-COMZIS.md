# Coolify SSH Fix: Root to Comzis Migration

**Date:** December 13, 2025  
**Issue:** `Error: root@100.83.222.69: Permission denied (publickey,password)`

## Problem

Coolify is configured to connect as `root@100.83.222.69`, but root login is **disabled** on the server for security reasons. The server only allows SSH access via the `comzis` user.

## Solution

### Step 1: Update Coolify Server Configuration

1. **Access Coolify UI**: Navigate to `https://deploy.inlock.ai`
2. **Go to Servers**: Click on **Servers** in the sidebar
3. **Edit Server**: Click on **deploy-inlock-ai** server → **Edit** (or **Settings**)
4. **Update SSH Username**:
   - Find the **SSH Username** field
   - Change from: `root`
   - Change to: `comzis`
5. **Validate Connection**: Click **"Validate Connection"** button
   - This should now succeed ✅
6. **Save**: Click **Save** to persist the changes

### Step 2: Verify Configuration

After updating, the server configuration should show:
- **IP Address**: `100.83.222.69`
- **SSH Username**: `comzis` ✅
- **SSH Port**: `22`
- **Status**: ✅ Server is reachable

### Step 3: Test Connection (Optional)

From your local machine, test the connection:

```bash
# Test with the deploy-inlock-ai-key
ssh -i ~/.ssh/keys/deploy-inlock-ai-key comzis@100.83.222.69 "echo 'Connection successful'"
```

Expected output:
```
Connection successful
```

## Technical Details

### Server SSH Configuration

- **PermitRootLogin**: `no` (root login disabled)
- **PubkeyAuthentication**: `yes` (public key auth enabled)
- **PasswordAuthentication**: `no` (password auth disabled)
- **Authorized User**: `comzis`
- **Authorized Keys**: `/home/comzis/.ssh/authorized_keys`

### SSH Key Status

The `deploy-inlock-ai-key` public key has been added to:
- `/home/comzis/.ssh/authorized_keys` ✅

### Permissions

All permissions are correctly set:
- `/home/comzis`: `700` (drwx------)
- `/home/comzis/.ssh`: `700` (drwx------)
- `/home/comzis/.ssh/authorized_keys`: `600` (-rw-------)

## Why This Change Was Necessary

1. **Security Best Practice**: Root login is disabled to prevent unauthorized access
2. **Server Policy**: The server enforces `PermitRootLogin no` in `/etc/ssh/sshd_config`
3. **User Privileges**: The `comzis` user has:
   - Sudo privileges (for administrative tasks)
   - Docker group membership (for container management)
   - Full access to deployment directories

## Troubleshooting

### Still Getting "Permission denied"?

1. **Verify username in Coolify UI**:
   - Go to Servers → deploy-inlock-ai → Edit
   - Confirm SSH Username is `comzis` (not `root`)

2. **Check SSH key is authorized**:
   ```bash
   ssh comzis@100.83.222.69 "cat ~/.ssh/authorized_keys | grep deploy.inlock.ai"
   ```
   Should show: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai`

3. **Test connection manually**:
   ```bash
   ssh -i ~/.ssh/keys/deploy-inlock-ai-key -vvv comzis@100.83.222.69
   ```

4. **Check server logs** (if you have console access):
   ```bash
   sudo tail -f /var/log/auth.log | grep comzis
   ```

### Connection Works But Coolify Still Shows Error?

1. **Clear Coolify cache**: Restart the Coolify container
   ```bash
   cd /home/comzis/inlock-infra
   docker compose -f compose/coolify.yml restart coolify
   ```

2. **Re-validate in UI**: Go back to server settings and click "Validate Connection" again

## Verification Checklist

- [x] SSH key `deploy-inlock-ai-key` added to `/home/comzis/.ssh/authorized_keys`
- [x] Manual SSH connection works: `ssh -i ~/.ssh/keys/deploy-inlock-ai-key comzis@100.83.222.69`
- [x] Documentation updated to reflect `comzis` user
- [ ] Coolify UI updated to use `comzis` instead of `root` (requires manual update in UI)
- [ ] Coolify "Validate Connection" succeeds
- [ ] Server status shows "✅ Server is reachable"

## Related Documentation

- [Coolify Server Setup Guide](COOLIFY-SERVER-SETUP.md)
- [Coolify Setup Complete](COOLIFY-SETUP-COMPLETE.md)
- [SSH Connection Guide](../SSH-CONNECTION-GUIDE.md)

---

**Last Updated:** December 13, 2025  
**Status:** ✅ SSH Key Configured - Awaiting UI Update

