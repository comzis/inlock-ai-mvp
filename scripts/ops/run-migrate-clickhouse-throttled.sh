#!/bin/bash
# Throttled ClickHouse Migration Check Wrapper
# Prevents CPU saturation by throttling migrate_clickhouse --check execution
#
# This script was created in response to a 2026-01-20 incident where
# migrate_clickhouse --check caused 90-minute CPU/I/O spike (96-99% CPU, 760 MB/s disk I/O)
# during business hours when baseline CPU was already ~90%.
#
# Requirements:
# - Uses flock to prevent concurrent runs
# - Throttles CPU/I/O via nice/ionice and systemd-run (if available)
# - Load guard: refuses to run when system load is high
# - Logs via logger and optional file

set -euo pipefail

# Configuration (can be overridden via environment variables)
CPU_QUOTA_PERCENT="${CPU_QUOTA_PERCENT:-200}"  # 200% = ~2 cores on 6-core system
IONICE_CLASS="${IONICE_CLASS:-2}"              # 2 = best-effort
IONICE_PRIO="${IONICE_PRIO:-7}"                # 7 = lowest priority (0-7)
NICE_LEVEL="${NICE_LEVEL:-10}"                  # 10 = lower priority (-20 to 19)
LOAD_FACTOR="${LOAD_FACTOR:-0.80}"             # 80% of CPU cores
PROJECT_DIR="${PROJECT_DIR:-/home/comzis/projects/inlock-ai-mvp}"
MIGRATION_CMD="${MIGRATION_CMD:-python manage.py migrate_clickhouse --check}"
LOG_FILE="${LOG_FILE:-/var/log/migrate-clickhouse.log}"
# Use user-writable location if /var/run is not accessible
if [ -w /var/run ] 2>/dev/null; then
    LOCK_FILE="${LOCK_FILE:-/var/run/migrate-clickhouse.lock}"
else
    LOCK_FILE="${LOCK_FILE:-/tmp/migrate-clickhouse.lock}"
fi
DRY_RUN="${DRY_RUN:-false}"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to syslog
    logger -t migrate-clickhouse "[$level] $message"
    
    # Log to file if writable
    if [ -w "$(dirname "$LOG_FILE")" ] 2>/dev/null; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Also output to stderr for immediate visibility
    echo "[$timestamp] [$level] $message" >&2
}

# Check if running in dry-run mode
if [ "$DRY_RUN" = "true" ] || [ "${1:-}" = "--dry-run" ]; then
    log "INFO" "DRY RUN MODE - No actual migration will be executed"
    DRY_RUN=true
fi

# Acquire lock to prevent concurrent runs
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "WARN" "Another migrate_clickhouse process is already running (lock: $LOCK_FILE)"
    exit 73  # EX_CANTCREAT - cannot create lock
fi

# Cleanup function
cleanup() {
    flock -u 200
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

log "INFO" "Starting ClickHouse migration check (throttled)"

# Load guard: Check system load average
if [ -r /proc/loadavg ]; then
    read -r load1 load5 load15 _ < /proc/loadavg
    
    # Get number of CPU cores
    if command -v nproc >/dev/null 2>&1; then
        cpu_cores=$(nproc)
    else
        # Fallback: count processors in /proc/cpuinfo
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
    fi
    
    # Calculate threshold
    threshold=$(awk "BEGIN {printf \"%.2f\", $cpu_cores * $LOAD_FACTOR}")
    
    log "INFO" "System load: 1m=$load1, 5m=$load5, 15m=$load15 | CPU cores: $cpu_cores | Threshold: $threshold"
    
    # Compare load1 (1-minute average) against threshold
    if awk "BEGIN {exit !($load1 >= $threshold)}"; then
        log "ERROR" "System load too high (load1=$load1 >= threshold=$threshold). Skipping migration check."
        exit 75  # EX_TEMPFAIL - temporary failure, try again later
    fi
else
    log "WARN" "Cannot read /proc/loadavg, skipping load check"
fi

# Verify project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    log "ERROR" "Project directory not found: $PROJECT_DIR"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR" || {
    log "ERROR" "Cannot change to project directory: $PROJECT_DIR"
    exit 1
}

# Determine if we're running in a Docker container or on host
if [ -f /.dockerenv ] || [ -n "${DOCKER_CONTAINER:-}" ]; then
    # Running inside Docker container - use nice/ionice only
    log "INFO" "Running inside Docker container, using nice/ionice for throttling"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "INFO" "DRY RUN: Would execute: nice -n $NICE_LEVEL ionice -c $IONICE_CLASS -n $IONICE_PRIO $MIGRATION_CMD"
        exit 0
    fi
    
    # Execute with nice/ionice
    if nice -n "$NICE_LEVEL" ionice -c "$IONICE_CLASS" -n "$IONICE_PRIO" $MIGRATION_CMD; then
        log "INFO" "ClickHouse migration check completed successfully"
        exit 0
    else
        exit_code=$?
        log "ERROR" "ClickHouse migration check failed with exit code: $exit_code"
        exit $exit_code
    fi
else
    # Running on host - try systemd-run for better resource control
    if command -v systemd-run >/dev/null 2>&1; then
        log "INFO" "Using systemd-run for resource throttling"
        
        if [ "$DRY_RUN" = "true" ]; then
            log "INFO" "DRY RUN: Would execute via systemd-run with CPUQuota=${CPU_QUOTA_PERCENT}%, Nice=$NICE_LEVEL, IOSchedulingClass=$IONICE_CLASS, IOSchedulingPriority=$IONICE_PRIO"
            exit 0
        fi
        
        # Use systemd-run with resource limits
        # Note: systemd-run creates a transient unit, so we need to run the command in a way that works
        # We'll use a shell wrapper to change directory and execute
        if systemd-run \
            --unit=migrate-clickhouse-$$ \
            --scope \
            --property=CPUQuota="${CPU_QUOTA_PERCENT}%" \
            --property=Nice="$NICE_LEVEL" \
            --property=IOSchedulingClass="$IONICE_CLASS" \
            --property=IOSchedulingPriority="$IONICE_PRIO" \
            --property=WorkingDirectory="$PROJECT_DIR" \
            --property=StandardOutput=journal \
            --property=StandardError=journal \
            sh -c "cd '$PROJECT_DIR' && $MIGRATION_CMD"; then
            log "INFO" "ClickHouse migration check completed successfully"
            exit 0
        else
            exit_code=$?
            log "ERROR" "ClickHouse migration check failed with exit code: $exit_code"
            exit $exit_code
        fi
    else
        # Fallback to nice/ionice if systemd-run not available
        log "INFO" "systemd-run not available, using nice/ionice for throttling"
        
        if [ "$DRY_RUN" = "true" ]; then
            log "INFO" "DRY RUN: Would execute: nice -n $NICE_LEVEL ionice -c $IONICE_CLASS -n $IONICE_PRIO $MIGRATION_CMD"
            exit 0
        fi
        
        if nice -n "$NICE_LEVEL" ionice -c "$IONICE_CLASS" -n "$IONICE_PRIO" $MIGRATION_CMD; then
            log "INFO" "ClickHouse migration check completed successfully"
            exit 0
        else
            exit_code=$?
            log "ERROR" "ClickHouse migration check failed with exit code: $exit_code"
            exit $exit_code
        fi
    fi
fi
