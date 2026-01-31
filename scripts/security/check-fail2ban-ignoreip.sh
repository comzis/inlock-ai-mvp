#!/bin/bash
# Check if an IP is in fail2ban ignoreip (so it won't be banned).
# Run on the server: sudo ./scripts/security/check-fail2ban-ignoreip.sh [IP]
# Example: sudo ./scripts/security/check-fail2ban-ignoreip.sh 31.10.147.220

set -euo pipefail

CHECK_IP="${1:-31.10.147.220}"

echo "=== fail2ban ignoreip check for $CHECK_IP ==="
echo ""

if ! command -v fail2ban-client >/dev/null 2>&1; then
  echo "fail2ban not installed."
  exit 0
fi

if ! systemctl is-active fail2ban >/dev/null 2>&1; then
  echo "fail2ban service is not active."
  exit 0
fi

echo "--- ignoreip in jail config ---"
shopt -s nullglob 2>/dev/null || true
for f in /etc/fail2ban/jail.local /etc/fail2ban/jail.d/*.local /etc/fail2ban/jail.d/*.conf; do
  [ -f "$f" ] || continue
  if grep -q "ignoreip" "$f" 2>/dev/null; then
    echo "  $f:"
    grep -E "ignoreip|^\s*#" "$f" 2>/dev/null | sed 's/^/    /'
  fi
done
echo ""

# Check if CHECK_IP appears in any ignoreip line
FOUND=0
for f in /etc/fail2ban/jail.local /etc/fail2ban/jail.d/*.local /etc/fail2ban/jail.d/*.conf; do
  [ -f "$f" ] || continue
  if grep "ignoreip" "$f" 2>/dev/null | grep -q "$CHECK_IP"; then
    FOUND=1
    break
  fi
done

if [ "$FOUND" -eq 1 ]; then
  echo "  Result: $CHECK_IP IS in fail2ban ignoreip (will not be banned)."
else
  echo "  Result: $CHECK_IP is NOT in fail2ban ignoreip (can be banned after failed SSH attempts)."
  echo ""
  echo "  To add on the server:"
  echo "    sudo sed -i \"s/ignoreip = \\(.*\\)/ignoreip = \\1 $CHECK_IP/\" /etc/fail2ban/jail.d/sshd.local"
  echo "    # or edit manually: sudo nano /etc/fail2ban/jail.d/sshd.local"
  echo "    sudo systemctl restart fail2ban"
fi
echo ""

echo "--- SSH jail status ---"
fail2ban-client status sshd 2>/dev/null || echo "  (sshd jail not available)"
echo ""

# Check if IP is currently banned
if fail2ban-client status sshd 2>/dev/null | grep -q "Banned IP list"; then
  BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" | sed 's/.*://;s/^[[:space:]]*//')
  if echo "$BANNED" | grep -qw "$CHECK_IP" 2>/dev/null; then
    echo "  WARNING: $CHECK_IP is currently BANNED. Unban with:"
    echo "    sudo fail2ban-client set sshd unbanip $CHECK_IP"
  fi
fi
echo ""
echo "=== End ==="
