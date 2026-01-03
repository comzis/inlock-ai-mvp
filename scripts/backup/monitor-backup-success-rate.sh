#!/usr/bin/env bash
set -euo pipefail

# Monitor Backup Success Rate
# Analyzes backup logs and generates weekly success/failure summaries
# Usage: ./scripts/backup/monitor-backup-success-rate.sh [--week YYYY-WW]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="${LOG_FILE:-$PROJECT_ROOT/logs/inlock-backup-system.log}"
SUMMARY_DIR="${SUMMARY_DIR:-$PROJECT_ROOT/logs/backup-summaries}"
WEEK="${1:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$SUMMARY_DIR"

# Function to get week number
get_week() {
    if [ -n "$WEEK" ]; then
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
    local week_num=$(echo "$week" | cut -d'-' -f2 | sed 's/W//')
    
    # Calculate date range for the week
    local start_date=$(date -d "$year-01-01 +$((week_num - 1)) weeks" +%Y-%m-%d 2>/dev/null || date -d "last monday" +%Y-%m-%d)
    local end_date=$(date -d "$start_date +6 days" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
    
    echo "Analyzing backups from $start_date to $end_date..."
    echo ""
    
    # Extract backup events
    local total_backups=0
    local successful_backups=0
    local failed_backups=0
    local database_backups=0
    local volume_backups=0
    local db_success=0
    local vol_success=0
    local db_fail=0
    local vol_fail=0
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}ERROR: Log file not found: $LOG_FILE${NC}"
        return 1
    fi
    
    # Parse log file for the week
    while IFS= read -r line; do
        # Check if line is within date range
        local log_date=$(echo "$line" | grep -oP '\[\K[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || echo "")
        if [ -z "$log_date" ]; then
            continue
        fi
        
        # Check if date is in range (simple string comparison)
        if [[ "$log_date" < "$start_date" ]] || [[ "$log_date" > "$end_date" ]]; then
            continue
        fi
        
        # Count backup starts
        if echo "$line" | grep -qE "backup start|Starting.*backup|Backup type:"; then
            total_backups=$((total_backups + 1))
        fi
        
        # Count database backups
        if echo "$line" | grep -qE "Starting database backups|Database backup"; then
            database_backups=$((database_backups + 1))
        fi
        
        # Count volume backups
        if echo "$line" | grep -qE "Starting volume backups|Volume backup"; then
            volume_backups=$((volume_backups + 1))
        fi
        
        # Count successes
        if echo "$line" | grep -qE "✓.*completed|✅.*completed|Database backups completed|Volume backups completed"; then
            successful_backups=$((successful_backups + 1))
            if echo "$line" | grep -q "database"; then
                db_success=$((db_success + 1))
            fi
            if echo "$line" | grep -q "volume"; then
                vol_success=$((vol_success + 1))
            fi
        fi
        
        # Count failures
        if echo "$line" | grep -qE "ERROR.*failed|❌.*failed|Database backup failed|Volume backup failed"; then
            failed_backups=$((failed_backups + 1))
            if echo "$line" | grep -q "database"; then
                db_fail=$((db_fail + 1))
            fi
            if echo "$line" | grep -q "volume"; then
                vol_fail=$((vol_fail + 1))
            fi
        fi
    done < "$LOG_FILE"
    
    # Calculate success rate
    local success_rate=0
    if [ "$total_backups" -gt 0 ]; then
        success_rate=$((successful_backups * 100 / total_backups))
    fi
    
    # Generate summary
    local summary_file="$SUMMARY_DIR/weekly-summary-${week}.txt"
    {
        echo "=== Weekly Backup Summary - Week $week ==="
        echo "Period: $start_date to $end_date"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Overall Statistics:"
        echo "  Total Backup Runs: $total_backups"
        echo "  Successful: $successful_backups"
        echo "  Failed: $failed_backups"
        echo "  Success Rate: ${success_rate}%"
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
        
        if [ "$failed_backups" -gt 0 ]; then
            echo "⚠️  Failures Detected:"
            grep -E "ERROR|failed" "$LOG_FILE" | tail -10
        fi
    } > "$summary_file"
    
    # Display summary
    echo "=== Weekly Backup Summary - Week $week ==="
    echo "Period: $start_date to $end_date"
    echo ""
    echo -e "Total Backup Runs: ${GREEN}$total_backups${NC}"
    echo -e "Successful: ${GREEN}$successful_backups${NC}"
    echo -e "Failed: ${RED}$failed_backups${NC}"
    echo -e "Success Rate: ${GREEN}${success_rate}%${NC}"
    echo ""
    echo "Database Backups: $db_success successful, $db_fail failed"
    echo "Volume Backups: $vol_success successful, $vol_fail failed"
    echo ""
    echo "Summary saved to: $summary_file"
    
    # Return status
    if [ "$failed_backups" -eq 0 ] && [ "$total_backups" -gt 0 ]; then
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

