#!/bin/bash
# Achieve 10/10 Security Score - Complete Hardening
# Run with: sudo ./achieve-10-10-security.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

LOG_FILE="/tmp/security-10-10-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=========================================="
echo "  Achieving 10/10 Security Score"
echo "  Started: $(date)"
echo "  Log: $LOG_FILE"
echo "=========================================="
echo ""

# ============================================================================
# STEP 1: VERIFY SSH HARDENING (Already Done)
# ============================================================================
echo "=== STEP 1: Verifying SSH Configuration ==="

SSH_CONFIG="/etc/ssh/sshd_config"
if grep -q "^PasswordAuthentication no" "$SSH_CONFIG" && \
   grep -q "^X11Forwarding no" "$SSH_CONFIG" && \
   grep -q "^PermitRootLogin no" "$SSH_CONFIG"; then
    echo "  ✓ SSH is properly hardened"
else
    echo "  Fixing SSH configuration..."
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sshd -t && systemctl restart sshd
    echo "  ✓ SSH hardened"
fi
echo ""

# ============================================================================
# STEP 2: FIX FAIL2BAN SSH JAIL
# ============================================================================
echo "=== STEP 2: Configuring Fail2ban SSH Jail ==="

# Ensure fail2ban is installed
if ! command -v fail2ban-server >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y fail2ban
fi

# Create SSH jail configuration
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600
findtime = 600
ignoreip = 127.0.0.1/8 ::1 100.83.222.69 100.96.110.8
EOF

# Enable and start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban
sleep 2

# Verify SSH jail is active
if fail2ban-client status sshd >/dev/null 2>&1; then
    echo "  ✓ SSH jail is active"
    BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
    echo "  Currently banned IPs: $BANNED"
else
    echo "  ⚠️  SSH jail not active, checking configuration..."
    fail2ban-client reload
    sleep 2
    if fail2ban-client status sshd >/dev/null 2>&1; then
        echo "  ✓ SSH jail is now active"
    else
        echo "  ⚠️  SSH jail still not active - manual review needed"
    fi
fi
echo ""

# ============================================================================
# STEP 3: CONFIGURE FIREWALL (UFW)
# ============================================================================
echo "=== STEP 3: Configuring Firewall ==="

# Install UFW if not present
if ! command -v ufw >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y ufw
fi

# Backup existing rules
if [ -f /etc/ufw/user.rules ]; then
    cp /etc/ufw/user.rules "/etc/ufw/user.rules.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Enable UFW
if ! ufw status | grep -q "Status: active"; then
    ufw --force enable
    echo "  ✓ UFW enabled"
else
    echo "  UFW already active"
fi

# Set default policies
ufw default deny incoming
ufw default allow outgoing
echo "  ✓ Default policies set"

# Remove all existing rules to start fresh
ufw --force reset >/dev/null 2>&1 || true
ufw --force enable

# Allow Tailscale
ufw allow 41641/udp comment 'Tailscale'

# Allow HTTP/HTTPS (Traefik)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Restrict SSH to Tailscale IPs only
ufw allow from 100.83.222.69/32 to any port 22 comment 'SSH - Tailscale Server'
ufw allow from 100.96.110.8/32 to any port 22 comment 'SSH - Tailscale MacBook'

# Block unnecessary ports
ufw deny 9090/tcp comment 'Prometheus - Internal only'
ufw deny 9100/tcp comment 'Node Exporter - Internal only'
ufw deny 5432/tcp comment 'PostgreSQL - Internal only'
ufw deny 6379/tcp comment 'Redis - Internal only'
ufw deny 3000/tcp comment 'Next.js - Internal only'

# Allow internal Docker networks
ufw allow from 172.20.0.0/16 comment 'Docker edge network'
ufw allow from 172.18.0.0/16 comment 'Docker default network'
ufw allow from 172.17.0.0/16 comment 'Docker bridge network'

echo "  ✓ Firewall rules configured"
echo ""
echo "Firewall status:"
ufw status numbered
echo ""

# ============================================================================
# STEP 4: APPLY SECURITY UPDATES
# ============================================================================
echo "=== STEP 4: Applying Security Updates ==="

apt-get update -qq
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")

if [ "$UPGRADABLE" -gt 1 ]; then
    echo "  Found $UPGRADABLE upgradable packages"
    echo "  Applying updates..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
    echo "  ✓ Security updates applied"
    
    # Check if kernel was updated
    if [ -f /var/run/reboot-required ]; then
        echo "  ⚠️  Reboot required for kernel updates"
        echo "  Run: sudo reboot"
    fi
else
    echo "  ✓ System is up to date"
fi
echo ""

# ============================================================================
# STEP 5: REVIEW AND RESTRICT EXPOSED PORTS
# ============================================================================
echo "=== STEP 5: Reviewing Exposed Ports ==="

# Check what's actually exposed
EXPOSED=$(netstat -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u || ss -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $5}' | cut -d: -f2 | sort -u || true)

