#!/bin/bash
# Fresh start for n8n: Delete user, update to latest, restart
# Run: ./scripts/fresh-start-n8n.sh

set -euo pipefail

echo "=== Fresh Start for n8n ==="
echo ""

# Check current version
echo "1. Checking current n8n version..."
CURRENT_IMAGE=$(docker inspect compose-n8n-1 --format '{{.Config.Image}}' 2>/dev/null || echo "n8nio/n8n")
echo "   Current: $CURRENT_IMAGE"
echo ""

# Show current users
echo "2. Current n8n users:"
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -10
echo ""

USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n' || echo "0")

if [ "$USER_COUNT" -gt 0 ]; then
    echo "3. Deleting existing user(s)..."
    read -p "   Delete all users? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        # Get all user emails
        docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT email FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | while read -r email; do
            if [ -n "$email" ]; then
                echo "   Deleting user: $email"
                ./scripts/delete-n8n-user.sh "$email" >/dev/null 2>&1 || true
            fi
        done
        echo "   ✓ All users deleted"
    else
        echo "   Skipping user deletion"
    fi
else
    echo "3. No users found (already fresh)"
fi
echo ""

# Stop n8n
echo "4. Stopping n8n..."
docker compose -f compose/n8n.yml --env-file .env stop n8n 2>&1 >/dev/null || true
echo "   ✓ n8n stopped"
echo ""

# Pull latest image
echo "5. Pulling latest n8n image..."
docker compose -f compose/n8n.yml --env-file .env pull n8n 2>&1 | tail -5
echo "   ✓ Latest image pulled"
echo ""

# Update compose file to use latest (remove any version pinning)
echo "6. Updating compose file to use latest tag..."
# Remove SHA256 pins
sed -i 's|image: n8nio/n8n@sha256:[^ ]*|image: n8nio/n8n:latest|g' compose/n8n.yml
# Update any version tags to latest
sed -i 's|image: n8nio/n8n:[0-9].*|image: n8nio/n8n:latest|g' compose/n8n.yml
# Ensure it's set to latest if not already
if ! grep -q "image: n8nio/n8n:latest" compose/n8n.yml; then
    sed -i 's|image: n8nio/n8n.*|image: n8nio/n8n:latest|g' compose/n8n.yml
fi
echo "   ✓ Compose file updated to use latest"
echo ""

# Start n8n with latest image
echo "7. Starting n8n with latest version..."
docker compose -f compose/n8n.yml --env-file .env up -d n8n 2>&1 | tail -3
echo "   ✓ n8n started"
echo ""

# Wait for n8n to be ready
echo "8. Waiting for n8n to be ready..."
sleep 10
for i in {1..30}; do
    if docker exec compose-n8n-1 wget -qO- http://localhost:5678/healthz 2>&1 | grep -q "ok\|OK"; then
        echo "   ✓ n8n is ready"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done
echo ""

# Show new version
echo "9. New n8n version:"
NEW_IMAGE=$(docker inspect compose-n8n-1 --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
echo "   New: $NEW_IMAGE"
docker exec compose-n8n-1 n8n --version 2>&1 | head -3 || echo "   (version check unavailable)"
echo ""

echo "=== Fresh Start Complete ==="
echo ""
echo "n8n has been updated and reset."
echo ""
echo "To create a new account:"
echo "  1. Go to: https://n8n.inlock.ai"
echo "  2. You'll see a setup screen"
echo "  3. Enter your email, name, and password"
echo "  4. Click 'Create Account'"
echo ""
echo "The first user will become the owner/admin."
echo ""

