# Auth0 + NextAuth.js + Vault Implementation Summary

**Date:** December 10, 2025  
**Status:** ✅ Configuration Complete - Ready for Setup

---

## 🎯 Overview

Complete authentication and secrets management system implemented:
- **Auth0** - Identity provider with social logins and passkeys
- **NextAuth.js** - Frontend authentication
- **OAuth2-Proxy** - Admin service authentication via Traefik
- **HashiCorp Vault** - Centralized secrets management

---

## ✅ What's Been Implemented

### 1. Infrastructure Services

**OAuth2-Proxy Service** (`compose/stack.yml`):
- Configured with Auth0 OIDC provider
- Handles authentication for admin services (Traefik, Portainer, Grafana, n8n)
- Callback endpoint at `auth.inlock.ai`

**Vault Service** (`compose/stack.yml`):
- HashiCorp Vault container (dev mode for now)
- API accessible at `localhost:8200`
- Volume persistence configured

### 2. Traefik Configuration

**Updated Middlewares** (`traefik/dynamic/middlewares.yml`):
- `admin-forward-auth` - New middleware for OAuth2-Proxy
- Routes unauthenticated users to Auth0 login
- Extracts user info from headers

**Updated Routers** (`traefik/dynamic/routers.yml`):
- Traefik dashboard uses `admin-forward-auth`
- Grafana uses `admin-forward-auth`
- n8n uses `admin-forward-auth`
- Portainer uses `admin-forward-auth`
- OAuth2-Proxy callback route added

**Updated Services** (`traefik/dynamic/services.yml`):
- OAuth2-Proxy service definition added

### 3. Next.js Application

**NextAuth.js Route** (`app/api/auth/[...nextauth]/route.ts`):
- Auth0 provider configured
- Role extraction from Auth0 custom claims
- Session management with JWT tokens
- Callback handlers for sign-in/sign-out

### 4. Secrets Management

**Vault Integration Script** (`scripts/fetch-vault-secrets.sh`):
- Fetches secrets from Vault
- Creates Docker secrets automatically
- Updates .env with non-secret values
- Supports root token (dev) or AppRole (prod)

**Deployment Integration** (`scripts/deploy-manual.sh`):
- Calls `fetch-vault-secrets.sh` before deployment
- Falls back to .env if Vault unavailable

### 5. Documentation

**Setup Guide** (`docs/AUTH0-NEXTAUTH-SETUP.md`):
- Complete Auth0 tenant setup instructions
- Application configuration
- Social connections (Google, Apple)
- MFA setup
- Role management
- Vault configuration
- Testing procedures

**Environment Template** (`env.example`):
- Auth0 configuration variables
- OAuth2-Proxy settings
- Vault configuration

---

## 📋 Setup Checklist

### Auth0 Configuration (Required)

- [ ] Create Auth0 tenant
- [ ] Create `inlock-admin` application (Regular Web App)
- [ ] Create `inlock-web` application (Single Page App)
- [ ] Configure callback URLs
- [ ] Enable Google Workspace connection
- [ ] Enable Apple connection
- [ ] Configure WebAuthn/Passkeys
- [ ] Create roles (admin, developer, viewer)
- [ ] Create action to inject roles into tokens
- [ ] Copy credentials to `.env`

### Environment Variables (Required)

**Infrastructure** (`/home/comzis/inlock-infra/.env`):
```bash
AUTH0_ISSUER=https://your-tenant.auth0.com
AUTH0_ADMIN_CLIENT_ID=your-admin-client-id
AUTH0_ADMIN_CLIENT_SECRET=your-admin-client-secret
OAUTH2_COOKIE_SECRET=$(openssl rand -base64 32 | head -c 32)
VAULT_ROOT_TOKEN=your-secure-token
```

**Application** (`/opt/inlock-ai-secure-mvp/.env.production`):
```bash
AUTH0_WEB_CLIENT_ID=your-web-client-id
AUTH0_WEB_CLIENT_SECRET=your-web-client-secret
AUTH0_ISSUER=https://your-tenant.auth0.com
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=https://inlock.ai
```

### Vault Setup (Optional but Recommended)

- [ ] Deploy Vault (dev mode included, production setup recommended)
- [ ] Store Auth0 secrets: `vault kv put secret/inlock/production ...`
- [ ] Store SSL certificates: `vault kv put secret/inlock/ssl ...`
- [ ] Store database credentials: `vault kv put secret/inlock/database ...`
- [ ] Configure AppRole for production (optional)

### Next.js Setup (Required)

- [ ] Install NextAuth.js: `npm install next-auth`
- [ ] Update auth components to use `signIn("auth0")`
- [ ] Add `SessionProvider` to root layout
- [ ] Test authentication flow

### Deployment

- [ ] Update `.env` files with Auth0 credentials
- [ ] Test Vault connection: `./scripts/fetch-vault-secrets.sh`
- [ ] Deploy services: `docker compose -f compose/stack.yml --env-file .env up -d`
- [ ] Verify OAuth2-Proxy: Visit `https://portainer.inlock.ai`
- [ ] Verify NextAuth: Visit `https://inlock.ai/auth/signin`

---

## 🔧 Usage

### Admin Services Authentication

All admin services now use Auth0 authentication via OAuth2-Proxy:
- Visit `https://traefik.inlock.ai/dashboard/`
- Visit `https://portainer.inlock.ai`
- Visit `https://grafana.inlock.ai`
- Visit `https://n8n.inlock.ai`

Users will be redirected to Auth0 login, then back to the service.

### Frontend Authentication

Users can sign in via NextAuth.js:
```typescript
import { signIn, signOut, useSession } from "next-auth/react";

// Sign in
await signIn("auth0");

// Sign out
await signOut();

// Get session
const { data: session } = useSession();
```

### Vault Secrets

Fetch secrets before deployment:
```bash
./scripts/fetch-vault-secrets.sh
```

Or manually:
```bash
export VAULT_TOKEN=your-token
vault kv get secret/inlock/production
```

---

## 📚 Documentation

- **Complete Setup Guide:** `docs/AUTH0-NEXTAUTH-SETUP.md`
- **Secrets Management:** `docs/SECRET-MANAGEMENT.md`
- **Environment Template:** `env.example`

---

## 🔒 Security Notes

1. **Never commit secrets** - Use Vault or CI/CD secrets
2. **Rotate secrets regularly** - See rotation cadence in `SECRET-MANAGEMENT.md`
3. **Use production Vault** - Dev mode is insecure (for testing only)
4. **Enable MFA** - Required for admin roles in Auth0
5. **Monitor access logs** - Check Auth0 logs regularly
6. **Limit OAuth scopes** - Request only needed permissions

---

## 🚀 Next Steps

1. **Complete Auth0 setup** - Follow `docs/AUTH0-NEXTAUTH-SETUP.md`
2. **Configure environment variables** - Update `.env` files
3. **Set up Vault** - Store secrets (optional but recommended)
4. **Install NextAuth.js** - `npm install next-auth` in app directory
5. **Test authentication** - Verify all flows work
6. **Deploy to production** - Use AppRole for Vault in production

---

**Last Updated:** December 10, 2025  
**Status:** Configuration complete, awaiting Auth0 tenant setup

