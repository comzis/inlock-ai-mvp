# Management API Test Examples & Validation

**Agent:** API Tester Buddy (Agent 7)  
**Date:** 2025-12-13  
**Purpose:** curl/jq examples for Management API validation

---

## Prerequisites

### Required Environment Variables

Ensure these are set in `/home/comzis/inlock-infra/.env`:

```bash
AUTH0_DOMAIN=comzis.eu.auth0.com
AUTH0_MGMT_CLIENT_ID=<your-m2m-client-id>
AUTH0_MGMT_CLIENT_SECRET=<your-m2m-client-secret>
AUTH0_ADMIN_CLIENT_ID=aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o
```

### Setup Script

If not configured, run:
```bash
cd /home/comzis/inlock-infra
./scripts/setup-auth0-management-api.sh
```

---

## Quick Test Script

### Test 1: Verify Credentials & Get Token

```bash
#!/bin/bash
# Quick test: Verify Management API access

cd /home/comzis/inlock-infra
source .env

AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"

echo "=== Testing Auth0 Management API ==="
echo "Domain: $AUTH0_DOMAIN"
echo ""

# Check if credentials exist
if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
  echo "❌ Error: Management API credentials not found in .env"
  echo "Run: ./scripts/setup-auth0-management-api.sh"
  exit 1
fi

echo "✓ Credentials found"
echo ""

# Get access token
echo "1. Getting access token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')
ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

if [ -n "$ERROR" ] || [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Failed to get access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "   ✓ Token obtained (length: ${#ACCESS_TOKEN} chars)"
echo ""

# Test API access
echo "2. Testing API access..."
APPS_RESPONSE=$(curl -s -X GET "${AUTH0_API_URL}/clients" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

ERROR=$(echo "$APPS_RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "❌ API request failed: $ERROR"
  exit 1
fi

APP_COUNT=$(echo "$APPS_RESPONSE" | jq '. | length')
echo "   ✓ API access working ($APP_COUNT applications found)"
echo ""

echo "=== Test Complete ==="
echo "✓ Management API is configured and working"
```

**Save and run:**
```bash
chmod +x /tmp/test-mgmt-api-quick.sh
/tmp/test-mgmt-api-quick.sh
```

---

## curl/jq Examples

### Example 1: Get Access Token

```bash
cd /home/comzis/inlock-infra
source .env

AUTH0_DOMAIN="comzis.eu.auth0.com"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"

# Get token
TOKEN_RESPONSE=$(curl -s -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

# Extract token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

# Verify token
echo "Token: ${ACCESS_TOKEN:0:20}..."  # First 20 chars
```

**Expected output:**
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

---

### Example 2: Get Admin Application Details

```bash
# Using ACCESS_TOKEN from Example 1

CLIENT_ID="aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"

# Get application
APP=$(curl -s -X GET "${AUTH0_API_URL}/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

# Extract key fields
echo "Application Name: $(echo "$APP" | jq -r '.name')"
echo "Client ID: $(echo "$APP" | jq -r '.client_id')"
echo "Application Type: $(echo "$APP" | jq -r '.app_type')"
echo ""
echo "Callback URLs:"
echo "$APP" | jq -r '.callbacks[]?' | while read url; do
  echo "  - $url"
done
```

**Expected output:**
```
Application Name: inlock-admin
Client ID: aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o
Application Type: regular_web

Callback URLs:
  - https://auth.inlock.ai/oauth2/callback
```

---

### Example 3: Verify Callback URL Configuration

```bash
# Verify callback URL is configured correctly

CLIENT_ID="aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"
EXPECTED_CALLBACK="https://auth.inlock.ai/oauth2/callback"

APP=$(curl -s -X GET "${AUTH0_API_URL}/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

CALLBACKS=$(echo "$APP" | jq -r '.callbacks[]?')

if echo "$CALLBACKS" | grep -q "^${EXPECTED_CALLBACK}$"; then
  echo "✓ Callback URL is correctly configured: $EXPECTED_CALLBACK"
else
  echo "❌ Callback URL not found or incorrect"
  echo "Current callbacks:"
  echo "$CALLBACKS" | while read url; do
    echo "  - $url"
  done
  echo ""
  echo "Expected: $EXPECTED_CALLBACK"
fi
```

---

### Example 4: Update Callback URL (if needed)

```bash
# WARNING: This modifies Auth0 configuration. Use with caution.

CLIENT_ID="aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"
NEW_CALLBACK="https://auth.inlock.ai/oauth2/callback"

# First, get current application config
APP=$(curl -s -X GET "${AUTH0_API_URL}/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

# Extract current callbacks and add new one (avoid duplicates)
CURRENT_CALLBACKS=$(echo "$APP" | jq -c '.callbacks // []')
NEW_CALLBACKS=$(echo "$CURRENT_CALLBACKS" | jq ". + [\"$NEW_CALLBACK\"] | unique")

# Update application
UPDATE_RESPONSE=$(curl -s -X PATCH "${AUTH0_API_URL}/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"callbacks\": $NEW_CALLBACKS}")

# Verify update
if echo "$UPDATE_RESPONSE" | jq -e '.callbacks[]? | select(. == "'"$NEW_CALLBACK"'")' > /dev/null; then
  echo "✓ Callback URL updated successfully"
else
  echo "❌ Update may have failed"
  echo "Response: $UPDATE_RESPONSE"
fi
```

