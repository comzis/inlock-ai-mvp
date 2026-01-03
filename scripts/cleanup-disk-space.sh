#!/usr/bin/env bash
set -euo pipefail

# Disk cleanup script for INLOCK infrastructure
# Cleans up Docker resources, journal logs, and old backups

echo "=== INLOCK Disk Cleanup Script ==="
echo ""

# Check current disk usage
echo "Current disk usage:"
df -h / | tail -1
echo ""

# 1. Clean up journal logs (keep 7 days)
echo "1. Cleaning journal logs (keeping last 7 days)..."
sudo journalctl --vacuum-time=7d
echo "✅ Journal logs cleaned"
echo ""

# 2. Remove old backup files (older than 30 days, or failed backups < 10KB older than 1 day)
echo "2. Cleaning old backup files..."
BACKUP_DIR="${HOME}/backups"
if [ -d "$BACKUP_DIR" ]; then
    # Remove backups older than 30 days
    find "$BACKUP_DIR" -type f \( -name "*.gpg" -o -name "*.tar.gz" \) -mtime +30 -delete
    echo "   Removed backups older than 30 days"
    
    # Remove failed backups (< 10KB, older than 1 day)
    find "$BACKUP_DIR" -type f \( -name "*.gpg" -o -name "*.tar.gz" \) -size -10k -mtime +1 -delete
    echo "   Removed failed backups (< 10KB, older than 1 day)"
fi
echo "✅ Backup cleanup completed"
echo ""

# 3. Docker system prune (unused images, containers, networks)
echo "3. Pruning unused Docker resources..."
docker system prune -f --filter "until=168h" 2>&1 | tail -5
echo "✅ Docker system prune completed"
echo ""

# 4. Final disk usage
echo "Final disk usage:"
df -h / | tail -1
echo ""

echo "=== Cleanup completed ==="

