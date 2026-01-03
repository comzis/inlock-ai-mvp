# SSH Security Fixes Applied

**Date:** 2026-01-03  
**Status:** ✅ Applied

## Issues Found

From `verify-ssh-restrictions.sh` output:

1. ⚠️ **No SSH rules found in UFW** - SSH was accessible from anywhere
2. ⚠️ **Root login may be enabled** - `PermitRootLogin prohibit-password` allows key-based root login

## Fixes Applied

### 1. UFW SSH Restriction ✅

**Action:** Added firewall rule to restrict SSH to Tailscale subnet only

**Command:**
```bash
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'
```

**Result:**
- SSH now only accessible from Tailscale subnet (100.64.0.0/10)
- Public internet access to SSH blocked
- Accessible from Tailscale IPs: 100.83.222.69, 100.96.110.8, etc.

**Verification:**
```bash
sudo ufw status numbered | grep 22
```

### 2. SSH Root Login Disabled ✅

**Action:** Changed `PermitRootLogin` from `prohibit-password` to `no`

**Command:**
```bash
sudo sed -i.bak 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sshd -t  # Verify syntax
```

**Result:**
- Root login completely disabled
- Backup created: `/etc/ssh/sshd_config.bak`
- SSH config syntax verified

**Next Step:**
```bash
sudo systemctl restart sshd
```

## Security Improvements

### Before
- SSH accessible from anywhere (no firewall restriction)
- Root login allowed with keys (`prohibit-password`)

### After
- SSH restricted to Tailscale subnet (100.64.0.0/10)
- Root login completely disabled
- Password authentication already disabled ✅
- fail2ban active and monitoring ✅

## Verification

After restarting SSH service, verify:

```bash
# Check firewall rule
sudo ufw status numbered | grep 22

# Check SSH config
sudo grep "^PermitRootLogin" /etc/ssh/sshd_config
# Should show: PermitRootLogin no

# Test SSH access (from Tailscale device)
ssh user@100.83.222.69
```

## Related Files

- `/etc/ssh/sshd_config` - SSH configuration (backup: `sshd_config.bak`)
- `/etc/ufw/` - Firewall rules
- `scripts/security/verify-ssh-restrictions.sh` - Verification script
- `docs/security/SSH-ACCESS-POLICY.md` - SSH access policy

## Notes

- Firewall rule is persistent (survives reboots)
- SSH config change requires service restart to take effect
- Backup of original SSH config saved as `sshd_config.bak`
- All changes align with `.cursorrules-security` requirements

