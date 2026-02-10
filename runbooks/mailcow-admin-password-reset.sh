#!/bin/bash
# Mailcow Admin Password Reset Script
# Resets the admin password for Mailcow

set -e

# Configuration
CONTAINER_PHP="mailcowdockerized-php-fpm-mailcow-1"
CONTAINER_MYSQL="mailcowdockerized-mysql-mailcow-1"
NEW_PASSWORD="${1:?Usage: $0 <new-password>}"

echo "========================================="
echo "Mailcow Admin Password Reset"
echo "========================================="
echo ""

# Generate password hash with BLF-CRYPT prefix
echo "Generating password hash..."
PASSWORD_HASH=$(docker exec "$CONTAINER_PHP" php -r "echo '{BLF-CRYPT}' . password_hash('$NEW_PASSWORD', PASSWORD_BCRYPT) . PHP_EOL;")

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ Failed to generate password hash"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Get database root password from environment
echo "Getting database credentials..."
DB_ROOT_PW=$(docker exec "$CONTAINER_MYSQL" printenv | grep 'DB''ROOT' | cut -d= -f2)

if [ -z "$DB_ROOT_PW" ]; then
    echo "❌ Failed to get database password from environment"
    echo "Trying alternative method..."
    DB_ROOT_PW=$(docker exec "$CONTAINER_MYSQL" cat /etc/mailcow/mailcow.conf 2>/dev/null | grep 'DB''ROOT' | cut -d= -f2 | tr -d ' \r\n' || echo "")
fi

if [ -z "$DB_ROOT_PW" ]; then
    echo "❌ Could not get database password"
    echo "Please provide database root password manually or check Mailcow configuration"
    exit 1
fi

echo "✅ Database credentials obtained"
echo ""

# Update password in database
echo "Updating admin password in database..."
docker exec "$CONTAINER_MYSQL" mysql -u root -p"$DB_ROOT_PW" mailcow -e "UPDATE admin SET password = '$PASSWORD_HASH' WHERE username = 'admin';" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Password reset successful!"
    echo ""
    echo "========================================="
    echo "New Credentials"
    echo "========================================="
    echo "Username: admin"
    echo "Password: $NEW_PASSWORD"
    echo ""
    echo "⚠️  IMPORTANT: Change this password immediately after logging in!"
    echo ""
    echo "Login at: https://mail.inlock.ai"
    echo "========================================="
else
    echo ""
    echo "❌ Failed to update password in database"
    echo "Check database connection and permissions"
    exit 1
fi
