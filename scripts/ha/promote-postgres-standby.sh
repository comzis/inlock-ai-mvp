#!/bin/bash
#
# Promote PostgreSQL standby server to primary
# Use this script for failover scenarios
#
# Usage: sudo ./scripts/ha/promote-postgres-standby.sh
# WARNING: This makes the standby a primary. Original primary must be stopped/removed.

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Promote Standby to Primary"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will promote the standby database to primary."
echo "   The original primary should be stopped or removed."
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

PG_VERSION="${PG_VERSION:-15}"

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    echo "ERROR: PostgreSQL is not running"
    exit 1
fi

# Check if currently in recovery mode
echo "Checking current replication status..."
IN_RECOVERY=$(sudo -u postgres psql -tAc "SELECT pg_is_in_recovery();")

if [ "$IN_RECOVERY" != "t" ]; then
    echo "⚠️  WARNING: This server does not appear to be in recovery mode"
    echo "   It may already be a primary server"
    read -p "Continue anyway? (yes/no): " CONFIRM2
    if [ "$CONFIRM2" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

echo ""
echo "Promoting standby to primary..."

# Promote using pg_ctl or pg_promote (PostgreSQL 11+)
if sudo -u postgres pg_ctl promote -D /var/lib/postgresql/${PG_VERSION}/main 2>/dev/null; then
    echo "✓ Promotion command executed"
elif sudo -u postgres psql -c "SELECT pg_promote();" 2>/dev/null; then
    echo "✓ Promotion command executed"
else
    echo "❌ ERROR: Failed to promote standby"
    echo "Manual promotion may be required"
    exit 1
fi

# Wait for promotion to complete
echo "Waiting for promotion to complete..."
sleep 5

# Verify promotion
echo ""
echo "Verifying promotion..."
IN_RECOVERY_AFTER=$(sudo -u postgres psql -tAc "SELECT pg_is_in_recovery();")

if [ "$IN_RECOVERY_AFTER" = "f" ]; then
    echo "✓ Standby successfully promoted to primary"
else
    echo "⚠️  WARNING: Server still appears to be in recovery mode"
    echo "   Check logs: sudo journalctl -u postgresql -n 50"
fi

echo ""
echo "=========================================="
echo "  Promotion Complete"
echo "=========================================="
echo ""
echo "This server is now a PRIMARY database."
echo ""
echo "Next steps:"
echo "1. Update application connection strings to point to this server"
echo "2. Stop or reconfigure the old primary server"
echo "3. If creating a new standby, run setup-postgres-standby.sh"
echo ""
echo "Verify with:"
echo "  sudo -u postgres psql -c \"SELECT pg_is_in_recovery();\"  # Should return 'f'"


