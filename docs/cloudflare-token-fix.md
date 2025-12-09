# Cloudflare Token Configuration Fix

## Current Issue

Traefik is receiving the Cloudflare API token, but Cloudflare is rejecting it with:
```
error: Cannot use the access token from location: 156.67.29.52
status code 403
```

## Root Cause

The Cloudflare API token has one of these issues:
1. **IP Restriction**: Token is restricted to specific IPs that don't include `156.67.29.52`
2. **Insufficient Permissions**: Token doesn't have DNS:Edit permissions
3. **Zone Access**: Token doesn't have access to `inlock.ai` zone

## Solution: Update Cloudflare Token

### Step 1: Go to Cloudflare Dashboard
1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**

### Step 2: Create/Edit Token
Create a new token or edit the existing one with these settings:

**Token Permissions:**
- **Zone** → **DNS** → **Edit** → Select `inlock.ai` zone

**Zone Resources:**
- Include → Specific zone → `inlock.ai`

**Client IP Address Filtering:**
- **Option 1 (Recommended)**: Leave empty (no IP restriction)
- **Option 2**: Add your server IP: `156.67.29.52`

### Step 3: Update .env File
Replace the token in `/home/comzis/inlock-infra/.env`:
```bash
CLOUDFLARE_API_TOKEN=your-new-token-here
```

### Step 4: Restart Traefik
```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart traefik
```

## Alternative: Use Global API Key

If you prefer to use the Global API Key (less secure):

1. Get your Global API Key from Cloudflare Dashboard
2. Update `.env`:
   ```bash
   CLOUDFLARE_EMAIL=your-email@example.com
   CLOUDFLARE_API_KEY=your-global-api-key
   ```

3. Update `compose/stack.yml` to use these variables instead of `CF_DNS_API_TOKEN`

## Verification

After updating the token, check Traefik logs:
```bash
docker logs compose-traefik-1 --tail 50 | grep -i cloudflare
```

You should see successful certificate generation instead of 403 errors.

## Current Status

✅ **Token is configured** in `.env`  
✅ **Traefik is receiving the token**  
❌ **Cloudflare is rejecting it** (needs permission/IP fix)

Once the token permissions are fixed, Let's Encrypt certificates will be automatically generated for all subdomains.



