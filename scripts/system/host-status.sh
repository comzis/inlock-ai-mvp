#!/usr/bin/env bash
# Host status check: core containers, NAT, backups, optional HTTP.
# Run weekly (e.g. cron) on vmi2953354. Append-only log; no secrets.
# Usage: ./host-status.sh [--no-http]

set -e

LOG_DIR="${LOG_DIR:-/home/comzis/logs}"
DATE=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${LOG_DIR}/host-status-$(date +%Y%m%d).log"
SKIP_HTTP=false
[[ "${1:-}" == "--no-http" ]] && SKIP_HTTP=true

mkdir -p "$LOG_DIR"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

log "=== Host status check start ==="

# 1) Core containers
log "--- Containers ---"
for name in inlock-ai-secure-mvp-web-1 inlock-ai-secure-mvp-db-1 services-inlock-ai-1 services-inlock-db-1 mailcowdockerized-unbound-mailcow-1; do
  status=$(docker ps --filter "name=$name" --format "{{.Status}}" 2>/dev/null | head -1)
  if [[ -n "$status" ]]; then
    log "OK $name: $status"
  else
    log "MISSING $name"
  fi
done

# 2) NAT rule (mailcow 10.0.0.0/24)
log "--- NAT (mailcow) ---"
if sudo -n iptables -t nat -L POSTROUTING -n -v 2>/dev/null | grep -q "10.0.0.0/24"; then
  line=$(sudo -n iptables -t nat -L POSTROUTING -n -v 2>/dev/null | grep "10.0.0.0/24" | head -1)
  log "OK NAT mailcow: $line"
else
  log "MISSING NAT rule for 10.0.0.0/24"
fi

# 3) Backup artifacts (last 8 days)
log "--- Backups ---"
BACKUP_BASE="${BACKUP_BASE:-/home/comzis/backups/inlock-ai-secure-mvp}"
for sub in db config; do
  dir="$BACKUP_BASE/$sub"
  if [[ -d "$dir" ]]; then
    recent=$(find "$dir" -maxdepth 1 -type f -mtime -8 2>/dev/null | wc -l)
    latest=$(ls -t "$dir" 2>/dev/null | head -1)
    log "OK $sub: $recent file(s) in last 8d, latest: $latest"
  else
    log "MISSING backup dir: $dir"
  fi
done

# 4) Optional HTTP checks
if [[ "$SKIP_HTTP" != "true" ]]; then
  log "--- HTTP ---"
  for url in https://inlock.ai https://mail.inlock.ai; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    if [[ "$code" == "000" ]]; then
      log "FAIL $url: no response"
    else
      log "OK $url: HTTP $code"
    fi
  done
fi

log "=== Host status check end ==="
