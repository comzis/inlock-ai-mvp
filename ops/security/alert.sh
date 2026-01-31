#!/bin/bash
# Lightweight alert helper for cron/security scripts.
#
# Usage:
#   ./alert.sh "<subject>" "<message>"
#
# Optional env:
#   ALERT_SYSLOG_TAG   (default: security-alert)
#   ALERT_SEVERITY     (default: warning)
#   ALERT_EMAIL        (e.g. milorad.stevanovic@inlock.ai) - uses `msmtp` (Mailcow) then `mail`/`sendmail`
#   ALERT_WEBHOOK_URL  (e.g. http://n8n:5678/webhook/security-alert) - JSON POST if `curl` available
set -euo pipefail

SUBJECT="${1:-}"
MESSAGE="${2:-}"

if [ -z "$SUBJECT" ] || [ -z "$MESSAGE" ]; then
  echo "usage: $0 \"<subject>\" \"<message>\"" >&2
  exit 2
fi

TAG="${ALERT_SYSLOG_TAG:-security-alert}"
SEVERITY="${ALERT_SEVERITY:-warning}"
HOST="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown-host)"
TS="$(date -Is 2>/dev/null || date)"

log() {
  logger -t "$TAG" "$1" 2>/dev/null || true
}

json_escape() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY' "$1"
import json, sys
print(json.dumps(sys.argv[1])[1:-1])
PY
    return 0
  fi
  # Best-effort escaping (quotes, backslashes, newlines).
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

log "severity=$SEVERITY subject=$(printf '%s' "$SUBJECT" | tr '\n' ' ')"

# Webhook (best-effort)
if [ -n "${ALERT_WEBHOOK_URL:-}" ] && command -v curl >/dev/null 2>&1; then
  subj_esc="$(json_escape "$SUBJECT")"
  msg_esc="$(json_escape "$MESSAGE")"
  host_esc="$(json_escape "$HOST")"
  ts_esc="$(json_escape "$TS")"
  sev_esc="$(json_escape "$SEVERITY")"

  payload="{\"severity\":\"$sev_esc\",\"host\":\"$host_esc\",\"timestamp\":\"$ts_esc\",\"subject\":\"$subj_esc\",\"message\":\"$msg_esc\"}"
  if ! curl -fsS -m 10 -H "Content-Type: application/json" -d "$payload" "$ALERT_WEBHOOK_URL" >/dev/null 2>&1; then
    log "WARN: webhook delivery failed url=$ALERT_WEBHOOK_URL"
  fi
fi

# Email (best-effort): prefer msmtp (same path as test-alert-email.sh / Mailcow)
if [ -n "${ALERT_EMAIL:-}" ]; then
  SEND_SUBJECT="[$SEVERITY] $SUBJECT"
  if command -v msmtp >/dev/null 2>&1; then
    # Use msmtp so delivery goes via Mailcow like test-alert-email.sh (needs /etc/msmtprc, often root)
    if printf 'To: %s\nSubject: %s\n\n%s\n' "$ALERT_EMAIL" "$SEND_SUBJECT" "$MESSAGE" | msmtp -t -a default >/dev/null 2>&1; then
      : # sent
    else
      log "WARN: msmtp delivery failed to=$ALERT_EMAIL (check /etc/msmtprc and run as root?)"
    fi
  elif command -v mail >/dev/null 2>&1; then
    if ! printf '%s\n' "$MESSAGE" | mail -s "$SEND_SUBJECT" "$ALERT_EMAIL" >/dev/null 2>&1; then
      log "WARN: mail delivery failed to=$ALERT_EMAIL via=mail"
    fi
  elif command -v sendmail >/dev/null 2>&1; then
    if ! sendmail -t >/dev/null 2>&1 <<EOF
To: $ALERT_EMAIL
Subject: $SEND_SUBJECT

$MESSAGE
EOF
    then
      log "WARN: mail delivery failed to=$ALERT_EMAIL via=sendmail"
    fi
  else
    log "WARN: ALERT_EMAIL set but no mailer (msmtp/mail/sendmail) available"
  fi
fi

exit 0
