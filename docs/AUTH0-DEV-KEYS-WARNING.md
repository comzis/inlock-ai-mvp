# Auth0 Dev Keys Warning - Explanation & Fix

**Date:** December 11, 2025  
**Issue:** Auth0 dashboard showing "Dev Keys" warning

## What This Means

Auth0 is warning that you're using **development/test keys** instead of **production keys**. This alert appears when:

1. The Auth0 application/client was created in a test/development environment
2. The client has development-specific settings enabled
3. Auth0 detects usage patterns that suggest development/testing

## Current Configuration

- **Auth0 Tenant**: `comzis.eu.auth0.com`
- **Client ID**: `aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o`
- **Usage**: OAuth2-Proxy for admin service authentication

## Is This a Problem?

**For now: No** - Authentication will still work correctly. This is just a warning.

**For production: Yes** - You should use production keys for:
- Better security
- Production-grade rate limits
- Compliance requirements
- Proper monitoring/analytics

## How to Fix (When Ready for Production)

### Option 1: Create New Production Application (Recommended)

1. **Go to Auth0 Dashboard**: https://manage.auth0.com/
2. **Applications** → **Create Application**
3. **Name**: `inlock-admin-production` (or similar)
4. **Type**: Regular Web Application
5. **Settings**:
   - **Allowed Callback URLs**: `https://auth.inlock.ai/oauth2/callback`
   - **Allowed Logout URLs**: `https://auth.inlock.ai/oauth2/callback,https://traefik.inlock.ai,https://portainer.inlock.ai,https://grafana.inlock.ai,https://n8n.inlock.ai,https://deploy.inlock.ai,https://dashboard.inlock.ai,https://cockpit.inlock.ai` (comma-separated, no trailing slashes)
   - **Allowed Web Origins**: Leave empty (OAuth2-Proxy handles this)
   - **Application Type**: Regular Web Application
6. **Copy the new Client ID and Secret**
7. **Update `.env` file**:
   ```bash
   AUTH0_ADMIN_CLIENT_ID=<new-production-client-id>
   AUTH0_ADMIN_CLIENT_SECRET=<new-production-client-secret>
   ```
8. **Restart OAuth2-Proxy**:
   ```bash
   cd /home/comzis/inlock-infra
   docker compose -f compose/stack.yml --env-file .env restart oauth2-proxy
   ```

### Option 2: Convert Existing Application to Production

1. **Go to Auth0 Dashboard** → **Applications** → Select your current app
2. **Settings** tab
3. **Ensure production settings**:
   - Remove any test/development flags
   - Set proper rate limits
   - Enable production monitoring
4. **Save changes**

## Current Status

- ✅ Authentication working correctly
- ⚠️ Using development keys (warning only)
- ✅ Can continue using current setup
- 📋 Should migrate to production keys before full production launch

## Verification

After updating to production keys:
1. Restart OAuth2-Proxy
2. Test authentication flow
3. Check Auth0 dashboard - warning should disappear
4. Verify all protected services still work

---

**Last Updated:** December 11, 2025  
**Status:** Warning only - Authentication functional
