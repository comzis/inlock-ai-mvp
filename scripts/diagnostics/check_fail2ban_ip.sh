#!/bin/bash
# Check if an IP address is blocked by fail2ban

set -euo pipefail

IP_TO_CHECK="${1:-}"
if [ -z "$IP_TO_CHECK" ]; then
    echo "Usage: $0 <IP_ADDRESS>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

SERVER="comzis@100.83.222.69"

echo "========================================="
echo "fail2ban IP Block Check"
echo "========================================="
echo ""
echo "Checking IP: $IP_TO_CHECK"
echo "Server: $SERVER"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if fail2ban is running
echo "1. Checking fail2ban status..."
F2B_STATUS=$(timeout 10 ssh "$SERVER" "sudo systemctl status fail2ban --no-pager 2>&1 | grep -E 'Active:|failed|running' | head -2" || echo "fail2ban not running")

if echo "$F2B_STATUS" | grep -qi "active.*running"; then
    echo -e "${GREEN}✓${NC} fail2ban is running"
else
    echo -e "${YELLOW}⚠${NC} fail2ban may not be running"
    echo "$F2B_STATUS" | sed 's/^/   /'
fi
echo ""

# Check active jails
echo "2. Checking active jails..."
JAILS=$(timeout 10 ssh "$SERVER" "sudo fail2ban-client status 2>&1 | grep -A 100 'Jail list:' | head -20" || echo "")

if [ -n "$JAILS" ]; then
    echo "   Active jails:"
    echo "$JAILS" | sed 's/^/   /'
else
    echo "   No active jails found or fail2ban not configured"
fi
echo ""

# Check each jail for the IP
echo "3. Checking for IP in fail2ban jails..."
JAIL_LIST=$(timeout 10 ssh "$SERVER" "sudo fail2ban-client status 2>&1 | grep -A 100 'Jail list:' | tail -n +2 | tr ',' '\n' | tr -d ' ' | head -20" || echo "")

FOUND_IN_JAILS=""

if [ -n "$JAIL_LIST" ]; then
    for JAIL in $JAIL_LIST; do
        JAIL=$(echo "$JAIL" | xargs)
        if [ -z "$JAIL" ]; then
            continue
        fi
        
        BANNED_IPS=$(timeout 10 ssh "$SERVER" "sudo fail2ban-client status $JAIL 2>&1 | grep -E 'Banned IP list|Currently banned' -A 50 | grep -E '^[0-9]|IP list' || echo ''" || echo "")
        
        if echo "$BANNED_IPS" | grep -q "$IP_TO_CHECK"; then
            echo -e "${RED}✗${NC} IP $IP_TO_CHECK is BANNED in jail: $JAIL"
            FOUND_IN_JAILS="$FOUND_IN_JAILS $JAIL"
            
            # Get more details
            JAIL_STATUS=$(timeout 10 ssh "$SERVER" "sudo fail2ban-client status $JAIL 2>&1 | grep -A 5 'Banned IP list' || sudo fail2ban-client status $JAIL 2>&1 | grep -A 5 'Currently banned'" || echo "")
            if [ -n "$JAIL_STATUS" ]; then
                echo "$JAIL_STATUS" | sed 's/^/   /'
            fi
        fi
    done
fi

echo ""

# Check iptables rules
echo "4. Checking iptables for fail2ban rules..."
IPTABLES_RULES=$(timeout 10 ssh "$SERVER" "sudo iptables -L -n 2>&1 | grep -i 'fail2ban' -A 2 -B 2 | head -30" || echo "")

if [ -n "$IPTABLES_RULES" ]; then
    if echo "$IPTABLES_RULES" | grep -q "$IP_TO_CHECK"; then
        echo -e "${RED}✗${NC} IP $IP_TO_CHECK found in iptables fail2ban rules"
        echo "$IPTABLES_RULES" | grep -A 2 -B 2 "$IP_TO_CHECK" | sed 's/^/   /'
    else
        echo -e "${GREEN}✓${NC} IP $IP_TO_CHECK not found in iptables fail2ban rules"
    fi
else
    echo "   Could not check iptables rules"
fi
echo ""

# Summary
echo "=== Summary ==="
echo ""
if [ -n "$FOUND_IN_JAILS" ]; then
    echo -e "${RED}✗ IP $IP_TO_CHECK IS BLOCKED by fail2ban${NC}"
    echo ""
    echo "Blocked in jails: $FOUND_IN_JAILS"
    echo ""
    echo "To unban this IP, run:"
    for JAIL in $FOUND_IN_JAILS; do
        JAIL=$(echo "$JAIL" | xargs)
        echo "  ssh $SERVER \"sudo fail2ban-client set $JAIL unbanip $IP_TO_CHECK\""
    done
    echo ""
    echo "Or unban from all jails at once:"
    echo "  ssh $SERVER \"sudo fail2ban-client unban $IP_TO_CHECK\""
else
    echo -e "${GREEN}✓ IP $IP_TO_CHECK is NOT blocked by fail2ban${NC}"
    echo ""
    echo "If you're still experiencing connection issues:"
    echo "  1. Check iOS Mail configuration (see docs/ios-mail-imap-server-null-fix.md)"
    echo "  2. Check network connectivity from your device"
    echo "  3. Check Dovecot logs for connection errors"
fi
echo ""
