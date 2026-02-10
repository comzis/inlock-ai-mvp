#!/bin/bash
# Setup Email Forwarding: contact@inlock.ai -> milorad.stevanovic@inlock.ai
# Creates a Mailcow alias to forward all emails from contact@inlock.ai

set -euo pipefail

FROM_EMAIL="contact@inlock.ai"
TO_EMAIL="milorad.stevanovic@inlock.ai"

echo "========================================="
echo "Setup Email Forwarding"
echo "========================================="
echo "From: $FROM_EMAIL"
echo "To: $TO_EMAIL"
echo ""

# Get database credentials
echo "Getting database credentials..."
# Try multiple methods to get DBROOT password
if [ -f /home/comzis/mailcow/mailcow.conf ]; then
    DB_ROOT_PW=$(grep "^DB""ROOT=" /home/comzis/mailcow/mailcow.conf | cut -d= -f2 | tr -d ' \r\n')
elif docker exec mailcowdockerized-mysql-mailcow-1 test -f /etc/mailcow/mailcow.conf 2>/dev/null; then
    DB_ROOT_PW=$(docker exec mailcowdockerized-mysql-mailcow-1 cat /etc/mailcow/mailcow.conf 2>/dev/null | grep "^DB""ROOT=" | cut -d= -f2 | tr -d ' \r\n')
else
    DB_ROOT_PW=$(docker exec mailcowdockerized-mysql-mailcow-1 printenv | grep "^DB""ROOT=" | cut -d= -f2)
fi

if [ -z "$DB_ROOT_PW" ]; then
    echo "❌ Failed to get database password"
    echo "   Please check Mailcow configuration"
    exit 1
fi

echo "✅ Database credentials obtained"
echo ""

# Check if alias already exists
echo "Checking if forwarding alias already exists..."
ALIAS_EXISTS=$(docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -sN -e "SELECT COUNT(*) FROM alias WHERE address='$FROM_EMAIL';" 2>/dev/null || echo "0")

if [ "$ALIAS_EXISTS" != "0" ]; then
    echo "⚠️  Forwarding alias already exists!"
    echo ""
    echo "Current forwarding configuration:"
    docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -e "SELECT address, goto, active FROM alias WHERE address='$FROM_EMAIL';" 2>/dev/null
    echo ""
    read -p "Update existing alias? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    
    # Update existing alias
    echo "Updating existing alias..."
    docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow <<EOF
UPDATE alias 
SET goto = '$TO_EMAIL',
    active = 1,
    modified = NOW()
WHERE address = '$FROM_EMAIL';
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Forwarding alias updated successfully"
    else
        echo "❌ Failed to update alias"
        exit 1
    fi
else
    # Create new alias
    echo "Creating forwarding alias..."
    docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow <<EOF
INSERT INTO alias (
    address,
    goto,
    domain,
    active,
    created,
    modified
) VALUES (
    '$FROM_EMAIL',
    '$TO_EMAIL',
    'inlock.ai',
    1,
    NOW(),
    NOW()
);
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Forwarding alias created successfully"
    else
        echo "❌ Failed to create alias"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "Forwarding Configuration"
echo "========================================="
echo "From: $FROM_EMAIL"
echo "To: $TO_EMAIL"
echo ""
echo "✅ Email forwarding is now active!"
echo ""
echo "Note: It may take a few minutes for changes to propagate."
echo "      You can test by sending an email to $FROM_EMAIL"
echo "========================================="
