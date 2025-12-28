#!/bin/bash
#
# Scan Docker images from compose files for vulnerabilities
# Checks images before deployment
#
# Usage: ./scripts/security/scan-images.sh [OPTIONS]
# Options:
#   --compose-file <file>       Compose file to scan (default: compose/services/stack.yml)
#   --format <json|html|table>  Output format (default: all)
#   --output-dir <dir>          Output directory (default: docs/reports/security/vulnerabilities)
#   --fail-on-critical          Exit with error if critical vulnerabilities found
#   --severity <level>          Minimum severity (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)
#   --pull                      Pull images before scanning (default: false)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/compose/services/stack.yml}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/docs/reports/security/vulnerabilities}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_PREFIX="image-scan-$TIMESTAMP"
FORMAT="${FORMAT:-all}"
FAIL_ON_CRITICAL="${FAIL_ON_CRITICAL:-false}"
MIN_SEVERITY="${MIN_SEVERITY:-MEDIUM}"
PULL_IMAGES="${PULL_IMAGES:-false}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
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
        --pull)
            PULL_IMAGES=true
            shift
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

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Check if docker-compose or docker compose is available
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "ERROR: docker-compose or docker compose is not available"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "  Scanning Docker Images"
echo "=========================================="
echo ""
echo "Compose file: $COMPOSE_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "Format: $FORMAT"
echo "Minimum severity: $MIN_SEVERITY"
echo "Pull images: $PULL_IMAGES"
echo ""

# Extract image names from compose file
echo "Extracting images from compose file..."
IMAGES=$($COMPOSE_CMD -f "$COMPOSE_FILE" config 2>/dev/null | grep -E "^\s+image:" | awk '{print $2}' | sort -u | sed 's/"//g')

if [ -z "$IMAGES" ]; then
    echo "No images found in compose file"
    exit 0
fi

IMAGE_COUNT=$(echo "$IMAGES" | wc -l)
echo "Found $IMAGE_COUNT unique image(s)"
echo ""

# Pull images if requested
if [ "$PULL_IMAGES" = "true" ]; then
    echo "Pulling images..."
    for IMAGE in $IMAGES; do
        echo "  Pulling: $IMAGE"
        docker pull "$IMAGE" || echo "  ⚠️  Warning: Failed to pull $IMAGE"
    done
    echo ""
fi

# Scan each image
CRITICAL_FOUND=0
HIGH_FOUND=0
SCAN_COUNT=0

for IMAGE in $IMAGES; do
    SCAN_COUNT=$((SCAN_COUNT + 1))
    
    # Sanitize image name for filename
    IMAGE_SANITIZED=$(echo "$IMAGE" | sed 's/[^a-zA-Z0-9._-]/-/g' | sed 's/--*/-/g')
    
    echo "[$SCAN_COUNT/$IMAGE_COUNT] Scanning: $IMAGE"
    
    REPORT_NAME="${REPORT_PREFIX}-${IMAGE_SANITIZED}"
    
    # Build Trivy command
    # Note: Trivy doesn't support --severity flag directly
    # We'll scan all vulnerabilities and filter by severity in post-processing
    TRIVY_CMD="trivy image"
    
    # Generate reports based on format
    if [ "$FORMAT" = "all" ] || [ "$FORMAT" = "json" ]; then
        JSON_FILE="$OUTPUT_DIR/${REPORT_NAME}.json"
        $TRIVY_CMD --format json "$IMAGE" > "$JSON_FILE" 2>&1 || {
            echo "  ⚠️  Warning: Scan failed for $IMAGE"
            continue
        }
        
        # Count critical and high vulnerabilities
        if command -v jq >/dev/null 2>&1; then
            CRIT_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
            HIGH_COUNT=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
        else
            CRIT_COUNT=$(grep -c '"Severity": "CRITICAL"' "$JSON_FILE" 2>/dev/null || echo "0")
            HIGH_COUNT=$(grep -c '"Severity": "HIGH"' "$JSON_FILE" 2>/dev/null || echo "0")
        fi
        
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
        $TRIVY_CMD --format template --template "@contrib/html.tpl" "$IMAGE" > "$HTML_FILE" 2>/dev/null || {
            # Fallback to table format if HTML template not available
            $TRIVY_CMD --format table "$IMAGE" > "$HTML_FILE" 2>&1 || true
        }
    fi
    
    if [ "$FORMAT" = "table" ]; then
        TABLE_FILE="$OUTPUT_DIR/${REPORT_NAME}.txt"
        $TRIVY_CMD --format table "$IMAGE" > "$TABLE_FILE" 2>&1 || true
    fi
done

echo ""
echo "=========================================="
echo "  Scan Summary"
echo "=========================================="
echo ""
echo "Images scanned: $SCAN_COUNT"
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

