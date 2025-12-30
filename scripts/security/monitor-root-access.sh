#!/bin/bash
#
# Monitor root SSH access
# Logs all root SSH connections and generates reports
#
# Usage: 
#   ./scripts/security/monitor-root-access.sh [OPTIONS]
# Options:
#   --watch              Watch auth.log in real-time
#   --report             Generate monthly access report
#   --alert-on-unusual   Send alerts on unexpected patterns
#   --log-file <file>    Custom log file (default: /var/log/auth.log)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"
REPORT_DIR="$SCRIPT_DIR/archive/docs/reports/security"
WATCH_MODE=false
GENERATE_REPORT=false
ALERT_ON_UNUSUAL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --watch)
            WATCH_MODE=true
            shift
            ;;
        --report)
            GENERATE_REPORT=true
            shift
            ;;
        --alert-on-unusual)
            ALERT_ON_UNUSUAL=true
            shift
            ;;
        --log-file)
            AUTH_LOG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if running as root for log access
if [ ! -r "$AUTH_LOG" ] && [ "$EUID" -ne 0 ]; then
    echo "ERROR: Cannot read $AUTH_LOG (requires root or log group membership)"
    echo "Run with: sudo $0 $*"
    exit 1
fi

mkdir -p "$REPORT_DIR"

echo "=========================================="
echo "  Root SSH Access Monitor"
echo "=========================================="
echo ""

# Watch mode
if [ "$WATCH_MODE" = "true" ]; then
    echo "Watching $AUTH_LOG for root SSH connections..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    tail -f "$AUTH_LOG" | grep --line-buffered -E "sshd.*root" | while read line; do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Extract IP address
        IP=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "unknown")
        
        # Extract action
        if echo "$line" | grep -q "Accepted"; then
            ACTION="✓ Accepted"
        elif echo "$line" | grep -q "Failed"; then
            ACTION="✗ Failed"
        else
            ACTION="  Other"
        fi
        
        echo "[$TIMESTAMP] $ACTION root@$IP"
        
        # Alert on unusual patterns
        if [ "$ALERT_ON_UNUSUAL" = "true" ]; then
            # Alert on non-Tailscale, non-Docker-gateway IPs
            if [[ ! "$IP" =~ ^100\. ]] && [[ ! "$IP" == "172.18.0.1" ]] && [[ "$IP" != "unknown" ]]; then
                echo "  ⚠️  ALERT: Unexpected source IP: $IP"
            fi
        fi
    done
    
    exit 0
fi

# Generate report
if [ "$GENERATE_REPORT" = "true" ]; then
    MONTH=$(date +%Y-%m)
    REPORT_FILE="$REPORT_DIR/root-access-report-$MONTH.md"
    
    echo "Generating monthly access report..."
    echo "Report file: $REPORT_FILE"
    echo ""
    
    # Get date range for current month
    MONTH_START="${MONTH}-01"
    NEXT_MONTH=$(date -d "$MONTH_START +1 month" +%Y-%m-%d)
    
    # Extract root SSH connections from auth.log
    ROOT_CONNECTIONS=$(grep "sshd.*root" "$AUTH_LOG" 2>/dev/null | \
        awk -v start="$MONTH_START" -v end="$NEXT_MONTH" \
        '$0 >= start && $0 < end' || true)
    
    if [ -z "$ROOT_CONNECTIONS" ]; then
        echo "No root SSH connections found for $MONTH"
        # Still create report with summary
    fi
    
    # Generate report
    cat > "$REPORT_FILE" << EOF
# Root SSH Access Report - $MONTH

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Log File:** $AUTH_LOG  
**Period:** $MONTH_START to $NEXT_MONTH

---

## Summary

EOF

    # Count connections
    ACCEPTED_COUNT=$(echo "$ROOT_CONNECTIONS" | grep -c "Accepted" || echo "0")
    FAILED_COUNT=$(echo "$ROOT_CONNECTIONS" | grep -c "Failed\|Invalid" || echo "0")
    
    cat >> "$REPORT_FILE" << EOF
- **Accepted connections:** $ACCEPTED_COUNT
- **Failed attempts:** $FAILED_COUNT

---

