#!/usr/bin/env bash
# Run this script on your MacBook Pro to find the SSL certificate private key

echo "=========================================="
echo "Searching for SSL Certificate Private Key"
echo "=========================================="
echo ""

echo "Searching common locations..."
echo ""

# Search Downloads
if [ -d ~/Downloads ]; then
  echo "📁 Checking Downloads folder..."
  find ~/Downloads -maxdepth 1 -type f \( -name "*.key" -o -name "*inlock*" -o -name "*private*" -o -name "*certificate*" \) 2>/dev/null | while read file; do
    if grep -q "BEGIN.*PRIVATE KEY" "$file" 2>/dev/null; then
      echo "  ✅ FOUND: $file (contains private key)"
    else
      echo "  📄 $file (not a private key)"
    fi
  done
  echo ""
fi

# Search Desktop
if [ -d ~/Desktop ]; then
  echo "📁 Checking Desktop folder..."
  find ~/Desktop -maxdepth 1 -type f \( -name "*.key" -o -name "*inlock*" -o -name "*private*" -o -name "*certificate*" \) 2>/dev/null | while read file; do
    if grep -q "BEGIN.*PRIVATE KEY" "$file" 2>/dev/null; then
      echo "  ✅ FOUND: $file (contains private key)"
    else
      echo "  📄 $file (not a private key)"
    fi
  done
  echo ""
fi

# Search Documents
if [ -d ~/Documents ]; then
  echo "📁 Checking Documents folder..."
  find ~/Documents -maxdepth 2 -type f \( -name "*.key" -o -name "*inlock*" \) 2>/dev/null | head -10 | while read file; do
    if grep -q "BEGIN.*PRIVATE KEY" "$file" 2>/dev/null; then
      echo "  ✅ FOUND: $file (contains private key)"
    fi
  done
  echo ""
fi

echo "=========================================="
echo "If you found a .key file, transfer it with:"
echo "  scp /path/to/keyfile.key comzis@your-server:/tmp/inlock_ai.key"
echo "=========================================="



