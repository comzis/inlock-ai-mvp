#!/bin/bash
# Reset Cockpit (Linux system user) password
# Run: sudo ./scripts/reset-cockpit-password.sh [username]

set -euo pipefail

echo "=== Reset Cockpit Password ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Check if username provided
if [ $# -eq 0 ]; then
    echo "Usage: sudo $0 <username>"
    echo ""
    echo "Example: sudo $0 comzis"
    echo ""
    echo "Available system users:"
    cat /etc/passwd | grep -E "/bin/(bash|sh)" | cut -d: -f1,5 | while IFS=: read -r user name; do
        echo "  - $user"
        [ -n "$name" ] && echo "    ($name)"
    done
    exit 1
fi

USERNAME="$1"

# Verify user exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "Error: User '$USERNAME' does not exist"
    echo ""
    echo "Available users:"
    cat /etc/passwd | grep -E "/bin/(bash|sh)" | cut -d: -f1
    exit 1
fi

echo "Resetting password for user: $USERNAME"
echo ""
echo "You will be prompted to enter a new password twice."
echo ""

# Reset password
passwd "$USERNAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Password reset successfully"
    echo ""
    echo "To log into Cockpit:"
    echo "  1. Go to: https://cockpit.inlock.ai"
    echo "  2. Username: $USERNAME"
    echo "  3. Password: (the password you just set)"
else
    echo ""
    echo "✗ Password reset failed"
    exit 1
fi
echo ""

