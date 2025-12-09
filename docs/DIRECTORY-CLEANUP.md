# Directory Cleanup - StreamArt → Inlock

## Directory Rename & Move

The application directory has been renamed and moved to a cleaner path:

**Old Path:** `/opt/streamart-ai-secure-mvp/streamart-ai-secure-mvp/`  
**New Path:** `/opt/inlock-ai-secure-mvp/`

## Move Command

To move the directory, run:

```bash
/home/comzis/move-to-inlock.sh
```

Or manually:

```bash
# Move directory
sudo mv /opt/streamart-ai-secure-mvp/streamart-ai-secure-mvp /opt/inlock-ai-secure-mvp

# Set ownership
sudo chown -R comzis:comzis /opt/inlock-ai-secure-mvp

# Backup old parent directory (if empty)
if [ -d /opt/streamart-ai-secure-mvp ] && [ -z "$(ls -A /opt/streamart-ai-secure-mvp)" ]; then
    sudo mv /opt/streamart-ai-secure-mvp /tmp/streamart-ai-secure-mvp-old-backup
fi
```

## Updated References

All configuration files have been updated to use the new path:

- ✅ `compose/inlock-ai.yml` - Environment file path
- ✅ `scripts/prepare-inlock-deployment.sh` - Application directory
- ✅ All documentation files - Updated paths

## After Moving

1. **Verify directory moved:**
   ```bash
   ls -la /opt/inlock-ai-secure-mvp
   ```

2. **Rebuild Docker image:**
   ```bash
   cd /opt/inlock-ai-secure-mvp
   docker build -t inlock-ai:latest .
   ```

3. **Redeploy:**
   ```bash
   cd /home/comzis/inlock-infra
   docker compose -f compose/stack.yml --env-file .env up -d inlock-ai
   ```

## Benefits

- ✅ Cleaner path structure
- ✅ Consistent naming (inlock-ai-secure-mvp)
- ✅ Easier to navigate
- ✅ Matches branding (Inlock AI)

---

**Status:** Configuration updated, ready for directory move

