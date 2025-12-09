#!/bin/bash
# Verify container hardening compliance

set -e

echo "=========================================="
echo "CONTAINER HARDENING VERIFICATION"
echo "=========================================="
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

# Check image digests
echo "Checking image digests..."
for compose_file in "$REPO_DIR"/compose/*.yml; do
    if grep -q "image:" "$compose_file"; then
        while IFS= read -r line; do
            if [[ "$line" =~ image:.*:latest ]] && [[ ! "$line" =~ @sha256 ]]; then
                echo "  ❌ Unpinned image found: $line"
                ((ERRORS++))
            elif [[ "$line" =~ @sha256 ]]; then
                echo "  ✅ Pinned image: $(echo "$line" | grep -oE '[^/]+@sha256:[a-f0-9]+')"
            fi
        done < <(grep "image:" "$compose_file")
    fi
done

echo ""
echo "Checking non-root users..."
if grep -q 'user:' "$REPO_DIR"/compose/*.yml; then
    echo "  ✅ Non-root users configured:"
    grep -h "user:" "$REPO_DIR"/compose/*.yml | sed 's/^/    /'
else
    echo "  ⚠️  No explicit user configuration (some services may require root)"
    ((WARNINGS++))
fi

echo ""
echo "Checking capability dropping..."
if grep -q "cap_drop:" "$REPO_DIR"/compose/*.yml; then
    echo "  ✅ Capability dropping configured:"
    grep -A 1 "cap_drop:" "$REPO_DIR"/compose/*.yml | grep -E "cap_drop:|ALL" | head -5 | sed 's/^/    /'
else
    echo "  ❌ No capability dropping found"
    ((ERRORS++))
fi

echo ""
echo "Checking read-only filesystems..."
if grep -q "read_only:" "$REPO_DIR"/compose/*.yml; then
    echo "  ✅ Read-only filesystems configured:"
    grep -B 1 "read_only:" "$REPO_DIR"/compose/*.yml | grep -E "services:|read_only" | head -4 | sed 's/^/    /'
else
    echo "  ⚠️  No read-only filesystems (may be intentional for writable services)"
    ((WARNINGS++))
fi

echo ""
echo "Checking tmpfs usage..."
if grep -q "tmpfs:" "$REPO_DIR"/compose/*.yml; then
    echo "  ✅ tmpfs configured:"
    grep -B 1 -A 2 "tmpfs:" "$REPO_DIR"/compose/*.yml | head -10 | sed 's/^/    /'
else
    echo "  ⚠️  No tmpfs configured (may be intentional)"
    ((WARNINGS++))
fi

echo ""
echo "Checking no-new-privileges..."
if grep -q "no-new-privileges" "$REPO_DIR"/compose/*.yml; then
    echo "  ✅ no-new-privileges configured"
else
    echo "  ❌ no-new-privileges not found"
    ((ERRORS++))
fi

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "=========================================="
    echo "✅ ALL CHECKS PASSED"
    echo "=========================================="
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "=========================================="
    echo "⚠️  $WARNINGS WARNING(S) (non-critical)"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "❌ FOUND $ERRORS ISSUE(S), $WARNINGS WARNING(S)"
    echo "=========================================="
    exit 1
fi
