# Tailscale Recovery Guide

## Problem
After running `fix-tailscale-stability.sh`, SSH access via Tailscale was lost. The script's systemd override with `--netfilter-mode=off` may have broken Tailscale's networking.

## Recovery Options

### Option 1: Revert via SSH (if you can access via public IP)

If you can SSH via the public IP (156.67.29.52), run:

```bash
cd /home/comzis/inlock
sudo bash scripts/revert-tailscale-fix.sh
```

### Option 2: Revert via Console/Out-of-Band Access

If you have console access (e.g., VPS provider console, IPMI, etc.):

1. Log in via console
2. Run the revert script:
   ```bash
   cd /home/comzis/inlock
   sudo bash scripts/revert-tailscale-fix.sh
   ```

### Option 3: Manual Revert (if scripts don't work)

If you need to manually revert:

```bash
# Remove the override file
sudo rm /etc/systemd/system/tailscaled.service.d/override.conf

# Remove empty directory
sudo rmdir /etc/systemd/system/tailscaled.service.d 2>/dev/null || true

# Reload systemd
sudo systemctl daemon-reload

# Restart Tailscale
sudo systemctl restart tailscaled

# Verify it's running
sudo systemctl status tailscaled
tailscale status
```

### Option 4: Temporarily Allow SSH from Public IP

If the firewall is blocking SSH from public IP, you can temporarily allow it:

```bash
# Allow SSH from any IP (temporary - for recovery only)
sudo ufw allow 22/tcp comment 'SSH - Temporary Recovery'

# After recovery, remove this rule and restore Tailscale-only access
sudo ufw delete allow 22/tcp
```

**⚠️ WARNING:** Only use Option 4 if absolutely necessary, and remove the rule immediately after recovery.

## Verification

After reverting, verify Tailscale is working:

```bash
# Check service status
systemctl status tailscaled

# Check Tailscale status
tailscale status

# Test connectivity
ping 100.83.222.69  # Server's Tailscale IP
```

## Root Cause

The `--netfilter-mode=off` flag in the systemd override may have:
- Disabled Tailscale's netfilter integration
- Broken routing for Tailscale traffic
- Prevented proper network interface binding

## Alternative Fix (Future)

Instead of `--netfilter-mode=off`, consider:
1. Using Tailscale's `--accept-routes=false` if routing is the issue
2. Configuring Docker to use a specific network mode
3. Using `iptables` rules to exclude Docker interfaces from Tailscale monitoring
4. Updating Tailscale to a newer version that handles interface churn better


