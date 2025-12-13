#!/usr/bin/env bash
# Setup Auth0 Management API credentials
# This script helps configure Auth0 Management API access for automation
#
# Usage: ./scripts/setup-auth0-management-api.sh
#
# Prerequisites:
# 1. Auth0 account with admin access
# 2. Access to Auth0 Dashboard: https://manage.auth0.com/

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

ENV_FILE="${ENV_FILE:-.env}"

echo "========================================="
echo "Auth0 Management API Setup"
echo "========================================="
echo ""

echo "This script will guide you through setting up Auth0 Management API access."
echo "Management API allows programmatic access to Auth0 configuration."
echo ""

echo "Step 1: Create Machine-to-Machine Application in Auth0"
echo "------------------------------------------------------"
echo "1. Go to: https://manage.auth0.com/"
echo "2. Navigate to: Applications → Applications"
echo "3. Click: 'Create Application'"
echo "4. Name: 'inlock-management-api' (or similar)"
echo "5. Select: 'Machine to Machine Applications'"
echo "6. Click: 'Create'"
echo ""
read -p "Press Enter when you've created the M2M application..."

echo ""
echo "Step 2: Authorize Management API"
echo "--------------------------------"
echo "1. In your M2M application settings, find 'APIs' section"
echo "2. Select: 'Auth0 Management API'"
echo "3. Authorize the application"
echo "4. Grant the following scopes:"
echo "   - read:applications"
echo "   - update:applications"
echo "   - read:clients"
echo "   - update:clients"
echo ""
read -p "Press Enter when you've authorized and granted scopes..."

echo ""
echo "Step 3: Get Client Credentials"
echo "------------------------------"
echo "1. In your M2M application, go to 'Settings' tab"
echo "2. Copy the 'Client ID'"
echo "3. Copy the 'Client Secret' (click 'Show' if hidden)"
echo ""

read -p "Enter Client ID: " CLIENT_ID
read -sp "Enter Client Secret: " CLIENT_SECRET
echo ""

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "❌ Error: Client ID and Client Secret are required"
  exit 1
fi

echo ""
echo "Step 4: Update .env file"
echo "-----------------------"

# Backup .env file
if [ -f "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${ENV_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "✅ Backed up $ENV_FILE"
fi

# Update or add AUTH0_MGMT_CLIENT_ID
if grep -q "^AUTH0_MGMT_CLIENT_ID=" "$ENV_FILE" 2>/dev/null; then
  sed -i "s|^AUTH0_MGMT_CLIENT_ID=.*|AUTH0_MGMT_CLIENT_ID=$CLIENT_ID|" "$ENV_FILE"
  echo "✅ Updated AUTH0_MGMT_CLIENT_ID in $ENV_FILE"
else
  echo "" >> "$ENV_FILE"
  echo "# Auth0 Management API (M2M)" >> "$ENV_FILE"
  echo "AUTH0_MGMT_CLIENT_ID=$CLIENT_ID" >> "$ENV_FILE"
  echo "✅ Added AUTH0_MGMT_CLIENT_ID to $ENV_FILE"
fi

# Update or add AUTH0_MGMT_CLIENT_SECRET
if grep -q "^AUTH0_MGMT_CLIENT_SECRET=" "$ENV_FILE" 2>/dev/null; then
  sed -i "s|^AUTH0_MGMT_CLIENT_SECRET=.*|AUTH0_MGMT_CLIENT_SECRET=$CLIENT_SECRET|" "$ENV_FILE"
  echo "✅ Updated AUTH0_MGMT_CLIENT_SECRET in $ENV_FILE"
else
  echo "AUTH0_MGMT_CLIENT_SECRET=$CLIENT_SECRET" >> "$ENV_FILE"
  echo "✅ Added AUTH0_MGMT_CLIENT_SECRET to $ENV_FILE"
fi

echo ""
echo "Step 5: Test Configuration"
echo "-------------------------"
echo "Testing Management API access..."

if [ -f "scripts/test-auth0-api.sh" ]; then
  ./scripts/test-auth0-api.sh
else
  echo "⚠️  test-auth0-api.sh not found, skipping automated test"
  echo "   You can test manually using curl or the Auth0 Management API"
fi

echo ""
echo "========================================="
echo "✅ Setup Complete"
echo "========================================="
echo ""
echo "Management API credentials have been added to $ENV_FILE"
echo ""
echo "Next steps:"
echo "1. Restart services that use Auth0 if needed"
echo "2. Test Management API access: ./scripts/test-auth0-api.sh"
echo "3. Use scripts/configure-auth0-api.sh to configure Auth0 via API"
echo ""

