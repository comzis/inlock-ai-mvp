#!/bin/bash
#
# Monitor PostgreSQL replication status
# Checks replication lag, connection status, and health
#
# Usage: ./scripts/ha/monitor-postgres-replication.sh [OPTIONS]
# Options:
#   --alert-on-lag <bytes>  Alert if lag exceeds bytes (default: 1048576 = 1MB)
#   --json                   Output JSON format
#   --check-only             Exit with error code if replication is unhealthy

set -e

ALERT_LAG="${ALERT_LAG:-1048576}"  # 1MB default
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
CHECK_ONLY="${CHECK_ONLY:-false}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --alert-on-lag)
            ALERT_LAG="$2"
            shift 2
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if running as postgres user or with sudo
if [ "$EUID" -eq 0 ]; then
    PSQL_CMD="sudo -u postgres psql"
else
    PSQL_CMD="psql -U postgres"
fi

# Check if this is a primary or standby
IS_PRIMARY=$(sudo -u postgres psql -tAc "SELECT NOT pg_is_in_recovery();" 2>/dev/null || echo "unknown")

if [ "$IS_PRIMARY" = "t" ]; then
    SERVER_ROLE="primary"
elif [ "$IS_PRIMARY" = "f" ]; then
    SERVER_ROLE="standby"
else
    echo "ERROR: Cannot determine server role"
    exit 1
fi

if [ "$OUTPUT_FORMAT" = "json" ]; then
    # JSON output
    if [ "$SERVER_ROLE" = "primary" ]; then
        REPLICATION_STATS=$(sudo -u postgres psql -tAc "
            SELECT json_agg(row_to_json(t))
            FROM (
                SELECT 
                    client_addr,
                    state,
                    sync_state,
                    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS sent_lag_bytes,
                    pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn) AS write_lag_bytes,
                    pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) AS flush_lag_bytes,
                    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replay_lag_bytes
                FROM pg_stat_replication
            ) t;
        " 2>/dev/null || echo "[]")
        
        echo "{\"role\":\"$SERVER_ROLE\",\"replication_stats\":$REPLICATION_STATS}"
    else
        REPLICATION_STATUS=$(sudo -u postgres psql -tAc "
            SELECT json_build_object(
                'role', 'standby',
                'recovery_status', (SELECT json_agg(row_to_json(t)) FROM (
                    SELECT 
                        pg_is_in_recovery() as in_recovery,
                        pg_last_wal_receive_lsn() as last_receive_lsn,
                        pg_last_wal_replay_lsn() as last_replay_lsn,
                        pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn()) as lag_bytes
                ) t)
            );
        " 2>/dev/null || echo "{}")
        
        echo "$REPLICATION_STATUS"
    fi
    exit 0
fi

# Text output
echo "=========================================="
echo "  PostgreSQL Replication Monitor"
echo "=========================================="
echo ""
echo "Server role: $SERVER_ROLE"
echo "Timestamp: $(date)"
echo ""

if [ "$SERVER_ROLE" = "primary" ]; then
    echo "Replication Status (Primary Server):"
    echo ""
    
    REPLICATION_COUNT=$(sudo -u postgres psql -tAc "SELECT count(*) FROM pg_stat_replication;" 2>/dev/null || echo "0")
    
    if [ "$REPLICATION_COUNT" -eq 0 ]; then
        echo "⚠️  WARNING: No standby servers connected"
        if [ "$CHECK_ONLY" = "true" ]; then
            exit 1
        fi
    else
        echo "Connected standbys: $REPLICATION_COUNT"
        echo ""
        echo "Replication Details:"
        echo ""
        
        sudo -u postgres psql -c "
            SELECT 
                client_addr as \"Standby IP\",
                state as \"State\",
                sync_state as \"Sync State\",
                pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) as \"Sent Lag\",
                pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn)) as \"Write Lag\",
                pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)) as \"Flush Lag\",
                pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as \"Replay Lag\"
            FROM pg_stat_replication;
        " 2>/dev/null || echo "  (Unable to retrieve replication stats)"
        
        # Check for lag exceeding threshold
        MAX_LAG=$(sudo -u postgres psql -tAc "
            SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)), 0)
            FROM pg_stat_replication;
        " 2>/dev/null || echo "0")
        
        if [ "$MAX_LAG" -gt "$ALERT_LAG" ]; then
            echo ""
            echo "⚠️  WARNING: Replication lag exceeds threshold"
            echo "   Maximum lag: $(numfmt --to=iec-i --suffix=B $MAX_LAG 2>/dev/null || echo "$MAX_LAG bytes")"
            echo "   Threshold: $(numfmt --to=iec-i --suffix=B $ALERT_LAG 2>/dev/null || echo "$ALERT_LAG bytes")"
            if [ "$CHECK_ONLY" = "true" ]; then
                exit 1
            fi
        else
            echo ""
            echo "✓ Replication lag is within acceptable limits"
        fi
    fi
else
    echo "Replication Status (Standby Server):"
    echo ""
    
    # Check if in recovery
    IN_RECOVERY=$(sudo -u postgres psql -tAc "SELECT pg_is_in_recovery();" 2>/dev/null || echo "unknown")
    
    if [ "$IN_RECOVERY" != "t" ]; then
        echo "⚠️  WARNING: Server is not in recovery mode"
        echo "   This may indicate the standby was promoted or replication failed"
        if [ "$CHECK_ONLY" = "true" ]; then
            exit 1
        fi
    else
        echo "✓ Server is in recovery mode (standby)"
    fi
    
    echo ""
    echo "Replication Lag:"
    sudo -u postgres psql -c "
        SELECT 
            pg_last_wal_receive_lsn() as \"Last Receive LSN\",
            pg_last_wal_replay_lsn() as \"Last Replay LSN\",
            pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) as \"Replay Lag\"
    " 2>/dev/null || echo "  (Unable to retrieve replication lag)"
fi

echo ""
echo "=========================================="

if [ "$CHECK_ONLY" = "true" ]; then
    if [ "$SERVER_ROLE" = "primary" ] && [ "$REPLICATION_COUNT" -eq 0 ]; then
        exit 1
    fi
    exit 0
fi







