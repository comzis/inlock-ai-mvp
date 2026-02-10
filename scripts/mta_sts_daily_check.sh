#!/bin/bash
# Daily MTA-STS monitoring report with TLS/DNS checks.

set -euo pipefail

DOMAIN="${DOMAIN:-inlock.ai}"
MX_HOST="${MX_HOST:-mail.inlock.ai}"
DKIM_SELECTOR="${DKIM_SELECTOR:-dkim}"
RECIPIENT="${RECIPIENT:-milorad.stevanovic@inlock.ai}"
FROM_ADDR="${FROM_ADDR:-mta-sts-monitor@inlock.ai}"
SINCE="${SINCE:-24h}"
LOG_LIMIT="${LOG_LIMIT:-120}"
CURL_TIMEOUT="${CURL_TIMEOUT:-10}"
POSTFIX_CONTAINER="${POSTFIX_CONTAINER:-mailcowdockerized-postfix-mailcow-1}"
DOVECOT_CONTAINER="${DOVECOT_CONTAINER:-mailcowdockerized-dovecot-mailcow-1}"
TLS_TIMEOUT="${TLS_TIMEOUT:-5}"
SUMMARY_ISSUES_MAX="${SUMMARY_ISSUES_MAX:-10}"

NOW_UTC="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
SUBJECT="MTA-STS Daily Check ($DOMAIN) - $NOW_UTC"
REPORT_FILE="$(mktemp -t mta-sts-report.XXXXXX)"
SUMMARY_ISSUES_FILE="$(mktemp -t mta-sts-summary.XXXXXX)"

cleanup() {
  rm -f "$REPORT_FILE" "${POLICY_FILE:-}" "${POSTFIX_TMP:-}" "${DOVECOT_TMP:-}" "$SUMMARY_ISSUES_FILE" 2>/dev/null || true
}
trap cleanup EXIT

add_summary() {
  local severity="$1"  # FAIL, WARN, or empty for info
  local msg="$2"
  if [ -n "$severity" ]; then
    echo "[$severity] $msg" >> "$SUMMARY_ISSUES_FILE"
  fi
}

# Optional: short lookup (MX, A, AAAA, PTR). Empty if dig missing or lookup fails.
dig_short() {
  local qtype="$1"
  local name="$2"
  if command -v dig >/dev/null 2>&1; then
    dig +short "$qtype" "$name" 2>/dev/null | paste -sd " " - || true
  fi
}

txt_lookup() {
  local name="$1"
  if command -v dig >/dev/null 2>&1; then
    dig +short TXT "$name" 2>/dev/null | tr -d '"' | paste -sd " " - || true
    return 0
  fi
  if command -v nslookup >/dev/null 2>&1; then
    nslookup -type=TXT "$name" 2>/dev/null | awk -F'"' '/text =/ {print $2}' | paste -sd " " - || true
    return 0
  fi
  if command -v host >/dev/null 2>&1; then
    host -t txt "$name" 2>/dev/null | sed -n 's/.*descriptive text \"//;s/\"$//p' | paste -sd " " - || true
    return 0
  fi
  echo "TXT lookup tool not available"
}

send_report() {
  local report_path="$1"
  local header
  header=$(cat <<EOF
To: ${RECIPIENT}
From: ${FROM_ADDR}
Subject: ${SUBJECT}
Content-Type: text/plain; charset=UTF-8

EOF
)

  if command -v sendmail >/dev/null 2>&1; then
    { echo "$header"; cat "$report_path"; } | sendmail -t
    return 0
  fi

  if command -v mail >/dev/null 2>&1; then
    cat "$report_path" | mail -s "$SUBJECT" "$RECIPIENT"
    return 0
  fi

  if command -v mailx >/dev/null 2>&1; then
    cat "$report_path" | mailx -s "$SUBJECT" "$RECIPIENT"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    if docker ps --format '{{.Names}}' | grep -q "^${POSTFIX_CONTAINER}$"; then
      { echo "$header"; cat "$report_path"; } | docker exec -i "$POSTFIX_CONTAINER" sendmail -t
      return 0
    fi
  fi

  echo "No mailer available. Report saved to: $report_path"
  return 1
}

