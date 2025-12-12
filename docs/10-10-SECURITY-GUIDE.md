# Achieving 10/10 Security Score - Complete Guide

## Quick Start

Run the comprehensive hardening script:

```bash
cd /home/comzis/inlock-infra
sudo ./scripts/achieve-10-10-security.sh
```

This script addresses ALL security issues to achieve a 10/10 score.

## What Gets Fixed

### 1. SSH Hardening ✅
- Verifies password authentication is disabled
- Verifies X11 forwarding is disabled
- Verifies root login is disabled
- **Status**: Already done, script verifies

### 2. Fail2ban SSH Jail ✅
- Creates proper SSH jail configuration
- Enables and starts fail2ban service
- Configures IP whitelist (Tailscale IPs)
- Sets ban parameters (5 retries, 1 hour ban, 10 min window)
- **Status**: Will be fixed by script

### 3. Firewall Configuration ✅
- Enables UFW firewall
- Sets default deny incoming / allow outgoing
- Restricts SSH to Tailscale IPs only
- Blocks unnecessary ports (9090, 9100, 5432, 6379, 3000)
- Allows required services (80, 443, 41641)
- Allows internal Docker networks
- **Status**: Will be fixed by script

### 4. Security Updates ✅
- Applies all pending security updates
- Checks for kernel updates (reboot if needed)
- **Status**: Will be fixed by script

### 5. Port Exposure Review ✅
- Identifies all exposed ports
- Verifies which are safe (localhost/Tailscale only)
- **Status**: Will be reviewed by script

### 6. Docker Security ✅
- Verifies no unnecessary port exposures
- Checks Docker socket exposure
- **Status**: Will be verified by script

### 7. Security Monitoring ✅
- Creates monitoring script
- Adds to cron (runs every 30 minutes)
- **Status**: Will be set up by script

## Manual Steps (if script can't run)

### Fix Fail2ban SSH Jail

```bash
sudo nano /etc/fail2ban/jail.d/sshd.local
```

Add:
```ini
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600
findtime = 600
ignoreip = 127.0.0.1/8 ::1 100.83.222.69 100.96.110.8
```

Then:
```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

### Enable and Configure Firewall

```bash
# Enable UFW
sudo ufw --force enable

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow required services
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Restrict SSH to Tailscale
sudo ufw allow from 100.83.222.69/32 to any port 22
sudo ufw allow from 100.96.110.8/32 to any port 22

# Block unnecessary ports
sudo ufw deny 9090/tcp
sudo ufw deny 9100/tcp
sudo ufw deny 5432/tcp
sudo ufw deny 6379/tcp
sudo ufw deny 3000/tcp

# Allow Docker networks
sudo ufw allow from 172.20.0.0/16
sudo ufw allow from 172.18.0.0/16
sudo ufw allow from 172.17.0.0/16

# Verify
sudo ufw status numbered
```

### Apply Security Updates

```bash
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Check if reboot needed
if [ -f /var/run/reboot-required ]; then
    echo "Reboot required"
    sudo reboot
fi
```

## Verification After Fixes

Run the security review:

```bash
cd /home/comzis/inlock-infra
./scripts/security-review.sh
```

Expected results:
- ✅ SSH: All checks pass
- ✅ fail2ban: Service running, SSH jail active
- ✅ Firewall: Active, SSH restricted
- ✅ Updates: Applied
- ✅ Ports: Only required ports exposed
- ✅ Docker: No unnecessary exposures

## Security Score Breakdown

| Category | Before | After | Status |
|----------|--------|-------|--------|
| SSH Configuration | 10/10 | 10/10 | ✅ Perfect |
| Fail2ban | 5/10 | 10/10 | ✅ Fixed |
| Firewall | 0/10 | 10/10 | ✅ Fixed |
| Automatic Updates | 8/10 | 10/10 | ✅ Fixed |
| Service Exposure | 6/10 | 10/10 | ✅ Fixed |
| Attack Monitoring | 7/10 | 10/10 | ✅ Fixed |
| Docker Security | 8/10 | 10/10 | ✅ Verified |
| **Overall** | **7/10** | **10/10** | ✅ **Perfect** |

## Monitoring

### Check Security Status

```bash
# Quick status
/usr/local/bin/security-monitor.sh

# Detailed review
./scripts/security-review.sh

# Check fail2ban
sudo fail2ban-client status sshd

# Check firewall
sudo ufw status verbose

# Check recent attacks
sudo grep "Failed password" /var/log/auth.log | tail -10
```

### Automated Monitoring

The script sets up cron job that runs every 30 minutes:
- Logs to: `/var/log/security-monitor.log`
- Checks: SSH failures, fail2ban status, firewall status

View logs:
```bash
sudo tail -f /var/log/security-monitor.log
```

## Troubleshooting

### fail2ban not banning

```bash
# Check service status
sudo systemctl status fail2ban

# Check jail status
sudo fail2ban-client status sshd

# Test ban manually
sudo fail2ban-client set sshd banip 192.168.1.100

# Check logs
sudo tail -f /var/log/fail2ban.log
```

### Firewall blocking legitimate traffic

```bash
# Check firewall logs
sudo tail -f /var/log/ufw.log

# Temporarily allow an IP
sudo ufw allow from <IP> to any port <PORT>

# Check current rules
sudo ufw status numbered
```

### SSH access blocked

If you're locked out:
1. Access via console/VNC if available
2. Or temporarily allow your IP:
   ```bash
   sudo ufw allow from <YOUR_IP> to any port 22
   ```

## Maintenance

### Regular Tasks

1. **Weekly**: Review security monitor logs
2. **Monthly**: Run security review script
3. **After updates**: Verify firewall and fail2ban still working
4. **Quarterly**: Review and update firewall rules

### Update Firewall Rules

If you need to add/remove rules:
```bash
# Add rule
sudo ufw allow from <IP> to any port <PORT>

# Delete rule
sudo ufw status numbered  # Find rule number
sudo ufw delete <NUMBER>
```

## Expected Final State

After running the script:
- ✅ **SSH**: Hardened (no password, no X11, no root)
- ✅ **fail2ban**: Running with active SSH jail
- ✅ **Firewall**: Active, SSH restricted, ports blocked
- ✅ **Updates**: All security updates applied
- ✅ **Monitoring**: Automated security monitoring active
- ✅ **Score**: **10/10**

## Related Scripts

- `achieve-10-10-security.sh` - Complete hardening (this guide)
- `harden-security.sh` - Basic hardening
- `security-review.sh` - Security assessment
- `configure-firewall.sh` - Firewall only

