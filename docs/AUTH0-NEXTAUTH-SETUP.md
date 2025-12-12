# Auth0 + NextAuth.js + OAuth2-Proxy Setup Guide

## Overview

This guide covers the complete authentication setup for Inlock infrastructure using:
- **Auth0** - Identity provider (with Google Workspace, Apple, Passkeys support)
- **NextAuth.js** - Frontend authentication for Next.js app
- **OAuth2-Proxy** - Forward auth for admin services (Traefik, Portainer, Grafana, etc.)
- **HashiCorp Vault** - Centralized secrets management

---

## 1. Auth0 Tenant Setup

### Create Auth0 Tenant

1. Sign up at https://auth0.com
2. Choose a tenant name (e.g., `inlock-ai`)
3. Select region (closest to your users)

### Create Applications

#### Application 1: `inlock-admin` (Regular Web App)

**Purpose:** OAuth2-Proxy for admin services

1. Go to **Applications → Applications → Create Application**
2. Name: `inlock-admin`
3. Type: **Regular Web Application**
4. Click **Create**

**Settings:**
- **Allowed Callback URLs:**
  ```
  https://auth.inlock.ai/oauth2/callback
  ```
- **Allowed Logout URLs:** (comma-separated format, no trailing slashes on root domains)
  ```
  https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai
  ```
- **Allowed Web Origins:** Leave empty (OAuth2-Proxy handles this)

**Important:** This URL (`https://auth.inlock.ai/oauth2/callback`) is the **oauth2-proxy callback endpoint** configured in `compose/stack.yml`. It's where Auth0 redirects users after authentication, and oauth2-proxy then forwards them to the admin service they were trying to access.

**Save and note:**
- `Client ID` → `AUTH0_ADMIN_CLIENT_ID`
- `Client Secret` → `AUTH0_ADMIN_CLIENT_SECRET`

#### Application 2: `inlock-web` (Single Page App)

**Purpose:** NextAuth.js for frontend

1. Go to **Applications → Applications → Create Application**
2. Name: `inlock-web`
3. Type: **Single Page Application**
4. Click **Create**

**Settings:**
- **Allowed Callback URLs:**
  ```
  https://inlock.ai/api/auth/callback/auth0
  http://localhost:3040/api/auth/callback/auth0
  ```
- **Allowed Logout URLs:**
  ```
  https://inlock.ai
  http://localhost:3040
  ```
- **Allowed Web Origins:**
  ```
  https://inlock.ai
  http://localhost:3040
  ```

**Save and note:**
- `Client ID` → `AUTH0_WEB_CLIENT_ID`
- `Client Secret` → `AUTH0_WEB_CLIENT_SECRET`
- `Domain` → `AUTH0_ISSUER` (e.g., `https://your-tenant.auth0.com`)

### Enable Social Connections

#### Google Workspace

1. Go to **Authentication → Social**
2. Click **Google**
3. Enable **Google Workspace** connection
4. Enter Google Client ID and Secret
5. Configure team domains if needed

#### Apple

1. Go to **Authentication → Social**
2. Click **Apple**
3. Enable Apple connection
4. Configure Apple Services ID

### Configure Multi-Factor Authentication

1. Go to **Security → Multi-factor Auth**
2. Enable **WebAuthn** with "Passkeys"
3. Enable **OTP** as fallback
4. Go to **Rules → Create Rule**
5. Require MFA for admin roles:
   ```javascript
   function requireMFAForAdmins(user, context, callback) {
     const roles = context.authorization.roles || [];
     if (roles.includes('admin')) {
       context.multifactor = {
         provider: 'any',
         allowRememberBrowser: false
       };
     }
     callback(null, user, context);
   }
   ```

### Create Roles

1. Go to **User Management → Roles**
2. Create roles:
   - `admin` - Full access to admin services
   - `developer` - Access to development tools
   - `viewer` - Read-only access

### Configure Role Injection (Rules/Actions)

1. Go to **Actions → Flows → Login**
2. Create new Action: "Add Roles to Token"
3. Code:
   ```javascript
   exports.onExecutePostLogin = async (event, api) => {
     const namespace = 'https://inlock.ai';
     
     if (event.authorization) {
       api.idToken.setCustomClaim(`${namespace}/roles`, event.authorization.roles);
     }
   };
   ```
