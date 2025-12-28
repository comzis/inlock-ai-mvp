# Quick Fix: Root SSH Key Missing

## Problem
Coolify can't connect as root: `Permission denied (publickey,password)`

This means root's `authorized_keys` file is missing or doesn't have the correct key.

## Solution

**Run this command:**

```bash
sudo bash /home/comzis/projects/inlock-ai-mvp/fix-root-ssh-key.sh
```

This will:
1. ✅ Create `/root/.ssh/authorized_keys`
2. ✅ Add your SSH key to root's authorized_keys
3. ✅ Set correct permissions (600)
4. ✅ Verify SSH configuration
5. ✅ Enable root login if needed

## After Running

Test the connection:
```bash
ssh -i /home/comzis/.ssh/keys/deploy-inlock-ai-key root@172.18.0.1 "echo test"
```

Should output: `test`

Then go back to Coolify UI and click "Validate & configure" again - it should work! ✅

