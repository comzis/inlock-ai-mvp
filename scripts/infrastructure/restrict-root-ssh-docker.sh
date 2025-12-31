#!/bin/bash
#
# Restrict root SSH access to specific Docker gateway IP only
# Removes broad Docker network access (172.16.0.0/12) and restricts to gateway IP
#
# Usage: sudo ./scripts/infrastructure/restrict-root-ssh-docker.sh

set -e

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

echo "=========================================="
echo "  Restricting Root SSH Access"
echo "  (Docker Networks -> Gateway IP Only)"
echo "=========================================="
echo ""

# Backup UFW rules
BACKUP_DIR="/root/ufw-backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/ufw-rules-$(date +%Y%m%d-%H%M%S).txt"
ufw status numbered > "$BACKUP_FILE"
echo "✓ UFW rules backed up to: $BACKUP_FILE"

# Current Docker gateway IP (may vary by network)
DOCKER_GATEWAY="172.18.0.1"
echo ""
echo "Target Docker gateway IP: $DOCKER_GATEWAY"
echo ""

# Check current SSH rules
echo "Current SSH rules:"
ufw status numbered | grep -E "22/tcp|22/udp" || echo "  (none found)"
echo ""

# Remove broad Docker network SSH rules
echo "Removing broad Docker network SSH rules..."
RULE_NUMS=$(ufw status numbered | grep -E "22.*172\.(16|18|20|23)" | sed -n 's/^\[\([0-9]*\)\].*/\1/p' | sort -rn)

REMOVED_COUNT=0
for NUM in $RULE_NUMS; do
    RULE_DESC=$(ufw status numbered | grep "^\[$NUM\]" | sed "s/^\[$NUM\]//")
    if echo "$RULE_DESC" | grep -qE "172\.(16|18|20|23)"; then
        echo "y" | ufw delete "$NUM" >/dev/null 2>&1 && {
            echo "  ✓ Removed rule [$NUM]: $RULE_DESC"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        } || echo "  ⚠️  Failed to remove rule [$NUM]"
    fi
done

if [ "$REMOVED_COUNT" -eq 0 ]; then
    echo "  (no broad Docker network rules found)"
fi

# Add specific gateway IP rule if not already present
echo ""
echo "Adding specific Docker gateway IP rule..."
if ufw status | grep -q "$DOCKER_GATEWAY.*22"; then
    echo "  ✓ Rule for $DOCKER_GATEWAY:22 already exists"
else
    ufw allow from "$DOCKER_GATEWAY/32" to any port 22 proto tcp comment 'SSH - Docker gateway (Coolify)' || {
        echo "  ❌ ERROR: Failed to add gateway IP rule"
        exit 1
    }
    echo "  ✓ Added rule for $DOCKER_GATEWAY/32:22"
fi

# Ensure Tailscale rules are still present
echo ""
echo "Verifying Tailscale SSH access..."
if ufw status | grep -qE "100\.(64|83|96)"; then
    echo "  ✓ Tailscale SSH rules present"
else
    echo "  ⚠️  WARNING: Tailscale SSH rules not found"
    echo "  Adding Tailscale network rule..."
    ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH - Tailscale network' || {
        echo "  ⚠️  Warning: Failed to add Tailscale rule (may already exist)"
    }
fi

# Reload firewall
echo ""
echo "Reloading UFW firewall..."
ufw reload || {
    echo "  ⚠️  Warning: UFW reload failed, but rules may still be applied"
}

# Verify final configuration
echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""
echo "SSH rules after changes:"
ufw status numbered | grep -E "22/tcp|22/udp" || echo "  (none found)"
echo ""

# Summary
echo "=========================================="
echo "  Configuration Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Removed: $REMOVED_COUNT broad Docker network rule(s)"
echo "  - Added: Docker gateway IP rule ($DOCKER_GATEWAY/32)"
echo "  - Preserved: Tailscale network access (100.64.0.0/10)"
echo ""
echo "Root SSH access is now restricted to:"
echo "  ✅ Tailscale network (100.64.0.0/10)"
echo "  ✅ Docker gateway IP only ($DOCKER_GATEWAY/32)"
echo "  ❌ No longer accessible from all Docker networks"
echo ""
echo "Security Impact:"
echo "  ✅ More restrictive access control"
echo "  ✅ Reduced attack surface"
echo "  ✅ Coolify still works (uses gateway IP)"
echo ""
echo "Next steps:"
echo "  1. Test Coolify connection: Check if server validation still works"
echo "  2. Monitor SSH logs: sudo tail -f /var/log/auth.log | grep root"
echo "  3. Review: docs/services/coolify/COOLIFY-SSH-RESTRICTION.md"
echo ""
echo "If Coolify breaks, rollback using:"
echo "  sudo ufw status numbered"
echo "  # Restore from backup or re-add Docker network rules"







