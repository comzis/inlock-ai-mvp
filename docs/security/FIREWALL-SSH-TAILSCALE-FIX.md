# Firewall SSH Access Fix - Tailscale Subnet

## Problem

When the firewall is enabled, SSH access from MacBook and Cursor is not working because:

1. **Current Configuration**: Firewall uses specific Tailscale IPs:
   - `100.83.222.69/32` (Server)
   - `100.96.110.8/32` (MacBook)

2. **Issue**: If your MacBook's Tailscale IP changes, or if you're using a different Tailscale device, SSH access is blocked.

3. **Cursor Rules Requirement**: According to `.cursorrules-security`, SSH should be accessible from the **entire Tailscale subnet** (`100.64.0.0/10`), not just specific IPs.

## Solution

Update the firewall to allow SSH from the entire Tailscale subnet (`100.64.0.0/10`), which covers all Tailscale devices.

## Quick Fix

Run the fix script:

```bash
cd /home/comzis/inlock
sudo bash scripts/security/fix-firewall-ssh-tailscale.sh
```

This script will:
1. Remove existing SSH rules (specific IPs)
2. Add rule for entire Tailscale subnet (`100.64.0.0/10`)
3. Verify the changes

## Manual Fix

If you prefer to fix manually:

```bash
# 1. Remove existing SSH rules
sudo ufw status numbered | grep "22/tcp" | awk -F'[][]' '{print $2}' | sort -rn | while read num; do
    echo "y" | sudo ufw delete "$num"
done

# 2. Add Tailscale subnet rule
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale (100.64.0.0/10)'

# 3. Verify
sudo ufw status numbered | grep -E "22|ssh|100\.64"
```

## Verification

After applying the fix:

1. **Check firewall rules:**
   ```bash
   sudo ufw status numbered | grep -E "22|ssh|100\.64"
   ```
   
   Should show:
   ```
   [X] 22/tcp                     ALLOW IN    100.64.0.0/10
   ```

2. **Test SSH access from MacBook:**
   ```bash
   # From your MacBook
   ssh comzis@100.83.222.69
   ```

3. **Check Tailscale status:**
   ```bash
   # On server
   tailscale status
   ```

## Security Impact

✅ **No security degradation:**
- Still restricts SSH to Tailscale network only
- Only allows devices connected to your Tailscale tailnet
- Matches `.cursorrules-security` requirements exactly

✅ **Improved usability:**
- Works with any Tailscale device (not just specific IPs)
- No need to update firewall when Tailscale IPs change
- Supports multiple admin devices automatically

## Updated Scripts

The following scripts have been updated to use the Tailscale subnet:

- ✅ `scripts/infrastructure/configure-firewall.sh` - Now uses `100.64.0.0/10`
- ✅ `scripts/security/fix-ssh-security.sh` - Already uses `100.64.0.0/10`
- ✅ `scripts/security/fix-firewall-ssh-tailscale.sh` - New fix script

## Related Documentation

- `.cursorrules-security` - Security rules requiring Tailscale subnet
- `docs/security/SSH-ACCESS-POLICY.md` - SSH access policy
- `docs/security/FIREWALL-MANAGEMENT.md` - Firewall management guide

## Troubleshooting

### Still can't connect?

1. **Check Tailscale is running:**
   ```bash
   systemctl status tailscaled
   tailscale status
   ```

2. **Check firewall is active:**
   ```bash
   sudo ufw status
   ```

3. **Check SSH service:**
   ```bash
   systemctl status sshd
   ```

4. **Check firewall logs:**
   ```bash
   sudo tail -f /var/log/ufw.log
   ```

5. **Verify your MacBook's Tailscale IP:**
   ```bash
   # On MacBook
   tailscale ip -4
   ```
   
   Should be in `100.64.0.0/10` range.

### Firewall rule not applying?

1. **Reload UFW:**
   ```bash
   sudo ufw reload
   ```

2. **Check rule order:**
   ```bash
   sudo ufw status numbered
   ```
   
   The Tailscale subnet rule should be before any deny rules.

## Prevention

To prevent this issue in the future:

1. **Always use Tailscale subnet** (`100.64.0.0/10`) instead of specific IPs
2. **Run firewall configuration script** after any Tailscale changes:
   ```bash
   sudo bash scripts/infrastructure/configure-firewall.sh
   ```
3. **Verify firewall rules** match `.cursorrules-security` requirements

---

**Last Updated:** 2026-01-03  
**Related Issue:** Firewall blocking SSH from MacBook/Cursor when enabled


