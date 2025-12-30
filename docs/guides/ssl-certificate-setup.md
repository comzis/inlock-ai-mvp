# SSL Certificate Setup Guide

## Certificate Signing Request (CSR) Received

You have a CSR for `inlock.ai` and `www.inlock.ai`. Here's how to complete the certificate setup:

## Step 1: Submit CSR to PositiveSSL

1. Log in to your PositiveSSL account (or your certificate provider)
2. Submit the CSR you received
3. Complete domain validation (email or DNS verification)
4. Download the signed certificate files

## Step 2: Receive Certificate Files

You should receive:
- **Certificate file** (`.crt` or `.pem`) - The signed certificate
- **Intermediate certificate** (`.ca-bundle` or `.chain`) - CA chain
- **Private key** - The key that matches your CSR (you should have this from when you generated the CSR)

## Step 3: Install Certificate Files

Place the files in the secrets directory:

```bash
# Certificate (may need to combine with intermediate)
cat your-certificate.crt your-intermediate.crt > /home/comzis/apps/secrets-real/positive-ssl.crt

# Private key (the one you used to generate the CSR)
cp your-private.key /home/comzis/apps/secrets-real/positive-ssl.key

# Set permissions
chmod 600 /home/comzis/apps/secrets-real/positive-ssl.crt
chmod 600 /home/comzis/apps/secrets-real/positive-ssl.key
```

## Step 4: Restart Traefik

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart traefik
```

## Step 5: Verify Certificate

```bash
# Check Traefik logs
docker logs compose-traefik-1 | grep -i certificate

# Test HTTPS
curl -k -v https://inlock.ai 2>&1 | grep -i "SSL\|certificate"
```

## CSR Storage

Your CSR has been saved to:
- `/home/comzis/inlock-infra/secrets/inlock-ai.csr`

Keep this CSR file for reference, but the actual certificate files (`.crt` and `.key`) are what Traefik needs.

## Troubleshooting

**If certificate doesn't load:**
- Verify file format (should be PEM, not DER)
- Check certificate chain is complete (cert + intermediate)
- Ensure private key matches the CSR
- Check file permissions (600)
- Review Traefik logs for specific errors

**Common errors:**
- "failed to find any PEM data" → File format issue or empty file
- "certificate and key don't match" → Wrong private key
- "certificate expired" → Need to renew

## Certificate Rotation

When renewing or replacing certificates:

1. **Backup current certificate:**
   ```bash
   cp /home/comzis/apps/secrets-real/positive-ssl.crt /home/comzis/apps/secrets-real/positive-ssl.crt.backup-$(date +%Y%m%d)
   cp /home/comzis/apps/secrets-real/positive-ssl.key /home/comzis/apps/secrets-real/positive-ssl.key.backup-$(date +%Y%m%d)
   ```

2. **Install new certificate:**
   ```bash
   cp new-certificate.crt /home/comzis/apps/secrets-real/positive-ssl.crt
   cp new-private.key /home/comzis/apps/secrets-real/positive-ssl.key
   chmod 600 /home/comzis/apps/secrets-real/positive-ssl.*
   ```

3. **Update Docker secrets:**
   ```bash
   # Docker Compose reads directly from /home/comzis/apps/secrets-real/
   chmod 600 /home/comzis/apps/secrets-real/positive-ssl.*
   ```

4. **Restart Traefik:**
   ```bash
   cd /home/comzis/inlock-infra
   docker compose -f compose/stack.yml --env-file .env restart traefik
   ```

5. **Verify certificate:**
   ```bash
   openssl s_client -connect inlock.ai:443 -servername inlock.ai < /dev/null 2>/dev/null | openssl x509 -noout -dates
   ```

## Secret Storage

**Important:** Real secrets are stored in `/home/comzis/apps/secrets-real/` (outside the Git repository). The `secrets/` directory in the repository contains only `.example` placeholder files.

## Next Steps

Once PositiveSSL certificate is installed:
1. Traefik will use it as default certificate for `inlock.ai`
2. Let's Encrypt will handle subdomains (`traefik.inlock.ai`, `portainer.inlock.ai`, etc.)
3. Test access control with HTTPS endpoints

