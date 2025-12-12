#!/bin/bash
# Comprehensive Security Review Script
# Run: ./security-review.sh

set -euo pipefail

echo "=========================================="
echo "  Security Review"
echo "  $(date)"
echo "=========================================="
echo ""

SCORE=0
MAX_SCORE=10
ISSUES=()
GOOD=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_pass() {
    GOOD+=("$1")
    SCORE=$((SCORE + 1))
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    ISSUES+=("$1")
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    ISSUES+=("$1")
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# SSH CONFIGURATION
# ============================================================================
echo "=== 1. SSH Configuration ==="

if [ -f /etc/ssh/sshd_config ]; then
    SSH_PASS=$(grep -E "^PasswordAuthentication" /etc/ssh/sshd_config | grep -v "^#" || echo "yes")
    SSH_X11=$(grep -E "^X11Forwarding" /etc/ssh/sshd_config | grep -v "^#" || echo "yes")
    SSH_ROOT=$(grep -E "^PermitRootLogin" /etc/ssh/sshd_config | grep -v "^#" || echo "yes")
    SSH_KBD=$(grep -E "^KbdInteractiveAuthentication" /etc/ssh/sshd_config | grep -v "^#" || echo "yes")
    
    if echo "$SSH_PASS" | grep -qi "no"; then
        check_pass "Password authentication disabled"
    else
        check_fail "Password authentication enabled (should be 'PasswordAuthentication no')"
    fi
    
    if echo "$SSH_X11" | grep -qi "no"; then
        check_pass "X11 forwarding disabled"
    else
        check_fail "X11 forwarding enabled (should be 'X11Forwarding no')"
    fi
    
    if echo "$SSH_ROOT" | grep -qi "no"; then
        check_pass "Root login disabled"
    else
        check_fail "Root login enabled (should be 'PermitRootLogin no')"
    fi
    
    if echo "$SSH_KBD" | grep -qi "no"; then
        check_pass "Keyboard-interactive auth disabled"
    else
        check_warn "Keyboard-interactive auth enabled"
    fi
else
    check_fail "SSH config file not found"
fi

echo ""

# ============================================================================
# FAIL2BAN
# ============================================================================
echo "=== 2. Fail2ban Protection ==="

if command -v fail2ban-server >/dev/null 2>&1; then
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        check_pass "fail2ban service is running"
        
        if fail2ban-client status sshd >/dev/null 2>&1; then
            check_pass "SSH jail is active"
            BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
            if [ "$BANNED" -gt 0 ]; then
                echo "  Currently banned IPs: $BANNED"
            fi
        else
            check_fail "SSH jail not configured"
        fi
    else
        check_fail "fail2ban service is NOT running (configured but inactive)"
    fi
else
    check_fail "fail2ban not installed"
fi

echo ""

# ============================================================================
# FIREWALL
# ============================================================================
echo "=== 3. Firewall Configuration ==="

if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        check_pass "UFW firewall is active"
        
        # Check SSH restriction
        SSH_RULES=$(ufw status | grep "22/tcp" | wc -l)
        if [ "$SSH_RULES" -gt 0 ]; then
            if ufw status | grep -q "100.83.222.69\|100.96.110.8"; then
                check_pass "SSH restricted to Tailscale IPs"
            else
                check_warn "SSH has rules but may not be restricted to Tailscale"
            fi
        else
            check_warn "SSH port 22 not found in firewall rules"
        fi
        
        # Check blocked ports
        BLOCKED_PORTS=$(ufw status | grep -E "DENY.*(9090|9100|5432|6379|3000)" | wc -l)
        if [ "$BLOCKED_PORTS" -gt 0 ]; then
            check_pass "Unnecessary ports blocked"
        else
            check_warn "Some unnecessary ports may not be blocked"
        fi
    else
        check_fail "UFW firewall is NOT active"
    fi
else
    check_fail "UFW not installed"
fi

echo ""

# ============================================================================
# EXPOSED PORTS
# ============================================================================
echo "=== 4. Exposed Ports Analysis ==="

EXPOSED=$(netstat -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u || ss -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $5}' | cut -d: -f2 | sort -u || true)

REQUIRED_PORTS=("22" "80" "443" "41641")
UNNECESSARY_PORTS=("9090" "9100" "5432" "6379" "3000")

for port in $EXPOSED; do
    if [[ " ${REQUIRED_PORTS[@]} " =~ " ${port} " ]]; then
        case "$port" in
            22) echo "  $port - SSH (should be restricted to Tailscale)" ;;
            80|443) echo "  $port - Traefik (required)" ;;
            41641) echo "  $port - Tailscale (required)" ;;
        esac
    elif [[ " ${UNNECESSARY_PORTS[@]} " =~ " ${port} " ]]; then
        check_fail "Port $port is publicly exposed (should be internal only)"
    elif [ "$port" = "53" ]; then
        echo "  $port - DNS (system service)"
    else
        check_warn "Port $port is exposed - review if needed"
    fi
