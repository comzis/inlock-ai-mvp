#!/bin/bash
#
# Configure PostgreSQL primary server for streaming replication
# Sets up WAL archiving, replication user, and replication slots
#
# Usage: sudo ./scripts/ha/setup-postgres-replication.sh
# Prerequisites:
#   - PostgreSQL installed and running
#   - Postgres user has sudo access
#   - Replication password set in environment or provided

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  PostgreSQL Primary Replication Setup"
echo "=========================================="
echo ""

# Configuration
PG_VERSION="${PG_VERSION:-15}"
PG_DATA_DIR="/var/lib/postgresql/${PG_VERSION}/main"
PG_CONFIG="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
REPLICATION_USER="${REPLICATION_USER:-replicator}"
REPLICATION_SLOT="${REPLICATION_SLOT:-standby_slot}"
WAL_ARCHIVE_DIR="${WAL_ARCHIVE_DIR:-/var/backups/postgresql/wal_archive}"

# Get replication password
if [ -z "$REPLICATION_PASSWORD" ]; then
    read -sp "Enter replication password: " REPLICATION_PASSWORD
    echo ""
    if [ -z "$REPLICATION_PASSWORD" ]; then
        echo "ERROR: Replication password is required"
        exit 1
    fi
fi

echo "PostgreSQL version: $PG_VERSION"
echo "Data directory: $PG_DATA_DIR"
echo "Replication user: $REPLICATION_USER"
echo "Replication slot: $REPLICATION_SLOT"
echo ""

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    echo "ERROR: PostgreSQL is not running"
    exit 1
fi

# Backup configuration files
echo "Backing up configuration files..."
BACKUP_DIR="/root/postgres-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$PG_CONFIG" "$BACKUP_DIR/postgresql.conf.backup"
cp "$PG_HBA" "$BACKUP_DIR/pg_hba.conf.backup"
echo "✓ Backups saved to: $BACKUP_DIR"
echo ""

# Create WAL archive directory
echo "Creating WAL archive directory..."
mkdir -p "$WAL_ARCHIVE_DIR"
chown postgres:postgres "$WAL_ARCHIVE_DIR"
chmod 700 "$WAL_ARCHIVE_DIR"
echo "✓ WAL archive directory: $WAL_ARCHIVE_DIR"
echo ""

# Configure postgresql.conf
echo "Configuring postgresql.conf for replication..."

# Backup and update configuration
cp "$PG_CONFIG" "$PG_CONFIG.tmp"

# Update WAL level
sed -i 's/^#*wal_level.*/wal_level = replica/' "$PG_CONFIG.tmp"
if ! grep -q "^wal_level" "$PG_CONFIG.tmp"; then
    echo "wal_level = replica" >> "$PG_CONFIG.tmp"
fi

# Update max_wal_senders
sed -i 's/^#*max_wal_senders.*/max_wal_senders = 3/' "$PG_CONFIG.tmp"
if ! grep -q "^max_wal_senders" "$PG_CONFIG.tmp"; then
    echo "max_wal_senders = 3" >> "$PG_CONFIG.tmp"
fi

# Update max_replication_slots
sed -i 's/^#*max_replication_slots.*/max_replication_slots = 3/' "$PG_CONFIG.tmp"
if ! grep -q "^max_replication_slots" "$PG_CONFIG.tmp"; then
    echo "max_replication_slots = 3" >> "$PG_CONFIG.tmp"
fi

# Update hot_standby
sed -i 's/^#*hot_standby.*/hot_standby = on/' "$PG_CONFIG.tmp"
if ! grep -q "^hot_standby" "$PG_CONFIG.tmp"; then
    echo "hot_standby = on" >> "$PG_CONFIG.tmp"
fi

# Update archive mode (for PITR)
sed -i 's/^#*archive_mode.*/archive_mode = on/' "$PG_CONFIG.tmp"
if ! grep -q "^archive_mode" "$PG_CONFIG.tmp"; then
    echo "archive_mode = on" >> "$PG_CONFIG.tmp"
fi

