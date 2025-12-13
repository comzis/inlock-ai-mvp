# Mailu One-Liners - Quick Fixes

**Quick reference for common fixes and checks**

---

## Permission Fixes

```bash
# Fix nginx logs directory (if using volume)
docker compose -f compose/mailu.yml exec mailu-front mkdir -p /var/lib/nginx/logs && chown -R nginx:nginx /var/lib/nginx

# Fix admin volume permissions
docker compose -f compose/mailu.yml exec mailu-admin chown -R mailu:mailu /dkim /data 2>/dev/null || echo "Permission denied - expected, use security opts fix"

# Fix redis data permissions
docker compose -f compose/mailu.yml exec mailu-redis chown -R redis:redis /data
```

---

## Log Checks

```bash
# Front errors
docker compose -f compose/mailu.yml logs mailu-front 2>&1 | grep -iE "error|emerg|fail"

# Admin errors
docker compose -f compose/mailu.yml logs mailu-admin 2>&1 | grep -iE "error|permission|setgroups"

# All Mailu errors
docker compose -f compose/mailu.yml logs 2>&1 | grep -iE "error|emerg|fail|permission"
```

---

## Service Status

```bash
# Quick status
docker compose -f compose/mailu.yml ps

# Health check all
docker compose -f compose/mailu.yml ps --format "table {{.Name}}\t{{.Status}}"

# Count running
docker compose -f compose/mailu.yml ps -q | wc -l
```

---

## Restart Commands

```bash
# Restart all
docker compose -f compose/mailu.yml --env-file .env up -d

# Restart specific service
docker compose -f compose/mailu.yml --env-file .env up -d --force-recreate mailu-front

# Restart front + admin
docker compose -f compose/mailu.yml --env-file .env up -d --force-recreate mailu-front mailu-admin
```

---

## Configuration Checks

```bash
# Verify compose syntax
docker compose -f compose/mailu.yml config > /dev/null && echo "✅ Valid" || echo "❌ Invalid"

# Check environment variables
docker compose -f compose/mailu.yml --env-file .env config | grep -A 5 "mailu-front:" | grep -E "SECRET|DB_|REDIS"

# Verify secrets mounted
docker compose -f compose/mailu.yml exec mailu-front ls -la /run/secrets/
```

---

## Testing

```bash
# Run quick test suite
./scripts/test-mailu-quick.sh

# Test SMTP (if swaks installed)
swaks --to admin@inlock.ai --from admin@inlock.ai --server mail.inlock.ai --port 587 -tls

# Test SMTP with telnet
echo -e "EHLO test\nQUIT" | nc mail.inlock.ai 587

# Test Redis
docker compose -f compose/mailu.yml exec mailu-redis redis-cli ping
```

---

## Volume Fixes

```bash
# List Mailu volumes
docker volume ls | grep mailu

# Inspect volume
docker volume inspect mailu_nginx_logs

# Remove and recreate volume (WARNING: data loss)
docker volume rm mailu_nginx_logs && docker compose -f compose/mailu.yml up -d mailu-front
```

---

## Network Checks

```bash
# Verify networks
docker network ls | grep -E "mail|mgmt"

# Test connectivity
docker compose -f compose/mailu.yml exec mailu-admin ping -c 1 mailu-redis
docker compose -f compose/mailu.yml exec mailu-admin ping -c 1 mailu-postgres
```

---

## Security Override (Emergency)

```bash
# Temporarily remove all security restrictions (TEST ONLY)
# Edit compose/mailu.yml to remove:
# - cap_drop
# - security_opt: no-new-privileges
# - read_only
# Then restart
```

---

## Rollback

```bash
# Revert to previous version
git checkout HEAD -- compose/mailu.yml && docker compose -f compose/mailu.yml --env-file .env up -d

# Check git diff
git diff compose/mailu.yml
```

