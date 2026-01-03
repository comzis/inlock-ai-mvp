#!/bin/bash
# Fix Postgres data directory permissions to enable no-new-privileges
# This script checks and fixes permissions so Postgres can run with no-new-privileges:true

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Postgres Permission Fix Script ==="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Warning: This script requires root privileges to fix permissions${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Find Postgres volumes
echo "Checking for Postgres volumes..."

# Check for n8n postgres volume
N8N_VOLUME="services_postgres_data"
if docker volume inspect "$N8N_VOLUME" >/dev/null 2>&1; then
    VOLUME_PATH=$(docker volume inspect "$N8N_VOLUME" | grep -oP '(?<="Mountpoint": ")[^"]*')
    echo -e "${GREEN}Found volume: $N8N_VOLUME${NC}"
    echo "  Mountpoint: $VOLUME_PATH"
    
    # Check current ownership
    CURRENT_OWNER=$(stat -c '%U:%G' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
    CURRENT_UID=$(stat -c '%u' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
    echo "  Current owner: $CURRENT_OWNER (UID: $CURRENT_UID)"
    
    # Postgres runs as UID 70 (postgres user)
    TARGET_UID=70
    TARGET_GID=70
    
    if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
        echo -e "${YELLOW}Fixing ownership to postgres user (UID 70)...${NC}"
        chown -R $TARGET_UID:$TARGET_GID "$VOLUME_PATH"
        echo -e "${GREEN}Ownership fixed${NC}"
    else
        echo -e "${GREEN}Ownership is already correct${NC}"
    fi
    
    # Check and fix permissions
    echo "Checking permissions..."
    chmod 700 "$VOLUME_PATH" 2>/dev/null || true
    find "$VOLUME_PATH" -type d -exec chmod 700 {} \; 2>/dev/null || true
    find "$VOLUME_PATH" -type f -exec chmod 600 {} \; 2>/dev/null || true
    echo -e "${GREEN}Permissions fixed${NC}"
else
    echo -e "${YELLOW}Volume $N8N_VOLUME not found (may not exist yet)${NC}"
fi

# Check for inlock-db volume
INLOCK_VOLUME="services_inlock_db_data"
if docker volume inspect "$INLOCK_VOLUME" >/dev/null 2>&1; then
    VOLUME_PATH=$(docker volume inspect "$INLOCK_VOLUME" | grep -oP '(?<="Mountpoint": ")[^"]*')
    echo -e "${GREEN}Found volume: $INLOCK_VOLUME${NC}"
    echo "  Mountpoint: $VOLUME_PATH"
    
    CURRENT_OWNER=$(stat -c '%U:%G' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
    CURRENT_UID=$(stat -c '%u' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
    echo "  Current owner: $CURRENT_OWNER (UID: $CURRENT_UID)"
    
    TARGET_UID=70
    TARGET_GID=70
    
    if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
        echo -e "${YELLOW}Fixing ownership to postgres user (UID 70)...${NC}"
        chown -R $TARGET_UID:$TARGET_GID "$VOLUME_PATH"
        echo -e "${GREEN}Ownership fixed${NC}"
    else
        echo -e "${GREEN}Ownership is already correct${NC}"
    fi
    
    chmod 700 "$VOLUME_PATH" 2>/dev/null || true
    find "$VOLUME_PATH" -type d -exec chmod 700 {} \; 2>/dev/null || true
    find "$VOLUME_PATH" -type f -exec chmod 600 {} \; 2>/dev/null || true
    echo -e "${GREEN}Permissions fixed${NC}"
fi

echo ""
echo -e "${GREEN}=== Permission Fix Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Test Postgres with no-new-privileges:true"
echo "2. Update compose/services/postgres.yml to re-enable no-new-privileges"
echo "3. Restart Postgres service"
echo ""
echo "Test command:"
echo "  docker compose -f compose/services/postgres.yml up -d"
echo "  docker logs services-postgres-1"