echo "Ports listening on 0.0.0.0:"
for port in $EXPOSED; do
    case "$port" in
        22) echo "  $port - SSH (restricted to Tailscale via firewall)" ;;
        80|443) echo "  $port - Traefik (required)" ;;
        41641) echo "  $port - Tailscale (required)" ;;
        53) echo "  $port - DNS (system service)" ;;
        *) 
            echo "  $port - Reviewing..."
            # Check if it's actually on localhost or Tailscale IP
            if netstat -tulpn 2>/dev/null | grep ":$port" | grep -q "127.0.0.1\|100.83.222.69"; then
                echo "    → Actually on localhost/Tailscale only (safe)"
            else
                echo "    → ⚠️  May need firewall rule"
            fi
            ;;
    esac
done
echo ""

# ============================================================================
# STEP 6: VERIFY DOCKER SECURITY
# ============================================================================
echo "=== STEP 6: Verifying Docker Security ==="

# Check Docker exposed ports
DOCKER_EXPOSED=$(docker ps --format "{{.Names}}\t{{.Ports}}" 2>/dev/null | grep "0.0.0.0" | grep -v "traefik" | wc -l)
# Handle case where wc returns "0\n" or empty
DOCKER_EXPOSED=$(echo "$DOCKER_EXPOSED" | tr -d ' \n')
if [ -z "$DOCKER_EXPOSED" ] || [ "$DOCKER_EXPOSED" = "0" ]; then
    echo "  ✓ No unnecessary Docker ports exposed"
else
    echo "  ⚠️  Some Docker containers expose ports:"
    docker ps --format "{{.Names}}\t{{.Ports}}" 2>/dev/null | grep "0.0.0.0" | grep -v "traefik" || true
fi

# Check Docker socket exposure
if docker ps --format "{{.Mounts}}" 2>/dev/null | grep -q "/var/run/docker.sock"; then
    echo "  ⚠️  Docker socket mounted in containers (review needed)"
else
    echo "  ✓ Docker socket not directly exposed"
fi
echo ""

# ============================================================================
# STEP 7: MONITORING SETUP
# ============================================================================
echo "=== STEP 7: Setting Up Security Monitoring ==="

# Create log monitoring script
cat > /usr/local/bin/security-monitor.sh <<'EOF'
#!/bin/bash
# Security monitoring script - check for attacks
echo "=== Security Monitor - $(date) ==="
echo ""
echo "Recent SSH failures:"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "None"
echo ""
echo "fail2ban status:"
fail2ban-client status sshd 2>/dev/null | grep -E "Currently banned|Total banned" || echo "Not available"
echo ""
echo "Firewall status:"
ufw status | head -5
EOF

chmod +x /usr/local/bin/security-monitor.sh
echo "  ✓ Security monitoring script created: /usr/local/bin/security-monitor.sh"

# Add to cron for regular monitoring (optional)
if ! crontab -l 2>/dev/null | grep -q "security-monitor"; then
    (crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/security-monitor.sh >> /var/log/security-monitor.log 2>&1") | crontab -
    echo "  ✓ Added to cron (runs every 30 minutes)"
fi
echo ""

# ============================================================================
# FINAL VERIFICATION
# ============================================================================
echo "=== FINAL VERIFICATION ==="

# Check SSH
if grep -q "^PasswordAuthentication no" "$SSH_CONFIG" && \
   grep -q "^X11Forwarding no" "$SSH_CONFIG" && \
   grep -q "^PermitRootLogin no" "$SSH_CONFIG"; then
    echo "  ✓ SSH: Hardened"
else
    echo "  ✗ SSH: Not fully hardened"
fi

# Check fail2ban
if systemctl is-active --quiet fail2ban && fail2ban-client status sshd >/dev/null 2>&1; then
    echo "  ✓ fail2ban: Active with SSH jail"
else
    echo "  ✗ fail2ban: Not fully configured"
fi

# Check firewall
if ufw status | grep -q "Status: active"; then
    SSH_RESTRICTED=$(ufw status | grep "22/tcp" | grep -q "100.83.222.69\|100.96.110.8" && echo "yes" || echo "no")
    if [ "$SSH_RESTRICTED" = "yes" ]; then
        echo "  ✓ Firewall: Active with SSH restricted"
    else
        echo "  ⚠️  Firewall: Active but SSH may not be restricted"
    fi
else
    echo "  ✗ Firewall: Not active"
fi

# Check updates
PENDING=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
if [ "$PENDING" -le 1 ]; then
    echo "  ✓ Updates: Applied"
else
    echo "  ⚠️  Updates: $PENDING packages pending"
fi

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
echo "✓ SSH hardened (password auth, X11, root login disabled)"
echo "✓ fail2ban configured with SSH jail"
echo "✓ Firewall (UFW) enabled and configured"
echo "✓ SSH restricted to Tailscale IPs"
echo "✓ Unnecessary ports blocked"
echo "✓ Security updates applied"
echo "✓ Monitoring script created"
echo ""
echo "Next steps:"
echo "1. Test SSH access from Tailscale IPs"
echo "2. Monitor fail2ban: sudo fail2ban-client status sshd"
echo "3. Check security monitor: /usr/local/bin/security-monitor.sh"
echo "4. Review logs: sudo tail -f /var/log/auth.log"
echo ""
echo "Run security review:"
echo "  ./scripts/security-review.sh"
echo ""
echo "Log file: $LOG_FILE"
echo ""

