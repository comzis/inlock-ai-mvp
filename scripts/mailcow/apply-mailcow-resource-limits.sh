#!/bin/bash
# Apply Resource Limits to Mailcow Services
# Prevents individual services from consuming excessive memory/CPU

set -euo pipefail

echo "========================================="
echo "Mailcow Resource Limits Application"
echo "========================================="
echo ""
echo "⚠️  This script will update running Mailcow containers with resource limits"
echo "    Limits are applied immediately but will be lost on container restart"
echo "    For persistent limits, modify Mailcow's docker-compose.yml file"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script requires sudo/root access"
    echo "    Some operations may fail without proper permissions"
    echo ""
fi

# Function to apply limits to a container
apply_limits() {
    local container=$1
    local memory=$2
    local memory_reservation=$3
    local cpus=$4
    
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "Applying limits to ${container}..."
        docker update \
            --memory="${memory}" \
            --memory-reservation="${memory_reservation}" \
            --cpus="${cpus}" \
            "${container}" 2>&1 && echo "✅ ${container} updated" || echo "❌ Failed to update ${container}"
    else
        echo "⚠️  Container ${container} not running"
    fi
}

# Apply limits to critical services
echo "=== Applying Limits to Critical Services ==="
echo ""

# MySQL (Database) - Critical
apply_limits "mailcowdockerized-mysql-mailcow-1" "1.5g" "512m" "2.0"

# PHP-FPM (Application) - Critical
apply_limits "mailcowdockerized-php-fpm-mailcow-1" "1g" "256m" "1.5"

# Dovecot (IMAP/POP3) - Critical
apply_limits "mailcowdockerized-dovecot-mailcow-1" "512m" "128m" "1.0"

# Postfix (SMTP) - Critical
apply_limits "mailcowdockerized-postfix-mailcow-1" "512m" "128m" "1.0"

echo ""
echo "=== Applying Limits to Medium Priority Services ==="
echo ""

# Nginx (Web Server)
apply_limits "mailcowdockerized-nginx-mailcow-1" "256m" "64m" "0.5"

# Redis (Cache)
apply_limits "mailcowdockerized-redis-mailcow-1" "512m" "128m" "0.5"

# SOGo (Webmail)
apply_limits "mailcowdockerized-sogo-mailcow-1" "512m" "128m" "1.0"

# Rspamd (Spam Filter)
apply_limits "mailcowdockerized-rspamd-mailcow-1" "512m" "128m" "1.0"

echo ""
echo "=== Applying Limits to Other Services ==="
echo ""

# Other Mailcow services (apply generic limits)
for container in $(docker ps --format '{{.Names}}' | grep mailcow | grep -v -E 'mysql|php-fpm|dovecot|postfix|nginx|redis|sogo|rspamd'); do
    apply_limits "${container}" "256m" "64m" "0.5"
done

echo ""
echo "========================================="
echo "✅ Resource Limits Applied"
echo "========================================="
echo ""
echo "Current resource usage:"
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' | grep -E 'NAME|mailcow' | head -20
echo ""
echo "⚠️  Note: These limits are temporary and will be lost on container restart"
echo "    For persistent limits, modify Mailcow's docker-compose.yml file"
echo ""
echo "Next steps:"
echo "1. Monitor services for 15-30 minutes"
echo "2. Check service health: docker ps --filter 'name=mailcow'"
echo "3. Review logs if any services show issues"
echo "4. Consider modifying Mailcow compose file for persistent limits"
