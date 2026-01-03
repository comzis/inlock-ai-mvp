# Postgres no-new-privileges Fix

**Status:** In Progress  
**Created:** 2026-01-03  
**Target Completion:** 2026-02-03

## Issue

Postgres service has `no-new-privileges:false` temporarily disabled in `compose/services/postgres.yml` (line 54-55).

**Risk Level:** Medium  
**Impact:** Postgres container can potentially gain new privileges, reducing security isolation.

## Root Cause

Postgres data directory permissions may not be correctly set for the postgres user (UID 70), preventing Postgres from starting with `no-new-privileges:true` enabled.

## Solution

### Step 1: Fix Permissions

Run the permission fix script:

```bash
sudo ./scripts/security/fix-postgres-permissions.sh
```

This script will:
- Check current volume ownership
- Fix ownership to postgres user (UID 70)
- Set correct permissions (700 for directories, 600 for files)

### Step 2: Test with no-new-privileges Enabled

1. Update `compose/services/postgres.yml` to set `no-new-privileges:true`
2. Test Postgres startup:

```bash
docker compose -f compose/services/postgres.yml config
docker compose -f compose/services/postgres.yml up -d
docker logs services-postgres-1
```

3. Verify no permission errors in logs
4. Verify Postgres is accessible and functioning

### Step 3: Re-enable no-new-privileges

Once permissions are fixed and tested:

1. Update `compose/services/postgres.yml`:
   ```yaml
   security_opt:
     - no-new-privileges:true
   ```

2. Restart Postgres:
   ```bash
   docker compose -f compose/services/postgres.yml restart postgres
   ```

3. Verify service is running correctly:
   ```bash
   docker logs services-postgres-1
   docker exec services-postgres-1 pg_isready
   ```

## Verification

After re-enabling `no-new-privileges:true`, verify:

- [ ] Postgres starts without errors
- [ ] No permission errors in logs
- [ ] Database connections work
- [ ] Health checks pass
- [ ] No privilege escalation warnings

## Related Files

- `compose/services/postgres.yml` - Postgres service configuration
- `compose/services/inlock-db.yml` - Inlock database (may need similar fix)
- `scripts/security/fix-postgres-permissions.sh` - Permission fix script

## Notes

- Both `postgres.yml` (n8n database) and `inlock-db.yml` may need this fix
- The fix script handles both volumes automatically
- Test in staging/dev environment first if possible

## Timeline

- **2026-01-03:** Issue documented, fix script created
- **2026-01-10:** Run permission fix script
- **2026-01-17:** Test with no-new-privileges enabled
- **2026-02-03:** Re-enable no-new-privileges in production

