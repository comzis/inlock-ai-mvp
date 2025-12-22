#!/bin/bash
# Reset n8n user password
# Run: ./scripts/reset-n8n-password.sh [email]

set -euo pipefail

echo "=== Reset n8n Password ==="
echo ""

# Check if email provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <email>"
    echo ""
    echo "Example: $0 milorad@inlock.ai"
    echo ""
    echo "Current n8n users:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -5
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

echo "Resetting password for: $EMAIL"
echo ""
echo "Method 1: Clear password (user must set new password on next login)"
echo "Method 2: Use n8n's password reset feature (recommended)"
echo ""
read -p "Choose method (1 or 2): " METHOD

if [ "$METHOD" = "1" ]; then
    echo ""
    echo "Clearing password hash..."
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "UPDATE \"user\" SET password = NULL WHERE email = '$EMAIL';" 2>&1
    echo "✓ Password cleared"
    echo ""
    echo "Next steps:"
    echo "  1. Go to: https://n8n.inlock.ai"
    echo "  2. Log in with email: $EMAIL"
    echo "  3. You'll be prompted to set a new password"
elif [ "$METHOD" = "2" ]; then
    echo ""
    echo "To reset password via n8n:"
    echo "  1. Go to: https://n8n.inlock.ai"
    echo "  2. Click 'Forgot Password'"
    echo "  3. Enter email: $EMAIL"
    echo "  4. Check your email for reset link"
    echo ""
    echo "Note: This requires email to be configured in n8n"
else
    echo "Invalid choice"
    exit 1
fi
echo ""