{
  echo "MTA-STS Daily Check Report"
  echo "=========================="
  echo "Generated: $NOW_UTC"
  echo "Domain: $DOMAIN"
  echo "MX Host: $MX_HOST"
  echo ""
} > "$REPORT_FILE"

# Policy fetch
POLICY_URL="https://mta-sts.${DOMAIN}/.well-known/mta-sts.txt"
POLICY_FILE="$(mktemp -t mta-sts-policy.XXXXXX)"
POLICY_STATUS="error"

if command -v curl >/dev/null 2>&1; then
  POLICY_STATUS="$(curl -sS -o "$POLICY_FILE" -w "%{http_code}" --max-time "$CURL_TIMEOUT" "$POLICY_URL" || echo "000")"
else
  echo "curl not available; cannot fetch policy file." >> "$REPORT_FILE"
fi

echo "Policy Check" >> "$REPORT_FILE"
echo "-----------" >> "$REPORT_FILE"
echo "URL: $POLICY_URL" >> "$REPORT_FILE"
echo "HTTP Status: $POLICY_STATUS" >> "$REPORT_FILE"
if [ "$POLICY_STATUS" = "200" ]; then
  echo "Policy Content:" >> "$REPORT_FILE"
  sed 's/^/  /' "$POLICY_FILE" >> "$REPORT_FILE"
else
  echo "Policy Content: (not available)" >> "$REPORT_FILE"
  add_summary "FAIL" "MTA-STS policy fetch failed (HTTP ${POLICY_STATUS})"
fi
echo "" >> "$REPORT_FILE"

# DNS records (deliverability)
echo "DNS Records" >> "$REPORT_FILE"
echo "-----------" >> "$REPORT_FILE"

if command -v dig >/dev/null 2>&1; then
  MX_RECORDS="$(dig_short MX "$DOMAIN")"
  echo "MX (${DOMAIN}): ${MX_RECORDS:- (none or lookup failed)}" >> "$REPORT_FILE"
  [ -z "$MX_RECORDS" ] && add_summary "WARN" "MX for ${DOMAIN} missing or empty"

  A_MAIL="$(dig_short A "$MX_HOST")"
  AAAA_MAIL="$(dig_short AAAA "$MX_HOST")"
  echo "A (${MX_HOST}): ${A_MAIL:- (none)}" >> "$REPORT_FILE"
  echo "AAAA (${MX_HOST}): ${AAAA_MAIL:- (none)}" >> "$REPORT_FILE"
  [ -z "$A_MAIL" ] && [ -z "$AAAA_MAIL" ] && add_summary "FAIL" "No A/AAAA for mail host ${MX_HOST}"

  SPF_TXT="$(txt_lookup "$DOMAIN")"
  if echo "$SPF_TXT" | grep -q "v=spf1"; then
    echo "SPF (TXT ${DOMAIN}): (present) ${SPF_TXT}" >> "$REPORT_FILE"
  else
    echo "SPF (TXT ${DOMAIN}): ${SPF_TXT:- (none or no SPF)}" >> "$REPORT_FILE"
    add_summary "WARN" "SPF (TXT on root) missing or no v=spf1"
  fi

  DKIM_TXT="$(txt_lookup "${DKIM_SELECTOR}._domainkey.${DOMAIN}")"
  echo "DKIM (${DKIM_SELECTOR}._domainkey.${DOMAIN}): ${DKIM_TXT:- (none)}" >> "$REPORT_FILE"
  [ -z "$DKIM_TXT" ] && add_summary "WARN" "DKIM (${DKIM_SELECTOR}._domainkey) missing"

  DMARC_TXT="$(txt_lookup "_dmarc.${DOMAIN}")"
  echo "DMARC (_dmarc.${DOMAIN}): ${DMARC_TXT:- (none)}" >> "$REPORT_FILE"
  [ -z "$DMARC_TXT" ] && add_summary "WARN" "DMARC (_dmarc) missing"

  # PTR for mail host's A records (one reverse lookup per IP)
  if [ -n "$A_MAIL" ]; then
    for ip in $A_MAIL; do
      PTR_RECORD="$(dig +short -x "$ip" 2>/dev/null | paste -sd " " - || true)"
      echo "PTR (${ip}): ${PTR_RECORD:- (none)}" >> "$REPORT_FILE"
      if [ -n "$PTR_RECORD" ]; then
        if ! echo "$PTR_RECORD" | grep -qi "mail\.${DOMAIN}\|mail\.inlock\.ai"; then
          add_summary "WARN" "PTR for ${ip} does not match mail.${DOMAIN} (got: ${PTR_RECORD}) (see docs/mailcow/rdns-ptr-mail-inlock-ai.md)"
        fi
      else
        add_summary "WARN" "PTR for mail host IP ${ip} missing (see docs/mailcow/rdns-ptr-mail-inlock-ai.md)"
      fi
    done
  fi

  echo "_mta-sts.${DOMAIN}: $(txt_lookup "_mta-sts.${DOMAIN}")" >> "$REPORT_FILE"
  echo "_smtp._tls.${DOMAIN}: $(txt_lookup "_smtp._tls.${DOMAIN}")" >> "$REPORT_FILE"
