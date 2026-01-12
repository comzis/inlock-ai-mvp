#!/bin/bash
# Setup pre-commit hooks for security and code quality
# Requires Node.js 20+ to be installed locally
#
# Usage: ./scripts/setup-pre-commit.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "========================================="
echo "Pre-commit Hooks Setup"
echo "========================================="
echo ""

# Check if Node.js is available
if ! command -v node &> /dev/null; then
  echo "❌ ERROR: Node.js not found"
  echo ""
  echo "Install Node.js 20 first:"
  echo "  Option 1: nvm install 20"
  echo "  Option 2: See docs/NODE-JS-SETUP.md"
  exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo "❌ ERROR: Node.js 18+ required (found v$NODE_VERSION)"
  exit 1
fi

echo "✅ Node.js $(node -v) found"
echo ""

# Install dependencies
echo "📦 Installing Husky and lint-staged..."
npm install --save-dev husky lint-staged

# Initialize Husky
echo ""
echo "🔧 Initializing Husky..."
npx husky init

# Create pre-commit hook
echo ""
echo "📝 Creating pre-commit hook..."
cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🔍 Running pre-commit checks..."

# Run lint-staged (runs linters on staged files)
echo "  → Running lint-staged..."
npx lint-staged

# Run tests (non-blocking, but will show warnings)
echo "  → Running tests..."
npm test -- --bail --findRelatedTests || echo "⚠️  Some tests failed - review before committing"

# Security audit (non-blocking, but shows warnings)
echo "  → Running security audit..."
npm audit --audit-level=moderate || echo "⚠️  Security audit warnings found - review manually"

echo "✅ Pre-commit checks complete"
EOF

chmod +x .husky/pre-commit

# Configure lint-staged
echo ""
echo "📝 Configuring lint-staged..."

# Check if package.json has lint-staged config
if ! grep -q '"lint-staged"' package.json; then
  # Add lint-staged config using jq if available, or manual edit
  if command -v jq &> /dev/null; then
    TMP=$(mktemp)
    jq '. + {"lint-staged": {
      "*.{js,jsx,ts,tsx}": [
        "eslint --fix",
        "prettier --write"
      ],
      "*.{json,md,yml,yaml}": [
        "prettier --write"
      ]
    }}' package.json > "$TMP" && mv "$TMP" package.json
  else
    echo "⚠️  jq not found - manually add lint-staged config to package.json:"
    echo ""
    echo '  "lint-staged": {'
    echo '    "*.{js,jsx,ts,tsx}": ['
    echo '      "eslint --fix",'
    echo '      "prettier --write"'
    echo '    ],'
    echo '    "*.{json,md,yml,yaml}": ['
    echo '      "prettier --write"'
    echo '    ]'
    echo '  }'
    echo ""
  fi
fi

# Install prettier if not already installed
if ! npm list prettier &> /dev/null; then
  echo ""
  echo "📦 Installing Prettier..."
  npm install --save-dev prettier
fi

echo ""
echo "========================================="
echo "✅ Pre-commit hooks setup complete!"
echo "========================================="
echo ""
echo "Hooks will run automatically on:"
echo "  - git commit (pre-commit)"
echo ""
echo "To test:"
echo "  git add ."
echo "  git commit -m 'test'"
echo ""
echo "To bypass hooks (not recommended):"
echo "  git commit --no-verify"
echo ""

