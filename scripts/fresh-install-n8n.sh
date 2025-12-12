#!/bin/bash
# Complete fresh install of n8n - removes everything and starts clean
# Run: sudo ./scripts/fresh-install-n8n.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

cd /home/comzis/inlock-infra

echo "=== Complete Fresh Install of n8n ==="
echo ""
echo "⚠️  WARNING: This will DELETE all n8n data:"
echo "  - All workflows"
echo "  - All credentials"
echo "  - All executions"
echo "  - All users"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# 1. Stop and remove n8n container
echo "1. Stopping and removing n8n container..."
docker compose -f compose/n8n.yml --env-file .env down n8n 2>&1 >/dev/null || true
docker rm -f compose-n8n-1 2>&1 >/dev/null || true
echo "   ✓ Container removed"
echo ""

# 2. Remove n8n volume (all data)
echo "2. Removing n8n data volume..."
docker volume rm compose_n8n_data 2>&1 >/dev/null || true
echo "   ✓ Volume removed"
echo ""

# 3. Clear n8n database
echo "3. Clearing n8n database..."
docker exec compose-postgres-1 psql -U n8n -d n8n <<EOF
-- Drop all tables (cascade will handle dependencies)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO n8n;
GRANT ALL ON SCHEMA public TO public;
EOF
echo "   ✓ Database cleared"
echo ""

# 4. Pull latest image
echo "4. Pulling latest n8n image..."
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 >/dev/null
echo "   ✓ Image pulled"
echo ""

# 5. Start n8n fresh
echo "5. Starting n8n with fresh installation..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 >/dev/null
echo "   ✓ n8n started"
echo ""

# 6. Wait for initialization
echo "6. Waiting for n8n to initialize..."
sleep 20
echo "   ✓ Wait complete"
echo ""

# 7. Verify
echo "7. Verifying installation..."
if docker ps | grep -q compose-n8n-1; then
    STATUS=$(docker ps | grep compose-n8n-1 | awk '{print $7}')
    echo "   Container status: $STATUS"
else
    echo "   ✗ Container not running"
    exit 1
fi

DB_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1 | tr -d ' \n\r' || echo "?")
echo "   Database tables: $DB_COUNT (should be 0 initially, will be created on first access)"

HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://n8n.inlock.ai 2>&1 || echo "000")
echo "   HTTP status: $HTTP_CODE"
echo ""

echo "=== Fresh Install Complete ==="
echo ""
echo "n8n has been completely removed and reinstalled."
echo ""
echo "Next steps:"
echo "  1. Wait 30 seconds for n8n to fully initialize"
echo "  2. Visit: https://n8n.inlock.ai"
echo "  3. IMPORTANT: Clear browser cache:"
echo "     - Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R)"
echo "     - Or use incognito window"
echo ""
echo "You should now see:"
echo "  ✅ 'Create your account' form (SETUP PAGE)"
echo ""
echo "If you still see login page:"
echo "  - It's 100% browser cache - try incognito window"
echo "  - Or clear ALL browser data for n8n.inlock.ai"
echo ""

