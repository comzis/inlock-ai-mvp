# Callback URL Verification - Evidence Template

**Agent:** Callback Validator Buddy (Agent 3)  
**Date:** 2025-12-13  
**Purpose:** Capture evidence of callback URL verification for handoff

---

## Quick Verification Checklist

### Pre-Verification
- [ ] Auth0 Dashboard accessible: https://manage.auth0.com/
- [ ] Access to tenant: `comzis.eu.auth0.com`
- [ ] Admin permissions available
- [ ] Browser ready for screenshots

### Core Verification Steps

1. **Navigate to Application**
   - [ ] Applications → Applications
   - [ ] Found application: `inlock-admin`
   - [ ] Client ID verified: `aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o`

2. **Callback URL Field**
   - [ ] Located "Allowed Callback URLs" field
   - [ ] Value contains: `https://auth.inlock.ai/oauth2/callback`
   - [ ] No typos or extra characters
   - [ ] Multiple URLs properly comma-separated (if present)
   - **Screenshot:** [Attach screenshot of callback URL field]

3. **Logout URLs Field**
   - [ ] Located "Allowed Logout URLs" field
   - [ ] Contains service URLs or is properly configured
   - **Screenshot:** [Attach screenshot if needed]

4. **Web Origins Field**
   - [ ] Located "Allowed Web Origins (CORS)" field
   - [ ] Value contains: `https://auth.inlock.ai`
   - **Screenshot:** [Attach screenshot if needed]

5. **Save Status**
   - [ ] Changes saved successfully (if any made)
   - [ ] Confirmation message received

---

## Evidence Capture Template

### Screenshot Checklist
- [ ] Screenshot 1: Auth0 Dashboard → Applications list
- [ ] Screenshot 2: `inlock-admin` application settings page
- [ ] Screenshot 3: Allowed Callback URLs field (zoomed/clear)
- [ ] Screenshot 4: Allowed Logout URLs field (if changed)
- [ ] Screenshot 5: Allowed Web Origins field (if changed)

### Verification Result

```
Verification Date: [YYYY-MM-DD HH:MM UTC]
Verified By: [Name/Username]
Auth0 Tenant: comzis.eu.auth0.com
Application: inlock-admin
Client ID: aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o

CALLBACK URL VERIFICATION:
Status: [PASS / FAIL / NEEDS UPDATE]
Current Value: [paste exact value from field]
Expected Value: https://auth.inlock.ai/oauth2/callback
Match: [YES / NO]
Action Taken: [None / Added / Updated / Needs Manual Fix]

LOGOUT URLS VERIFICATION:
Status: [PASS / FAIL / OPTIONAL]
Current Value: [paste exact value]
Expected: [list of service URLs]
Match: [YES / NO / PARTIAL]

WEB ORIGINS VERIFICATION:
Status: [PASS / FAIL]
Current Value: [paste exact value]
Expected: https://auth.inlock.ai
Match: [YES / NO]

CHANGES MADE:
[List any changes made during verification]

BLOCKERS IDENTIFIED:
[List any blockers or issues]

NEXT STEPS:
[Actions required after verification]

EVIDENCE FILES:
- Screenshot 1: [filename]
- Screenshot 2: [filename]
- Screenshot 3: [filename]
[etc.]

VERIFICATION RESULT: [PASS / FAIL / MANUAL FIX REQUIRED]
```

---

## Quick Verification Commands

### Using Management API (if configured)

```bash
# Test Management API access first
cd /home/comzis/inlock-infra
./scripts/test-auth0-api.sh

# If successful, fetch application details
AUTH0_DOMAIN="comzis.eu.auth0.com"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"
CLIENT_ID="aI9HhGX6SKQcKEsde2aJ7q2OqpxmnM1o"

# Get access token (requires AUTH0_MGMT_CLIENT_ID and AUTH0_MGMT_CLIENT_SECRET in .env)
source .env
TOKEN_RESPONSE=$(curl -s -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
    \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
    \"audience\": \"${AUTH0_API_URL}/\",
    \"grant_type\": \"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

# Get application details
curl -s -X GET "${AUTH0_API_URL}/clients/${CLIENT_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  | jq '{name, callbacks, allowed_logout_urls, web_origins}'
```

---

## Troubleshooting Quick Reference

| Issue | Symptom | Solution |
|-------|---------|----------|
| Callback URL Missing | Field empty or different URL | Add `https://auth.inlock.ai/oauth2/callback` |
| Multiple URLs | Field has multiple comma-separated URLs | Ensure callback URL is in the list |
| Cannot Save | Save button disabled or error | Check permissions, refresh page |
| Wrong Tenant | Different application found | Verify tenant is `comzis.eu.auth0.com` |
| Application Not Found | `inlock-admin` not in list | Verify application name or Client ID |

---

## Handoff Notes

**For Primary Team:**
- [ ] Evidence template completed
- [ ] Screenshots captured (if applicable)
- [ ] Status updated in AUTH0-FIX-STATUS.md
- [ ] Verification result documented
- [ ] Any blockers communicated

**Status:** [READY / NEEDS PRIMARY TEAM ACTION / BLOCKED]

