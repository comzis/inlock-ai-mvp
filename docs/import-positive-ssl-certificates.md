# Import PositiveSSL Certificates - Step by Step Guide

## What You Need

After downloading from PositiveSSL, you should have:
1. **Certificate file** (usually named like `inlock_ai.crt`, `certificate.crt`, or `domain.crt`)
2. **Private key** (usually named like `private.key`, `domain.key`, or `private_key.key`)
3. **Intermediate/Chain file** (usually named like `ca-bundle.crt`, `intermediate.crt`, or `chain.crt`)

## Method 1: Using the Installation Script (Recommended)

### Step 1: Upload Files to Server

Upload your downloaded certificate files to the server. You can use:
- `scp` (from your local machine):
  ```bash
  scp /path/to/certificate.crt user@server:/tmp/
  scp /path/to/private.key user@server:/tmp/
  scp /path/to/intermediate.crt user@server:/tmp/  # if you have it
  ```

- Or copy them directly if you're already on the server

### Step 2: Run Installation Script

```bash
cd /home/comzis/inlock-infra

# If you have all three files:
./scripts/install-positive-ssl.sh /tmp/certificate.crt /tmp/private.key /tmp/intermediate.crt

# If you only have certificate and key:
./scripts/install-positive-ssl.sh /tmp/certificate.crt /tmp/private.key
```

The script will:
- ✅ Validate certificate matches the key
- ✅ Create backups
- ✅ Install to correct location
- ✅ Set proper permissions
- ✅ Restart Traefik
- ✅ Show certificate details

## Method 2: Manual Installation

### Step 1: Combine Certificate with Intermediate Chain

If you have an intermediate certificate, combine it with your main certificate:

```bash
cat /path/to/certificate.crt /path/to/intermediate.crt > /home/comzis/apps/secrets/positive-ssl.crt
```

If you don't have an intermediate, just copy the certificate:

```bash
cp /path/to/certificate.crt /home/comzis/apps/secrets/positive-ssl.crt
```

### Step 2: Copy Private Key

```bash
cp /path/to/private.key /home/comzis/apps/secrets/positive-ssl.key
```

### Step 3: Set Permissions

```bash
chmod 600 /home/comzis/apps/secrets/positive-ssl.crt
chmod 600 /home/comzis/apps/secrets/positive-ssl.key
```

### Step 4: Verify Certificate

```bash
# Check certificate details
openssl x509 -in /home/comzis/apps/secrets/positive-ssl.crt -noout -text | head -20

# Verify certificate matches key
openssl x509 -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.crt | openssl md5
openssl rsa -noout -modulus -in /home/comzis/apps/secrets/positive-ssl.key | openssl md5
# These should match!
```

### Step 5: Restart Traefik

```bash
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart traefik
```

### Step 6: Check Traefik Logs

```bash
docker logs compose-traefik-1 --tail 50 | grep -i certificate
```

## Troubleshooting

### "Certificate and key don't match"
- Make sure you're using the private key that was used to generate the CSR
- The key should be the one you created when generating the CSR

### "Failed to find any PEM data"
- Certificate file might be in wrong format (DER instead of PEM)
- Convert DER to PEM: `openssl x509 -inform DER -in cert.der -out cert.pem`

### "Certificate expired"
- Check expiry: `openssl x509 -in /home/comzis/apps/secrets/positive-ssl.crt -noout -enddate`
- You may need to renew the certificate

### Traefik shows errors
- Check logs: `docker logs compose-traefik-1`
- Verify file paths in `traefik/dynamic/tls.yml` match your secret files
- Ensure certificate chain is complete (cert + intermediate)

## File Locations Summary

- **Certificate**: `/home/comzis/apps/secrets/positive-ssl.crt`
- **Private Key**: `/home/comzis/apps/secrets/positive-ssl.key`
- **CSR (reference)**: `/home/comzis/inlock-infra/secrets/inlock-ai.csr`

## Quick Check After Installation

```bash
# Test HTTPS endpoint
curl -k -v https://inlock.ai 2>&1 | grep -i "SSL\|certificate"

# Check certificate expiry
openssl s_client -connect inlock.ai:443 -servername inlock.ai </dev/null 2>/dev/null | openssl x509 -noout -dates
```

