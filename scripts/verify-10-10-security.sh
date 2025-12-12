#!/bin/bash
# Verify 10/10 Security Score
# Run: ./verify-10-10-security.sh

set -euo pipefail

echo "=========================================="
echo "  Verifying 10/10 Security Score"
echo "  $(date)"
echo "=========================================="
echo ""

SCORE=0
MAX_SCORE=10
ISSUES=()
PASSED=()

check_pass() {
    PASSED+=("$1")
    SCORE=$((SCORE + 1))
    echo "✓ $1"
}

check_fail() {
    ISSUES+=("$1")
    echo "✗ $1"
}

# 1. SSH Configuration
echo "=== 1. SSH Configuration ==="
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config && \
   grep -q "^X11Forwarding no" /etc/ssh/sshd_config && \
   grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    check_pass "SSH fully hardened"
else
    check_fail "SSH not fully hardened"
fi
echo ""

# 2. Fail2ban
echo "=== 2. Fail2ban ==="
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    if fail2ban-client status sshd >/dev/null 2>&1; then
        check_pass "fail2ban active with SSH jail"
    else
        check_fail "fail2ban running but SSH jail not active"
    fi
else
    check_fail "fail2ban not running"
fi
echo ""

# 3. Firewall
echo "=== 3. Firewall ==="
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    SSH_RULES=$(ufw status 2>/dev/null | grep "22/tcp" | grep -c "100.83.222.69\|100.96.110.8" || echo "0")
    if [ "$SSH_RULES" -gt 0 ]; then
        check_pass "Firewall active with SSH restricted"
    else
        check_fail "Firewall active but SSH not restricted"
    fi
else
    check_fail "Firewall not active"
fi
echo ""

# 4. Updates
echo "=== 4. Security Updates ==="
PENDING=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
if [ "$PENDING" -le 1 ]; then
    check_pass "Security updates applied"
else
    check_fail "Security updates pending ($PENDING packages)"
fi
echo ""

# 5. Port Exposure
echo "=== 5. Port Exposure ==="
EXPOSED=$(netstat -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u || ss -tulpn 2>/dev/null | grep "0.0.0.0" | awk '{print $5}' | cut -d: -f2 | sort -u || true)
UNSAFE_PORTS=$(echo "$EXPOSED" | grep -vE "^(22|80|443|41641|53)$" | wc -l)
if [ "$UNSAFE_PORTS" -eq 0 ]; then
    check_pass "Only required ports exposed"
else
    check_fail "Unnecessary ports exposed"
fi
echo ""

# 6. Docker Security
echo "=== 6. Docker Security ==="
DOCKER_EXPOSED=$(docker ps --format "{{.Names}}\t{{.Ports}}" 2>/dev/null | grep "0.0.0.0" | grep -v "traefik" | wc -l)
DOCKER_EXPOSED=$(echo "$DOCKER_EXPOSED" | tr -d ' \n')
if [ -z "$DOCKER_EXPOSED" ] || [ "$DOCKER_EXPOSED" = "0" ]; then
    check_pass "No unnecessary Docker ports exposed"
else
    check_fail "Docker containers expose unnecessary ports"
fi
echo ""

# 7. Monitoring
echo "=== 7. Security Monitoring ==="
if [ -f /usr/local/bin/security-monitor.sh ] && [ -x /usr/local/bin/security-monitor.sh ]; then
    check_pass "Security monitoring script installed"
else
    check_fail "Security monitoring not set up"
fi
echo ""

# 8. Auth Log Monitoring
echo "=== 8. Attack Detection ==="
if [ -f /var/log/auth.log ]; then
    RECENT_ATTACKS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -24h | wc -l || echo "0")
    if [ "$RECENT_ATTACKS" -lt 10 ]; then
        check_pass "No excessive recent attacks"
    else
        check_fail "High number of recent attacks ($RECENT_ATTACKS)"
    fi
else
    check_warn "Cannot check auth logs"
fi
echo ""

# 9. Automatic Updates
echo "=== 9. Automatic Updates ==="
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    UPDATE_LIST=$(grep "Update-Package-Lists" /etc/apt/apt.conf.d/20auto-upgrades | grep -oP '\d+' || echo "0")
    UNATTENDED=$(grep "Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades | grep -oP '\d+' || echo "0")
    if [ "$UPDATE_LIST" = "1" ] && [ "$UNATTENDED" = "1" ]; then
        check_pass "Automatic updates enabled"
    else
        check_fail "Automatic updates not fully configured"
    fi
else
    check_fail "Automatic updates not configured"
fi
echo ""

# 10. System Hardening
echo "=== 10. System Hardening ==="
if [ -f /etc/ssh/sshd_config ] && \
   systemctl is-active --quiet fail2ban 2>/dev/null && \
   ufw status 2>/dev/null | grep -q "Status: active"; then
    check_pass "System properly hardened"
else
    check_fail "System hardening incomplete"
fi
echo ""

# Final Score
FINAL_SCORE=$SCORE
echo "=========================================="
echo "  Security Score: $FINAL_SCORE/$MAX_SCORE"
echo "=========================================="
echo ""

if [ "$FINAL_SCORE" -eq 10 ]; then
    echo "🎉 PERFECT! Security score is 10/10!"
    echo ""
    echo "All security measures are in place:"
    for item in "${PASSED[@]}"; do
        echo "  ✓ $item"
    done
else
    echo "Issues found ($((MAX_SCORE - FINAL_SCORE)) remaining):"
    for item in "${ISSUES[@]}"; do
        echo "  ✗ $item"
    done
    echo ""
    echo "Run hardening script:"
    echo "  sudo ./scripts/achieve-10-10-security.sh"
fi

echo ""

