#!/bin/bash
# Validate project structure against .cursorrules
# This script checks that the project follows the defined structure

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

ERRORS=0
WARNINGS=0

echo "=== Validating Project Structure ==="
echo ""

# Check required directories
echo "Checking required directories..."
required_dirs=(
    "compose/services"
    "config/traefik"
    "traefik/dynamic"
    "docs/architecture"
    "docs/deployment"
    "docs/guides"
    "docs/security"
    "docs/services"
    "scripts"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Missing directory: $dir"
        ((ERRORS++))
    else
        echo "✅ Found: $dir"
    fi
done

echo ""

# Check for .cursorrules files
echo "Checking cursor rules files..."
if [ ! -f ".cursorrules" ]; then
    echo "❌ Missing: .cursorrules"
    ((ERRORS++))
else
    echo "✅ Found: .cursorrules"
fi

if [ ! -f ".cursorrules-security" ]; then
    echo "❌ Missing: .cursorrules-security"
    ((ERRORS++))
else
    echo "✅ Found: .cursorrules-security"
fi

echo ""

# Check for .env in git (should be ignored)
echo "Checking .env file..."
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    echo "❌ ERROR: .env is tracked in git (should be in .gitignore)"
    ((ERRORS++))
else
    echo "✅ .env is properly ignored"
fi

echo ""

# Check compose stack file
echo "Checking compose structure..."
if [ ! -f "compose/services/stack.yml" ]; then
    echo "❌ Missing: compose/services/stack.yml"
    ((ERRORS++))
else
    echo "✅ Found: compose/services/stack.yml"
    
    # Validate compose config
    if command -v docker >/dev/null 2>&1; then
        if docker compose -f compose/services/stack.yml config >/dev/null 2>&1; then
            echo "✅ Compose config is valid"
        else
            echo "⚠️  WARNING: Compose config has issues (run 'docker compose -f compose/services/stack.yml config' for details)"
            ((WARNINGS++))
        fi
    else
        echo "⚠️  WARNING: Docker not available, skipping compose validation"
        ((WARNINGS++))
    fi
fi

echo ""

# Check for documentation organization
echo "Checking documentation organization..."
docs_in_root=$(find docs -maxdepth 1 -name "*.md" -type f | wc -l)
if [ "$docs_in_root" -gt 5 ]; then
    echo "⚠️  WARNING: $docs_in_root markdown files in docs/ root (should be in subdirectories)"
    ((WARNINGS++))
else
    echo "✅ Documentation is well organized"
fi

echo ""

# Check for secrets in repo
echo "Checking for secrets..."
if find . -name "*.key" -o -name "*.pem" -o -name "*password*" -o -name "*secret*" | grep -v ".git" | grep -v "node_modules" | grep -v ".example" | head -1 | grep -q .; then
    echo "⚠️  WARNING: Potential secret files found (check .gitignore)"
    ((WARNINGS++))
else
    echo "✅ No obvious secret files in repository"
fi

echo ""

# Summary
echo "=== Validation Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Validation passed with warnings"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi






