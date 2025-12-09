#!/bin/bash
# Interactive script to generate GPG key for admin@inlock.ai

set -e

echo "=========================================="
echo "GPG KEY GENERATION FOR admin@inlock.ai"
echo "=========================================="
echo ""

# Check if key already exists
if gpg --list-keys admin@inlock.ai > /dev/null 2>&1; then
    echo "⚠️  GPG key already exists for admin@inlock.ai"
    echo ""
    gpg --list-keys admin@inlock.ai
    echo ""
    read -p "Do you want to generate a new key anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Use existing key or delete it first."
        exit 0
    fi
fi

echo "This will generate a new GPG key with:"
echo "  - Type: RSA and RSA"
echo "  - Size: 4096 bits"
echo "  - Email: admin@inlock.ai"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Generating GPG key (this may take a few minutes)..."
echo ""

# Generate key with batch mode
cat > /tmp/gpg-batch.txt << 'BATCH_EOF'
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: INLOCK Admin
Name-Email: admin@inlock.ai
Expire-Date: 0
%commit
BATCH_EOF

gpg --batch --generate-key /tmp/gpg-batch.txt
rm -f /tmp/gpg-batch.txt

echo ""
echo "✅ GPG key generated successfully!"
echo ""
gpg --list-keys admin@inlock.ai

echo ""
echo "Exporting public key to ~/admin-inlock-ai.pub..."
gpg --armor --export admin@inlock.ai > ~/admin-inlock-ai.pub

echo "✅ Public key exported to: ~/admin-inlock-ai.pub"
echo ""
echo "The key is now ready for backups. You can verify with:"
echo "  ./scripts/check-backup-readiness.sh"
