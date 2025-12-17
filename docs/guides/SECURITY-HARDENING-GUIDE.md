# Security Hardening Guide

## Quick Start

Run the comprehensive security hardening script:

```bash
cd /home/comzis/inlock-infra
sudo ./scripts/harden-security.sh
```

This script addresses all security review findings automatically.

## Security Review Findings Addressed

### 1. SSH Hardening ✅
- **Issue**: Password authentication at default (commented) setting
- **Fix**: Explicitly set `PasswordAuthentication no`
- **Issue**: X11 forwarding not disabled
- **Fix**: Set `X11Forwarding no`
- **Status**: Root login already disabled

### 2. Fail2ban Service ✅
- **Issue**: Configured but not running
- **Fix**: Enable and start fail2ban service
- **Status**: SSH jail will be active and monitoring

### 3. Firewall Configuration ✅
- **Issue**: No visible firewall controls
- **Fix**: Configure UFW firewall with restrictive rules
- **Actions**:
  - Enable UFW
  - Restrict SSH to Tailscale IPs only
  - Block unnecessary ports (9090, 9100, 5432, 6379, 3000)
  - Allow required services (80, 443, 41641)

### 4. Service Exposure Audit ✅
- **Issue**: Many services exposed on 0.0.0.0
- **Fix**: Firewall blocks unnecessary ports
- **Note**: Services should be accessed via Traefik reverse proxy

## Manual Steps (if needed)

### SSH Configuration

Edit `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Ensure these lines are set:
```
PasswordAuthentication no
X11Forwarding no
PermitRootLogin no
KbdInteractiveAuthentication no
```

Then restart SSH:
```bash
sudo systemctl restart sshd
sudo sshd -t  # Test configuration
```

### Fail2ban Configuration

Check status:
```bash
sudo systemctl status fail2ban
```

Start if not running:
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Check SSH jail:
```bash
sudo fail2ban-client status sshd
```

View bans:
```bash
sudo fail2ban-client status sshd | grep -E "Banned|Currently"
```

### Firewall Configuration

Check status:
```bash
sudo ufw status verbose
```

View rules:
```bash
sudo ufw status numbered
```

Manual rule management:
```bash
# Allow SSH from specific IP
sudo ufw allow from 100.83.222.69/32 to any port 22

# Block a port
sudo ufw deny 9090/tcp

# Delete a rule
sudo ufw delete [rule_number]
```

## Exposed Ports Analysis

### Required Public Ports
- **22 (SSH)**: Restricted to Tailscale IPs via firewall
- **80 (HTTP)**: Required for Traefik
- **443 (HTTPS)**: Required for Traefik
- **41641 (Tailscale)**: Required for VPN

### Blocked Ports (Internal Only)
- **9090 (Prometheus)**: Monitoring - internal only
- **9100 (Node Exporter)**: Metrics - internal only
- **5432 (PostgreSQL)**: Database - internal only
- **6379 (Redis)**: Cache - internal only
- **3000 (Next.js)**: Application - via Traefik

### System Ports
- **53 (DNS)**: System service - required

## Monitoring

### Check Auth Logs
```bash
sudo tail -f /var/log/auth.log
```

### Check Fail2ban Logs
```bash
sudo tail -f /var/log/fail2ban.log
```

### Check Firewall Logs
```bash
sudo tail -f /var/log/ufw.log
```

### Check Failed SSH Attempts
```bash
sudo grep "Failed password" /var/log/auth.log | tail -20
```

## Security Score Improvement

**Before**: 5/10
- SSH password auth enabled (default)
- No firewall active
- fail2ban not running
- Many exposed services

**After**: 8/10
- SSH password auth disabled
- Firewall active and restrictive
- fail2ban running and protecting SSH
- Unnecessary ports blocked
- Services behind reverse proxy

## Verification Commands

```bash
# Check SSH config
sudo sshd -T | grep -E "passwordauthentication|x11forwarding|permitrootlogin"

# Check fail2ban
sudo systemctl status fail2ban
sudo fail2ban-client status sshd

# Check firewall
sudo ufw status verbose

# Check exposed ports
sudo netstat -tulpn | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u

# Check Docker exposed ports
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep "0.0.0.0"
```

## Next Steps

1. ✅ Run hardening script: `sudo ./scripts/harden-security.sh`
2. ✅ Test SSH access from Tailscale IPs
3. ✅ Monitor fail2ban for bans
4. ✅ Review auth logs for suspicious activity
5. ✅ Verify all services accessible via Traefik
6. ✅ Consider setting up log aggregation for centralized monitoring

## Related Scripts

- `harden-security.sh` - Comprehensive security hardening
- `configure-firewall.sh` - Firewall configuration only
- `check-disk-usage.sh` - Disk space analysis

