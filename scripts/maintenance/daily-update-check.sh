#!/bin/bash
# =============================================================================
# Daily Maintenance Check — detect-only, no changes
# =============================================================================
# Checks OS security updates and container image staleness.
# Writes a report to $REPORT_DIR and optionally alerts via ops/security/alert.sh.
#
# Usage:
#   ./daily-update-check.sh              # full check + report
#   ./daily-update-check.sh --quiet      # suppress stdout (cron-friendly)
#
# Outputs:
#   /home/comzis/logs/maintenance/check-YYYY-MM-DD.md
#
# Cron:  0 6 * * * /home/comzis/inlock/scripts/maintenance/daily-update-check.sh --quiet
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="/home/comzis/logs/maintenance"
DATE="$(date +%Y-%m-%d)"
REPORT_FILE="$REPORT_DIR/check-$DATE.md"
QUIET=false
ALERT_SCRIPT="$REPO_ROOT/ops/security/alert.sh"

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
  esac
done

mkdir -p "$REPORT_DIR"

log() {
  if [ "$QUIET" = false ]; then
    echo "$1"
  fi
}

# =============================================================================
# Collect data
# =============================================================================

log "Checking OS security updates..."
APT_UPGRADABLE="$(apt list --upgradable 2>/dev/null | grep -v '^Listing' || true)"
APT_SECURITY="$(echo "$APT_UPGRADABLE" | grep -i security || true)"
APT_TOTAL=0
APT_SEC_COUNT=0
if [ -n "$APT_UPGRADABLE" ]; then
  APT_TOTAL="$(echo "$APT_UPGRADABLE" | grep -c '/' 2>/dev/null || true)"
  APT_TOTAL="${APT_TOTAL:-0}"
fi
if [ -n "$APT_SECURITY" ]; then
  APT_SEC_COUNT="$(echo "$APT_SECURITY" | grep -c '/' 2>/dev/null || true)"
  APT_SEC_COUNT="${APT_SEC_COUNT:-0}"
fi

log "Checking container image ages..."
COMPOSE_STACK="$REPO_ROOT/compose/services/stack.yml"
COMPOSE_LOGGING="$REPO_ROOT/compose/config/monitoring/logging.yml"
ENV_FILE="$REPO_ROOT/.env"

# Collect running image info
IMAGE_REPORT=""
STALE_COUNT=0

while IFS= read -r line; do
  name="$(echo "$line" | awk '{print $1}')"
  image="$(echo "$line" | awk '{print $2}')"
  created="$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')"

  # Flag images older than 12 months
  days_approx=""
  if echo "$created" | grep -qE "[0-9]+ years?"; then
    STALE_COUNT=$((STALE_COUNT + 1))
    days_approx="**STALE**"
  elif echo "$created" | grep -qE "(1[2-9]|[2-9][0-9]) months"; then
    STALE_COUNT=$((STALE_COUNT + 1))
    days_approx="**AGING**"
  fi

  IMAGE_REPORT="$IMAGE_REPORT
| $name | $image | $created | $days_approx |"
done < <(docker ps --format '{{.Names}} {{.Image}} {{.RunningFor}}' | sort)

log "Checking container health..."
UNHEALTHY="$(docker ps --filter health=unhealthy --format '{{.Names}} {{.Status}}' 2>/dev/null || true)"
UNHEALTHY_COUNT=0
if [ -n "$UNHEALTHY" ]; then
  UNHEALTHY_COUNT="$(echo "$UNHEALTHY" | wc -l)"
fi

log "Checking system state..."
LOAD="$(uptime | awk -F'load average:' '{print $2}' | xargs)"
MEM_AVAIL="$(free -h | awk '/^Mem:/ {print $7}')"
DISK_USE="$(df -h / | awk 'NR==2 {print $5}')"
CONTAINER_COUNT="$(docker ps -q | wc -l)"

# TLS cert check
TLS_REPORT=""
TLS_WARNING=0
for domain in inlock.ai mail.inlock.ai traefik.inlock.ai grafana.inlock.ai n8n.inlock.ai portainer.inlock.ai; do
  expiry="$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "FAILED")"
  days_left=""
  if [ "$expiry" != "FAILED" ] && [ -n "$expiry" ]; then
    exp_epoch="$(date -d "$expiry" +%s 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    if [ "$exp_epoch" -gt 0 ] 2>/dev/null; then
      days_left="$(( (exp_epoch - now_epoch) / 86400 ))"
      if [ "$days_left" -lt 30 ] 2>/dev/null; then
        TLS_WARNING=$((TLS_WARNING + 1))
        days_left="${days_left}d **EXPIRING SOON**"
      else
        days_left="${days_left}d"
      fi
    fi
  fi
  TLS_REPORT="$TLS_REPORT
