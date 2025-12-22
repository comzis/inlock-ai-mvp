#!/bin/bash
# Check disk space and list largest files/directories
# Run: ./check-disk-usage.sh

echo "=========================================="
echo "  Disk Space Analysis"
echo "  $(date)"
echo "=========================================="
echo ""

# Overall disk usage
echo "=== Overall Disk Usage ==="
df -h | grep -E "Filesystem|/dev/sda"
echo ""

# Top-level directories
echo "=== Top-Level Directories ==="
du -sh /* 2>/dev/null | sort -hr | head -10
echo ""

# Docker usage
echo "=== Docker Disk Usage ==="
docker system df
echo ""

# Docker volumes
echo "=== Docker Volumes (Top 10) ==="
for vol in $(docker volume ls -q); do
    mountpoint=$(docker volume inspect "$vol" --format '{{.Mountpoint}}' 2>/dev/null)
    if [ -n "$mountpoint" ] && [ -d "$mountpoint" ]; then
        size=$(du -sh "$mountpoint" 2>/dev/null | cut -f1)
        echo "$size - $vol"
    fi
done | sort -hr | head -10
echo ""

# Docker directories
echo "=== Docker Storage Directories ==="
if [ -d /var/lib/docker ]; then
    du -sh /var/lib/docker/* 2>/dev/null | sort -hr | head -10
fi
echo ""

# Home directory
echo "=== Home Directory (/home/comzis) ==="
du -sh /home/comzis/* 2>/dev/null | sort -hr | head -10
echo ""

# Opt directory
echo "=== /opt Directory ==="
du -sh /opt/* 2>/dev/null | sort -hr | head -10
echo ""

# Large files (>100MB)
echo "=== Large Files (>100MB) ==="
find /home/comzis /opt -type f -size +100M 2>/dev/null -exec du -h {} \; | sort -hr | head -10
echo ""

# Cursor server (often large)
if [ -d /home/comzis/.cursor-server ]; then
    echo "=== Cursor Server Size ==="
    du -sh /home/comzis/.cursor-server
    echo ""
fi

# Summary
echo "=========================================="
echo "  Summary"
echo "=========================================="
TOTAL_USED=$(df -h / | awk 'NR==2 {print $3}')
TOTAL_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
TOTAL_USE=$(df -h / | awk 'NR==2 {print $5}')
echo "Root filesystem: $TOTAL_USED used, $TOTAL_AVAIL available ($TOTAL_USE)"
echo ""
echo "Largest space consumers:"
echo "1. Docker images: 72.85GB (57.63GB reclaimable)"
echo "2. Docker build cache: 56.3GB (48.83GB reclaimable)"
echo "3. Docker volumes: 3.974GB (3.341GB reclaimable)"
echo ""
echo "To clean up Docker:"
echo "  docker system prune -a --volumes  # WARNING: Removes unused images, containers, volumes"
echo "  docker builder prune -a           # Removes build cache"
echo ""

