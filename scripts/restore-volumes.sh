#!/usr/bin/env bash
set -euo pipefail

# Restore script for encrypted Docker volume backups
# Supports: GPG-encrypted backups, Restic repositories

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/backup [--gpg] [--restic]"
  echo ""
  echo "Options:"
  echo "  --gpg    Decrypt GPG-encrypted backup first"
  echo "  --restic Restore from Restic repository"
  exit 1
fi

BACKUP_FILE="$1"
DECRYPT_GPG=false
USE_RESTIC=false

# Parse arguments
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --gpg)
      DECRYPT_GPG=true
      shift
      ;;
    --restic)
      USE_RESTIC=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ] && [ "$USE_RESTIC" = false ]; then
  echo "ERROR: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "=========================================="
echo "RESTORING DOCKER VOLUMES"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will overwrite existing volumes!"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# Handle GPG-encrypted backups
if [ "$DECRYPT_GPG" = true ] || [[ "$BACKUP_FILE" == *.gpg ]]; then
  if ! command -v gpg &> /dev/null; then
    echo "ERROR: GPG not found. Install with: apt install gnupg"
    exit 1
  fi
  
  echo "Decrypting GPG-encrypted backup..."
  DECRYPTED_FILE="${BACKUP_FILE%.gpg}"
  gpg --decrypt --output "$DECRYPTED_FILE" "$BACKUP_FILE"
  BACKUP_FILE="$DECRYPTED_FILE"
  echo "✅ Decrypted to: $BACKUP_FILE"
fi

# Handle Restic restore
if [ "$USE_RESTIC" = true ]; then
  RESTIC_REPO="${RESTIC_REPO:-b2:inlock-infra}"
  RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/root/.config/restic/password}"
  
  if ! command -v restic &> /dev/null; then
    echo "ERROR: Restic not found. Install with: apt install restic"
    exit 1
  fi
  
  echo "Restoring from Restic repository: $RESTIC_REPO"
  RESTORE_DIR="/tmp/restic-restore-$(date +%s)"
  mkdir -p "$RESTORE_DIR"
  
  restic -r "$RESTIC_REPO" \
    --password-file "$RESTIC_PASSWORD_FILE" \
    restore latest --target "$RESTORE_DIR"
  
  # Find the backup file in restored directory
  BACKUP_FILE=$(find "$RESTORE_DIR" -name "volumes-*.tar.gz" | head -1)
  if [ -z "$BACKUP_FILE" ]; then
    echo "ERROR: No backup file found in Restic restore"
    exit 1
  fi
  echo "✅ Restored from Restic: $BACKUP_FILE"
fi

# Verify backup file
if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo ""
echo "Restoring volumes from: $BACKUP_FILE"
echo "⚠️  This will overwrite existing volumes in /var/lib/docker/volumes"
echo ""

# Stop services that use volumes
echo "Stopping services..."
cd "$(dirname "$0")/.." || exit
docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env down || true

# Restore volumes
echo "Extracting backup..."
docker run --rm \
  -v /var/lib/docker/volumes:/dest \
  -v "$BACKUP_FILE":/backup.tar.gz:ro \
  alpine:3.20 \
  sh -c "cd /dest && tar xzf /backup.tar.gz"

echo "✅ Volumes restored"

# Cleanup
if [ -n "${DECRYPTED_FILE:-}" ] && [ -f "$DECRYPTED_FILE" ]; then
  echo "Cleaning up decrypted file..."
  rm -f "$DECRYPTED_FILE"
fi

if [ -n "${RESTORE_DIR:-}" ] && [ -d "$RESTORE_DIR" ]; then
  echo "Cleaning up Restic restore directory..."
  rm -rf "$RESTORE_DIR"
fi

echo ""
echo "=========================================="
echo "RESTORE COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify volume contents: docker volume ls"
echo "2. Start services: docker compose -f compose/stack.yml -f compose/postgres.yml -f compose/n8n.yml --env-file .env up -d"
echo "3. Verify services are healthy: docker compose ... ps"

