#!/usr/bin/env bash
set -euo pipefail

# Monitor Backup Success Rate
# Analyzes backup logs and generates weekly success/failure summaries
# Usage: ./scripts/backup/monitor-backup-success-rate.sh [--week YYYY-WW]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="${LOG_FILE:-$PROJECT_ROOT/logs/inlock-backup-system.log}"
SUMMARY_DIR="${SUMMARY_DIR:-$PROJECT_ROOT/logs/backup-summaries}"
WEEK=""

usage() {
    echo "Usage: ./scripts/backup/monitor-backup-success-rate.sh [--week YYYY-WW]"
    echo "       ./scripts/backup/monitor-backup-success-rate.sh [YYYY-WW]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --week)
            if [ -z "${2:-}" ]; then
                echo "ERROR: --week requires a value (YYYY-WW)"
                usage
                exit 1
            fi
            WEEK="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ -z "$WEEK" ]; then
                WEEK="$1"
                shift
            else
                echo "ERROR: Unknown argument: $1"
                usage
                exit 1
            fi
            ;;
    esac
done

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$SUMMARY_DIR"

# Function to get week number
get_week() {
    if [ -n "$WEEK" ]; then
        if [[ ! "$WEEK" =~ ^[0-9]{4}-W[0-9]{2}$ ]]; then
            echo "ERROR: Invalid week format: $WEEK (expected YYYY-WW)"
            exit 1
        fi
        echo "$WEEK"
    else
        # Current week (ISO week format: YYYY-WW)
        date +%Y-W%V
    fi
}

# Function to extract backup events from logs
analyze_backup_logs() {
    local week="$1"
    local year=$(echo "$week" | cut -d'-' -f1)
    local week_num_raw=$(echo "$week" | cut -d'-' -f2)
    local week_num="${week_num_raw#W}"

    # Calculate date range for the ISO week
    local start_date=""
    if ! start_date=$(date -d "${year}-W${week_num}-1" +%Y-%m-%d 2>/dev/null); then
        start_date=$(date -d "last monday" +%Y-%m-%d)
    fi
    local end_date=""
    if ! end_date=$(date -d "$start_date +6 days" +%Y-%m-%d 2>/dev/null); then
        end_date=$(date +%Y-%m-%d)
    fi

    echo "Analyzing backups from $start_date to $end_date..."
    echo ""

    local total_runs=0
    local successful_runs=0
    local failed_runs=0
    local db_success=0
    local db_fail=0
    local vol_success=0
    local vol_fail=0
    local in_run=false
    local run_failed=false
    local -a failure_lines=()

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}ERROR: Log file not found: $LOG_FILE${NC}"
        return 1
    fi

    start_run() {
        if [ "$in_run" = true ]; then
            if [ "$run_failed" = true ]; then
                failed_runs=$((failed_runs + 1))
            else
                successful_runs=$((successful_runs + 1))
            fi
        fi
        in_run=true
        run_failed=false
        total_runs=$((total_runs + 1))
    }

    # Parse log file for the week
    while IFS= read -r line; do
        # Check if line is within date range
        local log_date
        log_date=$(echo "$line" | grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 | tr -d '[' || true)
        if [ -z "$log_date" ]; then
            continue
        fi

        # Check if date is in range (simple string comparison)
        if [[ "$log_date" < "$start_date" ]] || [[ "$log_date" > "$end_date" ]]; then
            continue
        fi

        local line_lc="${line,,}"

        if [[ "$line_lc" == *"backup type:"* ]] || [[ "$line_lc" == *"starting backup with pre-flight checks"* ]]; then
            start_run
        fi

        local failure_recorded=false

        if [[ "$line_lc" == *"database"* && "$line_lc" == *"completed"* ]]; then
            db_success=$((db_success + 1))
        fi

        if [[ "$line_lc" == *"volume backups completed"* ]] || [[ "$line_lc" == *"backup completed successfully"* ]]; then
            vol_success=$((vol_success + 1))
        fi

        if [[ "$line_lc" == *"database"* && "$line_lc" == *"failed"* ]]; then
            db_fail=$((db_fail + 1))
            run_failed=true
            failure_recorded=true
        fi

        if [[ "$line_lc" == *"volume"* && "$line_lc" == *"failed"* ]]; then
            vol_fail=$((vol_fail + 1))
            run_failed=true
            failure_recorded=true
        fi

        if [[ "$line_lc" == *"backup script failed"* ]]; then
            vol_fail=$((vol_fail + 1))
            run_failed=true
            failure_recorded=true
        fi

        if [[ "$line_lc" == *"backup readiness check failed"* ]] || [[ "$line_lc" == *"error:"* ]]; then
            run_failed=true
            failure_recorded=true
        fi

        if [ "$failure_recorded" = true ]; then
            failure_lines+=("$line")
        fi
    done < "$LOG_FILE"

    if [ "$in_run" = true ]; then
        if [ "$run_failed" = true ]; then
            failed_runs=$((failed_runs + 1))
        else
            successful_runs=$((successful_runs + 1))
        fi
    fi

    local database_backups=$((db_success + db_fail))
    local volume_backups=$((vol_success + vol_fail))

    local run_success_rate=0
    if [ "$total_runs" -gt 0 ]; then
        run_success_rate=$((successful_runs * 100 / total_runs))
    fi

    local failure_start=0
    if [ "${#failure_lines[@]}" -gt 10 ]; then
        failure_start=$((${#failure_lines[@]} - 10))
    fi

    # Generate summary
    local summary_file="$SUMMARY_DIR/weekly-summary-${week}.txt"
    {
        echo "=== Weekly Backup Summary - Week $week ==="
        echo "Period: $start_date to $end_date"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Overall Statistics:"
        echo "  Total Backup Runs: $total_runs"
        echo "  Successful Runs: $successful_runs"
        echo "  Failed Runs: $failed_runs"
        echo "  Run Success Rate: ${run_success_rate}%"
        echo ""
        echo "Database Backups:"
        echo "  Total: $database_backups"
        echo "  Successful: $db_success"
        echo "  Failed: $db_fail"
        echo ""
        echo "Volume Backups:"
        echo "  Total: $volume_backups"
        echo "  Successful: $vol_success"
        echo "  Failed: $vol_fail"
        echo ""

        if [ "${#failure_lines[@]}" -gt 0 ]; then
            echo "Failures Detected:"
            for ((i=failure_start; i<${#failure_lines[@]}; i++)); do
                echo "  ${failure_lines[i]}"
            done
        fi
    } > "$summary_file"

    # Display summary
    echo "=== Weekly Backup Summary - Week $week ==="
    echo "Period: $start_date to $end_date"
    echo ""
    echo -e "Total Backup Runs: ${GREEN}$total_runs${NC}"
    echo -e "Successful Runs: ${GREEN}$successful_runs${NC}"
    echo -e "Failed Runs: ${RED}$failed_runs${NC}"
    echo -e "Run Success Rate: ${GREEN}${run_success_rate}%${NC}"
    echo ""
    echo "Database Backups: $db_success successful, $db_fail failed"
    echo "Volume Backups: $vol_success successful, $vol_fail failed"
    echo ""
    echo "Summary saved to: $summary_file"

    # Return status
    if [ "$failed_runs" -eq 0 ] && [ "$total_runs" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    local week=$(get_week)
    echo "=== Backup Success Rate Monitor ==="
    echo "Week: $week"
    echo "Log File: $LOG_FILE"
    echo ""
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}ERROR: Log file not found: $LOG_FILE${NC}"
        echo "Please ensure backups have been run at least once."
        exit 1
    fi
    
    analyze_backup_logs "$week"
    local exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ All backups successful this week${NC}"
    else
        echo -e "${YELLOW}⚠️  Some backups failed this week - review summary${NC}"
    fi
    
    return $exit_code
}

main "$@"
