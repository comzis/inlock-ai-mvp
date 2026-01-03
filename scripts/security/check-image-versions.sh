#!/bin/bash
# Check for :latest tags and outdated image versions in compose files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Image Version Check ==="
echo ""

ERRORS=0
WARNINGS=0

# Check for :latest tags in production files
echo "Checking for :latest tags in production files..."
echo ""

LATEST_TAGS=$(grep -r "image:.*:latest" "$PROJECT_ROOT/compose/services"/*.yml 2>/dev/null | grep -v "docker-compose.local.yml" | grep -v "#" || true)

if [ -n "$LATEST_TAGS" ]; then
    echo -e "${RED}❌ Found :latest tags in production files:${NC}"
    echo "$LATEST_TAGS" | while IFS= read -r line; do
        echo "  $line"
        ERRORS=$((ERRORS + 1))
    done
    echo ""
else
    echo -e "${GREEN}✅ No :latest tags in production files${NC}"
    echo ""
fi

# Check docker-compose.local.yml separately (allowed but should be noted)
LOCAL_LATEST=$(grep "image:.*:latest" "$PROJECT_ROOT/compose/services/docker-compose.local.yml" 2>/dev/null | grep -v "#" || true)
if [ -n "$LOCAL_LATEST" ]; then
    echo -e "${YELLOW}⚠️  :latest tags found in docker-compose.local.yml (allowed for dev)${NC}"
    echo "$LOCAL_LATEST" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
fi

# Check for commented :latest tags (should be updated)
COMMENTED_LATEST=$(grep -r "#.*:latest" "$PROJECT_ROOT/compose/services"/*.yml 2>/dev/null || true)
if [ -n "$COMMENTED_LATEST" ]; then
    echo -e "${YELLOW}⚠️  Found commented :latest tags (consider updating):${NC}"
    echo "$COMMENTED_LATEST" | while IFS= read -r line; do
        echo "  $line"
        WARNINGS=$((WARNINGS + 1))
    done
    echo ""
fi

# Summary
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) found, $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please update compose files to use specific version tags or SHA256 digests."
    echo "See docs/security/IMAGE-VERSION-POLICY.md for details."
    exit 1
fi

