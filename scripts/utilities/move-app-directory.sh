#!/bin/bash
# Move application directory (legacy script - directory already moved)
# This script renames and moves the directory to a cleaner path

set -e

OLD_PATH="/opt/inlock-ai-secure-mvp"
NEW_PATH="/opt/inlock-ai-secure-mvp"
OLD_PARENT="/opt/inlock-ai-secure-mvp"
BACKUP_PATH="/tmp/inlock-ai-secure-mvp-old-backup"

echo "========================================="
echo "Moving Application Directory"
echo "========================================="
echo ""
echo "This will:"
echo "  1. Move $OLD_PATH → $NEW_PATH"
echo "  2. Backup old parent directory to $BACKUP_PATH"
echo "  3. Update all configuration references"
echo ""

# Check if old path exists
if [ ! -d "$OLD_PATH" ]; then
    echo "❌ ERROR: Source directory not found: $OLD_PATH"
    exit 1
fi

# Check if new path already exists
if [ -d "$NEW_PATH" ]; then
    echo "⚠️  WARNING: Destination already exists: $NEW_PATH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

echo "Step 1: Moving directory..."
sudo mv "$OLD_PATH" "$NEW_PATH" || {
    echo "❌ Failed to move directory. Please run manually:"
    echo "   sudo mv $OLD_PATH $NEW_PATH"
    exit 1
}

echo "  ✅ Directory moved: $NEW_PATH"

echo ""
echo "Step 2: Backing up old parent directory..."
if [ -d "$OLD_PARENT" ] && [ -z "$(ls -A "$OLD_PARENT" 2>/dev/null)" ]; then
    sudo mv "$OLD_PARENT" "$BACKUP_PATH" || {
        echo "  ⚠️  Warning: Could not backup old parent directory"
    }
    echo "  ✅ Old directory backed up to: $BACKUP_PATH"
else
    echo "  ℹ️  Old parent directory not empty or doesn't exist, skipping backup"
fi

echo ""
echo "Step 3: Setting ownership..."
sudo chown -R comzis:comzis "$NEW_PATH" || {
    echo "  ⚠️  Warning: Could not set ownership"
}

echo ""
echo "========================================="
echo "✅ Directory Move Complete!"
echo "========================================="
echo ""
echo "New location: $NEW_PATH"
echo ""
echo "Next steps:"
echo "  1. Verify application: ls -la $NEW_PATH"
echo "  2. Rebuild Docker image: cd $NEW_PATH && docker build -t inlock-ai:latest ."
echo "  3. Redeploy: cd /home/comzis/inlock-infra && docker compose -f compose/stack.yml --env-file .env up -d inlock-ai"
echo ""

