#!/bin/bash
# Run as root (sudo) to test alert email delivery via Mailcow.
# Captures msmtp debug output; redacts password. Usage: sudo ./test-alert-email.sh
set -euo pipefail

RECIPIENT="${1:-milorad.stevanovic@inlock.ai}"
LOG="/tmp/msmtp-debug-$$.txt"

echo "Testing alert email to: $RECIPIENT"
echo "Running: msmtp -a default --debug $RECIPIENT"
echo ""

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root so msmtp can read /etc/msmtprc: sudo $0 $RECIPIENT"
  exit 1
fi

# Run msmtp in debug mode; capture stderr (debug goes there)
EXIT=0
echo "Test body from test-alert-email.sh" | msmtp -a default --debug "$RECIPIENT" 2> "$LOG" || EXIT=$?

if [ "$EXIT" -eq 0 ]; then
  echo "msmtp exited 0 - message may have been sent. Check inbox/spam for $RECIPIENT"
else
  echo "msmtp exited with error (code $EXIT). Debug output:"
  echo "---"
  cat "$LOG"
  echo "---"
  echo "(If you share this, redact any password lines.)"
fi

rm -f "$LOG"
exit "$EXIT"
