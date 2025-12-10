# Securing Firewall with Ansible

This guide explains how to secure the firewall using Ansible automation.

## Prerequisites

- Root/sudo access
- Python 3 installed
- Network connectivity for package installation

## Quick Setup

### Step 1: Install Ansible

**Option A: Using the setup script (Recommended)**
```bash
cd /home/comzis/inlock-infra
sudo ./scripts/setup-ansible.sh
```

**Option B: Manual installation**
```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible python3-pip

# Install required Ansible collection
ansible-galaxy collection install community.general
```

### Step 2: Verify Installation

```bash
# Check Ansible version
ansible-playbook --version

# Verify collection is installed
ansible-galaxy collection list | grep community.general
```

### Step 3: Run Hardening Playbook

```bash
cd /home/comzis/inlock-infra

# Dry run (check what would change)
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml --check

# Apply changes
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml
```

## What the Playbook Does

The hardening playbook (`ansible/playbooks/hardening.yml`) applies:

### 1. SSH Hardening
- Executes `scripts/harden-ssh.sh` if present
- Configures secure SSH settings

### 2. Docker Hardening
- Executes `scripts/harden-docker.sh` if present
- Applies Docker security best practices

### 3. Automatic Security Updates
- Installs `unattended-upgrades`
- Enables automatic security updates

### 4. Firewall Configuration (UFW)

**Default Policies:**
- Incoming: DENY (default deny all)
- Outgoing: ALLOW
- Routed: ALLOW

**Allowed Ports:**
- UDP 41641 - Tailscale VPN
- TCP 22 - SSH
- TCP 80 - HTTP (Traefik)
- TCP 443 - HTTPS (Traefik)

**Actions:**
1. Installs UFW if not present
2. Resets UFW to defaults
3. Sets default policies
4. Opens required ports
5. Enables UFW
6. Displays firewall status

## Inventory Configuration

The inventory is configured for localhost in `ansible/inventories/hosts.yml`:

```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_host: localhost
  vars:
    ansible_user: comzis
    ansible_become: true
    ansible_python_interpreter: /usr/bin/python3
```

## Running the Playbook

### Basic Run
```bash
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml
```

### With Verbose Output
```bash
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml -v
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml --check
```

### Limit to Specific Tasks
```bash
# Only firewall tasks
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml --tags firewall
```

## Verifying Firewall Configuration

After running the playbook, verify the firewall:

```bash
# Check firewall status
sudo ufw status verbose

# Expected output should show:
# - Status: active
# - Default: deny (incoming), allow (outgoing), allow (routed)
# - Rules for: 41641/udp, 22/tcp, 80/tcp, 443/tcp
```

## Troubleshooting

### Ansible Not Found

**Error**: `ansible-playbook: command not found`

**Solution**:
```bash
sudo ./scripts/setup-ansible.sh
# or
sudo apt install -y ansible
```

### Missing Collection

**Error**: `community.general.ufw` module not found

**Solution**:
```bash
ansible-galaxy collection install community.general
```

### Permission Denied

**Error**: Permission denied when running playbook

**Solution**:
- Ensure `ansible_become: true` in inventory
- Run with sudo if needed
- Check `/etc/sudoers` configuration

### Firewall Already Configured

**Note**: If UFW is already configured, the playbook will:
- Reset to defaults (removes existing rules)
- Apply new rules from the playbook

**To preserve existing rules**:
1. Backup current rules: `sudo ufw status numbered > /tmp/ufw-backup.txt`
2. Review the playbook rules
3. Add any custom rules to the playbook
4. Run the playbook

## Customizing Firewall Rules

To add custom firewall rules, edit `ansible/roles/hardening/tasks/main.yml`:

```yaml
# Add after existing rules
- name: Allow custom service port
  community.general.ufw:
    rule: allow
    port: '8080'
    proto: tcp
    comment: 'Custom Service'
```

Then run the playbook again.

## Re-running the Playbook

The playbook is idempotent - you can run it multiple times safely:

```bash
# Re-run to ensure configuration is correct
ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml
```

## Integration with CI/CD

The playbook can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Harden infrastructure
  run: |
    ansible-playbook -i ansible/inventories/hosts.yml ansible/playbooks/hardening.yml
```

## Alternative: Manual Script

If Ansible is not available, use the manual script:

```bash
sudo ./scripts/apply-firewall-manual.sh
```

This applies the same firewall rules without Ansible.

## Next Steps

After securing the firewall:

1. **Verify firewall status**: `sudo ufw status verbose`
2. **Test connectivity**: Ensure services are accessible
3. **Monitor logs**: `sudo tail -f /var/log/ufw.log`
4. **Document changes**: Update firewall documentation if rules were customized

## Related Documentation

- **[Firewall Management](FIREWALL-MANAGEMENT.md)** - Managing firewall after setup
- **[Network Security](network-security.md)** - Network security overview
- **[Firewall Status](FIREWALL-STATUS.md)** - Current firewall status

---

**Last Updated**: December 8, 2025  
**Maintainer**: INLOCK.AI Infrastructure Team




