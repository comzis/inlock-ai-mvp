#!/bin/bash
# Restore Mailcow Admin Access
# Sets admin password to a known value if access was lost

set -euo pipefail

SERVER="comzis@100.83.222.69"
CONTAINER_PHP="mailcowdockerized-php-fpm-mailcow-1"
CONTAINER_MYSQL="mailcowdockerized-mysql-mailcow-1"
DBROOT_PASSWORD="XQtTKP1D19Eq4JqnWBK7rUzX4KRv"

# Use the password that was working before: MailcowAdmin123!
RESTORE_PASSWORD="${1:-MailcowAdmin123!}"

echo "========================================="
echo "Restore Mailcow Admin Access"
echo "========================================="
echo ""
echo "Setting password to: $RESTORE_PASSWORD"
echo ""

# Generate password hash with BLF-CRYPT prefix
echo "Generating password hash..."
PASSWORD_HASH=$(ssh "$SERVER" "docker exec $CONTAINER_PHP php -r \"echo '{BLF-CRYPT}' . password_hash('$RESTORE_PASSWORD', PASSWORD_BCRYPT) . PHP_EOL;\"" 2>&1)

if [ -z "$PASSWORD_HASH" ] || echo "$PASSWORD_HASH" | grep -qi "error\|failed"; then
    echo "❌ Failed to generate password hash"
    echo "Error: $PASSWORD_HASH"
    exit 1
fi

echo "✅ Password hash generated"
echo ""

# Update password in database
echo "Updating admin password in database..."
RESULT=$(ssh "$SERVER" "docker exec $CONTAINER_MYSQL mysql -u root -p$DB_ROOT_PW_PASSWORD mailcow -e \"UPDATE admin SET password = '$PASSWORD_HASH' WHERE username = 'admin';\"" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Password reset successful!"
    echo ""
    echo "========================================="
    echo "Restored Credentials"
    echo "========================================="
    echo "Username: admin"
    echo "Password: $RESTORE_PASSWORD"
    echo ""
    echo "Login URL: https://mail.inlock.ai/admin"
    echo "========================================="
    echo ""
    echo "⚠️  IMPORTANT: Change this password after logging in!"
    exit 0
else
    echo "❌ Password reset failed"
    echo "Error: $RESULT"
    exit 1
fi
