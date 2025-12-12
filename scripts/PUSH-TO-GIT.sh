#!/bin/bash
# Push Inlock AI repositories to Git
# This script pushes both the application and infrastructure repositories

set -e

echo "========================================="
echo "Publishing Inlock AI to Git"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Application Repository
echo -e "${GREEN}Step 1: Application Repository${NC}"
echo "Location: /opt/inlock-ai-secure-mvp"
echo ""

cd /opt/inlock-ai-secure-mvp

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Warning: Uncommitted changes detected${NC}"
    git status --short
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Verify no sensitive files
echo "Checking for sensitive files..."
if git ls-files | grep -qE "\.env$|\.env\.(production|local)$" | grep -v ".example"; then
    echo -e "${RED}❌ ERROR: Sensitive .env files found in repository!${NC}"
    git ls-files | grep -E "\.env$|\.env\.(production|local)$" | grep -v ".example"
    echo "Please remove these files before pushing."
    exit 1
fi

echo -e "${GREEN}✅ No sensitive files detected${NC}"
echo ""

# Show commit
echo "Latest commit:"
git log --oneline -1
echo ""

# Confirm push
read -p "Push application repository to origin/main? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing to origin/main..."
    git push origin main
    echo -e "${GREEN}✅ Application repository pushed successfully!${NC}"
else
    echo "Skipped application repository push"
fi

echo ""
echo "========================================="
echo ""

# 2. Infrastructure Repository
echo -e "${GREEN}Step 2: Infrastructure Repository${NC}"
echo "Location: /home/comzis/inlock-infra"
echo ""

cd /home/comzis/inlock-infra

# Check remote
if ! git remote | grep -q origin; then
    echo -e "${YELLOW}⚠️  No remote configured${NC}"
    echo ""
    echo "To add a remote, run:"
    echo "  git remote add origin https://github.com/comzis/inlock-infra.git"
    echo ""
    read -p "Enter remote URL (or press Enter to skip): " REMOTE_URL
    if [ -n "$REMOTE_URL" ]; then
        git remote add origin "$REMOTE_URL"
        echo -e "${GREEN}✅ Remote added${NC}"
    else
        echo "Skipping infrastructure repository (no remote configured)"
        exit 0
    fi
fi

# Verify no secrets
echo "Checking for secrets..."
if git ls-files | grep -qE "secrets-real|\.env$|password|\.key$|\.crt$" | grep -v ".example"; then
    echo -e "${RED}❌ ERROR: Secrets found in repository!${NC}"
    git ls-files | grep -E "secrets-real|\.env$|password|\.key$|\.crt$" | grep -v ".example"
    echo "Please remove these files before pushing."
    exit 1
fi

echo -e "${GREEN}✅ No secrets detected${NC}"
echo ""

# Show commit
echo "Latest commit:"
git log --oneline -1
echo ""

# Show remote
echo "Remote:"
git remote -v
echo ""

# Confirm push
read -p "Push infrastructure repository to origin/main? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing to origin/main..."
    git push -u origin main
    echo -e "${GREEN}✅ Infrastructure repository pushed successfully!${NC}"
else
    echo "Skipped infrastructure repository push"
fi

echo ""
echo "========================================="
echo -e "${GREEN}✅ Publishing complete!${NC}"
echo ""

