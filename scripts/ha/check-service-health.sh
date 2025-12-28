#!/bin/bash
#
# Check health of all services
# Monitors services, detects failures, and triggers alerts
#
# Usage: ./scripts/ha/check-service-health.sh [OPTIONS]
# Options:
#   --json                   Output JSON format
#   --alert                  Send alerts on failures
#   --compose-file <file>    Compose file to check (default: compose/services/stack.yml)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/compose/services/stack.yml}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
ALERT_ON_FAILURE="${ALERT_ON_FAILURE:-false}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --alert)
            ALERT_ON_FAILURE=true
            shift
            ;;
        --compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if docker-compose or docker compose is available
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "ERROR: docker-compose or docker compose is not available"
    exit 1
fi

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Change to compose directory
cd "$(dirname "$COMPOSE_FILE")"

# Get list of services
SERVICES=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" config --services 2>/dev/null || echo "")

if [ -z "$SERVICES" ]; then
    echo "ERROR: No services found in compose file"
    exit 1
fi

HEALTHY_COUNT=0
UNHEALTHY_COUNT=0
UNKNOWN_COUNT=0
FAILED_COUNT=0
TOTAL_COUNT=0

# Check each service
for SERVICE in $SERVICES; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    # Get service status
    STATUS=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps "$SERVICE" --format json 2>/dev/null | jq -r '.[0].State // "unknown"' || echo "unknown")
    HEALTH=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps "$SERVICE" --format json 2>/dev/null | jq -r '.[0].Health // "none"' || echo "none")
    
    if [ "$STATUS" = "running" ]; then
        if [ "$HEALTH" = "healthy" ]; then
            HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
            SERVICE_STATE="healthy"
        elif [ "$HEALTH" = "unhealthy" ]; then
            UNHEALTHY_COUNT=$((UNHEALTHY_COUNT + 1))
            SERVICE_STATE="unhealthy"
        else
            # Running but no health check
            UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
            SERVICE_STATE="running"
        fi
    elif [ "$STATUS" = "exited" ] || [ "$STATUS" = "dead" ]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        SERVICE_STATE="failed"
    else
        UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
        SERVICE_STATE="unknown"
    fi
    
    SERVICE_STATUSES="$SERVICE_STATUSES$SERVICE:$SERVICE_STATE "
done

# Output results
if [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "{\"healthy\":$HEALTHY_COUNT,\"unhealthy\":$UNHEALTHY_COUNT,\"failed\":$FAILED_COUNT,\"unknown\":$UNKNOWN_COUNT,\"total\":$TOTAL_COUNT}"
    exit 0
fi

# Text output
echo "=========================================="
echo "  Service Health Check"
echo "=========================================="
echo ""
echo "Compose file: $COMPOSE_FILE"
echo "Timestamp: $(date)"
echo ""
echo "Summary:"
echo "  Total services: $TOTAL_COUNT"
echo "  Healthy: $HEALTHY_COUNT"
echo "  Unhealthy: $UNHEALTHY_COUNT"
echo "  Failed: $FAILED_COUNT"
echo "  Unknown: $UNKNOWN_COUNT"
echo ""

if [ "$UNHEALTHY_COUNT" -gt 0 ] || [ "$FAILED_COUNT" -gt 0 ]; then
    echo "=========================================="
    echo "  Service Details"
    echo "=========================================="
    echo ""
    
    for SERVICE in $SERVICES; do
        STATUS=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps "$SERVICE" --format json 2>/dev/null | jq -r '.[0].State // "unknown"' || echo "unknown")
        HEALTH=$($COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps "$SERVICE" --format json 2>/dev/null | jq -r '.[0].Health // "none"' || echo "none")
        
        if [ "$STATUS" != "running" ] || [ "$HEALTH" = "unhealthy" ]; then
            echo "Service: $SERVICE"
            echo "  Status: $STATUS"
            echo "  Health: $HEALTH"
            
            # Get logs (last 5 lines)
            echo "  Recent logs:"
            $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" logs --tail 5 "$SERVICE" 2>/dev/null | sed 's/^/    /' || echo "    (Unable to retrieve logs)"
            echo ""
        fi
    done
    
    if [ "$ALERT_ON_FAILURE" = "true" ]; then
        echo "⚠️  Alert: Unhealthy or failed services detected"
        # Add alert notification here (email, webhook, etc.)
    fi
    
    exit 1
else
    echo "✓ All services are healthy"
    exit 0
fi

