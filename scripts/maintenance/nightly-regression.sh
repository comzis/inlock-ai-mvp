#!/bin/bash
# Wrapper that runs the Inlock AI regression suite for cron/automation.
# Writes a timestamped log and exits non-zero if any step fails.

set -euo pipefail

APP_DIR="/opt/inlock-ai-secure-mvp"
LOG_DIR="/home/comzis/logs"
LOCK_FILE="/tmp/inlock-nightly-regression.lock"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
LOG_FILE="$LOG_DIR/nightly-regression.log"

mkdir -p "$LOG_DIR"

{
  echo "[$TIMESTAMP] ========================================="
  echo "[$TIMESTAMP] Nightly regression run starting"
  if [ ! -d "$APP_DIR" ]; then
    echo "[$TIMESTAMP] ERROR: Application directory $APP_DIR missing"
    exit 1
  fi

  cd "$APP_DIR"
  if ./scripts/regression-check.sh; then
    echo "[$TIMESTAMP] ✅ Regression suite passed"
  else
    STATUS=$?
    echo "[$TIMESTAMP] ❌ Regression suite failed with exit code $STATUS"
    exit $STATUS
  fi
} 200>"$LOCK_FILE" >>"$LOG_FILE" 2>&1
