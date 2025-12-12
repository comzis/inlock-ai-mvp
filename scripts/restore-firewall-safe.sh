#!/bin/bash
# Restore Firewall Settings Safely - Preserves SSH Access
# This script restores firewall rules while ensuring SSH access is maintained
# Run with: sudo ./scripts/restore-firewall-safe.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Restoring Firewall Settings Safely"
echo "  Started: $(date)"
echo "=========================================="
echo ""

# Tailscale IPs (from configure-firewall.sh)
TAILSCALE_SERVER="100.83.222.69"
TAILSCALE_MACBOOK="100.96.110.8"

# ============================================================================
# STEP 1: VERIFY SSH IS WORKING
# ============================================================================
echo "=== STEP 1: Verifying SSH Service ==="
if systemctl is-active --quiet ssh; then
    echo "  ✓ SSH service is running"
else
    echo "  ⚠️  SSH service is not running, starting it..."
    systemctl start ssh
    systemctl enable ssh
    echo "  ✓ SSH service started"
fi

# Check SSH is listening
if ss -tlnp | grep -q ":22"; then
    echo "  ✓ SSH is listening on port 22"
else
    echo "  ❌ SSH is not listening on port 22 - please check SSH configuration"
    exit 1
fi
echo ""

# ============================================================================
# STEP 2: INSTALL/ENSURE UFW IS AVAILABLE
# ============================================================================
echo "=== STEP 2: Ensuring UFW is installed ==="
if ! command -v ufw >/dev/null 2>&1; then
    echo "  Installing UFW..."
    apt-get update -qq
    apt-get install -y ufw
    echo "  ✓ UFW installed"
else
    echo "  ✓ UFW is installed"
fi
echo ""

# ============================================================================
# STEP 3: BACKUP CURRENT FIREWALL STATE
# ============================================================================
echo "=== STEP 3: Backing up current firewall state ==="
BACKUP_DIR="/root/firewall-backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/ufw-backup-$(date +%Y%m%d-%H%M%S).txt"
ufw status verbose > "$BACKUP_FILE" 2>&1 || true
if [ -f /etc/ufw/user.rules ]; then
    cp /etc/ufw/user.rules "$BACKUP_DIR/user.rules.backup-$(date +%Y%m%d-%H%M%S)"
fi
echo "  ✓ Backup saved to: $BACKUP_FILE"
echo ""

# ============================================================================
# STEP 4: RESET FIREWALL RULES (CAREFULLY)
# ============================================================================
echo "=== STEP 4: Resetting firewall rules ==="

# Disable firewall temporarily to reset rules safely
if ufw status | grep -q "Status: active"; then
    echo "  Firewall is currently active"
    echo "  Disabling temporarily to reset rules..."
    ufw --force disable
    sleep 2
fi

# Reset to defaults
echo "  Resetting to default policies..."
ufw --force reset
echo "  ✓ Firewall rules reset"
echo ""

# ============================================================================
# STEP 5: CONFIGURE DEFAULT POLICIES
# ============================================================================
echo "=== STEP 5: Setting default policies ==="
ufw default deny incoming
ufw default allow outgoing
ufw default allow routed
echo "  ✓ Default policies: deny incoming, allow outgoing, allow routed"
echo ""

# ============================================================================
# STEP 6: ALLOW ESSENTIAL SERVICES
# ============================================================================
echo "=== STEP 6: Allowing essential services ==="

# Tailscale (required for SSH access)
echo "  Allowing Tailscale..."
ufw allow 41641/udp comment 'Tailscale'
echo "  ✓ Tailscale allowed"

# HTTP/HTTPS (required for Traefik and services)
echo "  Allowing HTTP/HTTPS..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
echo "  ✓ HTTP/HTTPS allowed"
echo ""

# ============================================================================
# STEP 7: CONFIGURE SSH ACCESS (CRITICAL)
# ============================================================================
echo "=== STEP 7: Configuring SSH access (CRITICAL) ==="

# Remove any existing SSH rules first
echo "  Removing existing SSH rules..."
ufw status numbered | grep -E "22/tcp|22/udp" | awk -F'[][]' '{print $2}' | sort -rn | while read num; do
    if [ -n "$num" ]; then
        echo "y" | ufw delete "$num" >/dev/null 2>&1 || true
    fi
done

# Add Tailscale-specific SSH rules FIRST (most restrictive)
echo "  Adding SSH rules for Tailscale IPs..."
ufw allow from ${TAILSCALE_SERVER}/32 to any port 22 proto tcp comment 'SSH - Tailscale Server'
ufw allow from ${TAILSCALE_MACBOOK}/32 to any port 22 proto tcp comment 'SSH - Tailscale MacBook'
echo "  ✓ SSH restricted to Tailscale IPs: $TAILSCALE_SERVER, $TAILSCALE_MACBOOK"

