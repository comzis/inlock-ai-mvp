# Firewall Management Guide

## Overview

This guide covers how to manage the UFW (Uncomplicated Firewall) for the INLOCK.AI infrastructure moving forward. The firewall is a critical security component that should be managed carefully and documented.

## Table of Contents

1. [Viewing Firewall Status](#viewing-firewall-status)
2. [Adding Firewall Rules](#adding-firewall-rules)
3. [Removing Firewall Rules](#removing-firewall-rules)
4. [Modifying Existing Rules](#modifying-existing-rules)
5. [Managing via Ansible](#managing-via-ansible)
6. [Managing via Scripts](#managing-via-scripts)
7. [Best Practices](#best-practices)
8. [Monitoring & Logging](#monitoring--logging)
9. [Troubleshooting](#troubleshooting)

---

## Viewing Firewall Status

### Basic Status
```bash
# View current status
sudo ufw status

# Verbose status (shows policies and rules)
sudo ufw status verbose

# Numbered rules (useful for deletion)
sudo ufw status numbered
```

### Check Specific Port
```bash
# Check if a port is allowed
sudo ufw status | grep <port>

# Check firewall logs
sudo tail -f /var/log/ufw.log
```

---

## Adding Firewall Rules

### Basic Rule Addition

**Allow a port:**
```bash
# Allow TCP port
sudo ufw allow <port>/tcp comment 'Description'

# Allow UDP port
sudo ufw allow <port>/udp comment 'Description'

# Allow both TCP and UDP
sudo ufw allow <port> comment 'Description'
```

**Examples:**
```bash
# Allow MySQL (if needed)
sudo ufw allow 3306/tcp comment 'MySQL'

# Allow Redis (if needed)
sudo ufw allow 6379/tcp comment 'Redis'

# Allow Prometheus metrics (if exposing)
sudo ufw allow 9100/tcp comment 'Prometheus'
```

### Allow from Specific IP/CIDR

**Restrict SSH to Tailscale subnet:**
```bash
# Allow SSH only from Tailscale range
sudo ufw delete allow 22/tcp
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH from Tailscale'

# Or allow from specific IP
sudo ufw allow from 100.83.222.69 to any port 22 proto tcp comment 'SSH from admin device'
```

**Allow service from specific IP:**
```bash
# Allow port 8080 only from specific IP
sudo ufw allow from 192.168.1.100 to any port 8080 proto tcp comment 'Service from admin IP'
```

### Allow Port Range
```bash
# Allow port range
sudo ufw allow 8000:8010/tcp comment 'Port range for service'
```

---

## Removing Firewall Rules

### By Rule Number (Recommended)

**Step 1: List numbered rules**
```bash
sudo ufw status numbered
```

**Step 2: Delete by number**
```bash
# Delete rule number 5
sudo ufw delete 5
```

### By Rule Specification
```bash
# Delete specific rule
sudo ufw delete allow <port>/<protocol>

# Example
sudo ufw delete allow 3306/tcp
```

### Delete All Rules (Reset)
```bash
# Reset firewall to defaults (removes all rules)
sudo ufw --force reset

# Then reconfigure using Ansible or manual script
```

---

## Modifying Existing Rules

### Update a Rule

**Method 1: Delete and Re-add**
```bash
# 1. Find rule number
sudo ufw status numbered

# 2. Delete old rule
sudo ufw delete <number>

# 3. Add new rule
sudo ufw allow <port>/<protocol> comment 'Updated description'
```

**Method 2: Use Ansible (Recommended)**
Update the Ansible playbook and redeploy (see [Managing via Ansible](#managing-via-ansible)).

---

## Managing via Ansible

### Recommended Approach

The firewall should be managed via Ansible for consistency and version control.

**File**: `ansible/roles/hardening/tasks/main.yml`

### Adding New Rules

**Step 1: Edit Ansible playbook**
```yaml
# Add to ansible/roles/hardening/tasks/main.yml

- name: Allow new service port
  community.general.ufw:
    rule: allow
    port: '8080'
    proto: tcp
    comment: 'New Service'
```

**Step 2: Run playbook**
```bash
cd /home/comzis/inlock-infra
ansible-playbook playbooks/hardening.yml
```

### Updating Existing Rules

**Step 1: Update playbook**
```yaml
# Modify existing rule in ansible/roles/hardening/tasks/main.yml
- name: Allow SSH (restrict to Tailscale subnet)
  community.general.ufw:
    rule: allow
    port: '22'
    proto: tcp
    from_ip: '100.64.0.0/10'  # Add IP restriction
    comment: 'SSH from Tailscale'
```

**Step 2: Run playbook**
```bash
ansible-playbook playbooks/hardening.yml
```

**Note**: Ansible will handle removing old rules and adding new ones.

---

## Managing via Scripts

### Manual Script

**Script**: `scripts/apply-firewall-manual.sh`

**Usage:**
```bash
cd /home/comzis/inlock-infra
sudo ./scripts/apply-firewall-manual.sh
```

**To customize**: Edit the script to add/remove rules before running.

### Custom Management Script

Create a custom script for your specific needs:

```bash
#!/usr/bin/env bash
# scripts/manage-firewall.sh

set -euo pipefail

ACTION="${1:-status}"

case "$ACTION" in
  status)
    sudo ufw status verbose
    ;;
  allow)
    PORT="${2:-}"
    PROTO="${3:-tcp}"
    COMMENT="${4:-Service}"
    if [ -z "$PORT" ]; then
      echo "Usage: $0 allow <port> [protocol] [comment]"
      exit 1
    fi
    sudo ufw allow ${PORT}/${PROTO} comment "$COMMENT"
    ;;
  deny)
    PORT="${2:-}"
    PROTO="${3:-tcp}"
    if [ -z "$PORT" ]; then
      echo "Usage: $0 deny <port> [protocol]"
      exit 1
    fi
    sudo ufw delete allow ${PORT}/${PROTO} || true
    ;;
  reload)
    sudo ufw reload
    ;;
  *)
    echo "Usage: $0 {status|allow|deny|reload}"
    exit 1
    ;;
esac
```

**Usage:**
```bash
# View status
./scripts/manage-firewall.sh status

# Allow port
./scripts/manage-firewall.sh allow 8080 tcp "New Service"

# Remove port
./scripts/manage-firewall.sh deny 8080 tcp

# Reload firewall
./scripts/manage-firewall.sh reload
```

---

## Best Practices

### 1. Document All Changes

**Always document firewall changes:**
- Update `docs/FIREWALL-STATUS.md` with new rules
- Add comments to rules: `sudo ufw allow 8080/tcp comment 'Service Name'`
- Commit Ansible changes to Git

### 2. Use Ansible for Production

**For production environments:**
- ✅ Use Ansible playbooks (version controlled)
- ✅ Test changes in staging first
- ✅ Document changes in commit messages
- ❌ Avoid manual `ufw` commands in production

### 3. Principle of Least Privilege

**Only allow what's necessary:**
- ✅ Allow specific ports, not ranges
- ✅ Restrict SSH to Tailscale subnet when possible
- ✅ Use IP restrictions for admin services
- ❌ Don't allow ports "just in case"

### 4. Regular Audits

**Review firewall rules regularly:**
```bash
# Monthly audit checklist
sudo ufw status numbered > /tmp/firewall-audit-$(date +%Y%m%d).txt
# Review and remove unused rules
```

### 5. Test Before Applying

**Test firewall changes:**
```bash
# 1. Check current rules
sudo ufw status numbered > /tmp/before.txt

# 2. Make changes
sudo ufw allow <port>/tcp

# 3. Test connectivity
curl -v http://server:port

# 4. If issues, revert
sudo ufw delete <rule_number>
```

### 6. Backup Configuration

**Backup firewall rules:**
```bash
# Export current rules
sudo ufw status numbered > /home/comzis/inlock-infra/backups/firewall-rules-$(date +%Y%m%d).txt

# Or use iptables-save (if needed)
sudo iptables-save > /home/comzis/inlock-infra/backups/iptables-$(date +%Y%m%d).txt
```

---

## Monitoring & Logging

### Enable Logging

**UFW logging is typically enabled by default. Check:**
```bash
# Check log level
grep -i "LOG" /etc/ufw/ufw.conf

# Log levels:
# LOGLEVEL=off     - No logging
# LOGLEVEL=low     - Blocked packets only
# LOGLEVEL=medium  - Low + invalid packets
# LOGLEVEL=high    - Medium + all packets
# LOGLEVEL=full    - Everything
```

**View logs:**
```bash
# Real-time log monitoring
sudo tail -f /var/log/ufw.log

# Search for blocked connections
sudo grep BLOCK /var/log/ufw.log

# Search for specific IP
sudo grep "192.168.1.100" /var/log/ufw.log
```

### Log Rotation

**UFW logs are rotated automatically via logrotate:**
```bash
# Check logrotate config
cat /etc/logrotate.d/ufw
```

---

## Troubleshooting

### Firewall Blocking Legitimate Traffic

**Problem**: Service is not accessible

**Solution**:
```bash
# 1. Check if port is allowed
sudo ufw status | grep <port>

# 2. Check firewall logs
sudo tail -f /var/log/ufw.log

# 3. Temporarily allow port for testing
sudo ufw allow <port>/tcp

# 4. Test connectivity
curl -v http://server:port

# 5. If working, make permanent via Ansible
```

### Cannot Access Server After Firewall Change

**Problem**: Locked out of server

**Solution**:
```bash
# If you have console access:
# 1. Disable firewall temporarily
sudo ufw disable

# 2. Fix the issue
sudo ufw delete <problematic_rule>

# 3. Re-enable firewall
sudo ufw enable
```

### Firewall Not Starting

**Problem**: UFW fails to start

**Solution**:
```bash
# Check status
sudo systemctl status ufw

# Check logs
sudo journalctl -u ufw

# Reset firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
```

### Rules Not Applying

**Problem**: Changes not taking effect

**Solution**:
```bash
# Reload firewall
sudo ufw reload

# Or disable and re-enable
sudo ufw disable
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## Workflow for Adding New Service

### Step-by-Step Process

**1. Plan the change:**
- What port does the service need?
- Should it be public or restricted?
- What IPs should have access?

**2. Update Ansible playbook:**
```yaml
# Edit ansible/roles/hardening/tasks/main.yml
- name: Allow new service
  community.general.ufw:
    rule: allow
    port: '8080'
    proto: tcp
    from_ip: '100.64.0.0/10'  # If restricting to Tailscale
    comment: 'New Service Name'
```

**3. Test in staging (if available):**
```bash
ansible-playbook playbooks/hardening.yml --limit staging
```

**4. Apply to production:**
```bash
ansible-playbook playbooks/hardening.yml
```

**5. Verify:**
```bash
sudo ufw status | grep 8080
curl -v http://server:8080
```

**6. Document:**
- Update `docs/FIREWALL-STATUS.md`
- Commit changes to Git

---

## Quick Reference

### Common Commands

```bash
# View status
sudo ufw status verbose

# Allow port
sudo ufw allow <port>/tcp comment 'Description'

# Allow from IP
sudo ufw allow from <IP> to any port <port> proto tcp

# Delete rule
sudo ufw delete <rule_number>

# Reload firewall
sudo ufw reload

# Disable firewall (emergency)
sudo ufw disable

# Enable firewall
sudo ufw enable

# Reset firewall
sudo ufw --force reset
```

### Current Standard Rules

| Port | Protocol | Purpose | Access |
|------|----------|---------|--------|
| 41641 | UDP | Tailscale | Public |
| 22 | TCP | SSH | Public (should restrict to Tailscale) |
| 80 | TCP | HTTP | Public |
| 443 | TCP | HTTPS | Public |

---

## Automation & CI/CD

### GitOps Approach

**1. Store firewall rules in Git:**
- Ansible playbooks in `ansible/roles/hardening/`
- Documentation in `docs/FIREWALL-STATUS.md`

**2. Review changes:**
- All firewall changes via Pull Request
- Review before merging

**3. Deploy automatically:**
```bash
# In CI/CD pipeline
ansible-playbook playbooks/hardening.yml --check  # Dry run
ansible-playbook playbooks/hardening.yml          # Apply
```

### Scheduled Audits

**Create audit script:**
```bash
#!/usr/bin/env bash
# scripts/audit-firewall.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/home/comzis/inlock-infra/backups"

mkdir -p "$BACKUP_DIR"

# Backup current rules
sudo ufw status numbered > "$BACKUP_DIR/firewall-rules-$DATE.txt"

# Compare with previous backup
if [ -f "$BACKUP_DIR/firewall-rules-previous.txt" ]; then
  diff "$BACKUP_DIR/firewall-rules-previous.txt" "$BACKUP_DIR/firewall-rules-$DATE.txt"
fi

# Update previous backup
cp "$BACKUP_DIR/firewall-rules-$DATE.txt" "$BACKUP_DIR/firewall-rules-previous.txt"

echo "Firewall audit completed: $BACKUP_DIR/firewall-rules-$DATE.txt"
```

**Schedule monthly:**
```bash
# Add to crontab
0 0 1 * * /home/comzis/inlock-infra/scripts/audit-firewall.sh
```

---

## Summary

### Management Methods (Priority Order)

1. **Ansible Playbooks** (Recommended for production)
   - Version controlled
   - Consistent across environments
   - Documented in code

2. **Manual Scripts** (For quick fixes)
   - `scripts/apply-firewall-manual.sh`
   - Custom management scripts

3. **Direct UFW Commands** (Emergency only)
   - Quick fixes
   - Must document and commit changes

### Key Principles

- ✅ **Document everything** - Update docs and Git
- ✅ **Use Ansible** - For production changes
- ✅ **Test first** - Verify before applying
- ✅ **Audit regularly** - Review rules monthly
- ✅ **Least privilege** - Only allow what's needed
- ✅ **Monitor logs** - Watch for blocked traffic

---

**Last Updated**: December 8, 2025  
**Maintainer**: INLOCK.AI Infrastructure Team










