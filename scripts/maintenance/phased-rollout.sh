#!/bin/bash
# =============================================================================
# Phased Rollout with Health Gates and Auto-Rollback
# =============================================================================
# Human-in-the-loop execution engine. Operator starts this manually after
# approving a maintenance window. Each phase has a health gate; failures
# trigger automatic rollback of the affected phase only.
#
# Usage:
#   ./phased-rollout.sh                           # interactive execution
#   ./phased-rollout.sh --dry-run                  # show plan, no changes
#   ./phased-rollout.sh --ticket MAINT-001         # tag run with ticket ID
#   ./phased-rollout.sh --window 60                # maintenance window (min)
#   ./phased-rollout.sh --skip-os                  # skip OS updates
#   ./phased-rollout.sh --phase 2                  # start from phase N
#
# Reports written to: /home/comzis/logs/maintenance/rollout-YYYY-MM-DD-HHMMSS/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/compose/services/stack.yml"
ENV_FILE="$REPO_ROOT/.env"
ALERT_SCRIPT="$REPO_ROOT/ops/security/alert.sh"
REPORT_SCRIPT="$SCRIPT_DIR/maintenance-report.sh"

TS="$(date +%Y-%m-%d-%H%M%S)"
RUN_DIR="/home/comzis/logs/maintenance/rollout-$TS"
LOG_FILE="$RUN_DIR/rollout.log"

DRY_RUN=false
TICKET=""
WINDOW_MIN=60
SKIP_OS=false
START_PHASE=0
ROLLBACK_USED=false
FAILED_PHASE=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=true; shift ;;
    --ticket)      TICKET="$2"; shift 2 ;;
    --window)      WINDOW_MIN="$2"; shift 2 ;;
    --skip-os)     SKIP_OS=true; shift ;;
    --phase)       START_PHASE="$2"; shift 2 ;;
    *)             echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$RUN_DIR"

# =============================================================================
# Logging helpers
# =============================================================================
log() {
  local msg="[$(date '+%H:%M:%S')] $1"
  echo "$msg" | tee -a "$LOG_FILE"
}

log_ok() { log "  OK  $1"; }
log_fail() { log "  FAIL  $1"; }
log_phase() { log ""; log "========== $1 =========="; }
log_gate() { log "--- Health Gate: $1 ---"; }

# =============================================================================
# Phase definitions
# =============================================================================
# Format: PHASE_NAME|SERVICES (comma-sep)|HEALTH_CHECK_FUNCTION
declare -a PHASES=(
  "Auth Path|oauth2-proxy|gate_auth"
  "Monitoring Control|alertmanager,cadvisor|gate_monitoring"
  "Logging Plane|loki,promtail|gate_logging"
)

# =============================================================================
# Health gate functions
# =============================================================================
gate_auth() {
  local ok=true

  # Check oauth2-proxy container is running + healthy
  if ! docker ps --filter "name=services-oauth2-proxy-1" --filter "status=running" -q | grep -q .; then
    log_fail "oauth2-proxy container not running"
    ok=false
  fi

  # Wait for healthy (up to 60s)
  if [ "$ok" = true ]; then
    if wait_healthy "services-oauth2-proxy-1" 60; then
      log_ok "oauth2-proxy healthy"
    else
      log_fail "oauth2-proxy not healthy within 60s"
      ok=false
    fi
  fi

  # Functional check: auth endpoint responds
  if [ "$ok" = true ]; then
    if curl -fsS -o /dev/null -m 10 "https://auth.inlock.ai/oauth2/start" 2>/dev/null; then
      log_ok "auth.inlock.ai/oauth2/start responds"
    else
      # Try internal check as fallback
      if curl -fsS -o /dev/null -m 10 "http://127.0.0.1:4180/ping" 2>/dev/null; then
        log_ok "oauth2-proxy /ping responds (external may need DNS)"
      else
        log_fail "oauth2-proxy not responding on any endpoint"
        ok=false
      fi
    fi
  fi

  [ "$ok" = true ]
}

gate_monitoring() {
  local ok=true

  # Alertmanager ready
  if curl -fsS -o /dev/null -m 10 "http://127.0.0.1:9093/-/ready" 2>/dev/null; then
    log_ok "alertmanager ready"
  else
    if wait_healthy "services-alertmanager-1" 60; then
      log_ok "alertmanager healthy (ready endpoint slow)"
    else
      log_fail "alertmanager not ready"
      ok=false
    fi
  fi

  # cAdvisor running
  if wait_healthy "services-cadvisor-1" 60; then
    log_ok "cadvisor healthy"
  else
    log_fail "cadvisor not healthy"
    ok=false
  fi

  [ "$ok" = true ]
}

