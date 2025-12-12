# Auth0 Management API Reference

This document provides a quick reference for using the Auth0 Management API v2 with your access token.

## Base URL

```
https://comzis.eu.auth0.com/api/v2
```

## Authentication

All requests require a Bearer token in the Authorization header:

```bash
curl --request GET \
  --url "https://comzis.eu.auth0.com/api/v2/<endpoint>" \
  --header "authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

## Common Endpoints

### Clients (Applications)

**List all clients:**
```bash
GET /api/v2/clients
```

**Get specific client:**
```bash
GET /api/v2/clients/{client_id}
```

**Update client:**
```bash
PATCH /api/v2/clients/{client_id}
Content-Type: application/json

{
  "callbacks": ["https://example.com/callback"],
  "allowed_logout_urls": ["https://example.com/logout"],
  "allowed_origins": ["https://example.com"]
}
```

**Query parameters for listing clients:**
- `page`: Page number (default: 0)
- `per_page`: Items per page (default: 50, max: 100)
- `app_type`: Filter by type (`spa`, `native`, `non_interactive`, `regular_web`)
- `is_global`: Filter by global clients (boolean)
- `is_first_party`: Filter by first-party apps (boolean)

### Users

**List users:**
```bash
GET /api/v2/users?per_page=10&page=0
```

**Get specific user:**
```bash
GET /api/v2/users/{user_id}
```

**Create user:**
```bash
POST /api/v2/users
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "connection": "Username-Password-Authentication",
  "email_verified": true
}
```

**Update user:**
```bash
PATCH /api/v2/users/{user_id}
Content-Type: application/json

{
  "email": "newemail@example.com"
}
```

**Delete user:**
```bash
DELETE /api/v2/users/{user_id}
```

### Tenant Settings

**Get tenant settings:**
```bash
GET /api/v2/tenants/settings
```

**Update tenant settings:**
```bash
PATCH /api/v2/tenants/settings
Content-Type: application/json

{
  "friendly_name": "My Tenant",
  "support_email": "support@example.com"
}
```

### Connections

**List connections:**
```bash
GET /api/v2/connections
```

**Get specific connection:**
```bash
GET /api/v2/connections/{connection_id}
```

**Update connection:**
```bash
PATCH /api/v2/connections/{connection_id}
Content-Type: application/json

{
  "enabled_clients": ["client_id_1", "client_id_2"]
}
```

## Required Scopes

Your access token must have the appropriate scopes for each operation:

- **Clients:**
  - `read:clients` - Read client information
  - `create:clients` - Create clients
  - `update:clients` - Update clients
  - `delete:clients` - Delete clients

- **Users:**
  - `read:users` - Read user information
  - `create:users` - Create users
  - `update:users` - Update users
  - `delete:users` - Delete users

- **Tenant:**
  - `read:tenant_settings` - Read tenant settings
  - `update:tenant_settings` - Update tenant settings

## Example: Update OAuth2 Proxy Application

```bash
# Get current application details
curl --request GET \
  --url "https://comzis.eu.auth0.com/api/v2/clients/aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o" \
  --header "authorization: Bearer YOUR_TOKEN"

# Update callback URLs
curl --request PATCH \
  --url "https://comzis.eu.auth0.com/api/v2/clients/aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o" \
  --header "authorization: Bearer YOUR_TOKEN" \
  --header "content-type: application/json" \
  --data '{
    "callbacks": [
      "https://auth.inlock.ai/oauth2/callback",
      "https://deploy.inlock.ai/oauth2/callback"
    ],
    "allowed_logout_urls": [
      "https://auth.inlock.ai",
      "https://deploy.inlock.ai"
    ]
  }'
```

## Using the Helper Scripts

### Quick API Call

```bash
# List clients
./scripts/auth0-api-quick.sh "" "clients"

# Get specific client
./scripts/auth0-api-quick.sh "" "clients/aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"

# List users
./scripts/auth0-api-quick.sh "" "users?per_page=5"
```

### Using the Helper Functions

```bash
# Source the helper script
source ./scripts/auth0-api-helper.sh

# Set your token
auth0_set_token "YOUR_ACCESS_TOKEN"

# Get application details
auth0_get_app "aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"

# Update callback URLs
auth0_update_callbacks "aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o" "https://example.com/callback,https://example.com/callback2"
```

## Common Use Cases

### 1. Update Application Callback URLs

When deploying a new service, automatically add its callback URL:

```bash
# Get current callbacks
CURRENT=$(curl -s --request GET \
  --url "https://comzis.eu.auth0.com/api/v2/clients/CLIENT_ID" \
  --header "authorization: Bearer TOKEN" | \
  python3 -c "import sys, json; print(','.join(json.load(sys.stdin)['callbacks']))")

# Add new callback
NEW_CALLBACK="https://newservice.inlock.ai/oauth2/callback"
curl --request PATCH \
  --url "https://comzis.eu.auth0.com/api/v2/clients/CLIENT_ID" \
  --header "authorization: Bearer TOKEN" \
  --header "content-type: application/json" \
  --data "{\"callbacks\": [\"$CURRENT\", \"$NEW_CALLBACK\"]}"
```

### 2. List All Applications

```bash
curl --request GET \
  --url "https://comzis.eu.auth0.com/api/v2/clients?per_page=100" \
  --header "authorization: Bearer TOKEN" | \
  python3 -m json.tool | grep -E '"name"|"client_id"'
```

### 3. Find Application by Name

```bash
curl --request GET \
  --url "https://comzis.eu.auth0.com/api/v2/clients" \
  --header "authorization: Bearer TOKEN" | \
  python3 -c "import sys, json; [print(f\"{app['name']}: {app['client_id']}\") for app in json.load(sys.stdin) if 'oauth2' in app['name'].lower()]"
```

## Error Codes

- **400 Bad Request**: Invalid request format or parameters
- **401 Unauthorized**: Invalid or expired token
- **403 Forbidden**: Token lacks required scopes
- **404 Not Found**: Resource doesn't exist
- **429 Too Many Requests**: Rate limit exceeded

## Rate Limits

Auth0 Management API has rate limits:
- **Burst limit**: 5 requests per second
- **Sustained limit**: 50 requests per 10 seconds

If you hit rate limits, implement exponential backoff in your scripts.

## Official Documentation

- [Auth0 Management API v2](https://auth0.com/docs/api/management/v2)
- [Management API Explorer](https://auth0.com/docs/api/management/v2)
- [Access Tokens](https://auth0.com/docs/secure/tokens/access-tokens/management-api-access-tokens)

