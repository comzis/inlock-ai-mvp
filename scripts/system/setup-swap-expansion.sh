#!/bin/bash
# Expand Swap Space - Immediate Relief
# Adds 8 GiB swap file to provide memory buffer

set -euo pipefail

SWAPFILE="/swapfile-8gb"
SWAP_SIZE="8G"

echo "========================================="
echo "Swap Space Expansion"
echo "========================================="
echo ""
echo "⚠️  This script requires sudo/root access"
echo ""
echo "Current swap status:"
free -h
swapon --show
echo ""

# Check if swap file already exists
if [ -f "$SWAPFILE" ]; then
    echo "⚠️  Swap file $SWAPFILE already exists"
    read -p "Continue and recreate? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    # Disable existing swap file if active
    if swapon --show | grep -q "$SWAPFILE"; then
        echo "Disabling existing swap file..."
        sudo swapoff "$SWAPFILE"
    fi
    echo "Removing existing swap file..."
    sudo rm -f "$SWAPFILE"
fi

# Check available disk space
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 8 ]; then
    echo "❌ Error: Insufficient disk space. Need 8GB, have ${AVAILABLE_SPACE}GB"
    exit 1
fi

echo "Creating ${SWAP_SIZE} swap file..."
echo "This may take a few minutes..."

# Create swap file
sudo fallocate -l "$SWAP_SIZE" "$SWAPFILE"

# Set secure permissions
sudo chmod 600 "$SWAPFILE"

# Format as swap
echo "Formatting swap file..."
sudo mkswap "$SWAPFILE"

# Enable swap
echo "Enabling swap..."
sudo swapon "$SWAPFILE"

# Make permanent
if ! grep -q "$SWAPFILE" /etc/fstab; then
    echo "Adding to /etc/fstab for persistence..."
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
else
    echo "⚠️  Swap file already in /etc/fstab"
fi

echo ""
echo "========================================="
echo "✅ Swap Expansion Complete"
echo "========================================="
echo ""
echo "New swap status:"
free -h
swapon --show
echo ""
echo "Swap file location: $SWAPFILE"
echo "Swap size: ${SWAP_SIZE}"
echo ""
echo "⚠️  Note: Swap is slower than RAM. This is temporary relief."
echo "    Plan to upgrade RAM to 24-32 GiB for long-term solution."
