#!/usr/bin/env bash
set -euo pipefail

# Cursor Rules Compliance Checker
# Verifies compliance with .cursorrules guidelines
# Based on IMPROVEMENT-STEPS-2025-12-29.md

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SCORE=0
MAX_SCORE=0
ISSUES=0
WARNINGS=0

echo "=== Cursor Rules Compliance Check ==="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Date: $(date +%Y-%m-%d)"
echo ""

# Function to add score
add_score() {
    local points=$1
    local max=$2
    SCORE=$((SCORE + points))
    MAX_SCORE=$((MAX_SCORE + max))
}

# Function to report issue
report_issue() {
    local severity=$1
    shift
    echo -e "${RED}❌ $severity: $*${NC}"
    ISSUES=$((ISSUES + 1))
}

# Function to report warning
report_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $*${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# Function to report success
report_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

# 1. Root Directory Cleanliness (10 points)
echo "1. Checking Root Directory Cleanliness..."
cd "$PROJECT_ROOT" || exit 1
UNEXPECTED_ITEMS=0
UNEXPECTED_LIST=""

# Check each item in root directory
while IFS= read -r item; do
    [ -z "$item" ] && continue
    case "$item" in
        README.md|QUICK-START.md|TODO.md|env.example|inlock-ai.code-workspace|server_env_file_found|.cursorrules|.cursorrules-security|.gitignore|.env.local.example)
            # Allowed files - skip
            ;;
        compose|config|docs|scripts|traefik|ansible|archive|e2e|logs|secrets|infrastructure)
            # Allowed directories - skip
            ;;
        .git|.gitignore)
            # Git files - skip
            ;;
        *)
            # Unexpected item
            UNEXPECTED_ITEMS=$((UNEXPECTED_ITEMS + 1))
            UNEXPECTED_LIST="${UNEXPECTED_LIST}  - $item\n"
            ;;
    esac
done < <(ls -1 2>/dev/null)

if [ "$UNEXPECTED_ITEMS" -eq 0 ]; then
    report_success "Root directory is clean (only allowed files and directories)"
    add_score 10 10
else
    report_issue "HIGH" "Root directory contains $UNEXPECTED_ITEMS unexpected item(s)"
    echo -e "$UNEXPECTED_LIST"
    add_score 5 10
fi
echo ""

# 2. Directory Structure Compliance (10 points)
echo "2. Checking Directory Structure..."
MISSING_DIRS=0
for dir in "compose" "traefik" "docs" "config" "scripts"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        report_success "Directory exists: $dir/"
    else
        report_issue "HIGH" "Required directory missing: $dir/"
        MISSING_DIRS=$((MISSING_DIRS + 1))
    fi
done

# Check for competing structures
if [ -d "$PROJECT_ROOT/infrastructure" ]; then
    report_warning "Competing directory structure found: infrastructure/ (should use existing structure)"
fi

if [ "$MISSING_DIRS" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - MISSING_DIRS * 2)) 10
fi
echo ""

# 3. Empty Directory Check (10 points)
echo "3. Checking for Empty Directories..."
EMPTY_DIRS=0
if [ -d "$PROJECT_ROOT/compose/grafana" ]; then
    report_issue "MEDIUM" "Empty directory found: compose/grafana/ (should be removed, configs are in config/grafana/)"
    EMPTY_DIRS=$((EMPTY_DIRS + 1))
fi

# Check for other empty directories
find "$PROJECT_ROOT/compose" -type d -empty 2>/dev/null | while read -r dir; do
    if [ "$dir" != "$PROJECT_ROOT/compose" ]; then
        report_warning "Empty directory found: $dir"
    fi
done

if [ "$EMPTY_DIRS" -eq 0 ]; then
    report_success "No empty directories found"
    add_score 10 10
else
    add_score $((10 - EMPTY_DIRS * 5)) 10
fi
echo ""