else
  echo "(dig not available; skipping MX/A/AAAA/PTR)" >> "$REPORT_FILE"
  SPF_TXT="$(txt_lookup "$DOMAIN")"
  echo "SPF (TXT ${DOMAIN}): ${SPF_TXT:- (none)}" >> "$REPORT_FILE"
  if [ -z "$SPF_TXT" ] || ! echo "$SPF_TXT" | grep -q "v=spf1"; then
    add_summary "WARN" "SPF (TXT on root) missing or no v=spf1"
  fi
  DKIM_TXT="$(txt_lookup "${DKIM_SELECTOR}._domainkey.${DOMAIN}")"
  echo "DKIM (${DKIM_SELECTOR}._domainkey.${DOMAIN}): ${DKIM_TXT:- (none)}" >> "$REPORT_FILE"
  [ -z "$DKIM_TXT" ] && add_summary "WARN" "DKIM (${DKIM_SELECTOR}._domainkey) missing"
  DMARC_TXT="$(txt_lookup "_dmarc.${DOMAIN}")"
  echo "DMARC (_dmarc.${DOMAIN}): ${DMARC_TXT:- (none)}" >> "$REPORT_FILE"
  [ -z "$DMARC_TXT" ] && add_summary "WARN" "DMARC (_dmarc) missing"
  echo "_mta-sts.${DOMAIN}: $(txt_lookup "_mta-sts.${DOMAIN}")" >> "$REPORT_FILE"
  echo "_smtp._tls.${DOMAIN}: $(txt_lookup "_smtp._tls.${DOMAIN}")" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# TLS section (STARTTLS 25/587, SMTPS 465, HTTPS mta-sts)
tls_check() {
  local label="$1"
  local host="$2"
  local port="$3"
  local starttls_opt="$4"  # empty, or "-starttls smtp"
  local sni="${5:-$host}"
  local out
  local verify_code
  local subject issuer notafter
  local verify_ok=0
  local expiry_ok=0

  if ! command -v openssl >/dev/null 2>&1; then
    echo "  ${label}: (openssl not available)" >> "$REPORT_FILE"
    return 0
  fi
  out="$(timeout "${TLS_TIMEOUT}" openssl s_client -connect "${host}:${port}" $starttls_opt -servername "$sni" </dev/null 2>/dev/null)" || true
  verify_code="$(echo "$out" | grep -m1 "Verify return code:" | sed 's/.*: //' || true)"
  subject="$(echo "$out" | openssl x509 -noout -subject 2>/dev/null | sed 's/^subject=//' || true)"
  issuer="$(echo "$out" | openssl x509 -noout -issuer 2>/dev/null | sed 's/^issuer=//' || true)"
  notafter="$(echo "$out" | openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=//' || true)"

  [ "$verify_code" = "0 (ok)" ] && verify_ok=1
  if [ -n "$notafter" ]; then
    expiry_epoch="$(date -d "$notafter" +%s 2>/dev/null)" || expiry_epoch=0
    now_epoch="$(date +%s)"
    [ "$expiry_epoch" -gt 0 ] && [ $(( expiry_epoch - now_epoch )) -ge $(( 14 * 86400 )) ] && expiry_ok=1
  fi

  echo "  ${label} (${host}:${port}):" >> "$REPORT_FILE"
  echo "    verify: ${verify_code:- (unable to get)}" >> "$REPORT_FILE"
  echo "    subject: ${subject:- (unable to get)}" >> "$REPORT_FILE"
  echo "    issuer: ${issuer:- (unable to get)}" >> "$REPORT_FILE"
  echo "    notAfter: ${notafter:- (unable to get)}" >> "$REPORT_FILE"

  if [ "$verify_ok" -ne 1 ]; then
    add_summary "WARN" "TLS ${label} (${host}:${port}): verify != 0 (${verify_code:-unknown})"
  fi
  if [ "$expiry_ok" -ne 1 ]; then
    if [ -n "$notafter" ]; then
      add_summary "WARN" "TLS ${label} (${host}:${port}): cert expires in < 14 days (${notafter})"
    else
      add_summary "WARN" "TLS ${label} (${host}:${port}): cert missing or unparseable (no notAfter)"
    fi
  fi
}

