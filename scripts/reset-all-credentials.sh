#!/bin/bash
# Interactive script to reset n8n and/or Cockpit credentials
# Run: ./scripts/reset-all-credentials.sh

set -euo pipefail

echo "=== Reset Credentials ==="
echo ""
echo "Which credentials do you want to reset?"
echo ""
echo "1. n8n password"
echo "2. Cockpit password"
echo "3. Both"
echo "4. Show current credentials"
echo ""
read -p "Choose option (1-4): " OPTION

case "$OPTION" in
    1)
        echo ""
        echo "=== Reset n8n Password ==="
        echo ""
        echo "Current n8n users:"
        docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -5
        echo ""
        read -p "Enter email address: " EMAIL
        if [ -n "$EMAIL" ]; then
            ./scripts/reset-n8n-password.sh "$EMAIL"
        fi
        ;;
    2)
        echo ""
        echo "=== Reset Cockpit Password ==="
        echo ""
        echo "Available system users:"
        cat /etc/passwd | grep -E "/bin/(bash|sh)" | cut -d: -f1,5 | while IFS=: read -r user name; do
            echo "  - $user"
        done
        echo ""
        read -p "Enter username: " USERNAME
        if [ -n "$USERNAME" ]; then
            sudo ./scripts/reset-cockpit-password.sh "$USERNAME"
        fi
        ;;
    3)
        echo ""
        echo "=== Reset n8n Password ==="
        echo ""
        echo "Current n8n users:"
        docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\";" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -5
        echo ""
        read -p "Enter n8n email address: " EMAIL
        if [ -n "$EMAIL" ]; then
            ./scripts/reset-n8n-password.sh "$EMAIL"
        fi
        echo ""
        echo "=== Reset Cockpit Password ==="
        echo ""
        echo "Available system users:"
        cat /etc/passwd | grep -E "/bin/(bash|sh)" | cut -d: -f1,5 | while IFS=: read -r user name; do
            echo "  - $user"
        done
        echo ""
        read -p "Enter Cockpit username: " USERNAME
        if [ -n "$USERNAME" ]; then
            sudo ./scripts/reset-cockpit-password.sh "$USERNAME"
        fi
        ;;
    4)
        ./scripts/show-credentials.sh
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=== Done ==="
echo ""

