#!/bin/bash
#
# Automated failover procedures
# Handles database failover and service restart on failure
#
# Usage: sudo ./scripts/ha/failover-procedures.sh [OPTIONS]
# Options:
#   --database              Execute database failover
#   --service <name>        Restart failed service
#   --dry-run               Show what would be done without executing

set -e

DRY_RUN="${DRY_RUN:-false}"
FAILOVER_DATABASE="${FAILOVER_DATABASE:-false}"
SERVICE_NAME="${SERVICE_NAME:-}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --database)
            FAILOVER_DATABASE=true
            shift
            ;;
        --service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "  Failover Procedures"
echo "=========================================="
echo ""
echo "Mode: $([ "$DRY_RUN" = "true" ] && echo "DRY RUN" || echo "EXECUTE")"
echo ""

# Database failover
if [ "$FAILOVER_DATABASE" = "true" ]; then
    echo "Database Failover:"
    echo ""
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "  [DRY RUN] Would promote standby database to primary"
        echo "  [DRY RUN] Would update connection strings"
        echo "  [DRY RUN] Would restart services"
    else
        # Check if standby promotion script exists
        PROMOTE_SCRIPT="$(dirname "$0")/promote-postgres-standby.sh"
        
        if [ -f "$PROMOTE_SCRIPT" ]; then
            echo "  Promoting standby to primary..."
            bash "$PROMOTE_SCRIPT" || {
                echo "  ❌ ERROR: Failed to promote standby"
                exit 1
            }
            echo "  ✓ Standby promoted to primary"
        else
            echo "  ❌ ERROR: Promote script not found: $PROMOTE_SCRIPT"
            exit 1
        fi
        
        # Update connection strings (if needed)
        echo "  Note: Update application connection strings manually if needed"
        
        # Restart services (if needed)
        echo "  Note: Restart services manually if needed"
    fi
    echo ""
fi

# Service restart
if [ -n "$SERVICE_NAME" ]; then
    echo "Service Restart: $SERVICE_NAME"
    echo ""
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "  [DRY RUN] Would restart service: $SERVICE_NAME"
        echo "  [DRY RUN] Would verify service health"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
        COMPOSE_FILE="$SCRIPT_DIR/compose/services/stack.yml"
        
        if [ -f "$COMPOSE_FILE" ]; then
            cd "$(dirname "$COMPOSE_FILE")"
            
            # Check if docker-compose or docker compose is available
            if command -v docker-compose >/dev/null 2>&1; then
                COMPOSE_CMD="docker-compose"
            elif docker compose version >/dev/null 2>&1; then
                COMPOSE_CMD="docker compose"
            else
                echo "  ❌ ERROR: docker-compose not available"
                exit 1
            fi
            
            echo "  Restarting service: $SERVICE_NAME"
            $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" restart "$SERVICE_NAME" || {
                echo "  ❌ ERROR: Failed to restart service"
                exit 1
            }
            
            echo "  Waiting for service to start..."
            sleep 5
            
            # Check service health
            STATUS=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps "$SERVICE_NAME" --format json 2>/dev/null | jq -r '.[0].State // "unknown"' || echo "unknown")
            
            if [ "$STATUS" = "running" ]; then
                echo "  ✓ Service restarted successfully"
            else
                echo "  ⚠️  WARNING: Service status is $STATUS"
            fi
        else
            echo "  ❌ ERROR: Compose file not found: $COMPOSE_FILE"
            exit 1
        fi
    fi
    echo ""
fi

# If no specific action requested, show usage
if [ "$FAILOVER_DATABASE" != "true" ] && [ -z "$SERVICE_NAME" ]; then
    echo "Usage:"
    echo "  Database failover:"
    echo "    $0 --database"
    echo ""
    echo "  Service restart:"
    echo "    $0 --service <service-name>"
    echo ""
    echo "  Dry run:"
    echo "    $0 --database --dry-run"
    echo "    $0 --service <service-name> --dry-run"
    echo ""
    exit 0
fi

echo "=========================================="
echo "  Failover Procedures Complete"
echo "=========================================="




