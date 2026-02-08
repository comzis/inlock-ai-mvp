#!/bin/bash
# CPU / load check: logs to syslog and optionally emails when host load exceeds threshold.
# Uses alert.sh; set ALERT_EMAIL (e.g. milorad.stevanovic@inlock.ai) for email.
# Cron: see cron.cpu-alert (e.g. every 5 min with ALERT_EMAIL set).
#
# Persistence (reduce noise): by default only alerts when load is sustained, not a brief spike.
#   CPU_LOAD_PERSISTENCE=5m  (default) — require 5m average also above threshold
#   CPU_LOAD_PERSISTENCE=15m — require 15m average also above threshold (stricter)
#   CPU_LOAD_PERSISTENCE=1m  — legacy: alert on 1m only (no persistence check)
#
# Usage:
#   ./cpu-alert-check.sh           # normal: only emails when load sustained above threshold
#   ./cpu-alert-check.sh --test     # send one test email (verify delivery)
set -euo pipefail

TAG="cpu-alert"
# Per-core load threshold (alert when load > nproc * this). 0.85 ≈ 85% CPU.
CPU_LOAD_THRESHOLD="${CPU_LOAD_THRESHOLD:-0.85}"
# Persistence: require this average to also exceed threshold (reduces noise from brief spikes).
#   "5m" = require load5 > threshold (sustained ~5 min)
#   "15m" = require load15 > threshold (sustained ~15 min)
#   "" or "1m" = legacy: alert on load1 only (no persistence check)
CPU_LOAD_PERSISTENCE="${CPU_LOAD_PERSISTENCE:-5m}"
# Min minutes between email alerts (avoid flood)
COOLDOWN_MINUTES="${COOLDOWN_MINUTES:-60}"
COOLDOWN_FILE="${COOLDOWN_FILE:-/tmp/cpu-alert-cooldown.$(hostname -s 2>/dev/null || echo 'localhost')}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SH="${ALERT_SH:-$SCRIPT_DIR/alert.sh}"

# Number of cores (nproc or fallback)
get_cores() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  else
    grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1
  fi
}

CORES=$(get_cores)
read -r LOAD1 LOAD5 LOAD15 _ _ </proc/loadavg 2>/dev/null || { logger -t "$TAG" "cannot read /proc/loadavg"; exit 1; }
THRESHOLD=$(awk "BEGIN {printf \"%.2f\", $CORES * $CPU_LOAD_THRESHOLD}")

# --test: send one email regardless of load (to verify ALERT_EMAIL delivery)
if [ "${1:-}" = "--test" ]; then
  SUBJECT="[TEST] CPU alert – delivery check"
  MESSAGE="This is a test of the CPU alert email.

Host: $(hostname -f 2>/dev/null || hostname)
Load average: 1m=$LOAD1 5m=$LOAD5 15m=$LOAD15
Cores: $CORES | Threshold (load1): $THRESHOLD
Time: $(date -Is 2>/dev/null || date)

If you receive this, alert delivery to ALERT_EMAIL is working.
Normal runs only send when load exceeds the threshold."
  if [ -z "${ALERT_EMAIL:-}" ]; then
    echo "ALERT_EMAIL not set. Example: ALERT_EMAIL=milorad.stevanovic@inlock.ai $0 --test" >&2
    exit 2
  fi
  if [ -x "$ALERT_SH" ]; then
    ALERT_SEVERITY=info "$ALERT_SH" "$SUBJECT" "$MESSAGE" || true
    echo "Test email sent to $ALERT_EMAIL (check inbox and spam)."
  else
    echo "alert.sh not executable: $ALERT_SH" >&2
    exit 2
  fi
  exit 0
fi

logger -t "$TAG" "load1=$LOAD1 load5=$LOAD5 load15=$LOAD15 cores=$CORES threshold=$THRESHOLD persistence=$CPU_LOAD_PERSISTENCE"

# Require load1 over threshold
OVER1=$(awk "BEGIN {print ($LOAD1 > $THRESHOLD) ? 1 : 0}")
if [ "$OVER1" -eq 0 ]; then
  rm -f "$COOLDOWN_FILE"
  exit 0
fi

# Persistence: only alert if a longer average is also over threshold (avoids brief spikes)
case "${CPU_LOAD_PERSISTENCE}" in
  5m)
    OVER_PERSIST=$(awk "BEGIN {print ($LOAD5 > $THRESHOLD) ? 1 : 0}")
    ;;
  15m)
    OVER_PERSIST=$(awk "BEGIN {print ($LOAD15 > $THRESHOLD) ? 1 : 0}")
    ;;
  1m|""|none)
    OVER_PERSIST=1
    ;;
  *)
    OVER_PERSIST=1
    ;;
esac
if [ "$OVER_PERSIST" -eq 0 ]; then
  logger -t "$TAG" "load1 high but ${CPU_LOAD_PERSISTENCE} not sustained (load5=$LOAD5 load15=$LOAD15); skipping alert"
  exit 0
fi

logger -t "$TAG" "WARN: host load high (persistent) load1=$LOAD1 load5=$LOAD5 load15=$LOAD15 threshold=$THRESHOLD (${CPU_LOAD_THRESHOLD} per core)"

# Cooldown: skip sending if we sent recently
if [ -f "$COOLDOWN_FILE" ]; then
  MTIME=$(stat -c %Y "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [ "$(( NOW - MTIME ))" -lt "$(( COOLDOWN_MINUTES * 60 ))" ]; then
    logger -t "$TAG" "skipping alert (cooldown until $(( MTIME + COOLDOWN_MINUTES * 60 ))s)"
    exit 0
  fi
fi

SUBJECT="Host CPU / load high"
MESSAGE="Host: $(hostname -f 2>/dev/null || hostname)
Load average: 1m=$LOAD1 5m=$LOAD5 15m=$LOAD15
Cores: $CORES | Threshold (load1): $THRESHOLD (${CPU_LOAD_THRESHOLD} per core)
Time: $(date -Is 2>/dev/null || date)"

if [ -x "$ALERT_SH" ]; then
  ALERT_SEVERITY=warning "$ALERT_SH" "$SUBJECT" "$MESSAGE" || true
  touch "$COOLDOWN_FILE"
fi

exit 0
