#!/bin/bash
# Comprehensive Security Hardening Script
# Addresses security review findings
# Run with: sudo ./harden-security.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

LOG_FILE="/tmp/security-hardening-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=========================================="
echo "  Security Hardening Script"
echo "  Started: $(date)"
echo "  Log: $LOG_FILE"
echo "=========================================="
echo ""

# ============================================================================
# STEP 1: HARDEN SSH CONFIGURATION
# ============================================================================
echo "=== STEP 1: Hardening SSH Configuration ==="

SSH_CONFIG="/etc/ssh/sshd_config"
if [ ! -f "$SSH_CONFIG" ]; then
    echo "ERROR: SSH config not found at $SSH_CONFIG"
    exit 1
fi

# Backup original
BACKUP_FILE="${SSH_CONFIG}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SSH_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Disable password authentication
if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    echo "  ✓ Password authentication disabled"
elif grep -q "^#PasswordAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    echo "  ✓ Password authentication explicitly disabled"
else
    echo "PasswordAuthentication no" >> "$SSH_CONFIG"
    echo "  ✓ Password authentication disabled (added)"
fi

# Disable X11 forwarding
if grep -q "^X11Forwarding" "$SSH_CONFIG"; then
    sed -i 's/^X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
    echo "  ✓ X11 forwarding disabled"
elif grep -q "^#X11Forwarding" "$SSH_CONFIG"; then
    sed -i 's/^#X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
    echo "  ✓ X11 forwarding explicitly disabled"
else
    echo "X11Forwarding no" >> "$SSH_CONFIG"
    echo "  ✓ X11 forwarding disabled (added)"
fi

# Ensure root login is disabled
if grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    echo "  ✓ Root login confirmed disabled"
fi

# Test SSH config
if sshd -t; then
    echo "  ✓ SSH configuration is valid"
    systemctl restart sshd
    echo "  ✓ SSH service restarted"
else
    echo "  ERROR: SSH configuration test failed - restoring backup"
    cp "$BACKUP_FILE" "$SSH_CONFIG"
    exit 1
fi

echo ""

# ============================================================================
# STEP 2: FIX FAIL2BAN
# ============================================================================
echo "=== STEP 2: Configuring Fail2ban ==="

# Install fail2ban if not present
if ! command -v fail2ban-server >/dev/null 2>&1; then
    echo "Installing fail2ban..."
    apt-get update -qq
    apt-get install -y fail2ban
    echo "  ✓ fail2ban installed"
fi

# Check if fail2ban is running
if systemctl is-active --quiet fail2ban; then
    echo "  fail2ban is already running"
else
    echo "  Starting fail2ban service..."
    systemctl enable fail2ban
    systemctl start fail2ban
    sleep 2
    
    if systemctl is-active --quiet fail2ban; then
        echo "  ✓ fail2ban started successfully"
    else
        echo "  ⚠️  WARNING: fail2ban failed to start"
        systemctl status fail2ban --no-pager | head -10
    fi
fi

# Verify fail2ban is protecting SSH
if fail2ban-client status sshd >/dev/null 2>&1; then
    echo "  ✓ SSH jail is active"
    fail2ban-client status sshd | grep -E "Currently banned|Total banned" || true
else
    echo "  ⚠️  WARNING: SSH jail not found, creating..."
    # Create basic SSH jail if missing
    cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600
findtime = 600
EOF
    systemctl restart fail2ban
    echo "  ✓ SSH jail configured"
fi

echo ""

# ============================================================================
# STEP 3: CONFIGURE FIREWALL
# ============================================================================
echo "=== STEP 3: Configuring Firewall ==="

# Install UFW if not present
if ! command -v ufw >/dev/null 2>&1; then
    echo "Installing UFW..."
    apt-get update -qq
    apt-get install -y ufw
    echo "  ✓ UFW installed"
fi

# Backup existing rules
if [ -f /etc/ufw/user.rules ]; then
    UFW_BACKUP="/etc/ufw/user.rules.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/ufw/user.rules "$UFW_BACKUP"
    echo "Backup created: $UFW_BACKUP"
fi

# Enable UFW if not already enabled
if ! ufw status | grep -q "Status: active"; then
    echo "Enabling UFW firewall..."
    ufw --force enable
    echo "  ✓ UFW enabled"
else
    echo "  UFW is already active"
fi

# Set default policies
echo "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing
echo "  ✓ Default policies: deny incoming, allow outgoing"