echo "TLS (SMTP / HTTPS)" >> "$REPORT_FILE"
echo "------------------" >> "$REPORT_FILE"
TLS_SKIP=
if ! command -v timeout >/dev/null 2>&1; then
  echo "  (timeout not installed; skipping TLS checks to avoid hangs)" >> "$REPORT_FILE"
  TLS_SKIP=1
fi
if [ -z "${TLS_SKIP}" ] && command -v openssl >/dev/null 2>&1; then
  tls_check "STARTTLS (25)" "$MX_HOST" 25 "-starttls smtp" "$MX_HOST"
  tls_check "STARTTLS (587)" "$MX_HOST" 587 "-starttls smtp" "$MX_HOST"
  tls_check "SMTPS (465)" "$MX_HOST" 465 "" "$MX_HOST"

  # HTTPS cert for mta-sts.${DOMAIN} and SANs
  MTASTS_HOST="mta-sts.${DOMAIN}"
  out="$(timeout "${TLS_TIMEOUT}" openssl s_client -connect "${MTASTS_HOST}:443" -servername "$MTASTS_HOST" </dev/null 2>/dev/null)" || true
  verify_code="$(echo "$out" | grep -m1 "Verify return code:" | sed 's/.*: //' || true)"
  subject="$(echo "$out" | openssl x509 -noout -subject 2>/dev/null | sed 's/^subject=//' || true)"
  issuer="$(echo "$out" | openssl x509 -noout -issuer 2>/dev/null | sed 's/^issuer=//' || true)"
  notafter="$(echo "$out" | openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=//' || true)"
  sans="$(echo "$out" | openssl x509 -noout -ext subjectAltName 2>/dev/null | tr '\n' ' ' | sed 's/.*[Ss]ubject [Aa]lternative [Nn]ame[^:]*:[[:space:]]*//; s/.*[Ss]ubject[Aa]lt[Nn]ame[[:space:]]*=[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
  echo "  HTTPS (${MTASTS_HOST}:443):" >> "$REPORT_FILE"
  echo "    verify: ${verify_code:- (unable to get)}" >> "$REPORT_FILE"
  echo "    subject: ${subject:- (unable to get)}" >> "$REPORT_FILE"
  echo "    issuer: ${issuer:- (unable to get)}" >> "$REPORT_FILE"
  echo "    notAfter: ${notafter:- (unable to get)}" >> "$REPORT_FILE"
  echo "    SANs: ${sans:- (unable to get)}" >> "$REPORT_FILE"
  [ "$verify_code" != "0 (ok)" ] && add_summary "WARN" "HTTPS mta-sts.${DOMAIN}: verify != 0 (${verify_code:-unknown})"
  if [ -n "$notafter" ]; then
    expiry_epoch="$(date -d "$notafter" +%s 2>/dev/null)" || expiry_epoch=0
    now_epoch="$(date +%s)"
    [ "$expiry_epoch" -gt 0 ] && [ $(( expiry_epoch - now_epoch )) -lt $(( 14 * 86400 )) ] && add_summary "WARN" "HTTPS mta-sts.${DOMAIN}: cert expires in < 14 days (${notafter})"
  fi
