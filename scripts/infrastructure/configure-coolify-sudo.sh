#!/bin/bash
#
# Configure limited passwordless sudo for Coolify
# Allows only specific commands required by Coolify (docker, systemctl)
# More secure than full NOPASSWD:ALL but necessary for Coolify automation
#
# Usage: sudo ./scripts/infrastructure/configure-coolify-sudo.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Configuring Limited Sudo for Coolify"
echo "  (Security Exception - Documented)"
echo "=========================================="
echo ""
echo "⚠️  SECURITY NOTE:"
echo "   This adds NOPASSWD for specific commands only"
echo "   Required for Coolify automation (cannot provide passwords)"
echo "   More secure than full NOPASSWD:ALL"
echo ""

SUDOERS_FILE="/etc/sudoers.d/coolify-comzis"
BACKUP_FILE="${SUDOERS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Backup existing file if it exists
if [ -f "$SUDOERS_FILE" ]; then
    cp "$SUDOERS_FILE" "$BACKUP_FILE"
    echo "✓ Backed up existing sudoers file to: $BACKUP_FILE"
fi

# Create sudoers file with limited permissions
echo "Creating limited sudoers configuration..."
cat > "$SUDOERS_FILE" << 'EOF'
# Coolify Limited Sudo Access
# Security Exception: Required for Coolify automation (cannot provide passwords)
# Only allows specific commands needed by Coolify
# More secure than NOPASSWD:ALL
# Date: 2025-12-28

# Allow passwordless sudo for Docker commands (user is already in docker group, but Coolify validation checks sudo)
comzis ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/docker-compose-v1

# Allow passwordless sudo for systemctl commands (needed for service management)
comzis ALL=(ALL) NOPASSWD: /bin/systemctl, /usr/sbin/service

# Allow passwordless sudo for common file operations Coolify might need
comzis ALL=(ALL) NOPASSWD: /bin/mkdir, /bin/chmod, /bin/chown, /usr/bin/tee

# Allow passwordless sudo for network/netstat (Coolify checks network status)
comzis ALL=(ALL) NOPASSWD: /bin/ss, /usr/bin/netstat, /usr/sbin/iptables
EOF

# Set correct permissions (sudoers files must be 0440)
chmod 0440 "$SUDOERS_FILE"
chown root:root "$SUDOERS_FILE"

# Validate sudoers syntax
echo ""
echo "Validating sudoers syntax..."
if visudo -c -f "$SUDOERS_FILE"; then
    echo "✓ Sudoers file syntax is valid"
else
    echo "❌ ERROR: Sudoers file has syntax errors!"
    echo "   Restoring backup..."
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$SUDOERS_FILE"
        chmod 0440 "$SUDOERS_FILE"
    fi
    exit 1
fi

echo ""
echo "=========================================="
echo "  Configuration Complete"
echo "=========================================="
echo ""
echo "Sudoers file created: $SUDOERS_FILE"
echo ""
echo "Allowed commands (passwordless):"
echo "  - Docker: /usr/bin/docker, /usr/bin/docker-compose"
echo "  - System: /bin/systemctl, /usr/sbin/service"
echo "  - File ops: /bin/mkdir, /bin/chmod, /bin/chown, /usr/bin/tee"
echo "  - Network: /bin/ss, /usr/bin/netstat, /usr/sbin/iptables"
echo ""
echo "Security Notes:"
echo "  ✓ Limited to specific commands (not ALL)"
echo "  ✓ Documented as security exception"
echo "  ✓ Required for Coolify automation"
echo "  ✓ More secure than NOPASSWD:ALL"
echo ""
echo "To test:"
echo "  sudo -n /usr/bin/docker ps    # Should work without password"
echo "  sudo -n /bin/systemctl status # Should work without password"
echo "  sudo -n /usr/bin/whoami       # Should require password (not in list)"