# 4. Middleware Order Validation (10 points)
echo "4. Checking Traefik Middleware Order..."
MIDDLEWARE_VIOLATIONS=0
if [ -f "$PROJECT_ROOT/traefik/dynamic/routers.yml" ]; then
    # Check for allowed-admins after admin-forward-auth (CRITICAL violation)
    # Correct order: allowed-admins BEFORE admin-forward-auth (or not at all)
    # Wrong order: admin-forward-auth then allowed-admins (blocks authenticated users)
    VIOLATIONS=$(grep -A 15 "admin-forward-auth" "$PROJECT_ROOT/traefik/dynamic/routers.yml" 2>/dev/null | grep -B 5 "allowed-admins" 2>/dev/null | grep -c "admin-forward-auth" 2>/dev/null || echo "0")
    # Ensure VIOLATIONS is a number
    if ! [[ "$VIOLATIONS" =~ ^[0-9]+$ ]]; then
        VIOLATIONS=0
    fi
    if [ "$VIOLATIONS" -gt 0 ]; then
        report_issue "CRITICAL" "Middleware order violation: allowed-admins found after admin-forward-auth"
        echo "  This causes 403 errors for authenticated users"
        echo "  Correct order: allowed-admins BEFORE admin-forward-auth (or remove allowed-admins)"
        MIDDLEWARE_VIOLATIONS=$((MIDDLEWARE_VIOLATIONS + 1))
    else
        report_success "Middleware order is correct (no allowed-admins after admin-forward-auth)"
    fi
else
    report_warning "routers.yml not found, skipping middleware check"
fi

if [ "$MIDDLEWARE_VIOLATIONS" -eq 0 ]; then
    add_score 10 10
else
    add_score 0 10
fi
echo ""

# 5. Secrets Management (10 points)
echo "5. Checking Secrets Management..."
SECRET_VIOLATIONS=0

