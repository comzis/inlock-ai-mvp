#!/bin/bash
# Daily security summary: fail2ban sshd status and optional netfilter ban count.
# Logs one-line summary to syslog. Optional: alert if thresholds exceeded.
set -euo pipefail

TAG="security-summary"
BAN_THRESHOLD="${BAN_THRESHOLD:-10}"
NETFILTER_BAN_THRESHOLD="${NETFILTER_BAN_THRESHOLD:-25}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SH="${ALERT_SH:-$SCRIPT_DIR/alert.sh}"

alert_warn() {
  local subject="$1"
  local message="$2"
  if [ -x "$ALERT_SH" ]; then
    ALERT_SEVERITY=warning "$ALERT_SH" "$subject" "$message" || true
  fi
}

# fail2ban sshd status (read-only)
if command -v fail2ban-client >/dev/null 2>&1; then
  if fail2ban-client status sshd >/dev/null 2>&1; then
    BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned:" | sed -n 's/.*: *//p' || echo "?")
    TOTAL=$(fail2ban-client status sshd 2>/dev/null | grep "Total banned:" | sed -n 's/.*: *//p' || echo "?")
    logger -t "$TAG" "fail2ban sshd: currently_banned=$BANNED total_banned=$TOTAL"
    # Optional: alert if currently banned exceeds threshold
    if [ -n "$BANNED" ] && [ "$BANNED" != "?" ] && [ "$BANNED" -ge "$BAN_THRESHOLD" ] 2>/dev/null; then
      logger -t "$TAG" "WARN: fail2ban sshd currently banned ($BANNED) >= threshold ($BAN_THRESHOLD)"
      alert_warn "fail2ban sshd bans high" "Currently banned=$BANNED (threshold=$BAN_THRESHOLD). Total banned=$TOTAL."
    fi
  else
    logger -t "$TAG" "fail2ban sshd: jail not active"
    alert_warn "fail2ban sshd jail inactive" "fail2ban is installed but the sshd jail is not active."
  fi
else
  logger -t "$TAG" "fail2ban: not installed"
  alert_warn "fail2ban missing" "fail2ban-client not found; SSH brute force protection may be reduced."
fi

# Optional: netfilter ban count from Mailcow (if docker and container exist)
if command -v docker >/dev/null 2>&1; then
  NF_CONTAINER="mailcowdockerized-netfilter-mailcow-1"
  if docker ps -q -f name="$NF_CONTAINER" 2>/dev/null | grep -q .; then
    BAN_COUNT=$(docker logs --since 24h "$NF_CONTAINER" 2>/dev/null | grep -c "CRIT.*ban" || true)
    logger -t "$TAG" "netfilter mailcow: ban_events(recent)=${BAN_COUNT:-0}"
    if [ -n "${BAN_COUNT:-}" ] && [ "${BAN_COUNT:-0}" -ge "$NETFILTER_BAN_THRESHOLD" ] 2>/dev/null; then
      logger -t "$TAG" "WARN: netfilter ban events in last 24h ($BAN_COUNT) >= threshold ($NETFILTER_BAN_THRESHOLD)"
      alert_warn "mailcow netfilter bans high" "Ban events in last 24h=$BAN_COUNT (threshold=$NETFILTER_BAN_THRESHOLD)."
    fi
  fi
fi

exit 0
