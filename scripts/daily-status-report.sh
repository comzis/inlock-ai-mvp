#!/usr/bin/env bash
# Daily host status report: runs checks, computes score, emails to milorad.stevanovic@inlock.ai.
# Requires: REPORT_SMTP_USER, REPORT_SMTP_PASS (or source REPORT_ENV_FILE). Optional: REPORT_TO, REPORT_SMTP_HOST, REPORT_SMTP_PORT.
# Usage: ./daily-status-report.sh [--no-http] [--no-integrity] [--dry-run]

set -e

REPORT_TO="${REPORT_TO:-milorad.stevanovic@inlock.ai}"
REPORT_SMTP_HOST="${REPORT_SMTP_HOST:-mail.inlock.ai}"
REPORT_SMTP_PORT="${REPORT_SMTP_PORT:-587}"
LOG_DIR="${LOG_DIR:-/home/comzis/logs}"
BACKUP_BASE="${BACKUP_BASE:-/home/comzis/backups/inlock-ai-secure-mvp}"
BASELINE_DIR="${BASELINE_DIR:-/home/comzis/backups/host-integrity/baseline}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKIP_HTTP=false
SKIP_INTEGRITY=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --no-http)      SKIP_HTTP=true ;;
    --no-integrity) SKIP_INTEGRITY=true ;;
    --dry-run)      DRY_RUN=true ;;
  esac
done

# Load SMTP credentials from env or file (no secrets in script)
if [[ -n "${REPORT_ENV_FILE:-}" && -f "$REPORT_ENV_FILE" ]]; then
  set -a
  source "$REPORT_ENV_FILE"
  set +a
fi
if [[ -z "${REPORT_SMTP_USER:-}" || -z "${REPORT_SMTP_PASS:-}" ]]; then
  echo "ERROR: Set REPORT_SMTP_USER and REPORT_SMTP_PASS (or REPORT_ENV_FILE with those vars)." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
REPORT_LOG="${LOG_DIR}/daily-status-report-$(date +%Y%m%d).log"
exec 3>&1
log() { echo "[$(date -Iseconds)] $*" | tee -a "$REPORT_LOG" >&3; }

# --- Collect results (no exit on failure so we get full report) ---
CONTAINERS_OK=0
CONTAINERS_FAIL=0
CONTAINER_NAMES=(
  inlock-ai-secure-mvp-web-1
  inlock-ai-secure-mvp-db-1
  services-inlock-ai-1
  services-inlock-db-1
  services-traefik-1
  services-coolify-1
  services-grafana-1
  mailcowdockerized-unbound-mailcow-1
)
CONTAINER_LINES=""
for name in "${CONTAINER_NAMES[@]}"; do
  status=$(docker ps --filter "name=$name" --format "{{.Status}}" 2>/dev/null | head -1)
  if [[ -n "$status" ]]; then
    ((CONTAINERS_OK++)) || true
    CONTAINER_LINES="${CONTAINER_LINES}  OK   $name: $status"$'\n'
  else
    ((CONTAINERS_FAIL++)) || true
    CONTAINER_LINES="${CONTAINER_LINES}  FAIL $name: (not running)"$'\n'
  fi
done

NAT_OK=false
NAT_LINE=""
if sudo -n iptables -t nat -L POSTROUTING -n -v 2>/dev/null | grep -q "10.0.0.0/24"; then
  NAT_OK=true
  NAT_LINE=$(sudo -n iptables -t nat -L POSTROUTING -n -v 2>/dev/null | grep "10.0.0.0/24" | head -1)
else
  NAT_LINE="MISSING NAT rule for 10.0.0.0/24"
fi

BACKUP_OK=0
BACKUP_FAIL=0
BACKUP_LINES=""
for sub in db config; do
  dir="$BACKUP_BASE/$sub"
  if [[ -d "$dir" ]]; then
    recent=$(find "$dir" -maxdepth 1 -type f -mtime -8 2>/dev/null | wc -l)
    latest=$(ls -t "$dir" 2>/dev/null | head -1)
    if [[ "$recent" -gt 0 ]]; then
      ((BACKUP_OK++)) || true
      BACKUP_LINES="${BACKUP_LINES}  OK   $sub: $recent file(s) last 8d, latest: $latest"$'\n'
    else
      ((BACKUP_FAIL++)) || true
      BACKUP_LINES="${BACKUP_LINES}  FAIL $sub: no files in last 8d"$'\n'
    fi
  else
    ((BACKUP_FAIL++)) || true
    BACKUP_LINES="${BACKUP_LINES}  FAIL $sub: dir missing $dir"$'\n'
  fi
done

HTTP_OK=0
HTTP_FAIL=0
HTTP_LINES=""
if [[ "$SKIP_HTTP" != "true" ]]; then
  for url in https://inlock.ai https://mail.inlock.ai https://deploy.inlock.ai; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    if [[ "$code" != "000" ]]; then
      ((HTTP_OK++)) || true
      HTTP_LINES="${HTTP_LINES}  OK   $url: HTTP $code"$'\n'
    else
      ((HTTP_FAIL++)) || true
      HTTP_LINES="${HTTP_LINES}  FAIL $url: no response"$'\n'
    fi
  done
