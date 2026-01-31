#!/usr/bin/env bash
# Send alignment test email via swaks (for manual DKIM/SPF/DMARC check).
# Run on server: ./scripts/send_align_test_email.sh
# You'll be prompted for: external recipient (e.g. you@gmail.com), then SMTP password (hidden).

set -euo pipefail

echo "External recipient (e.g. you@gmail.com):"
read -r EXT_TO
echo "SMTP password for contact@inlock.ai (hidden):"
read -s SMTP_PASS
echo

swaks --to "$EXT_TO" --from "contact@inlock.ai" \
  --server mail.inlock.ai --port 587 \
  --auth-user "contact@inlock.ai" --auth-password "$SMTP_PASS" \
  --header "Subject: Alignment test $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --body "Alignment test message." --tls
