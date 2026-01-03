# SSH Firewall Access Fix - 2026-01-03

## Problem Summary

SSH access from MacBook and Cursor stopped working after running firewall configuration scripts. The issue was caused by:

1. **UFW Status Inconsistency**: UFW was reported as "inactive" in some checks but "active" in others
2. **Infinite Loop Bug**: The `enable-ufw-complete.sh` script got stuck in an infinite loop trying to remove SSH rules
3. **Missing SSH Rules**: After the loop issue, SSH firewall rules were not properly configured

## Root Cause

The `enable-ufw-complete.sh` script had a bug in its SSH rule removal logic:
- The `while` loop condition `ufw status numbered | grep -q "22/tcp"` could get stuck if rule number parsing failed
- No maximum iteration limit, causing infinite loops
- Rule number extraction using `sed` was fragile and could fail silently

## Solution

### 1. Created New Fix Script
**File**: `scripts/security/fix-ssh-firewall-access.sh`

This script:
- ✅ Properly checks and enables UFW if inactive
- ✅ Safely removes all existing SSH rules (with iteration limit to prevent loops)
- ✅ Adds correct Tailscale subnet rule (100.64.0.0/10) as per `.cursorrules-security`
- ✅ Verifies SSH configuration allows public key authentication
- ✅ Verifies MacBook key access is preserved

### 2. Fixed Existing Script
**File**: `scripts/security/enable-ufw-complete.sh`

Fixed the infinite loop bug by:
- Collecting all SSH rule numbers first, then removing them in reverse order
- Adding maximum iteration limit (3) to prevent infinite loops
- Using more robust rule number extraction with `awk`

## Firewall Configuration

According to `.cursorrules-security`:
- **Port 22 → ONLY 100.64.0.0/10 (Tailscale)**

The fix ensures:
- SSH is restricted to the entire Tailscale subnet (100.64.0.0/10)
- This allows any Tailscale device to connect, not just specific IPs
- MacBook (100.96.110.8) and Cursor (via Tailscale) can now access SSH

## How to Apply the Fix

### Option 1: Run the New Fix Script (Recommended)
```bash
cd /home/comzis/inlock
sudo ./scripts/security/fix-ssh-firewall-access.sh
```

### Option 2: Use the Fixed Enable Script
```bash
cd /home/comzis/inlock
sudo ./scripts/security/enable-ufw-complete.sh
```

## Verification

After running the fix script, verify:

1. **Check UFW Status**:
   ```bash
   sudo ufw status numbered | grep -E "22|ssh|100\.64"
   ```
   Should show: `100.64.0.0/10` rule for port 22

2. **Test SSH Access from MacBook**:
   ```bash
   ssh comzis@100.83.222.69
   ```

3. **Test SSH Access from Cursor** (via Tailscale):
   - Ensure Cursor is connected to Tailscale
   - SSH should work via Tailscale IP

4. **Verify SSH Configuration**:
   ```bash
   sudo ./scripts/security/verify-ssh-restrictions.sh
   ```

## Expected Results

After the fix:
- ✅ UFW is active
- ✅ SSH rule exists: `100.64.0.0/10` → port 22
- ✅ SSH access works from MacBook (100.96.110.8)
- ✅ SSH access works from Cursor (via Tailscale)
- ✅ Public key authentication is enabled
- ✅ MacBook key is preserved in `~/.ssh/authorized_keys`

## Security Compliance

This fix maintains compliance with `.cursorrules-security`:
- ✅ Port 22 restricted to Tailscale subnet (100.64.0.0/10)
- ✅ Public key authentication preserved
- ✅ MacBook key access maintained
- ✅ Password authentication remains disabled
- ✅ Root login remains disabled

## Related Files

- `scripts/security/fix-ssh-firewall-access.sh` - New comprehensive fix script
- `scripts/security/enable-ufw-complete.sh` - Fixed existing script (loop bug fixed)
- `scripts/security/fix-firewall-ssh-tailscale.sh` - Alternative fix script
- `.cursorrules-security` - Security rules that must be followed

## Notes

- The fix uses the entire Tailscale subnet (100.64.0.0/10) instead of specific IPs
- This is more flexible and matches the `.cursorrules-security` requirement
- All Tailscale devices can now access SSH, not just the MacBook and server IPs