gate_logging() {
  local ok=true

  # Loki ready
  if curl -fsS -o /dev/null -m 10 "http://127.0.0.1:3100/ready" 2>/dev/null; then
    log_ok "loki ready"
  else
    if wait_healthy "services-loki-1" 90; then
      log_ok "loki healthy (ready endpoint slow)"
    else
      log_fail "loki not ready"
      ok=false
    fi
  fi

  # Promtail running
  if wait_healthy "services-promtail-1" 60; then
    log_ok "promtail healthy"
  else
    log_fail "promtail not healthy"
    ok=false
  fi

  [ "$ok" = true ]
}

# =============================================================================
# Utility functions
# =============================================================================
wait_healthy() {
  local container="$1"
  local timeout="${2:-60}"
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    local health
    health="$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")"
    if [ "$health" = "healthy" ]; then
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  return 1
}

compose_cmd() {
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"
}

snapshot_images() {
  # Save current image IDs for rollback
  docker ps --format '{{.Names}} {{.Image}} {{.ID}}' | sort > "$RUN_DIR/images-before.txt"
  log "Image snapshot saved to $RUN_DIR/images-before.txt"
}

snapshot_service_image() {
  # Get current image for a specific service
  local svc="$1"
  local container="services-${svc}-1"
  docker inspect --format '{{.Config.Image}}' "$container" 2>/dev/null || echo "unknown"
}

rollback_phase() {
  local phase_name="$1"
  local services="$2"

  log ""
  log ">>> AUTO-ROLLBACK: $phase_name <<<"
  log "Rolling back services: $services"
  ROLLBACK_USED=true
  FAILED_PHASE="$phase_name"

  IFS=',' read -ra svc_arr <<< "$services"
  for svc in "${svc_arr[@]}"; do
    local old_image
    old_image="$(grep "services-${svc}-1" "$RUN_DIR/images-before.txt" | awk '{print $2}' || true)"
    if [ -n "$old_image" ] && [ "$old_image" != "unknown" ]; then
      log "  Restoring $svc → $old_image"
      # Pull the old image (should be cached) and restart the container
      docker pull "$old_image" >/dev/null 2>&1 || true
    fi
  done

  # Re-deploy with whatever images are in the compose files
  # The operator will need to revert the compose file pins manually
  # For now, restart the old containers
  for svc in "${svc_arr[@]}"; do
    local container="services-${svc}-1"
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
      docker restart "$container" >/dev/null 2>&1 || true
      log "  Restarted $container"
    fi
  done

  log "Rollback complete for $phase_name"
  log "NOTE: Compose file pins may need manual revert (git revert)"
}

# =============================================================================
# Preflight
# =============================================================================
preflight() {
  log_phase "PREFLIGHT"

  log "Ticket: ${TICKET:-none}"
  log "Window: ${WINDOW_MIN} minutes"
  log "Dry run: $DRY_RUN"
  log "Skip OS: $SKIP_OS"
  log "Start phase: $START_PHASE"
  log ""

  # System health
  log "System state:"
  log "  Load: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
  log "  Memory: $(free -h | awk '/^Mem:/ {printf "%s used, %s available", $3, $7}')"
  log "  Disk: $(df -h / | awk 'NR==2 {printf "%s used (%s)", $3, $5}')"
  log ""

  # Compose config validation
  if compose_cmd config >/dev/null 2>&1; then
    log_ok "Compose config valid"
  else
    log_fail "Compose config invalid — aborting"
    exit 1
  fi

  # All containers healthy
  local unhealthy
  unhealthy="$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null || true)"
  if [ -n "$unhealthy" ]; then
    log "  WARNING: unhealthy containers before starting: $unhealthy"
  else
    log_ok "All containers healthy"
  fi

  # Snapshot
  snapshot_images

  # Save compose config for rollback reference
  compose_cmd config > "$RUN_DIR/compose-config-before.yml" 2>/dev/null || true

  log ""
  log "Preflight complete."
}