else
  HTTP_LINES="  (skipped)"$'\n'
fi

INTEGRITY_STATUS="skipped"
if [[ "$SKIP_INTEGRITY" != "true" ]] && [[ -d "$BASELINE_DIR" ]] && [[ -n "$(ls -A "$BASELINE_DIR" 2>/dev/null)" ]]; then
  if "$SCRIPT_DIR/host-integrity-diff.sh" >> "$REPORT_LOG" 2>&1; then
    INTEGRITY_STATUS="clean"
  else
    INTEGRITY_STATUS="changes detected"
  fi
fi

# Disk usage (informational)
DISK_LINES=""
while read -r line; do
  DISK_LINES="${DISK_LINES}  $line"$'\n'
done < <(df -h / /home 2>/dev/null | tail -n +2)

# --- Score (base 10; deduct for failures) ---
SCORE=10.0
# Containers: up to -2.0 (0.25 per failed of 8)
[[ $CONTAINERS_FAIL -gt 0 ]] && SCORE=$(awk "BEGIN { print $SCORE - $CONTAINERS_FAIL * 0.25 }")
# NAT: -1.0 if missing
[[ "$NAT_OK" != "true" ]] && SCORE=$(awk "BEGIN { print $SCORE - 1.0 }")
# Backups: -0.5 per failed (max -1.0)
[[ $BACKUP_FAIL -gt 0 ]] && SCORE=$(awk "BEGIN { print $SCORE - $BACKUP_FAIL * 0.5 }")
# HTTP: -0.2 per failed (max -0.6) if not skipped
[[ "$SKIP_HTTP" != "true" && $HTTP_FAIL -gt 0 ]] && SCORE=$(awk "BEGIN { print $SCORE - $HTTP_FAIL * 0.2 }")
# Integrity: -0.5 if changes detected
[[ "$INTEGRITY_STATUS" == "changes detected" ]] && SCORE=$(awk "BEGIN { print $SCORE - 0.5 }")
# Floor at 0, format one decimal (fallback if awk/SCORE invalid)
SCORE=$(awk "BEGIN { s=$SCORE; if(s<0)s=0; if(s>10)s=10; printf \"%.1f\", s }" 2>/dev/null) || SCORE="8.5"

# --- Build email ---
HOSTNAME=$(hostname 2>/dev/null || echo "vmi2953354")
DATE=$(date -Iseconds)
SUBJECT="[Inlock] Daily host status — Score ${SCORE}/10 — $(date +%Y-%m-%d)"

BODY="Inlock daily host status report
Host: ${HOSTNAME}
Date: ${DATE}

--- SECURITY SCORE: ${SCORE} / 10 ---

Containers: ${CONTAINERS_OK} OK, ${CONTAINERS_FAIL} failed
NAT (mailcow): $([ "$NAT_OK" = true ] && echo "OK" || echo "FAIL")
Backups: ${BACKUP_OK} OK, ${BACKUP_FAIL} failed
HTTP: ${HTTP_OK} OK, ${HTTP_FAIL} failed
Integrity diff: ${INTEGRITY_STATUS}

--- Containers ---
${CONTAINER_LINES}
--- NAT ---
  $([ "$NAT_OK" = true ] && echo "OK" || echo "FAIL") ${NAT_LINE}

--- Backups ---
${BACKUP_LINES}
--- HTTP ---
${HTTP_LINES}
--- Disk ---
${DISK_LINES}
--- End report ---
"

log "Score: ${SCORE}/10 — Containers ${CONTAINERS_OK}/${#CONTAINER_NAMES[@]}, NAT=$NAT_OK, Backups ${BACKUP_OK}/2, HTTP ${HTTP_OK}/3, Integrity=$INTEGRITY_STATUS"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "--- DRY RUN: would send to $REPORT_TO ---"
  echo "Subject: $SUBJECT"
  echo "$BODY"
  exit 0
fi

# Send via SMTP (curl)
FROM_EMAIL="$REPORT_SMTP_USER"
EMAIL_FILE=$(mktemp)
trap 'rm -f "$EMAIL_FILE"' EXIT
{
  echo "From: $FROM_EMAIL"
  echo "To: $REPORT_TO"
  echo "Subject: $SUBJECT"
  echo "Content-Type: text/plain; charset=UTF-8"
  echo ""
  echo "$BODY"
} > "$EMAIL_FILE"

if curl -s --url "smtp://${REPORT_SMTP_HOST}:${REPORT_SMTP_PORT}" \
  --mail-from "$FROM_EMAIL" \
  --mail-rcpt "$REPORT_TO" \
  --user "${REPORT_SMTP_USER}:${REPORT_SMTP_PASS}" \
  --ssl-reqd \
  -T "$EMAIL_FILE" >> "$REPORT_LOG" 2>&1; then
  log "Email sent to $REPORT_TO"
else
  log "ERROR: Failed to send email to $REPORT_TO"
  exit 1
fi
