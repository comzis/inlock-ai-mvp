# Cloudflare ACME DNS Challenge Setup

## Problem

Traefik cannot obtain Let's Encrypt certificates because the Cloudflare API token is missing.

Error in Traefik logs:
```
cannot get ACME client cloudflare: some credentials information are missing: 
CLOUDFLARE_DNS_API_TOKEN
```

## Solution

### 1. Create Cloudflare API Token

1. Go to Cloudflare Dashboard → My Profile → API Tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. Set permissions:
   - Zone: DNS:Edit
   - Zone Resources: Include → Specific zone → inlock.ai
5. Click "Continue to summary" → "Create Token"
6. Copy the token (you won't see it again!)

### 2. Add Token to .env File

```bash
# Add to /home/comzis/inlock-infra/.env
CLOUDFLARE_DNS_API_TOKEN=your-token-here
```

### 3. Restart Traefik

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart traefik
```

### 4. Wait for Certificates

Traefik will:
- Authenticate with Cloudflare using the token
- Create DNS TXT records for ACME challenge
- Request certificates from Let's Encrypt
- Serve valid SSL certificates

This typically takes 2-3 minutes. Check logs:
```bash
docker logs compose-traefik-1 | grep -i acme
```

### 5. Verify Certificates

```bash
# Check certificate
openssl s_client -connect traefik.inlock.ai:443 -servername traefik.inlock.ai </dev/null 2>&1 | grep -E "subject=|issuer="

# Test HTTPS
curl -I https://traefik.inlock.ai
```

## Alternative: Use Email + API Key

If you prefer using email + API key instead of token:

```bash
# In .env file:
CLOUDFLARE_EMAIL=your-email@example.com
CLOUDFLARE_API_KEY=your-global-api-key
```

Note: API tokens are more secure than global API keys.

## Troubleshooting

**Certificates still not issued:**
- Verify token has DNS:Edit permission
- Check token is scoped to inlock.ai zone
- Verify .env file is being read (check Traefik container env vars)
- Check Traefik logs for specific errors

**SSL handshake fails:**
- Wait 2-3 minutes after restart for ACME challenge
- Verify DNS records point to server (156.67.29.52)
- Ensure Proxy is OFF (gray cloud) in Cloudflare
- Check certificate status in Traefik logs

