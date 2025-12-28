# Quick Fix: Coolify Sudo Configuration

## Problem
Coolify validation fails with:
```
Error: sudo: a password is required
```

## Solution
Run the sudo configuration script to enable passwordless sudo for Coolify:

```bash
cd /home/comzis/projects/inlock-ai-mvp
sudo ./scripts/infrastructure/configure-coolify-sudo.sh
```

This will:
1. Create `/etc/sudoers.d/coolify-comzis`
2. Allow passwordless sudo for specific commands only (docker, systemctl, etc.)
3. Validate the configuration syntax

## After Running

1. **Verify it worked:**
   ```bash
   sudo -n /usr/bin/docker ps
   ```
   Should work without password.

2. **Go back to Coolify UI** and click "Validate Connection" again

3. **It should now succeed!** ✅

## What This Does

Creates limited passwordless sudo access for:
- Docker commands (`/usr/bin/docker`, `/usr/bin/docker-compose`)
- System service commands (`/bin/systemctl`)
- File operations (`/bin/mkdir`, `/bin/chmod`, `/bin/chown`)
- Network tools (`/bin/ss`, `/usr/bin/netstat`)

**Security:** Only specific commands are passwordless, not full sudo access.