# Check for hardcoded passwords in compose files
if grep -r "PASSWORD=" "$PROJECT_ROOT/compose/services"/*.yml 2>/dev/null | grep -v "\${" | grep -v "#" | grep -v "Required" | grep -v "/run/secrets" | grep -v "example" > /dev/null; then
    report_issue "CRITICAL" "Hardcoded passwords found in compose files"
    grep -r "PASSWORD=" "$PROJECT_ROOT/compose/services"/*.yml 2>/dev/null | grep -v "\${" | grep -v "#" | grep -v "Required" | grep -v "/run/secrets" | grep -v "example" | while read -r line; do
        echo "  $line"
    done
    SECRET_VIOLATIONS=$((SECRET_VIOLATIONS + 1))
else
    report_success "No hardcoded passwords found"
fi

# Check for .env files in git
if git ls-files "$PROJECT_ROOT" 2>/dev/null | grep -q "\.env$"; then
    report_issue "HIGH" ".env file is tracked in git (should be in .gitignore)"
    SECRET_VIOLATIONS=$((SECRET_VIOLATIONS + 1))
else
    report_success ".env file not tracked in git"
fi

if [ "$SECRET_VIOLATIONS" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - SECRET_VIOLATIONS * 5)) 10
fi
echo ""

# 6. Documentation Structure (10 points)
echo "6. Checking Documentation Structure..."
DOC_ISSUES=0

# Check if docs/index.md exists
if [ ! -f "$PROJECT_ROOT/docs/index.md" ]; then
    report_warning "docs/index.md not found (should exist for major changes)"
    DOC_ISSUES=$((DOC_ISSUES + 1))
else
    report_success "docs/index.md exists"
fi

# Check documentation organization
if [ -d "$PROJECT_ROOT/docs/security" ] && [ -d "$PROJECT_ROOT/docs/architecture" ]; then
    report_success "Documentation is well-organized"
else
    report_warning "Documentation structure may need improvement"
fi

if [ "$DOC_ISSUES" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - DOC_ISSUES * 2)) 10
fi
echo ""

# 7. Compose File Structure (10 points)
echo "7. Checking Compose File Structure..."
COMPOSE_ISSUES=0

# Check if stack.yml exists
if [ ! -f "$PROJECT_ROOT/compose/services/stack.yml" ]; then
    report_issue "HIGH" "Main stack file missing: compose/services/stack.yml"
    COMPOSE_ISSUES=$((COMPOSE_ISSUES + 1))
else
    report_success "Main stack file exists"
fi

# Check for duplicate config files
if [ -f "$PROJECT_ROOT/compose/stack.yml" ] && [ -f "$PROJECT_ROOT/compose/services/stack.yml" ]; then
    report_warning "Duplicate stack files found (compose/stack.yml and compose/services/stack.yml)"
    COMPOSE_ISSUES=$((COMPOSE_ISSUES + 1))
fi

if [ "$COMPOSE_ISSUES" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - COMPOSE_ISSUES * 5)) 10
fi
echo ""

# 8. Traefik Configuration Structure (10 points)
echo "8. Checking Traefik Configuration Structure..."
TRAEFIK_ISSUES=0

# Check directory structure
if [ -d "$PROJECT_ROOT/traefik/dynamic" ] && [ -d "$PROJECT_ROOT/config/traefik" ]; then
    report_success "Traefik config structure is correct"
else
    report_issue "MEDIUM" "Traefik config structure issue (dynamic should be in traefik/, static in config/traefik/)"
    TRAEFIK_ISSUES=$((TRAEFIK_ISSUES + 1))
fi

if [ "$TRAEFIK_ISSUES" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - TRAEFIK_ISSUES * 5)) 10
fi
echo ""

# 9. Service Config Location (10 points)
echo "9. Checking Service Config Locations..."
SERVICE_ISSUES=0

# Check if service configs are in config/<service>/
for service in grafana prometheus alertmanager; do
    if [ -d "$PROJECT_ROOT/config/$service" ]; then
        report_success "Service config exists: config/$service/"
    else
        # This is not necessarily an issue, just informational
        :
    fi
done

# Check for configs in wrong location
if [ -d "$PROJECT_ROOT/compose/grafana" ]; then
    report_warning "Service config in wrong location: compose/grafana/ (should be in config/grafana/)"
    SERVICE_ISSUES=$((SERVICE_ISSUES + 1))
fi

if [ "$SERVICE_ISSUES" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - SERVICE_ISSUES * 5)) 10
fi
echo ""

# 10. Git Ignore Patterns (10 points)
echo "10. Checking .gitignore Patterns..."
GITIGNORE_ISSUES=0

if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if grep -q "\.env$" "$PROJECT_ROOT/.gitignore"; then
        report_success ".env is in .gitignore"
    else
        report_issue "MEDIUM" ".env not in .gitignore"
        GITIGNORE_ISSUES=$((GITIGNORE_ISSUES + 1))
    fi
    
    if grep -q "secrets/" "$PROJECT_ROOT/.gitignore" || grep -q "secrets-real/" "$PROJECT_ROOT/.gitignore"; then
        report_success "Secrets directories are in .gitignore"
    else
        report_warning "Secrets directories may not be in .gitignore"
    fi
else
    report_issue "MEDIUM" ".gitignore file not found"
    GITIGNORE_ISSUES=$((GITIGNORE_ISSUES + 1))
fi

if [ "$GITIGNORE_ISSUES" -eq 0 ]; then
    add_score 10 10
else
    add_score $((10 - GITIGNORE_ISSUES * 5)) 10
fi
echo ""

# Calculate final score
FINAL_SCORE=$((SCORE * 100 / MAX_SCORE))

echo "=== Compliance Score ==="
echo ""
echo "Score: $SCORE/$MAX_SCORE = $FINAL_SCORE/100"
echo "Issues Found: $ISSUES"
echo "Warnings: $WARNINGS"
echo ""

if [ "$FINAL_SCORE" -eq 100 ]; then
    echo -e "${GREEN}✅ PERFECT COMPLIANCE - 100/100${NC}"
    exit 0
elif [ "$FINAL_SCORE" -ge 90 ]; then
    echo -e "${GREEN}✅ EXCELLENT - $FINAL_SCORE/100${NC}"
    exit 0
elif [ "$FINAL_SCORE" -ge 80 ]; then
    echo -e "${YELLOW}⚠️  GOOD - $FINAL_SCORE/100 (needs minor improvements)${NC}"
    exit 0
elif [ "$FINAL_SCORE" -ge 70 ]; then
    echo -e "${YELLOW}⚠️  ACCEPTABLE - $FINAL_SCORE/100 (needs improvements)${NC}"
    exit 1
else
    echo -e "${RED}❌ NEEDS WORK - $FINAL_SCORE/100 (significant issues found)${NC}"
    exit 1
fi

