#!/bin/bash
#
# Disable passwordless sudo for Coolify
# Removes the limited sudo configuration
#
# Usage: sudo ./scripts/infrastructure/disable-coolify-sudo.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/coolify-comzis"

echo "=========================================="
echo "  Disabling Coolify Passwordless Sudo"
echo "=========================================="
echo ""

if [ -f "$SUDOERS_FILE" ]; then
    echo "Removing sudoers file: $SUDOERS_FILE"
    rm -f "$SUDOERS_FILE"
    echo "✓ Sudoers file removed"
    
    echo ""
    echo "Passwordless sudo for Coolify has been disabled"
    echo "All sudo commands will now require a password"
else
    echo "✓ Sudoers file does not exist (already disabled)"
fi

echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""

if [ -f "$SUDOERS_FILE" ]; then
    echo "⚠️  Warning: File still exists at $SUDOERS_FILE"
else
    echo "✓ Passwordless sudo configuration removed"
fi

echo ""
echo "To test (should require password now):"
echo "  sudo -n /usr/bin/docker ps    # Should fail (password required)"







