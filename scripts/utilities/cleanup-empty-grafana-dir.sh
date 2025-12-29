#!/bin/bash
# Cleanup script to remove empty compose/grafana directory
# This directory is unused - Grafana configs correctly live in config/grafana/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

# Check if directory exists
if [ -d "compose/grafana" ]; then
    echo "Found empty compose/grafana directory"
    
    # Check if it's actually empty (only contains empty subdirectories)
    if [ -z "$(find compose/grafana -type f 2>/dev/null)" ]; then
        echo "Directory is empty - removing..."
        sudo rm -rf compose/grafana
        echo "✅ Successfully removed compose/grafana directory"
    else
        echo "⚠️  Directory contains files - please check manually"
        find compose/grafana -type f
        exit 1
    fi
else
    echo "✅ compose/grafana directory does not exist (already cleaned up)"
fi

# Verify removal
if [ ! -d "compose/grafana" ]; then
    echo "✅ Verification: Directory successfully removed"
else
    echo "❌ Verification: Directory still exists"
    exit 1
fi