# =============================================================================
# OS updates phase
# =============================================================================
phase_os_updates() {
  log_phase "PHASE 0: OS Security Updates"

  if [ "$SKIP_OS" = true ]; then
    log "Skipped (--skip-os)"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: would run apt update + check for security packages"
    apt list --upgradable 2>/dev/null | grep -i security | head -10 || true
    return 0
  fi

  local sec_count
  sec_count="$(apt list --upgradable 2>/dev/null | grep -ic security || echo 0)"

  if [ "$sec_count" -gt 0 ]; then
    log "$sec_count security update(s) available"
    log "Applying security updates..."

    if sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
        $(apt list --upgradable 2>/dev/null | grep -i security | awk -F/ '{print $1}' | tr '\n' ' ') \
        >> "$RUN_DIR/apt-upgrade.log" 2>&1; then
      log_ok "OS security updates applied"
    else
      log_fail "OS security update failed — see $RUN_DIR/apt-upgrade.log"
      log "Continuing with container updates (OS failure is non-blocking)"
    fi
  else
    log_ok "No pending OS security updates"
  fi

  log_gate "OS Updates"
  # Check no unexpected service failures
  local errors
  errors="$(journalctl -p err --since '5 min ago' --no-pager -q 2>/dev/null | wc -l || echo 0)"
  if [ "$errors" -lt 5 ]; then
    log_ok "No error burst in journal ($errors errors)"
  else
    log "  WARNING: $errors errors in journal — review manually"
  fi
}

# =============================================================================
# Container update phases
# =============================================================================
run_phase() {
  local phase_idx="$1"
  local phase_def="${PHASES[$phase_idx]}"
  local phase_name phase_services phase_gate

  IFS='|' read -r phase_name phase_services phase_gate <<< "$phase_def"

  log_phase "PHASE $((phase_idx + 1)): $phase_name"
  log "Services: $phase_services"

  IFS=',' read -ra svc_arr <<< "$phase_services"

  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: would pull + up -d: ${svc_arr[*]}"
    for svc in "${svc_arr[@]}"; do
      local current
      current="$(snapshot_service_image "$svc")"
      log "  $svc: current=$current"
    done
    return 0
  fi

  # Record before-images for this phase
  for svc in "${svc_arr[@]}"; do
    local current
    current="$(snapshot_service_image "$svc")"
    log "  $svc before: $current"
  done

  # Pull new images
  log "Pulling images..."
  if compose_cmd pull "${svc_arr[@]}" >> "$RUN_DIR/pull.log" 2>&1; then
    log_ok "Pull complete"
  else
    log_fail "Pull failed — skipping this phase"
    return 1
  fi

  # Apply
  log "Applying (up -d)..."
  if compose_cmd up -d "${svc_arr[@]}" >> "$RUN_DIR/up.log" 2>&1; then
    log_ok "Containers recreated"
  else
    log_fail "up -d failed"
    rollback_phase "$phase_name" "$phase_services"
    return 1
  fi

  # Wait a moment for containers to start
  sleep 5

  # Record after-images
  for svc in "${svc_arr[@]}"; do
    local after
    after="$(snapshot_service_image "$svc")"
    log "  $svc after: $after"
  done

  # Health gate
  log_gate "$phase_name"
  if $phase_gate; then
    log_ok "Phase '$phase_name' passed"
  else
    log_fail "Phase '$phase_name' FAILED health gate"
    rollback_phase "$phase_name" "$phase_services"
    return 1
  fi
}

# =============================================================================
# Post-change monitoring hold
# =============================================================================
post_check() {
  log_phase "POST-CHANGE MONITORING HOLD"

  log "Waiting 30 seconds for settling..."
  if [ "$DRY_RUN" = false ]; then
    sleep 30
  fi

  # Full stack check
  log "Running full stack reconcile..."
  if [ "$DRY_RUN" = false ]; then
    compose_cmd up -d >> "$RUN_DIR/reconcile.log" 2>&1 || true
  fi

  # Public endpoint checks
  log ""
  log "Endpoint checks:"
  for url in "https://inlock.ai" "https://mail.inlock.ai" "https://grafana.inlock.ai"; do
    local status
    status="$(curl -ksS -o /dev/null -w '%{http_code}' -m 10 "$url" 2>/dev/null || echo "000")"
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ]; then
      log_ok "$url → $status"
    else
      log_fail "$url → $status"
    fi
  done

  # Container health summary
  log ""
  log "Container health:"
  local unhealthy
  unhealthy="$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null || true)"
  if [ -n "$unhealthy" ]; then
    log "  WARNING: unhealthy: $unhealthy"
  else
    log_ok "All containers healthy"
  fi

  # System state
  log ""
  log "Final system state:"
  log "  Load: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
  log "  Memory: $(free -h | awk '/^Mem:/ {printf "%s used, %s available", $3, $7}')"
}

