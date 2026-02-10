#!/bin/bash
# Reset Mailcow Admin Password to Default - Command Reference
# This file contains the commands to reset the admin password to default: moohoo

# Default password
DEFAULT_PASSWORD="moohoo"

echo "========================================="
echo "Reset Mailcow Admin Password to Default"
echo "========================================="
echo ""
echo "Default Password: $DEFAULT_PASSWORD"
echo ""

echo "Method 1: Using docker compose exec (Recommended)"
echo "-------------------------------------------------"
echo "ssh comzis@100.83.222.69"
echo "cd /home/comzis/mailcow"
echo "docker compose exec php-fpm-mailcow-1 php /web/inc/admin.php --setpassword admin $DEFAULT_PASSWORD"
echo ""

echo "Method 2: Using direct docker exec (If docker compose doesn't work)"
echo "--------------------------------------------------------------------"
echo "ssh comzis@100.83.222.69"
echo "PASSWORD_HASH=\$(docker exec mailcowdockerized-php-fpm-mailcow-1 php -r \"echo '{BLF-CRYPT}' . password_hash('$DEFAULT_PASSWORD', PASSWORD_BCRYPT) . PHP_EOL;\")"
echo "docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -pXQtTKP1D19Eq4JqnWBK7rUzX4KRv mailcow -e \"UPDATE admin SET password = '\$PASSWORD_HASH' WHERE username = 'admin';\""
echo ""

echo "Method 3: One-liner using database method"
echo "------------------------------------------"
echo "ssh comzis@100.83.222.69 'PASSWORD_HASH=\$(docker exec mailcowdockerized-php-fpm-mailcow-1 php -r \"echo \\\"{BLF-CRYPT}\\\" . password_hash(\\\"$DEFAULT_PASSWORD\\\", PASSWORD_BCRYPT) . PHP_EOL;\"); docker exec mailcowdockerized-mysql-mailcow-1 mysql -u root -pXQtTKP1D19Eq4JqnWBK7rUzX4KRv mailcow -e \"UPDATE admin SET password = \\\"\$PASSWORD_HASH\\\" WHERE username = \\\"admin\\\";\"'"
echo ""

echo "After reset:"
echo "  Username: admin"
echo "  Password: $DEFAULT_PASSWORD"
echo "  Login URL: https://mail.inlock.ai/admin"
echo ""
