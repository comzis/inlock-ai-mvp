#!/usr/bin/env bash
set -euo pipefail

# Generates sha256 checksums for secrets to detect unexpected changes.
# Intended to be run on the host where secrets are stored.
#
# Usage:
#   ./scripts/security/generate-secrets-checksums.sh
#
# Output:
#   Writes checksums to ${SECRETS_DIR}/secrets.sha256
#
# Notes:
# - Excludes existing checksum files to avoid self-diff noise.
# - You should store the output securely and compare against a known-good copy.

SECRETS_DIR="${SECRETS_DIR:-/home/comzis/apps/secrets-real}"
OUTPUT_FILE="${OUTPUT_FILE:-${SECRETS_DIR}/secrets.sha256}"

if [[ ! -d "$SECRETS_DIR" ]]; then
  echo "❌ Secrets directory not found: $SECRETS_DIR" >&2
  exit 1
fi

cd "$SECRETS_DIR"

TMP_FILE="$(mktemp)"

find . -maxdepth 1 -type f \
  ! -name "secrets.sha256" \
  ! -name "*.backup-*" \
  -print0 \
  | sort -z \
  | xargs -0 sha256sum > "$TMP_FILE"

mv "$TMP_FILE" "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"

echo "✅ Checksums written to $OUTPUT_FILE"

