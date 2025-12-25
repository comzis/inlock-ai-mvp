#!/usr/bin/env bash
set -euo pipefail

# Backup script for Docker volumes with encryption and secure transport
# Requires: gpg, restic (optional), or age encryption

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
  echo "  ./scripts/import-gpg-key.sh /path/to/admin-inlock-ai.pub"
  echo ""
  echo "Or manually:"
  echo "  gpg --import /path/to/admin-inlock-ai.pub"
  echo ""
  exit 1
fi

echo "Encrypting backup with GPG (recipient: $GPG_RECIPIENT)..."
# Stream tar directly to gpg to avoid plaintext on disk
docker run --rm \
  -v /var/lib/docker/volumes:/source:ro \
  alpine:3.20 \
  tar cz -C /source . | \
  gpg --encrypt --recipient "$GPG_RECIPIENT" \
    --output "$encrypted_dir/volumes-${timestamp}.tar.gz.gpg" \
    --compress-algo 1 --cipher-algo AES256

if [ $? -eq 0 ]; then
  echo "✅ Encrypted backup created: $encrypted_dir/volumes-${timestamp}.tar.gz.gpg"
else
  echo "ERROR: Backup encryption failed"
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
