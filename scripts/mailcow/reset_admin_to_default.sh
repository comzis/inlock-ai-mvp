#!/bin/bash
# Reset Mailcow Admin Password to Default
# Resets the admin password to the default: moohoo

set -e

DEFAULT_PASSWORD="moohoo"
SERVER="comzis@100.83.222.69"
MAILCOW_DIR="/home/comzis/mailcow"

echo "========================================="
echo "Reset Mailcow Admin Password to Default"
echo "========================================="
echo ""
echo "Default Password: $DEFAULT_PASSWORD"
echo "Server: $SERVER"
echo ""

# Method 1: Try using docker compose exec (recommended method)
echo "Attempting Method 1: Using docker compose exec..."
RESULT=$(ssh "$SERVER" "cd $MAILCOW_DIR && docker compose exec php-fpm-mailcow-1 php /web/inc/admin.php --setpassword admin $DEFAULT_PASSWORD" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Password reset successful using docker compose exec!"
    echo ""
    echo "New credentials:"
    echo "  Username: admin"
    echo "  Password: $DEFAULT_PASSWORD"
    echo ""
    exit 0
else
    echo "⚠️  Method 1 failed, trying Method 2 (database method)..."
    echo ""
fi

# Method 2: Database method (fallback)
echo "Attempting Method 2: Using database update..."

# Database credentials from documentation
DBROOT_PASSWORD="XQtTKP1D19Eq4JqnWBK7rUzX4KRv"
CONTAINER_PHP="mailcowdockerized-php-fpm-mailcow-1"
CONTAINER_MYSQL="mailcowdockerized-mysql-mailcow-1"

# Generate password hash with BLF-CRYPT prefix
echo "Generating password hash..."
PASSWORD_HASH=$(ssh "$SERVER" "docker exec $CONTAINER_PHP php -r \"echo '{BLF-CRYPT}' . password_hash('$DEFAULT_PASSWORD', PASSWORD_BCRYPT) . PHP_EOL;\"" 2>&1)

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ Failed to generate password hash"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Update password in database
echo "Updating admin password in database..."
RESULT=$(ssh "$SERVER" "docker exec $CONTAINER_MYSQL mysql -u root -p$DB_ROOT_PW_PASSWORD mailcow -e \"UPDATE admin SET password = '$PASSWORD_HASH' WHERE username = 'admin';\"" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Password reset successful using database method!"
    echo ""
    echo "New credentials:"
    echo "  Username: admin"
    echo "  Password: $DEFAULT_PASSWORD"
    echo ""
    echo "Login URL: https://mail.inlock.ai/admin"
    exit 0
else
    echo "❌ Password reset failed"
    echo "Error: $RESULT"
    exit 1
fi