| $domain | $expiry | $days_left |"
done

# =============================================================================
# Generate report
# =============================================================================

NEEDS_ATTENTION=false
if [ "${APT_SEC_COUNT:-0}" -gt 0 ] 2>/dev/null || [ "${STALE_COUNT:-0}" -gt 0 ] 2>/dev/null || [ "${UNHEALTHY_COUNT:-0}" -gt 0 ] 2>/dev/null || [ "${TLS_WARNING:-0}" -gt 0 ] 2>/dev/null; then
  NEEDS_ATTENTION=true
fi

cat > "$REPORT_FILE" <<REPORT
# Daily Maintenance Check — $DATE

Generated: $(date -Is)
Host: $(hostname -f 2>/dev/null || hostname)

## Summary

| Metric | Value |
|--------|-------|
| OS packages upgradable | $APT_TOTAL |
| OS security updates | $APT_SEC_COUNT |
| Stale/aging images (>12mo) | $STALE_COUNT |
| Unhealthy containers | $UNHEALTHY_COUNT |
| TLS certs expiring <30d | $TLS_WARNING |
| Load average | $LOAD |
| Available RAM | $MEM_AVAIL |
| Disk usage | $DISK_USE |
| Running containers | $CONTAINER_COUNT |

**Action needed:** $([ "$NEEDS_ATTENTION" = true ] && echo "YES" || echo "No — all clear")

## OS Security Updates

$(if [ "$APT_SEC_COUNT" -gt 0 ]; then
  echo "**$APT_SEC_COUNT security package(s) pending:**"
  echo ""
  echo '```'
  echo "$APT_SECURITY"
  echo '```'
else
  echo "No pending security updates."
fi)

$(if [ "$APT_TOTAL" -gt 0 ] && [ "$APT_SEC_COUNT" -ne "$APT_TOTAL" ]; then
  echo "Other upgradable packages: $((APT_TOTAL - APT_SEC_COUNT))"
fi)

## Container Images

| Container | Image | Running For | Status |
|-----------|-------|-------------|--------|$IMAGE_REPORT

$(if [ "$UNHEALTHY_COUNT" -gt 0 ]; then
  echo "### Unhealthy Containers"
  echo ""
  echo '```'
  echo "$UNHEALTHY"
  echo '```'
fi)

## TLS Certificates

| Domain | Expires | Days Left |
|--------|---------|-----------|$TLS_REPORT

## Recommended Actions

$(if [ "$APT_SEC_COUNT" -gt 0 ]; then
  echo "- [ ] Apply OS security updates: \`sudo apt upgrade\` or \`sudo ./scripts/maintenance/update-libexpat1.sh\`"
fi)
$(if [ "$STALE_COUNT" -gt 0 ]; then
  echo "- [ ] Review stale container images — update pins in compose files"
  echo "- [ ] Schedule maintenance window using \`runbooks/ZERO-SURPRISE-UPGRADE-WINDOW.md\`"
fi)
$(if [ "$UNHEALTHY_COUNT" -gt 0 ]; then
  echo "- [ ] Investigate unhealthy containers"
fi)
$(if [ "$TLS_WARNING" -gt 0 ]; then
  echo "- [ ] Renew expiring TLS certificates"
fi)
$(if [ "$NEEDS_ATTENTION" = false ]; then
  echo "- None — system is healthy"
fi)
REPORT

log "Report written to $REPORT_FILE"

# =============================================================================
# Alert if action needed
# =============================================================================

if [ "$NEEDS_ATTENTION" = true ] && [ -x "$ALERT_SCRIPT" ]; then
  ALERT_SUBJECT="[maintenance] $DATE: updates available"
  ALERT_BODY="OS security: ${APT_SEC_COUNT} pending | Stale images: ${STALE_COUNT} | Unhealthy: ${UNHEALTHY_COUNT} | TLS warnings: ${TLS_WARNING}
Report: $REPORT_FILE"

  ALERT_SEVERITY=info \
  ALERT_EMAIL="${ALERT_EMAIL:-milorad.stevanovic@inlock.ai}" \
    "$ALERT_SCRIPT" "$ALERT_SUBJECT" "$ALERT_BODY" || true
fi

log "Done."