4. Deploy and add to Login flow

---

## 2. Environment Variables

### Infrastructure `.env`

Add to `/home/comzis/inlock-infra/.env`:

```bash
# Auth0 Configuration
AUTH0_ISSUER=https://your-tenant.auth0.com
AUTH0_ADMIN_CLIENT_ID=your-admin-client-id
AUTH0_ADMIN_CLIENT_SECRET=your-admin-client-secret

# OAuth2-Proxy
OAUTH2_COOKIE_SECRET=$(openssl rand -base64 32 | head -c 32)

# Vault (Dev Mode - DO NOT USE IN PRODUCTION)
VAULT_ROOT_TOKEN=your-secure-root-token
```

### Application `.env.production`

Add to `/opt/inlock-ai-secure-mvp/.env.production`:

```bash
# Auth0 for NextAuth.js
AUTH0_WEB_CLIENT_ID=your-web-client-id
AUTH0_WEB_CLIENT_SECRET=your-web-client-secret
AUTH0_ISSUER=https://your-tenant.auth0.com
AUTH0_AUDIENCE=optional-api-audience

# NextAuth.js
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=https://inlock.ai
```

---

## 3. Vault Setup (Secrets Management)

### Initial Setup

**Dev Mode (Testing Only):**

Vault is configured in dev mode in `compose/stack.yml`. This is **NOT for production**.

**Production Setup:**

1. Deploy Vault in production mode:
   ```bash
   docker run -d \
     --name vault \
     -v vault_data:/vault/file \
     -p 127.0.0.1:8200:8200 \
     hashicorp/vault:1.16.1 \
     server -config /vault/config/config.hcl
   ```

2. Initialize Vault:
   ```bash
   vault operator init
   # Save unseal keys and root token securely
   ```

3. Unseal Vault:
   ```bash
   vault operator unseal <unseal-key-1>
   vault operator unseal <unseal-key-2>
   vault operator unseal <unseal-key-3>
   ```

### Store Secrets

```bash
# Set Vault address
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=your-root-token

# Enable KV secrets engine
vault secrets enable -path=secret kv-v2

# Store Auth0 secrets
vault kv put secret/inlock/production \
  AUTH0_ADMIN_CLIENT_ID="your-admin-client-id" \
  AUTH0_ADMIN_CLIENT_SECRET="your-admin-client-secret" \
  AUTH0_WEB_CLIENT_ID="your-web-client-id" \
  AUTH0_WEB_CLIENT_SECRET="your-web-client-secret" \
  OAUTH2_COOKIE_SECRET="your-cookie-secret" \
  NEXTAUTH_SECRET="your-nextauth-secret"

# Store SSL certificates
vault kv put secret/inlock/ssl \
  POSITIVE_SSL_CERT="$(cat /path/to/cert.crt)" \
  POSITIVE_SSL_KEY="$(cat /path/to/key.key)"

# Store database credentials
vault kv put secret/inlock/database \
  DATABASE_URL="postgresql://user:password@host:5432/dbname"
```

### Configure AppRole (Recommended for Production)

```bash
# Enable AppRole auth
vault auth enable approle

# Create policy
vault policy write inlock-app - <<EOF
path "secret/data/inlock/*" {
  capabilities = ["read"]
}
EOF

# Create AppRole
vault write auth/approle/role/inlock-app \
  token_policies="inlock-app" \
  token_ttl=1h \
  token_max_ttl=4h

# Get Role ID and Secret ID
vault read auth/approle/role/inlock-app/role-id
vault write -f auth/approle/role/inlock-app/secret-id
```

---

## 4. Update Deployment Scripts

### Fetch Secrets from Vault

Create `/home/comzis/inlock-infra/scripts/fetch-vault-secrets.sh`:

