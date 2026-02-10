#!/bin/bash
# Mailcow Admin Login Script
# Attempts to login to mailcow admin panel via curl

set -euo pipefail

COOKIE_FILE="/tmp/mailcow_admin_cookies.txt"
BASE_URL="https://mail.inlock.ai"
ADMIN_URL="${BASE_URL}/admin"

# Default credentials (may have been changed)
USERNAME="${1:-admin}"
PASSWORD="${2:-moohoo}"

echo "=== Mailcow Admin Login ==="
echo "URL: $ADMIN_URL"
echo "Username: $USERNAME"
echo ""

# Clean up old cookies
rm -f "$COOKIE_FILE"

# Step 1: Get initial session cookie
echo "1. Getting session cookie..."
curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" "$ADMIN_URL" > /dev/null 2>&1

if [ ! -f "$COOKIE_FILE" ]; then
    echo "Error: Failed to get initial session"
    exit 1
fi

echo "✓ Session cookie obtained"
echo ""

# Step 2: Attempt login
echo "2. Attempting login..."
RESPONSE=$(curl -s -L -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    -X POST \
    -d "login_user=${USERNAME}" \
    -d "pass_user=${PASSWORD}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: ${ADMIN_URL}" \
    "$ADMIN_URL" 2>&1)

# Step 3: Check if login was successful
if echo "$RESPONSE" | grep -qi "Administrator Login"; then
    echo "✗ Login failed - still showing login page"
    echo ""
    echo "Possible reasons:"
    echo "  - Password is incorrect (default was 'moohoo')"
    echo "  - Account may be locked"
    echo "  - CSRF token required"
    echo ""
    echo "Try with different password:"
    echo "  $0 admin YOUR_PASSWORD"
    exit 1
elif echo "$RESPONSE" | grep -qiE "dashboard|Mail Queue|System|Settings"; then
    echo "✓ Login successful!"
    echo ""
    echo "Session cookies saved to: $COOKIE_FILE"
    echo ""
    echo "You can now use this cookie file for authenticated requests:"
    echo "  curl -b $COOKIE_FILE $BASE_URL/admin"
    exit 0
else
    echo "? Unknown response - checking cookies..."
    if [ -f "$COOKIE_FILE" ]; then
        echo "Cookies saved:"
        cat "$COOKIE_FILE" | grep -v "^#" | head -5
    fi
    echo ""
    echo "Full response (first 200 chars):"
    echo "$RESPONSE" | head -c 200
    echo "..."
    exit 1
fi
