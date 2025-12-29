#!/bin/bash
# Reorganize documentation files according to .cursorrules
# This script uses git mv to preserve history

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

echo "=== Reorganizing Documentation Files ==="

# Create missing directories
mkdir -p docs/services/portainer
mkdir -p docs/services/cockpit
mkdir -p docs/reports/incidents

# Function to safely move files
move_file() {
    local src=$1
    local dest=$2
    if [ -f "$src" ]; then
        echo "Moving: $src -> $dest"
        git mv "$src" "$dest" 2>/dev/null || mv "$src" "$dest"
    else
        echo "Skipping (not found): $src"
    fi
}

# Move security docs
echo "Moving security documentation..."
move_file "docs/ACCESS-CONTROL-VALIDATION.md" "docs/security/ACCESS-CONTROL-VALIDATION.md"
move_file "docs/CLOUDFLARE-IP-ALLOWLIST.md" "docs/security/CLOUDFLARE-IP-ALLOWLIST.md"
move_file "docs/PORT-RESTRICTION-SUMMARY.md" "docs/security/PORT-RESTRICTION-SUMMARY.md"

# Move guides
echo "Moving guides..."
move_file "docs/ADDING-NEW-SERVICE.md" "docs/guides/ADDING-NEW-SERVICE.md"
move_file "docs/AUTOMATION-SCRIPTS.md" "docs/guides/AUTOMATION-SCRIPTS.md"
move_file "docs/CREDENTIALS-RECOVERY.md" "docs/guides/CREDENTIALS-RECOVERY.md"
move_file "docs/INLOCK-AI-QUICK-START.md" "docs/guides/INLOCK-AI-QUICK-START.md"
move_file "docs/INLOCK-CONTENT-MANAGEMENT.md" "docs/guides/INLOCK-CONTENT-MANAGEMENT.md"
move_file "docs/NODE-JS-DOCKER-ONLY.md" "docs/guides/NODE-JS-DOCKER-ONLY.md"
move_file "docs/ORPHAN-CONTAINER-CLEANUP.md" "docs/guides/ORPHAN-CONTAINER-CLEANUP.md"
move_file "docs/QUICK-ACTION-CHECKLIST.md" "docs/guides/QUICK-ACTION-CHECKLIST.md"
move_file "docs/RUN-DIAGNOSTICS.md" "docs/guides/RUN-DIAGNOSTICS.md"
move_file "docs/SECRET-MANAGEMENT.md" "docs/guides/SECRET-MANAGEMENT.md"
move_file "docs/SERVER-UPDATE-SCHEDULE.md" "docs/guides/SERVER-UPDATE-SCHEDULE.md"
move_file "docs/WEBSITE-LAUNCH-CHECKLIST.md" "docs/guides/WEBSITE-LAUNCH-CHECKLIST.md"
move_file "docs/WORKFLOW-BEST-PRACTICES.md" "docs/guides/WORKFLOW-BEST-PRACTICES.md"

# Move reports
echo "Moving reports..."
move_file "docs/DEVELOPMENT-STATUS-UPDATE.md" "docs/reports/DEVELOPMENT-STATUS-UPDATE.md"
move_file "docs/DEVOPS-TOOLS-STATUS.md" "docs/reports/DEVOPS-TOOLS-STATUS.md"
move_file "docs/EXECUTION-REPORT-2025-12-13.md" "docs/reports/EXECUTION-REPORT-2025-12-13.md"
move_file "docs/EXEC-COMMS-STATUS.md" "docs/reports/EXEC-COMMS-STATUS.md"
move_file "docs/FEATURE-TEST-RESULTS.md" "docs/reports/FEATURE-TEST-RESULTS.md"
move_file "docs/FINAL-DEPLOYMENT-STATUS.md" "docs/reports/FINAL-DEPLOYMENT-STATUS.md"
move_file "docs/FINAL-REVIEW-SUMMARY.md" "docs/reports/FINAL-REVIEW-SUMMARY.md"
move_file "docs/QUICK-ACTION-STATUS.md" "docs/reports/QUICK-ACTION-STATUS.md"
move_file "docs/VERIFICATION-REPORT.md" "docs/reports/VERIFICATION-REPORT.md"
move_file "docs/VERIFICATION-SUMMARY.md" "docs/reports/VERIFICATION-SUMMARY.md"

# Move SWARM reports
echo "Moving SWARM reports..."
for file in docs/SWARM-*.md; do
    if [ -f "$file" ]; then
        move_file "$file" "docs/reports/$(basename "$file")"
    fi
done

# Move architecture docs
echo "Moving architecture documentation..."
move_file "docs/SERVER-STRUCTURE-ANALYSIS.md" "docs/architecture/SERVER-STRUCTURE-ANALYSIS.md"

# Move service-specific docs
echo "Moving service-specific documentation..."
move_file "docs/PORTAINER-ACCESS.md" "docs/services/portainer/PORTAINER-ACCESS.md"
move_file "docs/PORTAINER-PASSWORD-RECOVERY.md" "docs/services/portainer/PORTAINER-PASSWORD-RECOVERY.md"

# Move Cockpit docs
for file in docs/COCKPIT-*.md; do
    if [ -f "$file" ]; then
        move_file "$file" "docs/services/cockpit/$(basename "$file")"
    fi
done

# Move incident reports
echo "Moving incident reports..."
for file in docs/STRIKE-TEAM-*.md; do
    if [ -f "$file" ]; then
        move_file "$file" "docs/reports/incidents/$(basename "$file")"
    fi
done

# Move reference/guides
move_file "docs/cloudflare-token-fix.md" "docs/guides/CLOUDFLARE-TOKEN-FIX.md"

# Move monitoring to services
move_file "docs/monitoring.md" "docs/services/monitoring/MONITORING.md"

echo ""
echo "=== Reorganization Complete ==="
echo "Review changes with: git status"
echo "Commit with: git commit -m 'docs: reorganize documentation per cursor rules'"






