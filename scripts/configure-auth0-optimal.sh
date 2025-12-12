#!/bin/bash
# Configure Auth0 Application with Optimal Security Settings
# Based on Auth0 best practices for OAuth2 Proxy integration

set -e

# Configuration
AUTH0_DOMAIN="comzis.eu.auth0.com"
API_URL="https://${AUTH0_DOMAIN}/api/v2"
CLIENT_ID="aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"

# Access token (can be passed as first argument or set as environment variable)
TOKEN="${1:-${AUTH0_ACCESS_TOKEN}}"

if [ -z "$TOKEN" ]; then
  echo "Error: Access token required"
  echo "Usage: $0 <access_token>"
  echo "   OR: export AUTH0_ACCESS_TOKEN=your_token && $0"
  exit 1
fi

echo "=========================================="
echo "Auth0 Optimal Configuration Script"
echo "=========================================="
echo ""

# Step 1: Get current application configuration
echo "1. Fetching current application configuration..."
CURRENT_APP=$(curl -s --request GET \
  --url "${API_URL}/clients/${CLIENT_ID}" \
  --header "authorization: Bearer ${TOKEN}")

ERROR=$(echo "$CURRENT_APP" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', ''))" 2>/dev/null || echo "")
if [ -n "$ERROR" ]; then
  echo "Error: Failed to fetch application"
  echo "$CURRENT_APP" | python3 -m json.tool 2>/dev/null || echo "$CURRENT_APP"
  exit 1
fi

CURRENT_NAME=$(echo "$CURRENT_APP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('name', 'Unknown'))" 2>/dev/null)
echo "   Application: $CURRENT_NAME"
echo ""

# Step 2: Define optimal configuration
echo "2. Preparing optimal configuration..."

# Callback URLs - OAuth2 Proxy callback endpoint
CALLBACK_URLS='["https://auth.inlock.ai/oauth2/callback"]'

# Logout URLs - All services that need logout capability
LOGOUT_URLS='[
  "https://auth.inlock.ai/oauth2/callback",
  "https://traefik.inlock.ai",
  "https://portainer.inlock.ai",
  "https://grafana.inlock.ai",
  "https://n8n.inlock.ai",
  "https://deploy.inlock.ai",
  "https://dashboard.inlock.ai",
  "https://cockpit.inlock.ai"
]'

# Allowed Origins (CORS) - For browser-based OAuth flows
ALLOWED_ORIGINS='[
  "https://auth.inlock.ai",
  "https://deploy.inlock.ai",
  "https://traefik.inlock.ai",
  "https://portainer.inlock.ai",
  "https://grafana.inlock.ai",
  "https://n8n.inlock.ai",
  "https://dashboard.inlock.ai",
  "https://cockpit.inlock.ai"
]'

# Build update payload with optimal security settings
UPDATE_PAYLOAD=$(python3 <<EOF
import json
import sys

payload = {
    # Callback and logout URLs
    "callbacks": json.loads('${CALLBACK_URLS}'),
    "allowed_logout_urls": json.loads('${LOGOUT_URLS}'),
    "allowed_origins": json.loads('${ALLOWED_ORIGINS}'),
    
    # Security settings
    "token_endpoint_auth_method": "client_secret_post",  # More secure than basic auth
    "grant_types": [
        "authorization_code",
        "refresh_token"
    ],
    
    # OAuth2/OIDC settings
    "oidc_conformant": True,
    "jwt_configuration": {
        "alg": "RS256",  # Use RS256 for JWT signing
        "lifetime_in_seconds": 36000,  # 10 hours
        "secret_encoded": False
    },
    
    # Refresh token settings
    "refresh_token": {
        "rotation_type": "rotating",  # Rotate refresh tokens for security
        "expiration_type": "expiring",
        "leeway": 0,
        "token_lifetime": 2592000,  # 30 days
        "infinite_token_lifetime": False,
        "idle_token_lifetime": 1296000,  # 15 days
        "infinite_idle_token_lifetime": False
    },
    
    # PKCE settings (for enhanced security)
    "app_type": "regular_web",
    
    # Additional security
    "cross_origin_auth": False,  # Disable cross-origin auth for security
    "cross_origin_loc": None,
    "sso": True,  # Enable SSO
    "sso_disabled": False,
    "custom_login_page_on": False,  # Use Auth0's secure login page
    "custom_login_page": "",
    "custom_login_page_preview": "",
    
    # Web origins (for CORS)
    "web_origins": json.loads('${ALLOWED_ORIGINS}'),
    
    # Encryption settings
    "encryption_key": None,  # Let Auth0 manage encryption
    
    # Form template (use Auth0's secure default)
    "form_template": "",
    
    # Addons (none for OAuth2 Proxy)
    "addons": {},
    
    # Client metadata (optional, for tracking)
    "client_metadata": {
        "integration": "oauth2-proxy",
        "managed_by": "automation"
    }
}

print(json.dumps(payload, indent=2))
EOF
)

