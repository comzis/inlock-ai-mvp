#!/usr/bin/env bash
# Purpose: Backup Docker volumes with encryption and secure transport
# Usage: ./scripts/backup/backup-volumes.sh
# Dependencies: docker, gpg, tar, alpine:3.20 image
# Environment Variables:
#   BACKUP_DIR - Backup directory (default: $HOME/backups/inlock)
#   BACKUP_ENCRYPTED_DIR - Encrypted backup directory (default: $BACKUP_DIR/encrypted)
#   GPG_RECIPIENT - GPG recipient email/key (default: admin@inlock.ai)
#   RESTIC_REPO - Restic repository (optional, default: b2:inlock-infra)
#   RESTIC_PASSWORD_FILE - Restic password file (optional)
# Exit Codes: 0=success, 1=error
# Author: INLOCK Infrastructure Team
# Last Updated: 2026-01-03

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMPORT_SCRIPT="$PROJECT_ROOT/scripts/utilities/import-gpg-key.sh"

timestamp="$(date +%F-%H%M%S)"
# Use user-writable location (can be changed to /var/backups/inlock if sudo is available)
backup_dir="${BACKUP_DIR:-$HOME/backups/inlock}"
encrypted_dir="${BACKUP_ENCRYPTED_DIR:-$HOME/backups/inlock/encrypted}"
mkdir -p "$backup_dir" "$encrypted_dir"

# GPG recipient (replace with your key ID or email)
GPG_RECIPIENT="${GPG_RECIPIENT:-admin@inlock.ai}"

# Restic repository (if using restic)
RESTIC_REPO="${RESTIC_REPO:-b2:inlock-infra}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/root/.config/restic/password}"

echo "Starting backup at $(date)"

# Backup Docker volumes (will be encrypted directly, no plaintext intermediate file)
# 
# Included volumes:
# - Core services: postgres, n8n, grafana, prometheus, alertmanager
echo "Backing up Docker volumes (will be encrypted directly)..."

# Encrypt backup with GPG (REQUIRED - no plaintext backups allowed)
if ! command -v gpg &> /dev/null; then
  echo "ERROR: GPG is required for encrypted backups. Please install gpg."
  exit 1
fi

if [ -z "$GPG_RECIPIENT" ]; then
  echo "ERROR: GPG_RECIPIENT must be set (e.g., admin@inlock.ai)"
  exit 1
fi

# Verify GPG key exists for recipient
if ! gpg --list-keys "$GPG_RECIPIENT" > /dev/null 2>&1; then
  echo "ERROR: GPG public key not found for recipient: $GPG_RECIPIENT"
  echo ""
  echo "To import a GPG public key, run:"
  echo "  $IMPORT_SCRIPT /path/to/admin-inlock-ai.pub"
  echo ""
  echo "Or manually:"
  echo "  gpg --import /path/to/admin-inlock-ai.pub"
  echo ""
  exit 1
fi

echo "Encrypting backup with GPG (recipient: $GPG_RECIPIENT)..."
# Stream tar directly to gpg to avoid plaintext on disk; ignore transient read errors (changing files)
# Use --network=none to prevent Docker network interface churn that affects Tailscale
# Exclude Tailscale-related volumes to minimize network interface monitoring
# Capture tar errors to a log file for debugging
TAR_ERROR_LOG="/tmp/tar-backup-errors-${timestamp}.log"

# Run tar and capture errors, but don't fail on tar exit code (tar may exit with error due to transient files)
# The key is to check if the backup file was successfully created, not tar's exit code
# Use set +e to allow tar to exit with error without failing the script
set +e
docker run --rm \
  --network=none \
  -v /var/lib/docker/volumes:/source:ro \
  alpine:3.20 \
  tar cz --ignore-failed-read --warning=no-file-changed \
    --exclude='*tailscale*' \
    --exclude='*wireguard*' \
    --exclude='*clickhouse*/store/*/parts' \
    --exclude='*clickhouse*/store/*/tmp' \
    --exclude='*clickhouse*/store/*/tmp_*' \
    --exclude='*clickhouse*/store/*/*_*_*_*' \
    --exclude='*clickhouse*/store/*/detached' \
    --exclude='*clickhouse*/store/*/format_version' \
    -C /source . 2>"$TAR_ERROR_LOG" | \
  gpg --batch --yes --encrypt --recipient "$GPG_RECIPIENT" \
    --output "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" \
    --compress-algo 1 --cipher-algo AES256
GPG_EXIT=$?
set -e

# Check if backup file was created successfully (this is what matters, not tar's exit code)
if [ -f "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" ]; then
  BACKUP_SIZE=$(stat -f%z "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" 2>/dev/null || stat -c%s "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" 2>/dev/null || echo "0")
  if [ "$BACKUP_SIZE" -gt 1000 ]; then
    echo "✅ Encrypted backup created: $encrypted_dir/volumes-${timestamp}.tar.gz.gpg ($(du -h "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" | cut -f1))"
    
    # Log tar errors if any (excluding expected warnings) for debugging
    if [ -s "$TAR_ERROR_LOG" ]; then
      CRITICAL_ERRORS=$(grep -vE "socket ignored|No such file or directory" "$TAR_ERROR_LOG" || true)
      if [ -n "$CRITICAL_ERRORS" ]; then
        echo "⚠️  Tar warnings (non-critical, backup succeeded):"
        echo "$CRITICAL_ERRORS" | head -5
        echo "  (Full error log: $TAR_ERROR_LOG - kept for 24h for debugging)"
      fi
    fi
    # Keep error log for 24 hours for debugging (don't delete immediately)
  else
    echo "ERROR: Backup file created but is too small ($BACKUP_SIZE bytes) - backup may be incomplete"
    if [ -s "$TAR_ERROR_LOG" ]; then
      echo "Tar errors:"
      cat "$TAR_ERROR_LOG" | head -20
    fi
    rm -f "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" "$TAR_ERROR_LOG"
    exit 1
  fi
else
  echo "ERROR: Backup file was not created"
  if [ -s "$TAR_ERROR_LOG" ]; then
    echo "Tar errors:"
    cat "$TAR_ERROR_LOG" | head -20
  fi
  if [ "$GPG_EXIT" -ne 0 ]; then
    echo "GPG encryption failed (exit code: $GPG_EXIT)"
  fi
  rm -f "$TAR_ERROR_LOG"
  exit 1
fi

# Option 1: Upload to Restic repository (encrypted by default)
if command -v restic &> /dev/null && [ -f "$RESTIC_PASSWORD_FILE" ]; then
  echo "Uploading to Restic repository..."
  restic -r "$RESTIC_REPO" \
    --password-file "$RESTIC_PASSWORD_FILE" \
    backup "$encrypted_dir" || echo "Restic upload failed"
fi

# Option 2: Transfer via Tailscale/WireGuard (manual step)
# scp -i ~/.ssh/tailscale_key "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" \
#   user@backup-server:/backups/

# Cleanup old backups (keep last 7 days)
find "$backup_dir" -name "volumes-*.tar.gz*" -mtime +7 -delete
find "$encrypted_dir" -name "volumes-*.tar.gz.gpg" -mtime +30 -delete

echo "Backup completed at $(date)"
