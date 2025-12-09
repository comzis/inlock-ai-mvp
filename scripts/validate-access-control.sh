#!/bin/bash
# Access Control Validation Script

echo "=========================================="
echo "ACCESS CONTROL VALIDATION"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check DNS resolution
echo "1. DNS RESOLUTION CHECK"
echo "----------------------"
for domain in traefik.inlock.ai portainer.inlock.ai n8n.inlock.ai cockpit.inlock.ai inlock.ai; do
    echo -n "  $domain: "
    IP=$(dig +short $domain | head -1)
    if [ -n "$IP" ]; then
        echo -e "${GREEN}✅ Resolves to $IP${NC}"
    else
        echo -e "${RED}❌ No resolution${NC}"
    fi
done
echo ""

# Check Traefik middleware
echo "2. TRAEFIK MIDDLEWARE CHECK"
echo "---------------------------"
if grep -q "allowed-admins" traefik/dynamic/middlewares.yml; then
    echo -e "  ${GREEN}✅ allowed-admins middleware exists${NC}"
    echo "  Allowed IPs:"
    grep -A 10 "allowed-admins:" traefik/dynamic/middlewares.yml | grep -E "100\.|2a09" | sed 's/^/    /'
else
    echo -e "  ${RED}❌ allowed-admins middleware NOT found${NC}"
fi
echo ""

# Check routers
echo "3. TRAEFIK ROUTER CHECK"
echo "----------------------"
for service in dashboard portainer n8n cockpit; do
    if grep -q "$service:" traefik/dynamic/routers.yml; then
        if grep -A 10 "$service:" traefik/dynamic/routers.yml | grep -q "allowed-admins"; then
            echo -e "  ${GREEN}✅ $service router has allowed-admins middleware${NC}"
        else
            echo -e "  ${YELLOW}⚠️  $service router exists but missing allowed-admins${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  $service router NOT found${NC}"
    fi
done
echo ""

# Test access
echo "4. ACCESS TEST (from server)"
echo "-----------------------------"
for domain in traefik.inlock.ai portainer.inlock.ai n8n.inlock.ai; do
    echo -n "  $domain: "
    STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://$domain 2>&1)
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
        echo -e "${GREEN}✅ HTTP $STATUS${NC}"
    else
        echo -e "${RED}❌ HTTP $STATUS${NC}"
    fi
done
echo ""

echo "=========================================="
echo "VALIDATION COMPLETE"
echo "=========================================="

