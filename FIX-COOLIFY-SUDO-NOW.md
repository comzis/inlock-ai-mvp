# 🔧 Fix Coolify Sudo Error - Run This Now

## The Problem
Coolify validation fails because passwordless sudo isn't configured yet.

## The Solution
**Run this ONE command on your server:**

```bash
sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/configure-coolify-sudo.sh
```

It will:
1. Ask for your sudo password (type it and press Enter)
2. Create the sudoers file automatically
3. Configure passwordless sudo for specific commands only
4. Verify everything is correct

## After Running

1. **Verify it worked** (should NOT ask for password):
   ```bash
   sudo -n /usr/bin/docker ps
   ```

2. **Go back to Coolify UI** → Click "Validate & configure" again

3. **It should succeed!** ✅

---

## What This Does

Creates `/etc/sudoers.d/coolify-comzis` with limited passwordless sudo for:
- Docker commands
- System service management
- File operations
- Network tools

**Security:** Only specific commands, not full sudo access.

---

**That's it! Just run the command above.** 🚀

