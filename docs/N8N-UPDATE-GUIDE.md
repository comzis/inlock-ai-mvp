# n8n Update Guide

## Current Status

- **Current Version**: 2.1.4
- **Latest Available**: 2.2.3
- **Update Status**: Attempted but encountered encryption key mismatch issues

## Update Process

### Prerequisites

1. Ensure you have backups of:
   - n8n data volume (`compose_n8n_data`)
   - n8n encryption key (`/home/comzis/apps/secrets-real/n8n-encryption-key`)
   - n8n database (PostgreSQL)

2. Verify current encryption key is accessible and matches the volume config

### Step-by-Step Update Process

1. **Check current version**:
   ```bash
   docker exec compose-n8n-1 n8n --version
   ```

2. **Pull the latest image**:
   ```bash
   docker pull n8nio/n8n:latest
   # Or specific version:
   docker pull n8nio/n8n:2.2.3
   ```

3. **Update compose file**:
   Edit `compose/services/n8n.yml` and update the image:
   ```yaml
   image: n8nio/n8n:2.2.3  # or use latest tag
   ```

4. **Ensure encryption key consistency**:
   ```bash
   # Read current encryption key from volume
   docker run --rm -v compose_n8n_data:/data alpine cat /data/config
   
   # Ensure secret file matches (no trailing newlines)
   printf "password123" > /home/comzis/apps/secrets-real/n8n-encryption-key
   chmod 600 /home/comzis/apps/secrets-real/n8n-encryption-key
   
   # Update volume config to match
   docker run --rm -v compose_n8n_data:/data alpine sh -c \
     "echo '{\"encryptionKey\": \"password123\"}' > /data/config && chmod 600 /data/config"
   ```

5. **Stop and recreate container**:
   ```bash
   cd /home/comzis/inlock
   docker compose -f compose/services/n8n.yml stop n8n
   docker compose -f compose/services/n8n.yml up -d n8n
   ```

6. **Verify update**:
   ```bash
   docker exec compose-n8n-1 n8n --version
   docker exec compose-n8n-1 wget -qO- http://localhost:5678/healthz
   curl -k -I https://n8n.inlock.ai
   ```

### Known Issues

**Encryption Key Mismatch Error**:
```
Error: Mismatching encryption keys. The encryption key in the settings file 
/home/node/.n8n/config does not match the N8N_ENCRYPTION_KEY env var.
```

**Solution**:
- Ensure the encryption key in `/home/comzis/apps/secrets-real/n8n-encryption-key` matches exactly what's in the volume config file
- Use `printf` instead of `echo` to avoid trailing newlines
- Verify with `od -An -tx1` that both files have identical content

### Recommendations

1. **Use version tags instead of digest pinning** for easier updates:
   ```yaml
   image: n8nio/n8n:2.2.3  # Instead of @sha256:...
   ```

2. **Test updates in staging first** if possible

3. **Check n8n release notes** for breaking changes:
   - https://github.com/n8n-io/n8n/releases

4. **Monitor logs** after update:
   ```bash
   docker logs -f compose-n8n-1
   ```

### Rollback Process

If the update fails:

1. **Revert compose file**:
   ```bash
   git checkout compose/services/n8n.yml
   ```

2. **Restore previous container**:
   ```bash
   docker compose -f compose/services/n8n.yml up -d n8n
   ```

3. **Verify old version is running**:
   ```bash
   docker exec compose-n8n-1 n8n --version
   ```

## Future Updates

When ready to attempt the update again:
1. Check n8n release notes for version 2.2.3+
2. Ensure encryption key is properly configured
3. Follow the step-by-step process above
4. Monitor closely for the first few hours after update