done

# Check Docker exposed ports
DOCKER_EXPOSED=$(docker ps --format "{{.Names}}\t{{.Ports}}" 2>/dev/null | grep "0.0.0.0" | grep -v "traefik" | wc -l || echo "0")
if [ -z "$DOCKER_EXPOSED" ]; then
    DOCKER_EXPOSED=0
fi
if [ "$DOCKER_EXPOSED" -eq 0 ]; then
    check_pass "No unnecessary Docker ports exposed"
else
    check_warn "Some Docker containers expose ports publicly"
    docker ps --format "{{.Names}}\t{{.Ports}}" 2>/dev/null | grep "0.0.0.0" | grep -v "traefik" || true
fi

echo ""

# ============================================================================
# AUTOMATIC UPDATES
# ============================================================================
echo "=== 5. Automatic Security Updates ==="

if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    UPDATE_LIST=$(grep "Update-Package-Lists" /etc/apt/apt.conf.d/20auto-upgrades | grep -oP '\d+' || echo "0")
    UNATTENDED=$(grep "Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades | grep -oP '\d+' || echo "0")
    
    if [ "$UPDATE_LIST" = "1" ] && [ "$UNATTENDED" = "1" ]; then
        check_pass "Automatic security updates enabled"
    else
        check_warn "Automatic updates may not be fully configured"
    fi
    
    # Check pending updates
    PENDING=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    if [ "$PENDING" -le 5 ]; then
        check_pass "Few pending updates ($PENDING packages)"
    else
        check_warn "Many pending updates ($PENDING packages) - consider updating"
    fi
else
    check_fail "Automatic updates not configured"
fi

echo ""

# ============================================================================
# AUTH LOGS REVIEW
# ============================================================================
echo "=== 6. Authentication Logs Review ==="

if [ -f /var/log/auth.log ]; then
    RECENT_FAILURES=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo "0")
    if [ "$RECENT_FAILURES" -eq 0 ]; then
        check_pass "No recent SSH password failures"
    else
        check_warn "Recent SSH password failures detected ($RECENT_FAILURES) - review logs"
        echo "  Recent failures:"
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -3 | awk '{print "    " $0}' || true
    fi
    
    SUDO_FAILURES=$(grep "sudo.*authentication failure" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo "0")
    if [ "$SUDO_FAILURES" -eq 0 ]; then
        check_pass "No recent sudo authentication failures"
    else
        check_warn "Recent sudo authentication failures ($SUDO_FAILURES) - review logs"
    fi
else
    check_warn "Auth log not accessible (need sudo)"
fi

echo ""

# ============================================================================
# DOCKER SECURITY
# ============================================================================
echo "=== 7. Docker Security ==="

# Check if containers are running as root
ROOT_CONTAINERS=$(docker ps --format "{{.Names}}\t{{.User}}" 2>/dev/null | grep -E "\troot$|\t$" | wc -l || echo "0")
if [ "$ROOT_CONTAINERS" -eq 0 ]; then
    check_pass "No containers running as root user"
else
    check_warn "Some containers running as root ($ROOT_CONTAINERS)"
fi

# Check for exposed Docker socket
if docker ps --format "{{.Mounts}}" 2>/dev/null | grep -q "/var/run/docker.sock"; then
    check_warn "Docker socket is mounted in containers (security risk)"
else
    check_pass "Docker socket not directly exposed"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "=========================================="
echo "  Security Review Summary"
echo "=========================================="
echo ""

FINAL_SCORE=$((SCORE * 10 / MAX_SCORE))
echo "Security Score: $FINAL_SCORE/10"
echo ""

if [ ${#GOOD[@]} -gt 0 ]; then
    echo "✓ Security Strengths:"
    for item in "${GOOD[@]}"; do
        echo "  - $item"
    done
    echo ""
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "⚠️  Issues Found:"
    for item in "${ISSUES[@]}"; do
        echo "  - $item"
    done
    echo ""
fi

echo "Recommendations:"
if [ "$FINAL_SCORE" -lt 7 ]; then
    echo "1. Run security hardening script: sudo ./scripts/harden-security.sh"
fi
if ! systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo "2. Start fail2ban: sudo systemctl start fail2ban"
fi
if ! ufw status | grep -q "Status: active"; then
    echo "3. Enable firewall: sudo ufw enable"
fi
echo "4. Monitor logs regularly: sudo tail -f /var/log/auth.log"
echo "5. Review exposed ports and restrict as needed"
echo ""

echo "For detailed hardening:"
echo "  sudo ./scripts/harden-security.sh"
echo ""