---

### Example 5: List All Applications

```bash
# List all applications in tenant

APPS=$(curl -s -X GET "${AUTH0_API_URL}/clients" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "Applications in tenant:"
echo "$APPS" | jq -r '.[] | "\(.name) (\(.client_id)) - \(.app_type)"'
```

---

### Example 6: Check M2M Application Scopes

```bash
# Verify Management API M2M application has required scopes

M2M_CLIENT_ID="${AUTH0_MGMT_CLIENT_ID}"

# Get M2M application details
M2M_APP=$(curl -s -X GET "${AUTH0_API_URL}/clients/${M2M_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "M2M Application: $(echo "$M2M_APP" | jq -r '.name')"
echo ""

# Check authorized APIs (requires checking grants)
# Note: This is a simplified check - full scope verification may require grants endpoint
```

---

### Example 7: Test-Specific Scopes

```bash
# Test if specific scopes are available (requires checking token scopes)

# Decode token to see scopes (first two parts of JWT)
TOKEN_PARTS=$(echo "$ACCESS_TOKEN" | tr '.' ' ')
TOKEN_PAYLOAD=$(echo "$TOKEN_PARTS" | awk '{print $2}')

# Decode base64 (add padding if needed)
TOKEN_JSON=$(echo "$TOKEN_PAYLOAD" | base64 -d 2>/dev/null || echo "$TOKEN_PAYLOAD" | base64 -d)

echo "Token scopes:"
echo "$TOKEN_JSON" | jq -r '.scope // "N/A"'
```

**Note:** Full scope verification typically requires checking the grants endpoint or API response.

---

## Complete Validation Script

Save this as `scripts/validate-auth0-config.sh`:

```bash
#!/bin/bash
# Complete Auth0 configuration validation via Management API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"
ADMIN_CLIENT_ID="${AUTH0_ADMIN_CLIENT_ID}"
EXPECTED_CALLBACK="https://auth.inlock.ai/oauth2/callback"

echo "=== Auth0 Configuration Validation ==="
echo ""

# Check credentials
if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
  echo "❌ Management API credentials not configured"
  exit 1
fi

# Get token
echo "Getting access token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✓ Token obtained"
echo ""

# Get admin application
echo "Fetching admin application..."
APP=$(curl -s -X GET "${AUTH0_API_URL}/clients/${ADMIN_CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

APP_NAME=$(echo "$APP" | jq -r '.name // "unknown"')
echo "Application: $APP_NAME"
echo ""

# Check callback URL
echo "Checking callback URL..."
CALLBACKS=$(echo "$APP" | jq -r '.callbacks[]? // empty')

if echo "$CALLBACKS" | grep -q "^${EXPECTED_CALLBACK}$"; then
  echo "✓ Callback URL configured correctly: $EXPECTED_CALLBACK"
else
  echo "❌ Callback URL issue:"
  if [ -z "$CALLBACKS" ]; then
    echo "   No callbacks configured"
  else
    echo "   Current callbacks:"
    echo "$CALLBACKS" | while read url; do
      echo "     - $url"
    done
  fi
  echo "   Expected: $EXPECTED_CALLBACK"
fi

echo ""
echo "=== Validation Complete ==="
```

---

## Expected Test Results

### Successful Test Output

```
=== Testing Auth0 Management API ===
Domain: comzis.eu.auth0.com

✓ Credentials found

1. Getting access token...
   ✓ Token obtained (length: 800+ chars)

2. Testing API access...
   ✓ API access working (X applications found)

Application Name: inlock-admin
Callback URLs:
  - https://auth.inlock.ai/oauth2/callback

=== Test Complete ===
✓ Management API is configured and working
```

---

## Troubleshooting

### Issue: "invalid_client" Error

**Symptom:** Token request returns `{"error":"invalid_client"}`

**Fix:**
- Verify `AUTH0_MGMT_CLIENT_ID` and `AUTH0_MGMT_CLIENT_SECRET` are correct
- Check M2M application exists in Auth0 Dashboard
- Verify credentials copied correctly (no extra spaces)

### Issue: "insufficient_scope" Error

**Symptom:** API request returns `{"error":"insufficient_scope"}`

**Fix:**
- Verify M2M application has Management API authorized
- Check required scopes are granted:
  - `read:applications`
  - `read:clients`
  - `update:applications` (if updating)
  - `update:clients` (if updating)

### Issue: "access_denied" Error

**Symptom:** API request returns `{"error":"access_denied"}`

**Fix:**
- Verify M2M application is authorized for Management API
- Check application has required permissions
- Verify tenant access

---

## Handoff Notes

**For Primary Team:**
- [ ] Test examples validated
- [ ] Credentials configured
- [ ] API access verified
- [ ] Callback URL verified via API
- [ ] Status documented

**Status:** [READY / NEEDS PRIMARY TEAM ACTION / BLOCKED]

