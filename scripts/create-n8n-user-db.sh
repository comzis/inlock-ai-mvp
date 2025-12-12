#!/bin/bash
# Create n8n user directly in database
# Usage: ./create-n8n-user-db.sh <email> <first_name> <last_name> <password>

set -e

EMAIL="${1:-admin@inlock.ai}"
FIRST_NAME="${2:-Admin}"
LAST_NAME="${3:-User}"
PASSWORD="${4:-TempPass123!}"

echo "=== Creating n8n User in Database ==="
echo ""
echo "Email: $EMAIL"
echo "Name: $FIRST_NAME $LAST_NAME"
echo ""

# Check if user already exists
EXISTING=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM \"user\" WHERE email = '$EMAIL';" 2>&1 | tr -d ' \n')

if [ "$EXISTING" != "0" ]; then
    echo "❌ User with email $EMAIL already exists!"
    echo "   Delete existing user first or use a different email."
    exit 1
fi

# Generate bcrypt hash using Node.js in n8n container (from n8n's node_modules)
echo "Generating password hash..."
HASH=$(docker exec compose-n8n-1 sh -c "cd /usr/local/lib/node_modules/n8n && node -e \"const bcrypt = require('bcryptjs'); bcrypt.hash('$PASSWORD', 10).then(h => console.log(h));\"" 2>&1 | tail -1)

if [ -z "$HASH" ] || [[ "$HASH" == *"Error"* ]]; then
    echo "❌ Failed to generate password hash!"
    echo "   Error: $HASH"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Get owner role slug (use global:owner which should exist)
ROLE_SLUG="global:owner"

echo "Using role: $ROLE_SLUG"
echo ""

# Insert user into database
echo "Creating user in database..."
# Use psql with -v to pass variables safely
RESULT=$(docker exec -i compose-postgres-1 psql -U n8n -d n8n <<PSQL
INSERT INTO "user" (email, "firstName", "lastName", password, "roleSlug", "createdAt", "updatedAt", disabled, "mfaEnabled")
VALUES ('$EMAIL', '$FIRST_NAME', '$LAST_NAME', '$HASH', '$ROLE_SLUG', NOW(), NOW(), false, false)
RETURNING email;
PSQL
2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && echo "$RESULT" | grep -q "$EMAIL"; then
    echo ""
    echo "✅ User created successfully!"
    
    # Create personal project for the user
    echo "Creating personal project..."
    USER_ID=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT id FROM \"user\" WHERE email = '$EMAIL';" 2>&1 | tr -d ' \n')
    
    if [ -n "$USER_ID" ] && [[ ! "$USER_ID" == *"ERROR"* ]]; then
        # Check if user already has a personal project
        EXISTING_PROJECT=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "SELECT pr.\"projectId\" FROM project_relation pr JOIN project p ON pr.\"projectId\" = p.id WHERE pr.\"userId\" = '$USER_ID' AND p.type = 'personal' LIMIT 1;" 2>&1 | tr -d ' \n')
        
        if [ -z "$EXISTING_PROJECT" ] || [[ "$EXISTING_PROJECT" == *"ERROR"* ]]; then
            # Create new personal project
            PROJECT_ID=$(docker exec compose-postgres-1 psql -U n8n -d n8n -t -c "INSERT INTO project (id, name, type, \"createdAt\", \"updatedAt\") VALUES (gen_random_uuid(), 'Personal', 'personal', NOW(), NOW()) RETURNING id;" 2>&1 | tr -d ' \n')
            
            if [ -n "$PROJECT_ID" ] && [[ ! "$PROJECT_ID" == *"ERROR"* ]]; then
                # Link user to project
                docker exec compose-postgres-1 psql -U n8n -d n8n -c "INSERT INTO project_relation (\"userId\", \"projectId\", role, \"createdAt\", \"updatedAt\") VALUES ('$USER_ID', '$PROJECT_ID', 'project:personalOwner', NOW(), NOW()) ON CONFLICT DO NOTHING;" 2>&1 > /dev/null
                echo "✅ Personal project created and linked"
            fi
        else
            echo "✅ User already has a personal project"
        fi
    fi
    
    echo ""
    echo "Login credentials:"
    echo "  Email: $EMAIL"
    echo "  Password: $PASSWORD"
    echo ""
    echo "You can now log in at: https://n8n.inlock.ai"
else
    echo ""
    echo "❌ Failed to create user!"
    echo "   Error: $RESULT"
    exit 1
fi

