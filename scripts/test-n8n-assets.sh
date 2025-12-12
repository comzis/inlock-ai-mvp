#!/bin/bash
# Test n8n asset loading
# Run: ./scripts/test-n8n-assets.sh

set -euo pipefail

echo "=== Testing n8n Asset Loading ==="
echo ""

# 1. Test main page
echo "1. Testing main page..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
echo "   HTTP Status: $HTTP_CODE"
echo ""

# 2. Test JavaScript files
echo "2. Testing JavaScript files..."
JS_FILES=(
    "index-qmt2pxHw.js"
    "SetupTemplateFormStep-upAeTa22.js"
    "Modal-CUSRNzxj.js"
)

for file in "${JS_FILES[@]}"; do
    echo "   Testing: $file"
    CONTENT_TYPE=$(curl -k -s -I "https://n8n.inlock.ai/assets/$file" 2>&1 | grep -i "content-type" | head -1 || echo "NOT FOUND")
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://n8n.inlock.ai/assets/$file" 2>&1 || echo "000")
    echo "     HTTP: $HTTP_CODE"
    echo "     Content-Type: $CONTENT_TYPE"
    
    if echo "$CONTENT_TYPE" | grep -qi "javascript"; then
        echo "     ✓ Correct MIME type"
    else
        echo "     ✗ Wrong or missing MIME type"
    fi
    echo ""
done

# 3. Test CSS files
echo "3. Testing CSS files..."
CSS_FILES=(
    "SetupTemplateFormStep-n3VY06cx.css"
)

for file in "${CSS_FILES[@]}"; do
    echo "   Testing: $file"
    CONTENT_TYPE=$(curl -k -s -I "https://n8n.inlock.ai/assets/$file" 2>&1 | grep -i "content-type" | head -1 || echo "NOT FOUND")
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://n8n.inlock.ai/assets/$file" 2>&1 || echo "000")
    echo "     HTTP: $HTTP_CODE"
    echo "     Content-Type: $CONTENT_TYPE"
    
    if echo "$CONTENT_TYPE" | grep -qi "css"; then
        echo "     ✓ Correct MIME type"
    else
        echo "     ✗ Wrong or missing MIME type"
    fi
    echo ""
done

# 4. Test direct from n8n
echo "4. Testing direct from n8n container..."
DIRECT_CT=$(docker exec compose-n8n-1 wget -qO- --server-response http://localhost:5678/assets/index-qmt2pxHw.js 2>&1 | grep -i "content-type" | head -1 || echo "NOT FOUND")
echo "   Direct Content-Type: $DIRECT_CT"
echo ""

# 5. Summary
echo "=== Summary ==="
echo ""
echo "If all files show correct Content-Type but browser still blocks:"
echo "  1. Clear browser cache completely"
echo "  2. Clear site data (F12 → Application → Clear storage)"
echo "  3. Unregister service workers"
echo "  4. Try incognito window"
echo ""
echo "If files show wrong/missing Content-Type:"
echo "  - Traefik middleware issue"
echo "  - Need to configure Content-Type headers"
echo ""

