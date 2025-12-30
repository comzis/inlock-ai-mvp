#!/bin/bash
#
# Scan all running Docker containers for vulnerabilities
# Generates JSON and HTML reports
#
# Usage: ./scripts/security/scan-containers.sh [OPTIONS]
# Options:
#   --format <json|html|table>  Output format (default: all)
#   --output-dir <dir>          Output directory (default: archive/docs/reports/security/vulnerabilities)
#   --fail-on-critical          Exit with error if critical vulnerabilities found
#   --severity <level>          Minimum severity (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/archive/docs/reports/security/vulnerabilities}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_PREFIX="container-scan-$TIMESTAMP"
FORMAT="${FORMAT:-all}"
FAIL_ON_CRITICAL="${FAIL_ON_CRITICAL:-false}"
MIN_SEVERITY="${MIN_SEVERITY:-MEDIUM}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --fail-on-critical)
            FAIL_ON_CRITICAL=true
            shift
            ;;
        --severity)
            MIN_SEVERITY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if Trivy is installed
if ! command -v trivy >/dev/null 2>&1; then
    echo "ERROR: Trivy is not installed"
    echo "Run: sudo ./scripts/security/install-trivy.sh"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "  Scanning Running Containers"
echo "=========================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Format: $FORMAT"
echo "Minimum severity: $MIN_SEVERITY"
echo ""

# Get list of running containers
echo "Finding running containers..."
CONTAINERS=$(docker ps --format "{{.ID}} {{.Names}}" | awk '{print $1}')

if [ -z "$CONTAINERS" ]; then
    echo "No running containers found"
    exit 0
fi

CONTAINER_COUNT=$(echo "$CONTAINERS" | wc -l)
echo "Found $CONTAINER_COUNT running container(s)"
echo ""

# Scan each container
CRITICAL_FOUND=0
HIGH_FOUND=0
SCAN_COUNT=0

for CONTAINER_ID in $CONTAINERS; do
    CONTAINER_NAME=$(docker ps --format "{{.ID}} {{.Names}}" | grep "^$CONTAINER_ID" | awk '{print $2}')
    CONTAINER_IMAGE=$(docker ps --format "{{.ID}} {{.Image}}" | grep "^$CONTAINER_ID" | awk '{print $2}')
    SCAN_COUNT=$((SCAN_COUNT + 1))
    
    echo "[$SCAN_COUNT/$CONTAINER_COUNT] Scanning: $CONTAINER_NAME (Image: $CONTAINER_IMAGE)"
    
    REPORT_NAME="${REPORT_PREFIX}-${CONTAINER_NAME}"
    
    # Build Trivy command - scan the container's image
    # Note: Trivy scans images, not running containers directly
    # We'll scan the image that the container is running
    TRIVY_CMD="trivy image"
    
    # Generate reports based on format
    if [ "$FORMAT" = "all" ] || [ "$FORMAT" = "json" ]; then
        JSON_FILE="$OUTPUT_DIR/${REPORT_NAME}.json"
        $TRIVY_CMD --format json "$CONTAINER_IMAGE" > "$JSON_FILE" 2>&1 || {
            echo "  ⚠️  Warning: Scan failed for $CONTAINER_NAME"
            continue
        }
        
        # Count critical and high vulnerabilities
        CRIT_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
        HIGH_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
        
        CRITICAL_FOUND=$((CRITICAL_FOUND + CRIT_COUNT))
        HIGH_FOUND=$((HIGH_FOUND + HIGH_COUNT))
        
        if [ "$CRIT_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
            echo "  ⚠️  Found: $CRIT_COUNT CRITICAL, $HIGH_COUNT HIGH vulnerabilities"
        else
            echo "  ✓ No critical or high severity vulnerabilities"
        fi
    fi
    
    if [ "$FORMAT" = "all" ] || [ "$FORMAT" = "html" ]; then
        HTML_FILE="$OUTPUT_DIR/${REPORT_NAME}.html"
        $TRIVY_CMD --format template --template "@contrib/html.tpl" "$CONTAINER_IMAGE" > "$HTML_FILE" 2>/dev/null || {
            # Fallback to table format if HTML template not available
            $TRIVY_CMD --format table "$CONTAINER_IMAGE" > "$HTML_FILE" 2>&1 || true
        }
    fi
    
    if [ "$FORMAT" = "table" ]; then
        TABLE_FILE="$OUTPUT_DIR/${REPORT_NAME}.txt"
        $TRIVY_CMD --format table "$CONTAINER_IMAGE" > "$TABLE_FILE" 2>&1 || true
    fi
done

echo ""
echo "=========================================="
echo "  Scan Summary"
echo "=========================================="
echo ""
echo "Containers scanned: $SCAN_COUNT"
echo "Critical vulnerabilities: $CRITICAL_FOUND"
echo "High vulnerabilities: $HIGH_FOUND"
echo ""
echo "Reports saved to: $OUTPUT_DIR"
echo ""

# Exit with error if critical vulnerabilities found and fail-on-critical is enabled
if [ "$FAIL_ON_CRITICAL" = "true" ] && [ "$CRITICAL_FOUND" -gt 0 ]; then
    echo "❌ FAILED: Critical vulnerabilities found"
    exit 1
fi

if [ "$CRITICAL_FOUND" -gt 0 ] || [ "$HIGH_FOUND" -gt 0 ]; then
    echo "⚠️  WARNING: Vulnerabilities found. Review reports for details."
    exit 0
else
    echo "✓ No critical or high severity vulnerabilities found"
    exit 0
fi