# Allow SSH from Docker networks (for Coolify)
echo "  Adding SSH rules for Docker networks..."
ufw allow from 172.18.0.0/16 to any port 22 proto tcp comment 'SSH - Docker mgmt network'
ufw allow from 172.23.0.0/16 to any port 22 proto tcp comment 'SSH - Docker coolify network'
ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'SSH - Docker networks (broad)'
echo "  ✓ SSH allowed from Docker networks"
echo ""

# ============================================================================
# STEP 8: BLOCK UNNECESSARY PORTS
# ============================================================================
echo "=== STEP 8: Blocking unnecessary ports ==="
ufw deny 11434/tcp comment 'Ollama - Internal only'
ufw deny 3040/tcp comment 'Port 3040 - Internal only'
ufw deny 5432/tcp comment 'PostgreSQL - Internal only'
echo "  ✓ Unnecessary ports blocked"
echo ""

# ============================================================================
# STEP 9: ALLOW INTERNAL DOCKER NETWORKS
# ============================================================================
echo "=== STEP 9: Allowing internal Docker networks ==="
ufw allow from 172.20.0.0/16 comment 'Docker edge network'
ufw allow from 172.18.0.0/16 comment 'Docker default network'
ufw allow from 172.17.0.0/16 comment 'Docker bridge network'
echo "  ✓ Internal Docker networks allowed"
echo ""

# ============================================================================
# STEP 10: ENABLE FIREWALL
# ============================================================================
echo "=== STEP 10: Enabling firewall ==="
echo "  WARNING: Firewall will be enabled in 5 seconds..."
echo "  Press Ctrl+C to cancel if SSH access is not ready"
sleep 5

ufw --force enable
echo "  ✓ Firewall enabled"
echo ""

# ============================================================================
# STEP 11: VERIFY CONFIGURATION
# ============================================================================
echo "=== STEP 11: Verifying configuration ==="
echo ""
echo "Firewall status:"
ufw status numbered
echo ""

# Check SSH rules specifically
echo "SSH access rules:"
ufw status numbered | grep -E "22|SSH|Tailscale|Docker" || ufw status | grep 22
echo ""

# ============================================================================
# STEP 12: VERIFY AUTH0 CONFIGURATION
# ============================================================================
echo "=== STEP 12: Verifying Auth0 configuration ==="
cd /home/comzis/inlock-infra 2>/dev/null || cd /root/inlock-infra 2>/dev/null || true

if [ -f .env ]; then
    if grep -q "AUTH0_ISSUER" .env && grep -q "AUTH0_ADMIN_CLIENT_ID" .env; then
        echo "  ✓ Auth0 configuration found in .env"
        AUTH0_ISSUER=$(grep "^AUTH0_ISSUER=" .env | cut -d'=' -f2 | tr -d '"' || echo "")
        if [ -n "$AUTH0_ISSUER" ]; then
            echo "  ✓ Auth0 Issuer: $AUTH0_ISSUER"
        fi
    else
        echo "  ⚠️  Auth0 configuration may be incomplete in .env"
    fi
else
    echo "  ⚠️  .env file not found - Auth0 configuration cannot be verified"
fi

# Check if oauth2-proxy container is running
if docker ps --format '{{.Names}}' | grep -q "oauth2-proxy"; then
    echo "  ✓ OAuth2-Proxy container is running"
else
    echo "  ⚠️  OAuth2-Proxy container is not running"
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "=========================================="
echo "  Firewall Restoration Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "✓ Firewall enabled with secure rules"
echo "✓ SSH restricted to Tailscale IPs: $TAILSCALE_SERVER, $TAILSCALE_MACBOOK"
echo "✓ SSH allowed from Docker networks (for Coolify)"
echo "✓ HTTP/HTTPS allowed (ports 80, 443)"
echo "✓ Tailscale allowed (port 41641/udp)"
echo "✓ Unnecessary ports blocked (11434, 3040, 5432)"
echo "✓ Internal Docker networks allowed"
echo ""
echo "Next steps:"
echo "1. Test SSH access from Tailscale IPs:"
echo "   ssh comzis@$(hostname -I | awk '{print $1}')"
echo ""
echo "2. Verify services are accessible:"
echo "   cd /home/comzis/inlock-infra"
echo "   docker compose -f compose/stack.yml --env-file .env ps"
echo ""
echo "3. Check firewall logs if needed:"
echo "   tail -f /var/log/ufw.log"
echo ""
echo "4. If SSH access is lost, firewall can be disabled temporarily:"
echo "   sudo ufw disable"
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