elif [ -z "${TLS_SKIP}" ]; then
  echo "  (openssl not available; skipping TLS checks)" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Log checks
echo "Mailcow TLS Log Check (last ${SINCE})" >> "$REPORT_FILE"
echo "-----------------------------------" >> "$REPORT_FILE"

if command -v docker >/dev/null 2>&1; then
  if docker ps --format '{{.Names}}' | grep -q "^${POSTFIX_CONTAINER}$"; then
    POSTFIX_TMP="$(mktemp -t postfix-tls.XXXXXX)"
    docker logs "$POSTFIX_CONTAINER" --since "$SINCE" 2>/dev/null | \
      grep -Ei "tls|handshake|verify|certificate|ssl" | \
      grep -Ev "unknown\\[10\\.0\\.0\\.1\\]" > "$POSTFIX_TMP" || true
    POSTFIX_COUNT="$(grep -c '.' "$POSTFIX_TMP" 2>/dev/null || true)"
    echo "Postfix (${POSTFIX_CONTAINER}) TLS-related lines: ${POSTFIX_COUNT}" >> "$REPORT_FILE"
    if [ "${POSTFIX_COUNT:-0}" -gt 0 ]; then
      echo "Recent Postfix TLS lines (last ${LOG_LIMIT}):" >> "$REPORT_FILE"
      tail -n "$LOG_LIMIT" "$POSTFIX_TMP" | sed 's/^/  /' >> "$REPORT_FILE"
    fi
  else
    echo "Postfix container not running: ${POSTFIX_CONTAINER}" >> "$REPORT_FILE"
  fi

  echo "" >> "$REPORT_FILE"

  if docker ps --format '{{.Names}}' | grep -q "^${DOVECOT_CONTAINER}$"; then
    DOVECOT_TMP="$(mktemp -t dovecot-tls.XXXXXX)"
    docker logs "$DOVECOT_CONTAINER" --since "$SINCE" 2>/dev/null | \
      grep -Ei "tls|handshake|verify|certificate|ssl" | \
      grep -Ev "unknown\\[10\\.0\\.0\\.1\\]" > "$DOVECOT_TMP" || true
    DOVECOT_COUNT="$(grep -c '.' "$DOVECOT_TMP" 2>/dev/null || true)"
    echo "Dovecot (${DOVECOT_CONTAINER}) TLS-related lines: ${DOVECOT_COUNT}" >> "$REPORT_FILE"
    if [ "${DOVECOT_COUNT:-0}" -gt 0 ]; then
      echo "Recent Dovecot TLS lines (last ${LOG_LIMIT}):" >> "$REPORT_FILE"
      tail -n "$LOG_LIMIT" "$DOVECOT_TMP" | sed 's/^/  /' >> "$REPORT_FILE"
    fi
  else
    echo "Dovecot container not running: ${DOVECOT_CONTAINER}" >> "$REPORT_FILE"
  fi
else
  echo "docker not available; cannot check Mailcow logs." >> "$REPORT_FILE"
fi

