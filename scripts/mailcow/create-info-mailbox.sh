#!/bin/bash
# Create info@inlock.ai Mailbox Script
# Creates the info@inlock.ai mailbox via Mailcow API or database

set -euo pipefail

EMAIL="info@inlock.ai"
PASSWORD="hssgZwbd7aeh2jsoio!dsUs"
NAME="Inlock Support"
QUOTA="2048"  # 2GB quota

echo "========================================="
echo "Create info@inlock.ai Mailbox"
echo "========================================="
echo ""

# Get database credentials
echo "Getting database credentials..."
DB_ROOT_PW=$(docker exec mailcowdockerized-mysql-mailcow-1 printenv | grep DB""ROOT | cut -d= -f2)

if [ -z "$DB_ROOT_PW" ]; then
    echo "❌ Failed to get database password"
    exit 1
fi

echo "✅ Database credentials obtained"
echo ""

# Check if mailbox already exists
echo "Checking if mailbox already exists..."
EXISTS=$(docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -sN -e "SELECT COUNT(*) FROM mailbox WHERE username='info' AND domain='inlock.ai';" 2>/dev/null || echo "0")

if [ "$EXISTS" != "0" ]; then
    echo "⚠️  Mailbox info@inlock.ai already exists!"
    echo ""
    echo "To update password, use Mailcow admin UI or update manually:"
    echo "  https://mail.inlock.ai/admin"
    exit 0
fi

echo "✅ Mailbox does not exist, proceeding with creation"
echo ""

# Check if domain exists
echo "Checking if domain inlock.ai exists..."
DOMAIN_EXISTS=$(docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow -sN -e "SELECT COUNT(*) FROM domain WHERE domain='inlock.ai';" 2>/dev/null || echo "0")

if [ "$DOMAIN_EXISTS" = "0" ]; then
    echo "❌ Domain inlock.ai does not exist in Mailcow!"
    echo "   Please add the domain first via Mailcow admin UI"
    exit 1
fi

echo "✅ Domain inlock.ai exists"
echo ""

# Generate password hash
echo "Generating password hash..."
PASSWORD_HASH=$(docker exec mailcowdockerized-php-fpm-mailcow-1 php -r "echo '{BLF-CRYPT}' . password_hash('$PASSWORD', PASSWORD_BCRYPT) . PHP_EOL;")

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ Failed to generate password hash"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Create mailbox via database
echo "Creating mailbox in database..."
docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -p"$DB_ROOT_PW" mailcow <<EOF
INSERT INTO mailbox (
    username,
    domain,
    password,
    name,
    quota,
    local_part,
    active,
    created,
    modified
) VALUES (
    'info',
    'inlock.ai',
    '$PASSWORD_HASH',
    '$NAME',
    $QUOTA,
    'info',
    1,
    NOW(),
    NOW()
);
EOF

if [ $? -eq 0 ]; then
    echo "✅ Mailbox created successfully in database"
    echo ""
    echo "========================================="
    echo "Mailbox Created"
    echo "========================================="
    echo "Email: $EMAIL"
    echo "Password: $PASSWORD"
    echo "Name: $NAME"
    echo "Quota: ${QUOTA}MB"
    echo ""
    echo "⚠️  Note: You may need to:"
    echo "  1. Restart Mailcow services for changes to take effect"
    echo "  2. Or wait a few minutes for Mailcow to sync"
    echo ""
    echo "Test login at: https://mail.inlock.ai"
    echo "========================================="
else
    echo "❌ Failed to create mailbox"
    exit 1
fi
