#!/bin/bash
# Delete existing n8n user and guide through creating a new one
# Run: ./scripts/recreate-n8n-user.sh

set -euo pipefail

echo "=== Recreate n8n User ==="
echo ""

# Show current users
echo "Current n8n users:"
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\", \"createdAt\" FROM \"user\" ORDER BY \"createdAt\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -10
echo ""

USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>&1 | tr -d ' \n' || echo "0")

if [ "$USER_COUNT" = "0" ]; then
    echo "No users found. You can create a new user now."
    echo ""
    echo "To create a new user:"
    echo "  1. Go to: https://n8n.inlock.ai"
    echo "  2. You'll see a setup screen"
    echo "  3. Enter your email, name, and password"
    echo "  4. Click 'Create Account'"
    exit 0
fi

# Ask which user to delete
echo "Which user do you want to delete?"
read -p "Enter email address: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "No email provided. Exiting."
    exit 1
fi

# Delete the user
./scripts/delete-n8n-user.sh "$EMAIL"

echo ""
echo "=== Next Steps ==="
echo ""
echo "After the user is deleted, you can create a new one:"
echo ""
echo "1. Wait a few seconds for n8n to recognize the change"
echo "2. Go to: https://n8n.inlock.ai"
echo "3. You'll see a setup screen (since no users exist)"
echo "4. Enter your new credentials:"
echo "   - Email: (your new email)"
echo "   - First Name: (your first name)"
echo "   - Last Name: (your last name)"
echo "   - Password: (choose a strong password)"
echo "5. Click 'Create Account'"
echo ""
echo "The new user will become the owner/admin."
echo ""

