# SSH Access Policy

**Effective Date:** 2026-01-03  
**Status:** Active

## Policy

SSH access (port 22) should be restricted to Tailscale VPN subnet (100.64.0.0/10) only.

## Current Configuration

### Firewall Rules

SSH should be accessible only from:
- Tailscale subnet: `100.64.0.0/10`
- Specific Tailscale IPs (if needed):
  - `100.83.222.69/32` - Server
  - `100.96.110.8/32` - Admin device

### SSH Configuration

- **Password Authentication:** Disabled (key-only)
- **Root Login:** Disabled
- **Port:** 22 (standard)
- **Fail2ban:** Active and monitoring SSH

## Verification

Run the verification script:

```bash
sudo ./scripts/security/verify-ssh-restrictions.sh
```

This checks:
- UFW firewall status
- SSH firewall rules
- fail2ban SSH jail status
- SSH configuration (password auth, root login)
- Tailscale status

## Firewall Rules

### Current Rules (Expected)

```bash
sudo ufw status numbered
```

Should show:
```
[1] 22/tcp                     ALLOW IN    100.64.0.0/10
```

### Setting Up Restricted SSH Access

If SSH is currently open to all, restrict it:

```bash
# Remove any existing SSH rules
sudo ufw delete allow 22/tcp

# Add Tailscale-only rule
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH via Tailscale'

# Verify
sudo ufw status numbered | grep 22
```

## Tailscale SSH

Alternative approach: Use Tailscale SSH feature

```bash
# Enable Tailscale SSH
sudo tailscale up --ssh

# This allows SSH access only through Tailscale mesh
# No need for firewall rules if using this approach
```

## Fail2ban Configuration

SSH jail should be active:

```bash
# Check fail2ban status
sudo systemctl status fail2ban

# Check SSH jail
sudo fail2ban-client status sshd

# Expected output shows:
# - Jail is active
# - Currently banned IPs (if any)
```

## Access Requirements

### For Admin Access

1. **Connect to Tailscale VPN**
   ```bash
   tailscale up
   ```

2. **Verify Tailscale IP**
   ```bash
   tailscale ip -4
   # Should return IP in 100.x.x.x range
   ```

3. **SSH to server**
   ```bash
   ssh user@server-ip
   # Or use Tailscale IP directly
   ssh user@100.83.222.69
   ```

### For New Devices

1. Add device to Tailscale network
2. Device gets IP in 100.64.0.0/10 range
3. SSH access automatically available

## Security Benefits

- **Reduced Attack Surface:** SSH not exposed to public internet
- **Encrypted Tunnel:** All SSH traffic through Tailscale VPN
- **Access Control:** Only Tailscale devices can connect
- **Fail2ban Protection:** Additional layer against brute force

## Troubleshooting

### Cannot SSH from Tailscale IP

1. **Check firewall rules:**
   ```bash
   sudo ufw status numbered | grep 22
   ```

2. **Check Tailscale IP:**
   ```bash
   tailscale ip -4
   ```

3. **Verify IP is in range:**
   - Should start with `100.`
   - Should be in `100.64.0.0/10` subnet

4. **Check fail2ban:**
   ```bash
   sudo fail2ban-client status sshd
   # Check if your IP is banned
   ```

### Need Emergency Access

If locked out:

1. **Via hosting provider console:**
   - Use provider's web console/VNC
   - Temporarily modify firewall rules

2. **Via another Tailscale device:**
   - Use device already connected to Tailscale
   - SSH from that device

## Related Files

- `scripts/security/verify-ssh-restrictions.sh` - Verification script
- `.cursorrules-security` - Security rules reference
- `/etc/ufw/` - Firewall configuration
- `/etc/fail2ban/` - Fail2ban configuration

## Review Schedule

- **Monthly:** Verify firewall rules and fail2ban status
- **Quarterly:** Review SSH access logs
- **Annually:** Update policy as needed