## Accepted Connections

EOF

    if [ "$ACCEPTED_COUNT" -gt 0 ]; then
        echo "$ROOT_CONNECTIONS" | grep "Accepted" | while read line; do
            DATE=$(echo "$line" | awk '{print $1, $2, $3}')
            IP=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "unknown")
            METHOD=$(echo "$line" | grep -oP 'publickey|password' || echo "unknown")
            echo "- **$DATE** - root@$IP ($METHOD)" >> "$REPORT_FILE"
        done
    else
        echo "No accepted connections found." >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

## Failed Attempts

EOF

    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo "$ROOT_CONNECTIONS" | grep "Failed\|Invalid" | while read line; do
            DATE=$(echo "$line" | awk '{print $1, $2, $3}')
            IP=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "unknown")
            REASON=$(echo "$line" | grep -oP 'Invalid user|Failed password|Connection closed' || echo "unknown")
            echo "- **$DATE** - $IP ($REASON)" >> "$REPORT_FILE"
        done
    else
        echo "No failed attempts found." >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

## Source IP Analysis

EOF

    # Count by IP
    echo "$ROOT_CONNECTIONS" | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | while read count ip; do
        IP_TYPE=""
        if [[ "$ip" =~ ^100\. ]]; then
            IP_TYPE="(Tailscale)"
        elif [[ "$ip" == "172.18.0.1" ]]; then
            IP_TYPE="(Docker gateway)"
        elif [[ "$ip" =~ ^172\. ]]; then
            IP_TYPE="⚠️ (Other Docker network)"
        else
            IP_TYPE="⚠️ (Unknown source)"
        fi
        echo "- **$ip**: $count connection(s) $IP_TYPE" >> "$REPORT_FILE"
    done
    
    cat >> "$REPORT_FILE" << EOF

---

## Recommendations

EOF

    # Check for unusual patterns
    UNUSUAL_IPS=$(echo "$ROOT_CONNECTIONS" | grep -oP 'from \K[0-9.]+' | grep -vE "^100\.|^172\.18\.0\.1" | sort -u)
    
    if [ -n "$UNUSUAL_IPS" ]; then
        cat >> "$REPORT_FILE" << EOF
⚠️ **Security Alert:** Connections from unexpected source IPs detected:

EOF
        for ip in $UNUSUAL_IPS; do
            echo "- $ip" >> "$REPORT_FILE"
        done
        cat >> "$REPORT_FILE" << EOF

**Action Required:**
- Review connection logs for these IPs
- Verify legitimate access
- Consider blocking if unauthorized
EOF
    else
        cat >> "$REPORT_FILE" << EOF
✓ All connections from expected sources (Tailscale or Docker gateway).

No action required.
EOF
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

## Next Steps

1. Review this report monthly
2. Investigate any unusual source IPs
3. Update firewall rules if needed
4. Document any exceptions

---

**Generated by:** \`scripts/security/monitor-root-access.sh\`  
**Next Report:** Run with \`--report\` next month
EOF

    echo "✓ Report generated: $REPORT_FILE"
    exit 0
fi

# Default: show recent root access
echo "Recent root SSH access (last 50 entries):"
echo ""

if [ -r "$AUTH_LOG" ]; then
    grep "sshd.*root" "$AUTH_LOG" 2>/dev/null | tail -50 | while read line; do
        # Extract and format
        DATE=$(echo "$line" | awk '{print $1, $2, $3}')
        ACTION=$(echo "$line" | grep -oE "Accepted|Failed|Invalid" || echo "Other")
        IP=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "unknown")
        
        case "$ACTION" in
            Accepted)
                echo "✓ [$DATE] root@$IP - Connection accepted"
                ;;
            Failed|Invalid)
                echo "✗ [$DATE] $IP - $ACTION"
                ;;
            *)
                echo "  [$DATE] $line"
                ;;
        esac
    done
else
    echo "Cannot read $AUTH_LOG"
    echo "Run with sudo for full access"
fi

echo ""
echo "Usage:"
echo "  $0 --watch              # Watch in real-time"
echo "  $0 --report             # Generate monthly report"
echo "  sudo $0                 # View recent access (requires root for log access)"