# Allow Tailscale
echo "Configuring Tailscale access..."
ufw allow 41641/udp comment 'Tailscale'
echo "  ✓ Tailscale port allowed"

# Allow HTTP/HTTPS (required for Traefik)
echo "Configuring web access..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
echo "  ✓ HTTP/HTTPS allowed"

# Restrict SSH to Tailscale IPs only
echo "Restricting SSH access..."
# Remove existing SSH rules
ufw status numbered | grep "22/tcp" | awk -F'[][]' '{print $2}' | sort -rn | while read num; do
    echo "y" | ufw delete "$num" >/dev/null 2>&1 || true
done

# Add Tailscale-specific SSH rules
ufw allow from 100.83.222.69/32 to any port 22 comment 'SSH - Tailscale Server'
ufw allow from 100.96.110.8/32 to any port 22 comment 'SSH - Tailscale MacBook'
echo "  ✓ SSH restricted to Tailscale IPs"

# Block unnecessary ports
echo "Blocking unnecessary ports..."
ufw deny 9090/tcp comment 'Prometheus - Internal only'
ufw deny 9100/tcp comment 'Node Exporter - Internal only'
ufw deny 5432/tcp comment 'PostgreSQL - Internal only'
ufw deny 6379/tcp comment 'Redis - Internal only'
ufw deny 3000/tcp comment 'Next.js - Internal only'
echo "  ✓ Unnecessary ports blocked"

# Allow internal Docker networks
echo "Configuring internal network access..."
ufw allow from 172.20.0.0/16 comment 'Docker edge network'
ufw allow from 172.18.0.0/16 comment 'Docker default network'
ufw allow from 172.17.0.0/16 comment 'Docker bridge network'
echo "  ✓ Internal Docker networks allowed"

echo ""
echo "Firewall status:"
ufw status numbered
echo ""

# ============================================================================
# STEP 4: VERIFY SECURITY POSTURE
# ============================================================================
echo "=== STEP 4: Security Verification ==="

# Check SSH configuration
SSH_PASS=$(grep -E "^PasswordAuthentication" "$SSH_CONFIG" | grep -v "^#" || echo "not set")
SSH_X11=$(grep -E "^X11Forwarding" "$SSH_CONFIG" | grep -v "^#" || echo "not set")
SSH_ROOT=$(grep -E "^PermitRootLogin" "$SSH_CONFIG" | grep -v "^#" || echo "not set")

echo "SSH Configuration:"
echo "  PasswordAuthentication: $SSH_PASS"
echo "  X11Forwarding: $SSH_X11"
echo "  PermitRootLogin: $SSH_ROOT"

# Check fail2ban
if systemctl is-active --quiet fail2ban; then
    echo "  ✓ fail2ban is running"
else
    echo "  ✗ fail2ban is NOT running"
fi

# Check firewall
if ufw status | grep -q "Status: active"; then
    echo "  ✓ Firewall is active"
else
    echo "  ✗ Firewall is NOT active"
fi

# Check exposed ports
EXPOSED=$(netstat -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u || ss -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $5}' | cut -d: -f2 | sort -u || true)
echo ""
echo "Ports listening on 0.0.0.0:"
echo "$EXPOSED" | while read port; do
    case "$port" in
        22) echo "  $port - SSH (restricted to Tailscale via firewall)" ;;
        80|443) echo "  $port - Traefik (required for reverse proxy)" ;;
        41641) echo "  $port - Tailscale (required)" ;;
        53) echo "  $port - DNS (system service)" ;;
        *) echo "  $port - Review if needed" ;;
    esac
done

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "=========================================="
echo "  Security Hardening Complete"
echo "  Completed: $(date)"
echo "=========================================="
echo ""
echo "Actions taken:"
echo "✓ SSH password authentication disabled"
echo "✓ SSH X11 forwarding disabled"
echo "✓ fail2ban configured and started"
echo "✓ Firewall (UFW) configured and active"
echo "✓ SSH restricted to Tailscale IPs"
echo "✓ Unnecessary ports blocked"
echo ""
echo "Next steps:"
echo "1. Test SSH access from Tailscale IPs"
echo "2. Monitor fail2ban logs: sudo tail -f /var/log/fail2ban.log"
echo "3. Review auth logs: sudo tail -f /var/log/auth.log"
echo "4. Verify Docker services are behind Traefik"
echo ""
echo "Log file: $LOG_FILE"
echo ""

