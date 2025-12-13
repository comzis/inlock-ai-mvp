# Auth0 Tenant Verification Checklist

**Created:** 2025-12-13 01:20 UTC  
**Agent:** Auth0 Tenant Scout (Agent 2)  
**Purpose:** Pre-fetch tenant settings and known pitfalls

---

## Tenant Information

### Basic Details
- **Tenant Domain:** `comzis.eu.auth0.com`
- **Tenant Region:** EU (based on domain)
- **OIDC Issuer:** `https://comzis.eu.auth0.com/`
- **Well-Known Config:** `https://comzis.eu.auth0.com/.well-known/openid-configuration`

### Known Endpoints
- **Authorization:** `https://comzis.eu.auth0.com/authorize`
- **Token:** `https://comzis.eu.auth0.com/oauth/token`
- **UserInfo:** `https://comzis.eu.auth0.com/userinfo`
- **JWKS:** `https://comzis.eu.auth0.com/.well-known/jwks.json`

---

## Application: inlock-admin

### Required Settings Checklist

#### ✅ Callback URLs (CRITICAL)
- [ ] **Allowed Callback URLs** contains: `https://auth.inlock.ai/oauth2/callback`
- [ ] No trailing slashes
- [ ] Exact match (case-sensitive)
- [ ] No wildcards unless intentional

**Current Expected:**
```
https://auth.inlock.ai/oauth2/callback
```

#### ✅ Logout URLs
- [ ] **Allowed Logout URLs** contains:
  - `https://auth.inlock.ai/oauth2/callback`
  - `https://traefik.inlock.ai`
  - `https://portainer.inlock.ai`
  - `https://grafana.inlock.ai`
  - `https://n8n.inlock.ai`
  - `https://deploy.inlock.ai`
  - `https://dashboard.inlock.ai`
  - `https://cockpit.inlock.ai`

**Format:** Comma-separated, no trailing slashes

#### ✅ Web Origins (CORS)
- [ ] **Allowed Web Origins** contains: `https://auth.inlock.ai`
- [ ] No trailing slashes
- [ ] Protocol must be `https://`

#### ✅ Application Type
- [ ] **Application Type:** Regular Web Application
- [ ] **Token Endpoint Authentication Method:** `client_secret_post` or `client_secret_basic`

#### ✅ Grant Types
- [ ] **Authorization Code** enabled
- [ ] **Refresh Token** enabled
- [ ] **Implicit** disabled (security best practice)

#### ✅ OIDC Settings
- [ ] **OIDC Conformant:** Enabled
- [ ] **JWT Expiration:** 36000 seconds (10 hours) or appropriate
- [ ] **JWT Algorithm:** RS256

#### ✅ PKCE Settings
- [ ] **PKCE Support:** Enabled (Auth0 supports S256 and plain)
- [ ] **Code Challenge Method:** S256 (preferred) or plain

#### ✅ Refresh Token Settings
- [ ] **Rotation Type:** Rotating (recommended)
- [ ] **Expiration Type:** Expiring
- [ ] **Token Lifetime:** 2592000 seconds (30 days) or appropriate
- [ ] **Idle Lifetime:** 1296000 seconds (15 days) or appropriate

---

## Known Pitfalls & Gotchas

### 1. Callback URL Mismatch
**Symptom:** "Invalid redirect_uri" error  
**Cause:** Callback URL not in allowed list or typo  
**Fix:** Verify exact match in Auth0 Dashboard

### 2. CORS Issues
**Symptom:** Browser blocks requests to Auth0  
**Cause:** Web Origins not configured  
**Fix:** Add `https://auth.inlock.ai` to Allowed Web Origins

### 3. PKCE Mismatch
**Symptom:** "Invalid code_verifier" error  
**Cause:** Code challenge method mismatch  
**Fix:** Ensure both client and server use same method (S256)

### 4. Token Expiration
**Symptom:** Frequent re-authentication  
**Cause:** JWT lifetime too short  
**Fix:** Adjust JWT expiration in Auth0 Dashboard

### 5. Refresh Token Issues
**Symptom:** Refresh fails after period of inactivity  
**Cause:** Idle token lifetime too short  
**Fix:** Adjust refresh token idle lifetime

### 6. SameSite Cookie Issues
**Symptom:** CSRF cookie not sent (already fixed)  
**Cause:** SameSite=Lax blocks cross-site redirects  
**Fix:** ✅ Already fixed - using SameSite=None

### 7. HTTPS Required
**Symptom:** Authentication fails in production  
**Cause:** Callback URL uses http:// instead of https://  
**Fix:** Ensure all URLs use https://

---

## Required Scopes

### For OAuth2-Proxy
- `openid` - Required for OIDC
- `profile` - User profile information
- `email` - User email address

**Current Configuration:**
```
OAUTH2_PROXY_SCOPE=openid profile email
```

### For Management API (if using)
- `read:applications` - Read application settings
- `update:applications` - Update application settings
- `read:clients` - Read client information
- `update:clients` - Update client information

---

## Verification Steps

### Step 1: Access Auth0 Dashboard
1. Go to: https://manage.auth0.com/
2. Select tenant: `comzis` (EU region)
3. Navigate to: **Applications** → **Applications**

### Step 2: Select Application
1. Find: `inlock-admin`
2. Click to open settings

### Step 3: Verify Settings
1. Check **Allowed Callback URLs** (see checklist above)
2. Check **Allowed Logout URLs** (see checklist above)
3. Check **Allowed Web Origins** (see checklist above)
4. Verify **Application Type** is "Regular Web Application"
5. Verify **Token Endpoint Authentication Method**

### Step 4: Verify Advanced Settings
1. Click **Show Advanced Settings**
2. Check **OAuth** tab:
   - Grant Types
   - JWT Expiration
   - JWT Algorithm
3. Check **OIDC** tab:
   - OIDC Conformant enabled

### Step 5: Test Configuration
1. Use test script: `scripts/test-auth0-api.sh` (if Management API configured)
2. Or manually test authentication flow

---

## Evidence Template

### Screenshot Checklist
- [ ] Application Settings page (showing callback URLs)
- [ ] Advanced Settings → OAuth tab
- [ ] Advanced Settings → OIDC tab
- [ ] Application Type confirmation

### Configuration Snapshot
```yaml
Application: inlock-admin
Client ID: aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o
Callback URLs: https://auth.inlock.ai/oauth2/callback
Logout URLs: [list]
Web Origins: https://auth.inlock.ai
Application Type: Regular Web Application
Token Auth Method: [client_secret_post/client_secret_basic]
OIDC Conformant: true
PKCE Support: true
```

---

## Quick Verification Script

```bash
# Verify OIDC configuration is accessible
curl -s https://comzis.eu.auth0.com/.well-known/openid-configuration | jq '.issuer, .authorization_endpoint'

# Verify JWKS endpoint
curl -s https://comzis.eu.auth0.com/.well-known/jwks.json | jq '.keys[0].kid'

# Test callback endpoint (should return 403 without OAuth params)
curl -I https://auth.inlock.ai/oauth2/callback
```

---

## Next Steps

1. **Primary Team:** Use this checklist to verify Auth0 Dashboard
2. **Document Results:** Update `AUTH0-FIX-STATUS.md` with verification results
3. **Fix Issues:** If any settings don't match, update in Auth0 Dashboard
4. **Test:** Run browser E2E test after verification

---

**Last Updated:** 2025-12-13 01:20 UTC  
**Status:** Ready for Primary Team Use