# Deliverability Alignment Test (optional)
echo "Deliverability Alignment Test (optional)" >> "$REPORT_FILE"
echo "--------------------------------------" >> "$REPORT_FILE"
if [ "${ALIGN_TEST_ENABLE:-0}" = "1" ]; then
  ALIGN_TEST_SMTP_HOST="${ALIGN_TEST_SMTP_HOST:-$MX_HOST}"
  ALIGN_TEST_SMTP_PORT="${ALIGN_TEST_SMTP_PORT:-587}"
  ALIGN_TEST_WAIT="${ALIGN_TEST_WAIT:-15}"
  ALIGN_HAVE_VARS=1
  [ -z "${ALIGN_TEST_TO:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_FROM:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_SMTP_USER:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_SMTP_PASS:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_IMAP_HOST:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_IMAP_USER:-}" ] && ALIGN_HAVE_VARS=0
  [ -z "${ALIGN_TEST_IMAP_PASS:-}" ] && ALIGN_HAVE_VARS=0
  ALIGN_HAVE_TOOLS=1
  command -v swaks >/dev/null 2>&1 || ALIGN_HAVE_TOOLS=0
  command -v python3 >/dev/null 2>&1 || ALIGN_HAVE_TOOLS=0

  if [ "$ALIGN_HAVE_VARS" -ne 1 ] || [ "$ALIGN_HAVE_TOOLS" -ne 1 ]; then
    ALIGN_MISSING=""
    command -v swaks >/dev/null 2>&1 || ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }swaks"
    command -v python3 >/dev/null 2>&1 || ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }python3"
    [ -z "${ALIGN_TEST_TO:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_TO"
    [ -z "${ALIGN_TEST_FROM:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_FROM"
    [ -z "${ALIGN_TEST_SMTP_USER:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_SMTP_USER"
    [ -z "${ALIGN_TEST_SMTP_PASS:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_SMTP_PASS"
    [ -z "${ALIGN_TEST_IMAP_HOST:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_IMAP_HOST"
    [ -z "${ALIGN_TEST_IMAP_USER:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_IMAP_USER"
    [ -z "${ALIGN_TEST_IMAP_PASS:-}" ] && ALIGN_MISSING="${ALIGN_MISSING:+$ALIGN_MISSING, }ALIGN_TEST_IMAP_PASS"
    echo "Alignment test skipped (missing: ${ALIGN_MISSING:-swaks/python3 or required env vars})" >> "$REPORT_FILE"
  else
    ALIGN_SUBJECT="Alignment test $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ALIGN_SEND_OK=0
    swaks --to "$ALIGN_TEST_TO" --from "$ALIGN_TEST_FROM" \
      --server "$ALIGN_TEST_SMTP_HOST" --port "$ALIGN_TEST_SMTP_PORT" \
      --auth-user "$ALIGN_TEST_SMTP_USER" --auth-password "$ALIGN_TEST_SMTP_PASS" \
      --header "Subject: $ALIGN_SUBJECT" --body "Alignment test message." \
      --tls 2>/dev/null && ALIGN_SEND_OK=1 || true
    if [ "$ALIGN_SEND_OK" -ne 1 ]; then
      echo "Send failed (swaks error)." >> "$REPORT_FILE"
      add_summary "WARN" "Alignment test: send failed (swaks)"
    else
      sleep "${ALIGN_TEST_WAIT}" 2>/dev/null || true
      ALIGN_RESULT="$(python3 - "$ALIGN_SUBJECT" "$ALIGN_TEST_IMAP_HOST" "$ALIGN_TEST_IMAP_USER" "$ALIGN_TEST_IMAP_PASS" <<'PYALIGN'
import imaplib
import re
import sys
def main():
    if len(sys.argv) < 5:
        print("ALIGN_DKIM=unknown\nALIGN_SPF=unknown\nALIGN_DMARC=unknown")
        return
    subject_search = sys.argv[1]
    imap_host, imap_user, imap_pass = sys.argv[2], sys.argv[3], sys.argv[4]
    dkim, spf, dmarc = "unknown", "unknown", "unknown"
    auth_header_parts = []
    try:
        m = imaplib.IMAP4_SSL(imap_host)
        m.login(imap_user, imap_pass)
        m.select("INBOX")
        _, data = m.search(None, 'SUBJECT', subject_search)
        ids = data[0].split()
        if not ids:
            print("ALIGN_DKIM=unknown\nALIGN_SPF=unknown\nALIGN_DMARC=unknown\nALIGN_AUTH_RESULTS=")
            m.logout()
            return
        _, msg_data = m.fetch(ids[-1], "(BODY.PEEK[HEADER.FIELDS (AUTHENTICATION-RESULTS)])")
        raw = msg_data[0][1].decode(errors="replace") if isinstance(msg_data[0][1], bytes) else str(msg_data[0][1])
        for line in raw.splitlines():
            if line.strip().upper().startswith("AUTHENTICATION-RESULTS"):
                line_lower = line.lower()
                auth_header_parts.append(line.strip())
                if "dkim=pass" in line_lower or "dkim= pass" in line_lower:
                    dkim = "pass"
                elif "dkim=fail" in line_lower or "dkim= fail" in line_lower:
                    dkim = "fail"
                if "spf=pass" in line_lower or "spf= pass" in line_lower:
                    spf = "pass"
                elif "spf=fail" in line_lower or "spf= fail" in line_lower:
                    spf = "fail"
                if "dmarc=pass" in line_lower or "dmarc= pass" in line_lower:
                    dmarc = "pass"
                elif "dmarc=fail" in line_lower or "dmarc= fail" in line_lower:
                    dmarc = "fail"
        m.logout()
    except Exception:
        pass
    auth_results_line = " ".join(auth_header_parts) if auth_header_parts else ""
    print("ALIGN_DKIM=%s\nALIGN_SPF=%s\nALIGN_DMARC=%s\nALIGN_AUTH_RESULTS=%s" % (dkim, spf, dmarc, auth_results_line))
main()
PYALIGN
)" 2>/dev/null || true
      ALIGN_DKIM="unknown"
      ALIGN_SPF="unknown"
      ALIGN_DMARC="unknown"
      ALIGN_AUTH_RESULTS=""
      while IFS= read -r line; do
        case "$line" in
          ALIGN_DKIM=*) ALIGN_DKIM="${line#ALIGN_DKIM=}";;
          ALIGN_SPF=*)  ALIGN_SPF="${line#ALIGN_SPF=}";;
          ALIGN_DMARC=*) ALIGN_DMARC="${line#ALIGN_DMARC=}";;
          ALIGN_AUTH_RESULTS=*) ALIGN_AUTH_RESULTS="${line#ALIGN_AUTH_RESULTS=}";;
        esac
      done <<EOF
$ALIGN_RESULT
EOF
      echo "DKIM: $ALIGN_DKIM" >> "$REPORT_FILE"
      echo "SPF: $ALIGN_SPF" >> "$REPORT_FILE"
      echo "DMARC: $ALIGN_DMARC" >> "$REPORT_FILE"
      if [ -n "$ALIGN_AUTH_RESULTS" ]; then
        echo "Authentication-Results (receiver): $ALIGN_AUTH_RESULTS" >> "$REPORT_FILE"
      fi
      [ "$ALIGN_DKIM" != "pass" ] && add_summary "WARN" "Alignment test DKIM: $ALIGN_DKIM"
      [ "$ALIGN_SPF" != "pass" ] && add_summary "WARN" "Alignment test SPF: $ALIGN_SPF"
      [ "$ALIGN_DMARC" != "pass" ] && add_summary "WARN" "Alignment test DMARC: $ALIGN_DMARC"
    fi
  fi
else
  echo "Not run (ALIGN_TEST_ENABLE not set)." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Summary block
echo "" >> "$REPORT_FILE"
echo "Summary" >> "$REPORT_FILE"
echo "-------" >> "$REPORT_FILE"
fail_count="$(grep -c '^\[FAIL\]' "$SUMMARY_ISSUES_FILE" 2>/dev/null || echo 0)"
warn_count="$(grep -c '^\[WARN\]' "$SUMMARY_ISSUES_FILE" 2>/dev/null || echo 0)"
fail_count="${fail_count//[^0-9]/}"
warn_count="${warn_count//[^0-9]/}"
fail_count="${fail_count:-0}"
warn_count="${warn_count:-0}"
if [ "${fail_count}" -gt 0 ]; then
  echo "Result: FAIL" >> "$REPORT_FILE"
elif [ "${warn_count}" -gt 0 ]; then
  echo "Result: WARN" >> "$REPORT_FILE"
else
  echo "Result: PASS" >> "$REPORT_FILE"
fi
if [ -s "$SUMMARY_ISSUES_FILE" ]; then
  echo "Top issues:" >> "$REPORT_FILE"
  head -n "${SUMMARY_ISSUES_MAX}" "$SUMMARY_ISSUES_FILE" | sed 's/^/  /' >> "$REPORT_FILE"
else
  echo "No issues recorded." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"
echo "End of report." >> "$REPORT_FILE"

send_report "$REPORT_FILE"
