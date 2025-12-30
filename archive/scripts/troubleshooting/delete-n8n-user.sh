#!/bin/bash
# Delete existing n8n user and prepare for new account creation
# Run: ./scripts/delete-n8n-user.sh [email]

set -euo pipefail

echo "=== Delete n8n User ==="
echo ""

# Check if email provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <email>"
    echo ""
    echo "Example: $0 milorad@inlock.ai"
    echo ""
    echo "Current n8n users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\", \"createdAt\" FROM \"user\" ORDER BY \"createdAt\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -10
    exit 1
fi

EMAIL="$1"

# Verify user exists
USER_EXISTS=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\" WHERE email = '$EMAIL';" 2>&1 | tr -d ' \n' || echo "0")

if [ "$USER_EXISTS" = "0" ]; then
    echo "Error: User with email '$EMAIL' not found"
    echo ""
    echo "Available users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$"
    exit 1
fi

# Show user info
echo "User to delete:"
docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\", \"createdAt\" FROM \"user\" WHERE email = '$EMAIL';" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$"
echo ""

# Confirm deletion
read -p "Are you sure you want to delete this user? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deletion cancelled"
    exit 0
fi

echo ""
echo "Deleting user and related data..."

# Get user ID
USER_ID=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT id FROM \"user\" WHERE email = '$EMAIL';" 2>&1 | tr -d ' \n')

if [ -z "$USER_ID" ] || [ "$USER_ID" = "0" ]; then
    echo "Error: Could not find user ID"
    exit 1
fi

echo "User ID: $USER_ID"
echo ""

# Delete user's workflows (if any)
echo "1. Deleting user's workflows..."
WORKFLOW_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM workflow_entity WHERE \"userId\" = '$USER_ID';" 2>&1 | tr -d ' \n' || echo "0")
if [ "$WORKFLOW_COUNT" -gt 0 ]; then
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "DELETE FROM workflow_entity WHERE \"userId\" = '$USER_ID';" 2>&1 >/dev/null
    echo "   Deleted $WORKFLOW_COUNT workflow(s)"
else
    echo "   No workflows found"
fi

# Delete user's executions (if any)
echo "2. Deleting user's executions..."
EXECUTION_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM execution_entity WHERE \"userId\" = '$USER_ID';" 2>&1 | tr -d ' \n' || echo "0")
if [ "$EXECUTION_COUNT" -gt 0 ]; then
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "DELETE FROM execution_entity WHERE \"userId\" = '$USER_ID';" 2>&1 >/dev/null
    echo "   Deleted $EXECUTION_COUNT execution(s)"
else
    echo "   No executions found"
fi

# Delete user's credentials (if any)
echo "3. Deleting user's credentials..."
CREDENTIAL_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM credentials_entity WHERE \"userId\" = '$USER_ID';" 2>&1 | tr -d ' \n' || echo "0")
if [ "$CREDENTIAL_COUNT" -gt 0 ]; then
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "DELETE FROM credentials_entity WHERE \"userId\" = '$USER_ID';" 2>&1 >/dev/null
    echo "   Deleted $CREDENTIAL_COUNT credential(s)"
else
    echo "   No credentials found"
fi

# Delete user's settings (if any)
echo "4. Deleting user's settings..."
docker exec compose-postgres-1 psql -U n8n -d n8n -c "DELETE FROM settings WHERE \"userId\" = '$USER_ID';" 2>&1 >/dev/null || true

# Finally delete the user
echo "5. Deleting user account..."
docker exec compose-postgres-1 psql -U n8n -d n8n -c "DELETE FROM \"user\" WHERE email = '$EMAIL';" 2>&1

if [ $? -eq 0 ]; then
    echo "   ✓ User deleted successfully"
else
    echo "   ✗ Error deleting user"
    exit 1
fi

echo ""
echo "=== User Deletion Complete ==="
echo ""
echo "The user '$EMAIL' has been deleted along with:"
echo "  - Workflows"
echo "  - Executions"
echo "  - Credentials"
echo "  - Settings"
echo ""
echo "=== Create New User ==="
echo ""
echo "To create a new n8n user:"
echo ""
echo "1. Go to: https://n8n.inlock.ai"
echo "2. You'll see a setup screen (since no users exist)"
echo "3. Enter:"
echo "   - Email: (your new email address)"
echo "   - First Name: (your first name)"
echo "   - Last Name: (your last name)"
echo "   - Password: (choose a strong password)"
echo "4. Click 'Create Account'"
echo ""
echo "The first user created will become the owner/admin."
echo ""

