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

# Helper function to dump and encrypt
backup_postgres() {
    local container_name="$1"
    local db_user="$2"
    local output_name="$3"

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

    # Execute pg_dumpall, compress, encrypt
    # Using pg_dumpall to capture globals (users, groups) + all DBs
    if docker exec "$container_name" pg_dumpall -c -U "$db_user" 2>/dev/null | \
       gzip | \
       gpg --encrypt --recipient "$GPG_RECIPIENT" \
           --output "$encrypted_dir/${output_name}-${timestamp}.sql.gz.gpg" \
           --compress-algo 1 --cipher-algo AES256; then
        echo "    ✅ Saved: ${output_name}-${timestamp}.sql.gz.gpg"
    else
        echo "    ❌ ERROR: Failed to backup $container_name"
        return 1
    fi
}

# 1. Inlock App DB
# Service: inlock-db (-f compose/inlock-db.yml)
# User env: INLOCK_DB_USER or default 'inlock'
backup_postgres "inlock-db" "inlock" "db-inlock"

# 2. N8N DB
# Service: postgres (-f compose/postgres.yml)
# User env: N8N_DB_USER or default 'n8n'
# Note: Container likely named *postgres* or *n8n-db* depending on stack name. 
# We'll look for common names or rely on the helper's grep.
backup_postgres "compose-postgres-1" "n8n" "db-n8n"

echo "Database Backup Completed."
