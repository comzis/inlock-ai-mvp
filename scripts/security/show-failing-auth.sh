#!/bin/bash
# Show what is failing: recent fail2ban bans and failed auth attempts.
# Run on the server: sudo ./scripts/security/show-failing-auth.sh [IP]
# Example: sudo ./scripts/security/show-failing-auth.sh 31.10.147.220
# Without IP: show recent failures for all IPs.

set -euo pipefail

CHECK_IP="${1:-}"
LINES="${2:-50}"

echo "=== What is failing (last ~$LINES relevant lines) ==="
echo ""

# --- 1. Recent fail2ban activity (bans, unban, found failures) ---
echo "--- 1. Recent fail2ban activity ---"
if [ -r /var/log/fail2ban.log ]; then
  grep -E "Ban |Unban |Found |WARNING \[" /var/log/fail2ban.log 2>/dev/null | tail -n "$LINES" || echo "  (no matches)"
else
  echo "  /var/log/fail2ban.log not readable (run with sudo?)"
fi
echo ""

# --- 2. Recent failed SSH/auth attempts (auth.log) ---
echo "--- 2. Recent failed SSH / invalid user attempts (auth.log) ---"
if [ -r /var/log/auth.log ]; then
  PATTERN="Failed password|Invalid user|Connection closed by authenticating user"
  if [ -n "$CHECK_IP" ]; then
    grep -E "$PATTERN" /var/log/auth.log 2>/dev/null | grep "$CHECK_IP" | tail -n "$LINES" || echo "  (no failures for $CHECK_IP)"
  else
    grep -E "$PATTERN" /var/log/auth.log 2>/dev/null | tail -n "$LINES" || echo "  (no matches)"
  fi
else
  echo "  /var/log/auth.log not readable (run with sudo?)"
fi
echo ""

# --- 3. Same from journalctl if auth.log is not used ---
echo "--- 3. Recent failed SSH (journalctl) ---"
if command -v journalctl >/dev/null 2>&1; then
  JCMD="journalctl -u sshd --no-pager -n $LINES 2>/dev/null"
  if [ -n "$CHECK_IP" ]; then
    journalctl -u sshd --no-pager -n 500 2>/dev/null | grep -E "Failed|Invalid|error" | grep "$CHECK_IP" | tail -n "$LINES" || echo "  (no failures for $CHECK_IP)"
  else
    journalctl -u sshd --no-pager -n "$LINES" 2>/dev/null | grep -E "Failed|Invalid|error" | tail -n "$LINES" || echo "  (no matches)"
  fi
else
  echo "  journalctl not available"
fi
echo ""

# --- 4. Current jail status ---
echo "--- 4. Current fail2ban jail status ---"
if command -v fail2ban-client >/dev/null 2>&1 && systemctl is-active fail2ban >/dev/null 2>&1; then
  fail2ban-client status sshd 2>/dev/null || echo "  (sshd jail not available)"
else
  echo "  fail2ban not active"
fi
echo ""
echo "=== End ==="