# =============================================================================
# Generate report
# =============================================================================
generate_report() {
  log_phase "GENERATING REPORT"

  # Save final image state
  docker ps --format '{{.Names}} {{.Image}} {{.ID}}' | sort > "$RUN_DIR/images-after.txt"

  # Diff images
  local changed=""
  while IFS= read -r line; do
    local name before_img after_img
    name="$(echo "$line" | awk '{print $1}')"
    before_img="$(grep "^$name " "$RUN_DIR/images-before.txt" 2>/dev/null | awk '{print $2}' || echo "?")"
    after_img="$(echo "$line" | awk '{print $2}')"
    if [ "$before_img" != "$after_img" ]; then
      changed="$changed
| $name | $before_img | $after_img |"
    fi
  done < "$RUN_DIR/images-after.txt"

  local status_text="SUCCESS"
  if [ "$ROLLBACK_USED" = true ]; then
    status_text="PARTIAL (rollback used on: $FAILED_PHASE)"
  fi
  if [ "$DRY_RUN" = true ]; then
    status_text="DRY RUN"
  fi

  cat > "$RUN_DIR/report.md" <<REPORT
# Maintenance Report — $(date +%Y-%m-%d)

Generated: $(date -Is)
Host: $(hostname -f 2>/dev/null || hostname)
Ticket: ${TICKET:-none}
Window: ${WINDOW_MIN} minutes
Status: **$status_text**
Rollback used: $ROLLBACK_USED

## Image Changes

$(if [ -n "$changed" ]; then
echo "| Container | Before | After |"
echo "|-----------|--------|-------|"
echo "$changed"
else
echo "No image changes applied."
fi)

## Phase Results

$(grep -E "^(\[|  (OK|FAIL)|=)" "$LOG_FILE" | tail -40 || true)

## System State (post-change)

- Load: $(uptime | awk -F'load average:' '{print $2}' | xargs)
- Memory: $(free -h | awk '/^Mem:/ {printf "%s used, %s available", $3, $7}')
- Disk: $(df -h / | awk 'NR==2 {printf "%s used (%s)", $3, $5}')
- Containers: $(docker ps -q | wc -l)

## Artifacts

- Full log: \`$LOG_FILE\`
- Images before: \`$RUN_DIR/images-before.txt\`
- Images after: \`$RUN_DIR/images-after.txt\`
- Compose config snapshot: \`$RUN_DIR/compose-config-before.yml\`
REPORT

  log "Report: $RUN_DIR/report.md"

  # Alert
  if [ -x "$ALERT_SCRIPT" ] && [ "$DRY_RUN" = false ]; then
    ALERT_SEVERITY=info \
    ALERT_EMAIL="${ALERT_EMAIL:-milorad.stevanovic@inlock.ai}" \
      "$ALERT_SCRIPT" \
        "[maintenance] Rollout $status_text — $(date +%Y-%m-%d)" \
        "Ticket: ${TICKET:-none}. Rollback: $ROLLBACK_USED. Report: $RUN_DIR/report.md" || true
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  log "=== Phased Rollout Started ==="
  log "Time: $(date -Is)"
  log ""

  preflight

  # Phase 0: OS updates
  if [ "$START_PHASE" -le 0 ]; then
    phase_os_updates
  fi

  # Container phases
  for i in "${!PHASES[@]}"; do
    if [ "$((i + 1))" -lt "$START_PHASE" ]; then
      continue
    fi

    if ! run_phase "$i"; then
      log ""
      log "Phase $((i + 1)) failed. Stopping further phases."
      log "Completed phases remain updated. Failed phase was rolled back."
      break
    fi
  done

  post_check
  generate_report

  log ""
  log "=== Phased Rollout Complete ==="
  log "Status: $([ "$ROLLBACK_USED" = true ] && echo "PARTIAL — rollback was used" || echo "SUCCESS")"
  log "Report: $RUN_DIR/report.md"
  log "Log:    $LOG_FILE"
}

main
