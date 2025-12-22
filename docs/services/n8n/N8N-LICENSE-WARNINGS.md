# n8n License SDK Warnings

## What Are These Warnings?

```
[license SDK] cert is invalid because device fingerprint does not match
```

These are **harmless warnings** from n8n's license validation system. They occur when:
- Container is restarted
- System hardware/configuration changes
- Device fingerprint changes

## Do They Cause Problems?

**NO** - These warnings:
- ✅ Don't affect n8n functionality
- ✅ Don't cause blank pages
- ✅ Don't prevent login/setup
- ✅ Are just log noise

n8n Community Edition (which you're using) doesn't require a license, so these warnings are irrelevant.

## How to Reduce Log Noise

### Option 1: Filter Logs (Recommended)

When viewing logs, filter out license warnings:

```bash
# View logs without license warnings
docker logs compose-n8n-1 2>&1 | grep -v "license SDK"

# Or with tail
docker logs compose-n8n-1 --tail 100 2>&1 | grep -v "license SDK"
```

### Option 2: Use Logging Driver Filter

You can configure Docker logging to filter these, but it's usually not worth the complexity.

### Option 3: Ignore Them

Simply ignore these warnings - they're harmless and don't indicate any problem.

## Real Issues vs License Warnings

**License warnings (harmless):**
- `[license SDK] cert is invalid because device fingerprint does not match`
- These are just informational

**Real errors (need attention):**
- `Error: ...`
- `Exception: ...`
- `Fatal: ...`
- `Failed to connect to database`
- `Encryption key mismatch`

## Blank Page Issue

If you're seeing a **blank page**, it's **NOT** caused by license warnings.

Blank pages are usually caused by:
1. **Browser JavaScript errors** (check browser console: F12)
2. **API calls failing** (check Network tab in browser)
3. **Browser cache issues** (hard refresh: Ctrl+Shift+R)

## Verification

To confirm n8n is working despite the warnings:

```bash
# Check n8n is running
docker ps | grep n8n
# Should show: Up ... (healthy)

# Check HTTP response
curl -k -I https://n8n.inlock.ai
# Should return: HTTP/2 200

# Check for real errors (not license warnings)
docker logs compose-n8n-1 --tail 100 2>&1 | grep -i error | grep -v "license SDK"
# Should be empty if no real errors
```

## Summary

- ✅ License SDK warnings are **harmless**
- ✅ They don't cause blank pages
- ✅ Filter them out when viewing logs: `grep -v "license SDK"`
- ✅ Focus on actual errors (not license warnings)
- ✅ Blank page = check browser console (F12)

