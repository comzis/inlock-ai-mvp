#!/bin/bash
# Show credentials for n8n and Cockpit
# Run: ./scripts/show-credentials.sh

echo "=== Credentials Information ==="
echo ""

# n8n
echo "=== n8n Credentials ==="
echo ""
echo "n8n uses EMAIL-BASED authentication (not username/password)"
echo ""
echo "Checking for existing users..."
USER_COUNT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\";" 2>/dev/null | tr -d ' \n' || echo "0")

if [ "$USER_COUNT" -gt 0 ]; then
    echo "Found $USER_COUNT user(s) in database:"
    docker exec compose-postgres-1 psql -U n8n -d n8n -c "SELECT email, \"firstName\", \"lastName\" FROM \"user\" ORDER BY \"createdAt\" LIMIT 5;" 2>&1 | grep -v "^-" | grep -v "rows)" | grep -v "email" | grep -v "^$" | head -5
    echo ""
    echo "To log in:"
    echo "  1. Go to: https://n8n.inlock.ai"
    echo "  2. Use one of the email addresses above"
    echo "  3. Click 'Forgot Password' if you don't remember the password"
else
    echo "No users found in database."
    echo ""
    echo "To create the first user:"
    echo "  1. Go to: https://n8n.inlock.ai"
    echo "  2. You'll see a setup screen"
    echo "  3. Enter your email, name, and password"
    echo "  4. This user will become the owner/admin"
fi
echo ""

# Cockpit
echo "=== Cockpit Credentials ==="
echo ""
echo "Cockpit uses LINUX SYSTEM USER authentication"
echo ""
echo "Available system users:"
cat /etc/passwd | grep -E "/bin/(bash|sh)" | cut -d: -f1,5 | while IFS=: read -r user name; do
    echo "  - Username: $user"
    [ -n "$name" ] && echo "    Name: $name"
done
echo ""
echo "To log in:"
echo "  1. Go to: https://cockpit.inlock.ai"
echo "  2. Username: Use one of the usernames above (likely 'comzis' or 'ubuntu')"
echo "  3. Password: Your SSH password for that user"
echo ""
echo "If you've forgotten your password, reset it:"
echo "  sudo passwd username"
echo ""

echo "=== Quick Access ==="
echo ""
echo "n8n:    https://n8n.inlock.ai"
echo "Cockpit: https://cockpit.inlock.ai"
echo ""
echo "Note: Both require IP allowlist access (Tailscale or server IP)"
echo ""

