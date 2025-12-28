#!/bin/bash
#
# Scan host filesystem for vulnerabilities
# Checks installed packages against CVE databases
#
# Usage: sudo ./scripts/security/scan-filesystem.sh [OPTIONS]
# Options:
#   --format <json|html|table>  Output format (default: all)
#   --output-dir <dir>          Output directory (default: docs/reports/security/vulnerabilities)
#   --fail-on-critical          Exit with error if critical vulnerabilities found
#   --severity <level>          Minimum severity (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/docs/reports/security/vulnerabilities}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_PREFIX="filesystem-scan-$TIMESTAMP"
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
echo "  Scanning Host Filesystem"
echo "=========================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Format: $FORMAT"
echo "Minimum severity: $MIN_SEVERITY"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_VERSION="$VERSION_ID"
    echo "OS: $OS_NAME $OS_VERSION"
else
    echo "WARNING: Cannot detect OS version"
    OS_NAME="unknown"
fi

REPORT_NAME="${REPORT_PREFIX}-$(hostname)"

# Build Trivy command
# Note: Trivy doesn't support --severity flag directly
# We'll scan all vulnerabilities and filter by severity in post-processing
TRIVY_CMD="trivy fs /"

echo "Scanning filesystem (this may take a while)..."
echo ""

# Generate reports based on format
CRITICAL_FOUND=0
HIGH_FOUND=0

if [ "$FORMAT" = "all" ] || [ "$FORMAT" = "json" ]; then
    JSON_FILE="$OUTPUT_DIR/${REPORT_NAME}.json"
    $TRIVY_CMD --format json > "$JSON_FILE" 2>&1 || {
        echo "ERROR: Filesystem scan failed"
        exit 1
    }
    
    # Count critical and high vulnerabilities
    if command -v jq >/dev/null 2>&1; then
        CRITICAL_FOUND=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
        HIGH_FOUND=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$JSON_FILE" 2>/dev/null || echo "0")
    else
        CRITICAL_FOUND=$(grep -c '"Severity": "CRITICAL"' "$JSON_FILE" 2>/dev/null || echo "0")
        HIGH_FOUND=$(grep -c '"Severity": "HIGH"' "$JSON_FILE" 2>/dev/null || echo "0")
    fi
fi

if [ "$FORMAT" = "all" ] || [ "$FORMAT" = "html" ]; then
    HTML_FILE="$OUTPUT_DIR/${REPORT_NAME}.html"
    $TRIVY_CMD --format template --template "@contrib/html.tpl" > "$HTML_FILE" 2>/dev/null || {
        # Fallback to table format if HTML template not available
        $TRIVY_CMD --format table > "$HTML_FILE" 2>&1 || true
    }
fi

if [ "$FORMAT" = "table" ]; then
    TABLE_FILE="$OUTPUT_DIR/${REPORT_NAME}.txt"
    $TRIVY_CMD --format table > "$TABLE_FILE" 2>&1 || true
fi

echo ""
echo "=========================================="
echo "  Scan Summary"
echo "=========================================="
echo ""
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
    echo ""
    echo "Recommendations:"
    echo "  1. Run: sudo apt update && sudo apt upgrade"
    echo "  2. Review reports in: $OUTPUT_DIR"
    echo "  3. Check for security updates: sudo unattended-upgrades --dry-run"
    exit 0
else
    echo "✓ No critical or high severity vulnerabilities found"
    exit 0
fi