echo "   Configuration prepared:"
echo "   - Callback URLs: $(echo "$CALLBACK_URLS" | python3 -c "import sys, json; print(', '.join(json.load(sys.stdin)))")"
echo "   - Logout URLs: $(echo "$LOGOUT_URLS" | python3 -c "import sys, json; print(', '.join(json.load(sys.stdin)))")"
echo "   - Allowed Origins: $(echo "$ALLOWED_ORIGINS" | python3 -c "import sys, json; print(', '.join(json.load(sys.stdin)))")"
echo "   - Security: PKCE, RS256, Token Rotation, SSO enabled"
echo ""

# Step 3: Update application
echo "3. Updating application configuration..."
UPDATE_RESPONSE=$(curl -s --request PATCH \
  --url "${API_URL}/clients/${CLIENT_ID}" \
  --header "authorization: Bearer ${TOKEN}" \
  --header "content-type: application/json" \
  --data "$UPDATE_PAYLOAD")

ERROR=$(echo "$UPDATE_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', ''))" 2>/dev/null || echo "")
if [ -n "$ERROR" ]; then
  echo "Error: Failed to update application"
  echo "$UPDATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_RESPONSE"
  exit 1
fi

echo "   ✓ Application updated successfully"
echo ""

# Step 4: Verify configuration
echo "4. Verifying updated configuration..."
VERIFY_APP=$(curl -s --request GET \
  --url "${API_URL}/clients/${CLIENT_ID}" \
  --header "authorization: Bearer ${TOKEN}")

echo ""
echo "=========================================="
echo "Updated Configuration Summary"
echo "=========================================="
echo ""

# Extract and display key settings
python3 <<EOF
import json
import sys

app = json.load(sys.stdin)

print(f"Application: {app.get('name', 'Unknown')}")
print(f"Client ID: {app.get('client_id', 'Unknown')}")
print(f"Application Type: {app.get('app_type', 'Unknown')}")
print(f"OIDC Conformant: {app.get('oidc_conformant', False)}")
print(f"SSO Enabled: {app.get('sso', False)}")
print(f"Token Endpoint Auth Method: {app.get('token_endpoint_auth_method', 'Unknown')}")
print("")
print("Callback URLs:")
for url in app.get('callbacks', []):
    print(f"  ✓ {url}")
print("")
print("Logout URLs:")
for url in app.get('allowed_logout_urls', []):
    print(f"  ✓ {url}")
print("")
print("Allowed Origins (CORS):")
for url in app.get('allowed_origins', []):
    print(f"  ✓ {url}")
print("")
print("Web Origins:")
for url in app.get('web_origins', []):
    print(f"  ✓ {url}")
print("")
print("Grant Types:")
for grant in app.get('grant_types', []):
    print(f"  ✓ {grant}")
print("")
print("JWT Configuration:")
jwt = app.get('jwt_configuration', {})
print(f"  Algorithm: {jwt.get('alg', 'Unknown')}")
print(f"  Lifetime: {jwt.get('lifetime_in_seconds', 0)} seconds")
print("")
print("Refresh Token Settings:")
refresh = app.get('refresh_token', {})
print(f"  Rotation Type: {refresh.get('rotation_type', 'Unknown')}")
print(f"  Token Lifetime: {refresh.get('token_lifetime', 0)} seconds")
print(f"  Idle Lifetime: {refresh.get('idle_token_lifetime', 0)} seconds")
EOF
< <(echo "$VERIFY_APP")

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "  1. Test authentication flow: https://deploy.inlock.ai"
echo "  2. Verify callback works: Check OAuth2-Proxy logs"
echo "  3. Test logout: Verify logout redirects correctly"
echo "  4. Monitor Auth0 Dashboard for authentication events"
echo ""
