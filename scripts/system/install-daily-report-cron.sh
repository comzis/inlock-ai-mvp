#!/usr/bin/env bash
# Install cron for daily status report email. Run once on the host (e.g. vmi2953354).
# Prereqs: REPORT_SMTP_USER and REPORT_SMTP_PASS set (or REPORT_ENV_FILE pointing to a file that exports them).
# Usage: ./install-daily-report-cron.sh [--hour 6] [--user comzis]

set -e

REPO="${REPO:-/home/comzis/.cursor/projects/home-comzis-inlock}"
SCRIPT="$REPO/scripts/daily-status-report.sh"
LOG_DIR="${LOG_DIR:-/home/comzis/logs}"
CRON_HOUR=6
CRON_USER="comzis"
ENV_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hour)   CRON_HOUR="$2"; shift 2 ;;
    --user)   CRON_USER="$2"; shift 2 ;;
    --env)    ENV_FILE="$2";  shift 2 ;;
    *)        shift ;;
  esac
done

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT not found or not executable." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

# Cron line: script reads REPORT_ENV_FILE and sources it for SMTP creds
DEFAULT_ENV="$REPO/config/daily-report.env"
ENV_TO_USE="${ENV_FILE:-$DEFAULT_ENV}"
CRON_LINE="0 ${CRON_HOUR} * * * REPORT_ENV_FILE=\"$ENV_TO_USE\" \"$SCRIPT\" >> \"${LOG_DIR}/daily-status-report-cron.log\" 2>&1"

echo "Add this line to crontab for user $CRON_USER (crontab -e -u $CRON_USER or crontab -e):"
echo ""
echo "$CRON_LINE"
echo ""
echo "Before enabling cron: create $DEFAULT_ENV (or path passed to --env) with:"
echo "  REPORT_SMTP_USER=contact@inlock.ai"
echo "  REPORT_SMTP_PASS=your-smtp-password"
echo "Copy from scripts/daily-status-report.env.example. chmod 600 the env file."
echo "Recipient: milorad.stevanovic@inlock.ai (override with REPORT_TO)."
