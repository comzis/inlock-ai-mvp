#!/bin/bash
# Verify all security improvements from the audit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Security Improvements Verification ==="
echo ""

PASSED=0
FAILED=0

# Check 1: Postgres no-new-privileges documentation
echo "1. Checking Postgres no-new-privileges documentation..."
if grep -q "SECURITY NOTE: no-new-privileges temporarily disabled" "$PROJECT_ROOT/compose/services/postgres.yml" 2>/dev/null; then
    echo -e "${GREEN}✓ Postgres has security documentation${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠️  Postgres security note not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 2: Postgres fix script exists
echo "2. Checking Postgres permission fix script..."
if [ -f "$PROJECT_ROOT/scripts/security/fix-postgres-permissions.sh" ]; then
    echo -e "${GREEN}✓ Postgres fix script exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Postgres fix script not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 3: CasaOS security hardening
echo "3. Checking CasaOS security hardening..."
if grep -q "cap_drop:" "$PROJECT_ROOT/compose/services/casaos.yml" 2>/dev/null && \
   grep -q "no-new-privileges:true" "$PROJECT_ROOT/compose/services/casaos.yml" 2>/dev/null; then
    echo -e "${GREEN}✓ CasaOS has security hardening${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ CasaOS missing security hardening${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 4: CasaOS version tag (not :latest)
echo "4. Checking CasaOS image version..."
if grep -q "image: linuxserver/heimdall:" "$PROJECT_ROOT/compose/services/casaos.yml" 2>/dev/null && \
   ! grep -q "image: linuxserver/heimdall:latest" "$PROJECT_ROOT/compose/services/casaos.yml" 2>/dev/null; then
    echo -e "${GREEN}✓ CasaOS uses specific version${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠️  CasaOS may still use :latest${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 5: Image version policy exists
echo "5. Checking image version policy..."
if [ -f "$PROJECT_ROOT/docs/security/IMAGE-VERSION-POLICY.md" ]; then
    echo -e "${GREEN}✓ Image version policy exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Image version policy not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 6: Image version check script exists
echo "6. Checking image version check script..."
if [ -f "$PROJECT_ROOT/scripts/security/check-image-versions.sh" ]; then
    echo -e "${GREEN}✓ Image version check script exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Image version check script not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 7: SSH verification script exists
echo "7. Checking SSH verification script..."
if [ -f "$PROJECT_ROOT/scripts/security/verify-ssh-restrictions.sh" ]; then
    echo -e "${GREEN}✓ SSH verification script exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ SSH verification script not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 8: SSH access policy exists
echo "8. Checking SSH access policy..."
if [ -f "$PROJECT_ROOT/docs/security/SSH-ACCESS-POLICY.md" ]; then
    echo -e "${GREEN}✓ SSH access policy exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ SSH access policy not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 9: Mailcow documentation exists
echo "9. Checking Mailcow documentation..."
if [ -f "$PROJECT_ROOT/docs/security/MAILCOW-PORT-8080.md" ]; then
    echo -e "${GREEN}✓ Mailcow documentation exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Mailcow documentation not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 10: Local dev environment file
echo "10. Checking local dev environment setup..."
if [ -f "$PROJECT_ROOT/.env.local.example" ]; then
    echo -e "${GREEN}✓ Local dev environment template exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠️  Local dev environment template not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 11: Local dev documentation
echo "11. Checking local dev documentation..."
if [ -f "$PROJECT_ROOT/docs/guides/LOCAL-DEVELOPMENT.md" ]; then
    echo -e "${GREEN}✓ Local dev documentation exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Local dev documentation not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 12: Security scanning documentation
echo "12. Checking security scanning documentation..."
if [ -f "$PROJECT_ROOT/docs/security/SECURITY-SCANNING.md" ]; then
    echo -e "${GREEN}✓ Security scanning documentation exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Security scanning documentation not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Check 13: Maintenance schedule
echo "13. Checking maintenance schedule..."
if [ -f "$PROJECT_ROOT/docs/security/MAINTENANCE-SCHEDULE.md" ]; then
    echo -e "${GREEN}✓ Maintenance schedule exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Maintenance schedule not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All security improvements verified${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some improvements need attention${NC}"
    exit 1
fi

