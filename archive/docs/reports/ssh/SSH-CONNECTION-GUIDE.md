# SSH Connection Guide - 100.83.222.69

**Issue:** Permission denied (publickey,password)  
**Root Cause:** Root login disabled; must use `comzis` user  
**Status:** ✅ Server configuration correct, ready for connection

---

## Quick Connection Commands

### Standard Connection
```bash
ssh comzis@100.83.222.69
```

### With Explicit Key
```bash
ssh -i ~/.ssh/id_ed25519 comzis@100.83.222.69
# Or if you have a different key:
ssh -i ~/.ssh/your_key_name comzis@100.83.222.69
```

### Verbose Diagnostics (if connection fails)
```bash
ssh -vvv comzis@100.83.222.69
```

---

## Server Configuration (Verified ✅)

### SSH Daemon Settings
- **PermitRootLogin:** `no` ✅ (Security best practice)
- **PubkeyAuthentication:** `yes` ✅ (Key auth enabled)
- **PasswordAuthentication:** `no` ✅ (Password auth disabled)

### User Configuration
- **User:** `comzis`
- **Home Directory:** `/home/comzis`
- **SSH Directory:** `/home/comzis/.ssh`
- **Permissions:** `700` (correct) ✅
- **authorized_keys:** `/home/comzis/.ssh/authorized_keys`
- **Permissions:** `600` (correct) ✅
- **Owner:** `comzis:comzis` (correct) ✅

### Public Key in authorized_keys
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuQl+SL+Q/z0QsSI/p5Iwcw3Sq/6dg+jyBy7NheXLXD
```

---

## Troubleshooting

### If Connection Still Fails

#### 1. Check Your Private Key
Ensure you have the private key that matches the public key above:
```bash
# Check if you have the key
ls -la ~/.ssh/

# Check key fingerprint (should match public key in authorized_keys)
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

#### 2. Run Verbose SSH
```bash
ssh -vvv comzis@100.83.222.69
```

**Look for:**
- `Offering public key` - Key is being offered
- `Server accepts key` - Key is accepted
- `Permission denied` - Key mismatch or other issue
- `ROOT LOGIN REFUSED` - You're still trying root (wrong!)

#### 3. Check Key Permissions (Client-Side)
```bash
# Private key should be 600
chmod 600 ~/.ssh/id_ed25519

# SSH directory should be 700
chmod 700 ~/.ssh
```

#### 4. Verify Key Type
The server expects `ed25519` key. If you have a different key type:
```bash
# Check your key type
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# If you need to generate a new ed25519 key:
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### 5. Test Key Locally
```bash
# Test if key works (will show what key is being used)
ssh -v comzis@100.83.222.69 2>&1 | grep -i "identity\|offering\|server accepts"
```

---

## Common Issues

### Issue: "Permission denied (publickey)"
**Possible Causes:**
1. Wrong username (using `root` instead of `comzis`)
2. Key not in `~/.ssh/authorized_keys` on server
3. Key permissions wrong on client (`~/.ssh/id_ed25519` should be `600`)
4. Wrong key being used (check with `ssh -v`)

**Solution:**
- Use `comzis@100.83.222.69` (not `root@`)
- Verify key matches authorized_keys on server
- Check client key permissions: `chmod 600 ~/.ssh/id_ed25519`

### Issue: "Connection refused"
**Possible Causes:**
1. SSH service not running
2. Firewall blocking port 22
3. Wrong IP address

**Solution:**
- Verify SSH service: `sudo systemctl status ssh` (on server)
- Check firewall: `sudo ufw status` (on server)
- Verify IP: `100.83.222.69`

### Issue: "Host key verification failed"
**Solution:**
```bash
# Remove old host key
ssh-keygen -R 100.83.222.69

# Or edit known_hosts manually
nano ~/.ssh/known_hosts
```

---

## Security Notes

✅ **Current Configuration is Secure:**
- Root login disabled (prevents brute force on root)
- Password authentication disabled (key-only)
- Public key authentication required
- Proper file permissions enforced

⚠️ **Best Practices:**
- Keep private keys secure (`600` permissions)
- Use strong key types (ed25519 recommended)
- Don't share private keys
- Use SSH agent for key management

---

## Verification Checklist

Before connecting, verify:

- [ ] You're using `comzis@100.83.222.69` (not `root@`)
- [ ] You have the private key matching the public key in authorized_keys
- [ ] Private key permissions are `600` on client
- [ ] SSH directory permissions are `700` on client
- [ ] You're connecting from a trusted network/IP

---

## Quick Test

```bash
# Test connection with verbose output
ssh -vvv comzis@100.83.222.69

# Expected output should show:
# - "Offering public key"
# - "Server accepts key"
# - Successful authentication
# - Shell prompt: comzis@vmi2953354:~$
```

---

## If You Need to Add a New Key

### On Client (Your Machine)
```bash
# Generate new key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to server (if you have another way to access)
ssh-copy-id comzis@100.83.222.69

# Or manually add to authorized_keys on server
cat ~/.ssh/id_ed25519.pub | ssh comzis@100.83.222.69 "cat >> ~/.ssh/authorized_keys"
```

### On Server (via console/KVM)
```bash
# Add public key to authorized_keys
echo "your_public_key_here" >> ~/.ssh/authorized_keys

# Fix permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

---

## Summary

**Connection Command:**
```bash
ssh comzis@100.83.222.69
```

**Server Status:** ✅ All configuration correct, ready for connections  
**Action Required:** Use correct username (`comzis`) on client side

---

**Last Updated:** 2025-12-13  
**Status:** Ready for Connection

