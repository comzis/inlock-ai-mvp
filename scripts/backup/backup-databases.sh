#!/usr/bin/env bash
set -euo pipefail

# Database Backup Script for Inlock AI
# Performs logical backups (pg_dump) of running Postgres containers.
# Outputs encrypted SQL dumps.

timestamp="$(date +%F-%H%M%S)"
backup_dir="${BACKUP_DIR:-$HOME/backups/inlock}"
encrypted_dir="${BACKUP_ENCRYPTED_DIR:-$HOME/backups/inlock/encrypted}"
mkdir -p "$backup_dir" "$encrypted_dir"

# GPG recipient
GPG_RECIPIENT="${GPG_RECIPIENT:-admin@inlock.ai}"

# Verify GPG
if ! command -v gpg &> /dev/null; then
  echo "ERROR: GPG is required."
  exit 1
fi

echo "Starting Database Backup at $timestamp"

# Defaults
INLOCK_DB_NAME="${INLOCK_DB_NAME:-inlock}"
INLOCK_DB_USER="${INLOCK_DB_USER:-inlock}"
N8N_DB_NAME="${N8N_DB_NAME:-n8n}"
N8N_DB_USER="${N8N_DB_USER:-n8n}"

# Helper function to dump and encrypt a single database
backup_postgres() {
    local container_name="$1"
    local db_user="$2"
    local db_name="$3"
    local output_name="$4"
    local secret_file="${5:-}"
    local pg_password=""

    echo "  > Backing up $container_name (User: $db_user)..."
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        # Try to find by service name suffix if exact match fails
        local found_container=$(docker ps --format '{{.Names}}' | grep "${container_name}" | head -n 1)
        if [ -n "$found_container" ]; then
            container_name="$found_container"
        else
            echo "    ⚠️  Container $container_name not found or not running. Skipping."
            return 1
        fi
    fi

    # Load password if provided
    if [[ -n "$secret_file" && -r "$secret_file" ]]; then
        pg_password="$(< "$secret_file")"
    fi

    # Execute pg_dump (custom format), encrypt
    if docker exec -e PGPASSWORD="$pg_password" "$container_name" pg_dump -Fc -U "$db_user" "$db_name" 2>/dev/null | \
       gpg --encrypt --recipient "$GPG_RECIPIENT" \
           --output "$encrypted_dir/${output_name}-${timestamp}.dump.gpg" \
           --compress-algo 1 --cipher-algo AES256; then
        echo "    ✅ Saved: ${output_name}-${timestamp}.dump.gpg"
    else
        echo "    ❌ ERROR: Failed to backup $container_name"
        return 1
    fi
}

# 1. Inlock App DB
# Service: inlock-db (-f compose/inlock-db.yml)
backup_postgres "inlock-db" "$INLOCK_DB_USER" "$INLOCK_DB_NAME" "db-inlock" "/home/comzis/apps/secrets-real/inlock-db-password"

# 2. N8N DB (same Postgres instance)
backup_postgres "inlock-db" "$N8N_DB_USER" "$N8N_DB_NAME" "db-n8n" "/home/comzis/apps/secrets-real/n8n-db-password"

echo "Database Backup Completed."