# Update archive command
ARCHIVE_CMD="archive_command = 'test ! -f $WAL_ARCHIVE_DIR/%f && cp %p $WAL_ARCHIVE_DIR/%f'"
sed -i "s|^#*archive_command.*|$ARCHIVE_CMD|" "$PG_CONFIG.tmp"
if ! grep -q "^archive_command" "$PG_CONFIG.tmp"; then
    echo "$ARCHIVE_CMD" >> "$PG_CONFIG.tmp"
fi

mv "$PG_CONFIG.tmp" "$PG_CONFIG"
echo "✓ postgresql.conf updated"
echo ""

# Configure pg_hba.conf for replication
echo "Configuring pg_hba.conf for replication..."

# Add replication entry (allows replication from any IP - restrict in production)
REPLICATION_LINE="host    replication    ${REPLICATION_USER}    0.0.0.0/0    scram-sha-256"

if ! grep -q "replication.*${REPLICATION_USER}" "$PG_HBA"; then
    echo "" >> "$PG_HBA"
    echo "# Replication user (added by setup-postgres-replication.sh)" >> "$PG_HBA"
    echo "$REPLICATION_LINE" >> "$PG_HBA"
    echo "✓ Replication entry added to pg_hba.conf"
else
    echo "⚠️  Replication entry already exists in pg_hba.conf"
fi
echo ""

# Create replication user
echo "Creating replication user..."
sudo -u postgres psql << EOF
-- Create replication user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${REPLICATION_USER}') THEN
        CREATE USER ${REPLICATION_USER} WITH REPLICATION ENCRYPTED PASSWORD '${REPLICATION_PASSWORD}';
        RAISE NOTICE 'User ${REPLICATION_USER} created';
    ELSE
        RAISE NOTICE 'User ${REPLICATION_USER} already exists, updating password';
        ALTER USER ${REPLICATION_USER} WITH ENCRYPTED PASSWORD '${REPLICATION_PASSWORD}';
    END IF;
END
\$\$;

-- List existing replication slots
SELECT slot_name, slot_type, active FROM pg_replication_slots;
EOF

echo "✓ Replication user configured"
echo ""

# Create replication slot
echo "Creating replication slot..."
sudo -u postgres psql << EOF
-- Create replication slot if not exists
SELECT pg_create_physical_replication_slot('${REPLICATION_SLOT}') 
WHERE NOT EXISTS (
    SELECT 1 FROM pg_replication_slots WHERE slot_name = '${REPLICATION_SLOT}'
);

-- Verify slot creation
SELECT slot_name, slot_type, active FROM pg_replication_slots WHERE slot_name = '${REPLICATION_SLOT}';
EOF

echo "✓ Replication slot created"
echo ""

# Restart PostgreSQL
echo "Restarting PostgreSQL..."
systemctl restart postgresql
sleep 3

if systemctl is-active --quiet postgresql; then
    echo "✓ PostgreSQL restarted successfully"
else
    echo "❌ ERROR: PostgreSQL failed to start"
    echo "Restore configuration from: $BACKUP_DIR"
    exit 1
fi
echo ""

# Verify configuration
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""

echo "PostgreSQL configuration:"
sudo -u postgres psql -c "SHOW wal_level;"
sudo -u postgres psql -c "SHOW max_wal_senders;"
sudo -u postgres psql -c "SHOW max_replication_slots;"
echo ""

echo "Replication slot:"
sudo -u postgres psql -c "SELECT slot_name, slot_type, active FROM pg_replication_slots WHERE slot_name = '${REPLICATION_SLOT}';"
echo ""

echo "Replication user:"
sudo -u postgres psql -c "\du ${REPLICATION_USER}"
echo ""

echo "=========================================="
echo "  Primary Replication Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Note the replication password (stored above)"
echo "2. Get primary server IP address"
echo "3. Run setup-postgres-standby.sh on standby server with:"
echo "   - Primary IP: <primary-server-ip>"
echo "   - Replication password: <password-used-above>"
echo "   - Replication slot: ${REPLICATION_SLOT}"
echo ""
echo "Monitor replication with:"
echo "  sudo -u postgres psql -c \"SELECT * FROM pg_stat_replication;\""
echo ""
echo "WAL archive directory: $WAL_ARCHIVE_DIR"
echo "Configuration backups: $BACKUP_DIR"