```bash
#!/bin/bash
# Fetch secrets from Vault and write to Docker secrets or env files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load Vault credentials
source .env
export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"

# Authenticate (dev mode or AppRole)
if [ -n "$VAULT_ROOT_TOKEN" ]; then
  export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
elif [ -n "$VAULT_ROLE_ID" ] && [ -n "$VAULT_SECRET_ID" ]; then
  export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="$VAULT_ROLE_ID" \
    secret_id="$VAULT_SECRET_ID")
fi

# Fetch secrets
echo "Fetching secrets from Vault..."

# Auth0 secrets
vault kv get -format=json secret/inlock/production | \
  jq -r '.data.data' > /tmp/vault-secrets.json

# Create Docker secrets
cat /tmp/vault-secrets.json | jq -r '.AUTH0_ADMIN_CLIENT_SECRET' | \
  docker secret create auth0-admin-secret - 2>/dev/null || \
  docker secret rm auth0-admin-secret && \
  cat /tmp/vault-secrets.json | jq -r '.AUTH0_ADMIN_CLIENT_SECRET' | \
  docker secret create auth0-admin-secret -

# Update .env with non-secret values
cat /tmp/vault-secrets.json | jq -r '.AUTH0_ADMIN_CLIENT_ID' > \
  .env.auth0-temp

# SSL certificates
if vault kv get secret/inlock/ssl &>/dev/null; then
  vault kv get -format=json secret/inlock/ssl | \
    jq -r '.data.data.POSITIVE_SSL_CERT' | \
    docker secret create positive_ssl_cert - 2>/dev/null || \
    echo "SSL cert already exists"

  vault kv get -format=json secret/inlock/ssl | \
    jq -r '.data.data.POSITIVE_SSL_KEY' | \
    docker secret create positive_ssl_key - 2>/dev/null || \
    echo "SSL key already exists"
fi

echo "✅ Secrets fetched and Docker secrets created"
```

Update `scripts/deploy-manual.sh` to call this before `docker compose up`.

---

## 5. Next.js Frontend Integration

### Install NextAuth.js

```bash
cd /opt/inlock-ai-secure-mvp
npm install next-auth
```

### Update Auth Components

Replace custom login with NextAuth:

```typescript
// components/auth/login-form.tsx
import { signIn } from "next-auth/react";

export function LoginForm() {
  const handleLogin = async () => {
    await signIn("auth0");
  };

  return (
    <button onClick={handleLogin}>
      Sign in with Auth0
    </button>
  );
}
```

### Session Provider

Wrap app in `SessionProvider`:

```typescript
// app/layout.tsx
import { SessionProvider } from "next-auth/react";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <SessionProvider>
          {children}
        </SessionProvider>
      </body>
    </html>
  );
}
```

---

## 6. Testing

### Test OAuth2-Proxy

1. Visit `https://portainer.inlock.ai`
2. Should redirect to Auth0 login
3. After login, should redirect back to Portainer

### Test NextAuth.js

1. Visit `https://inlock.ai/auth/signin`
2. Click "Sign in with Auth0"
3. Complete Auth0 login
4. Should redirect back to app with session

### Test Vault

```bash
# Check Vault status
curl http://localhost:8200/v1/sys/health

# List secrets
vault kv list secret/inlock/

# Read secret
vault kv get secret/inlock/production
```

---

## 7. Troubleshooting

### OAuth2-Proxy not redirecting

- Check `OAUTH2_PROXY_REDIRECT_URL` matches Auth0 callback URL
- Verify `AUTH0_ISSUER` is correct
- Check OAuth2-Proxy logs: `docker logs compose-oauth2-proxy-1`

### NextAuth.js not working

- Verify `NEXTAUTH_URL` matches your domain
- Check `NEXTAUTH_SECRET` is set
- Verify Auth0 application settings (callback URLs)
- Check browser console for errors

### Vault connection issues

- Verify `VAULT_ADDR` is correct
- Check Vault is unsealed (production)
- Verify token/AppRole credentials

---

## 8. Security Considerations

1. **Never commit secrets** - Use Vault or CI/CD secrets
2. **Rotate secrets regularly** - See `docs/SECRET-MANAGEMENT.md`
3. **Use production Vault** - Dev mode is insecure
4. **Enable MFA** - Required for admin roles
5. **Monitor access logs** - Check Auth0 logs regularly
6. **Limit OAuth scopes** - Request only needed permissions

---

**Last Updated:** December 10, 2025  
**Related:** `docs/SECRET-MANAGEMENT.md`, `compose/stack.yml`

