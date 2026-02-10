#!/bin/bash
# Quick check if IP 31.10.147.220 is blocked

set -euo pipefail

IP="31.10.147.220"
SERVER="comzis@100.83.222.69"

echo "========================================="
echo "Checking if IP is blocked: $IP"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "IP to check: $IP"
echo "Server: $SERVER"
echo ""
echo "⚠️  Note: This script requires sudo access on the server."
echo "You'll need to SSH to the server and run commands manually."
echo ""
echo "========================================="
echo "Manual Check Commands"
echo "========================================="
echo ""
echo "1. SSH to server:"
echo "   ssh $SERVER"
echo ""
echo "2. Check iptables (requires sudo):"
echo "   sudo iptables -L -n | grep '$IP'"
echo ""
echo "3. Check fail2ban dovecot jail:"
echo "   sudo fail2ban-client status dovecot | grep '$IP'"
echo ""
echo "4. Check fail2ban postfix jail:"
echo "   sudo fail2ban-client status postfix | grep '$IP'"
echo ""
echo "5. Check all fail2ban jails:"
echo "   sudo fail2ban-client status"
echo ""
echo "========================================="
echo "If IP is blocked, unban commands:"
echo "========================================="
echo ""
echo "1. Unban from all jails:"
echo "   sudo fail2ban-client unban $IP"
echo ""
echo "2. Unban from specific jail (dovecot):"
echo "   sudo fail2ban-client set dovecot unbanip $IP"
echo ""
echo "3. Unban from specific jail (postfix):"
echo "   sudo fail2ban-client set postfix unbanip $IP"
echo ""
echo "========================================="
echo "Quick Check (if you have passwordless sudo):"
echo "========================================="
echo ""

# Try to check if we can access iptables without sudo
IPTABLES_CHECK=$(timeout 5 ssh "$SERVER" "iptables -L -n 2>&1 | grep '$IP' || echo 'not found (non-sudo)'" || echo "SSH failed")

if echo "$IPTABLES_CHECK" | grep -q "$IP"; then
    echo -e "${RED}✗${NC} IP $IP found in iptables:"
    echo "$IPTABLES_CHECK" | sed 's/^/   /'
    echo ""
    echo "⚠️  This IP appears to be blocked!"
    echo "Run unban command on server: sudo fail2ban-client unban $IP"
else
    echo -e "${GREEN}✓${NC} IP $IP not found in iptables (non-sudo check)"
    echo ""
    echo "Note: To check with full privileges, run on server:"
    echo "  sudo iptables -L -n | grep '$IP'"
    echo "  sudo fail2ban-client status dovecot | grep '$IP'"
fi
echo ""
