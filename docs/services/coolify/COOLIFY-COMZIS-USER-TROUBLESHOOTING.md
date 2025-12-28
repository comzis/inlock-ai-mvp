# Coolify comzis User Troubleshooting

**Date:** 2025-12-28  
**Issue:** User `comzis` does not work in Coolify

---

## Verified Configuration ✅

### Server-Side (All Correct)

1. **User exists:** `comzis` (UID 1000, GID 1000)
2. **SSH Key matches:** Coolify's stored key matches `deploy-inlock-ai-key`
3. **Authorized keys:** Public key present in `/home/comzis/.ssh/authorized_keys`
4. **Permissions:** Correct (700 for .ssh, 600 for authorized_keys)
5. **Root login:** Disabled (as preferred)
6. **Sudo configured:** Passwordless sudo for Docker/systemctl commands
7. **Firewall:** Docker networks allowed (172.18.0.0/16, 172.23.0.0/16)

### SSH Connection Test

From host, connection works:
```bash
ssh -i ~/.ssh/keys/deploy-inlock-ai-key comzis@172.18.0.1
# ✅ Works successfully
```

---

## Coolify Configuration Checklist

Verify these settings in Coolify UI:

### Server Configuration

- **IP Address/Domain:** `172.18.0.1` (Docker gateway, NOT Tailscale IP)
- **User:** `comzis` (lowercase, exactly as shown)
- **Port:** `22`
- **SSH Key:** Select the key that matches `deploy-inlock-ai-key`
  - Key fingerprint: `SHA256:E2KkN7Kib72Pb87404BFsuqTteVS4bS3W1vQBgbvEmI`
  - Public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+O8NeWVNpH0JfxDGkiqprccaIMOrTKH4dLDiDiG7T9 deploy.inlock.ai`

---

## Common Issues

### Issue 1: Wrong IP Address

**Symptom:** Connection timeout or refused

**Fix:**
- ❌ Don't use: `100.83.222.69` (Tailscale IP - doesn't work from containers)
- ❌ Don't use: `localhost` or `127.0.0.1` (refers to container)
- ✅ Use: `172.18.0.1` (Docker gateway IP)

### Issue 2: Wrong Username

**Symptom:** Permission denied

**Fix:**
- ❌ Don't use: `root` (disabled)
- ✅ Use: `comzis` (exactly, lowercase)

### Issue 3: Wrong SSH Key

**Symptom:** Permission denied (publickey)

**Fix:**
- Ensure the SSH key selected in Coolify matches `deploy-inlock-ai-key`
- Key fingerprint should be: `SHA256:E2KkN7Kib72Pb87404BFsuqTteVS4bS3W1vQBgbvEmI`

### Issue 4: Sudo Password Error

**Symptom:** `sudo: a password is required`

**Fix:**
- Run: `sudo /home/comzis/projects/inlock-ai-mvp/scripts/infrastructure/configure-coolify-sudo.sh`
- This configures passwordless sudo for specific commands only

---

## Testing Steps

### Step 1: Test SSH Connection Manually

From the host:
```bash
ssh -i ~/.ssh/keys/deploy-inlock-ai-key comzis@172.18.0.1 "echo 'Test successful'"
```

Should output: `Test successful`

### Step 2: Test from Coolify Container

```bash
docker exec services-coolify-1 ssh -v -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /var/www/html/storage/app/ssh/keys/ssh_key@xcc44wo0gksgww4004skc0cg comzis@172.18.0.1 "echo 'Container test'"
```

### Step 3: Verify Sudo Works

```bash
sudo -n /usr/bin/docker ps | head -3
```

Should work without password.

---

## Current Configuration Status

✅ User: `comzis` exists and is configured  
✅ SSH Key: Matches in Coolify  
✅ Authorized Keys: Present on server  
✅ Sudo: Passwordless configured  
✅ Firewall: Docker networks allowed  
✅ SSH: Root login disabled (as preferred)  

---

## If Still Not Working

1. **Check exact error message** in Coolify UI
2. **Verify IP address** is `172.18.0.1` (not Tailscale IP)
3. **Verify username** is exactly `comzis` (not `Comzis` or `COMZIS`)
4. **Verify SSH key** is selected correctly in Coolify
5. **Check Coolify logs:**
   ```bash
   docker logs services-coolify-1 2>&1 | grep -i "ssh\|connection\|comzis" | tail -20
   ```

---

**Last Updated:** 2025-12-28

