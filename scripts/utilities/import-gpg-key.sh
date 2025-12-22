#!/bin/bash
# Helper script to import GPG public key for admin@inlock.ai
# Usage: ./scripts/import-gpg-key.sh /path/to/admin-inlock-ai.pub

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-gpg-public-key-file>"
    echo ""
    echo "This script imports a GPG public key for admin@inlock.ai"
    echo "which is required for encrypted backups."
    echo ""
    echo "Example:"
    echo "  $0 ~/admin-inlock-ai.pub"
    exit 1
fi

KEY_FILE="$1"

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file not found: $KEY_FILE"
    exit 1
fi

echo "Importing GPG public key from: $KEY_FILE"
gpg --import "$KEY_FILE"

echo ""
echo "Verifying key import..."
gpg --list-keys admin@inlock.ai

echo ""
echo "✅ GPG key imported successfully!"
echo "You can now run encrypted backups with: ./scripts/backup-volumes.sh"
