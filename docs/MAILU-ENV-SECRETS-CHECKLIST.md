# Mailu Environment Variables and Secrets Checklist

**Purpose:** Verify all required Mailu environment variables and secrets are configured correctly.

---

## ✅ Secrets Validation

### Required Secrets (Files)

**Location:** `/home/comzis/apps/secrets-real/`

| Secret File | Status | Purpose | Validation |
|------------|--------|---------|------------|
| `mailu-secret-key` | ✅ | SECRET_KEY_FILE | Must be non-empty, used for encryption |
| `mailu-admin-password` | ✅ | ADMIN_PW_FILE | Must be non-empty, admin login password |
| `mailu-db-password` | ✅ | DB_PW_FILE | Must be non-empty, PostgreSQL password |

### Quick Validation Commands

```bash
# Check secrets exist and are non-empty
for secret in mailu-secret-key mailu-admin-password mailu-db-password; do
  if [ -s "/home/comzis/apps/secrets-real/$secret" ]; then
    echo "✅ $secret: OK ($(wc -c < /home/comzis/apps/secrets-real/$secret) bytes)"
  else
    echo "❌ $secret: MISSING OR EMPTY"
  fi
done
```

**Expected Output:**
```
✅ mailu-secret-key: OK (32 bytes)
✅ mailu-admin-password: OK (16 bytes)
✅ mailu-db-password: OK (16 bytes)
```

---

## ✅ Environment Variables Checklist

### Required Mailu Environment Variables

**File:** `.env` or passed via `env_file` in compose

| Variable | Required | Purpose | Example | Status |
|----------|----------|---------|---------|--------|
| `DOMAIN` | ✅ Yes | Primary domain | `inlock.ai` | ✅ |
| `SECRET_KEY_FILE` | ✅ Yes | Path to secret key | `/run/secrets/mailu-secret-key` | ✅ |
| `DB_HOST` | ✅ Yes | PostgreSQL host | `mailu-postgres` | ✅ |
| `DB_USER` | ✅ Yes | PostgreSQL user | `mailu` | ✅ |
| `DB_PW_FILE` | ✅ Yes | Path to DB password | `/run/secrets/mailu-db-password` | ✅ |
| `DB_NAME` | ✅ Yes | Database name | `mailu` | ✅ |
| `REDIS_HOST` | ✅ Yes | Redis host | `mailu-redis` | ✅ |
| `REDIS_PORT` | ✅ Yes | Redis port | `6379` | ✅ |
| `TLS_FLAVOR` | ✅ Yes | TLS configuration | `mail-letsencrypt` | ✅ |
| `POSTMASTER` | ✅ Yes | Postmaster email | `admin@inlock.ai` | ✅ |
| `MESSAGE_SIZE_LIMIT` | ✅ Yes | Max message size (bytes) | `52428800` (50MB) | ✅ |

### Optional but Recommended

| Variable | Required | Purpose | Example | Status |
|----------|----------|---------|---------|--------|
| `HOSTNAMES` | ⚠️ Recommended | Comma-separated hostnames | `mail.inlock.ai` | ✅ |
| `TZ` | ⚠️ Recommended | Timezone | `UTC` | ✅ |
| `SUBNET` | ⚠️ Recommended | Docker network subnet | `172.18.0.0/16` | ✅ |
| `LOG_LEVEL` | ⚠️ Recommended | Logging level | `INFO` | ✅ |
| `ADMIN_USER` | ⚠️ Admin only | Admin username | `admin` | ✅ |
| `ADMIN_PW_FILE` | ⚠️ Admin only | Admin password file | `/run/secrets/mailu-admin-password` | ✅ |

---

## 🔍 Validation Commands

### Check Environment Variables in Running Containers

```bash
# Check front service
docker exec compose-mailu-front-1 env | grep -E "(DOMAIN|SECRET_KEY|DB_|REDIS_|TLS|POSTMASTER|MESSAGE_SIZE)"

# Check admin service (when running)
docker exec compose-mailu-admin-1 env | grep -E "(DOMAIN|SECRET_KEY|DB_|REDIS_|ADMIN_)"

# Check postfix service
docker exec compose-mailu-postfix-1 env | grep -E "(DOMAIN|SECRET_KEY|DB_|REDIS_|MESSAGE_SIZE)"
```

**Expected Output (example for front):**
```
DOMAIN=inlock.ai
SECRET_KEY_FILE=/run/secrets/mailu-secret-key
DB_HOST=mailu-postgres
DB_USER=mailu
DB_PW_FILE=/run/secrets/mailu-db-password
DB_NAME=mailu
REDIS_HOST=mailu-redis
REDIS_PORT=6379
TLS_FLAVOR=mail-letsencrypt
POSTMASTER=admin@inlock.ai
MESSAGE_SIZE_LIMIT=52428800
```

### Verify Secret File Accessibility

```bash
# Check if secrets are accessible in container
docker exec compose-mailu-front-1 test -r /run/secrets/mailu-secret-key && echo "✅ mailu-secret-key readable" || echo "❌ mailu-secret-key NOT readable"
docker exec compose-mailu-front-1 test -r /run/secrets/mailu-db-password && echo "✅ mailu-db-password readable" || echo "❌ mailu-db-password NOT readable"
```

---

## 🧪 Secret File Content Validation

### SECRET_KEY_FILE

**Requirements:**
- Must be non-empty
- Typically 32 bytes (256 bits)
- Used for session encryption, cookie signing

**Validation:**
```bash
SECRET_KEY_SIZE=$(wc -c < /home/comzis/apps/secrets-real/mailu-secret-key)
if [ "$SECRET_KEY_SIZE" -ge 16 ]; then
  echo "✅ SECRET_KEY_FILE: Size OK ($SECRET_KEY_SIZE bytes)"
else
  echo "❌ SECRET_KEY_FILE: Too short ($SECRET_KEY_SIZE bytes, need >= 16)"
fi
```

### DB_PW_FILE

**Requirements:**
- Must be non-empty
- Used for PostgreSQL authentication

**Validation:**
```bash
if [ -s /home/comzis/apps/secrets-real/mailu-db-password ]; then
  echo "✅ DB_PW_FILE: OK"
else
  echo "❌ DB_PW_FILE: Missing or empty"
fi
```

### ADMIN_PW_FILE

**Requirements:**
- Must be non-empty
- Plain text password (no hashing needed)

**Validation:**
```bash
if [ -s /home/comzis/apps/secrets-real/mailu-admin-password ]; then
  echo "✅ ADMIN_PW_FILE: OK"
  echo "⚠️  Admin password length: $(wc -c < /home/comzis/apps/secrets-real/mailu-admin-password) bytes"
else
  echo "❌ ADMIN_PW_FILE: Missing or empty"
fi
```

---

## 📋 Complete Validation Script

```bash
#!/bin/bash
# Mailu Secrets and Environment Validation

echo "=== Mailu Secrets and Environment Validation ==="
echo ""

# Check secrets
echo "1. Checking Secret Files..."
SECRETS_DIR="/home/comzis/apps/secrets-real"
for secret in mailu-secret-key mailu-admin-password mailu-db-password; do
  if [ -s "$SECRETS_DIR/$secret" ]; then
    size=$(wc -c < "$SECRETS_DIR/$secret")
    echo "   ✅ $secret: OK ($size bytes)"
  else
    echo "   ❌ $secret: MISSING OR EMPTY"
  fi
done

echo ""
echo "2. Checking Environment Variables (front service)..."
if docker ps | grep -q compose-mailu-front-1; then
  docker exec compose-mailu-front-1 env | grep -E "^DOMAIN=|^SECRET_KEY_FILE=|^DB_|^REDIS_|^TLS_|^POSTMASTER=|^MESSAGE_SIZE_LIMIT=" | while read line; do
    echo "   ✅ $line"
  done
else
  echo "   ⚠️  Front service not running"
fi

echo ""
echo "3. Checking Secret File Accessibility..."
if docker ps | grep -q compose-mailu-front-1; then
  for secret in mailu-secret-key mailu-db-password; do
    if docker exec compose-mailu-front-1 test -r "/run/secrets/$secret" 2>/dev/null; then
      echo "   ✅ $secret: Accessible in container"
    else
      echo "   ❌ $secret: NOT accessible in container"
    fi
  done
else
  echo "   ⚠️  Front service not running"
fi

echo ""
echo "=== Validation Complete ==="
```

**Save as:** `scripts/validate-mailu-secrets.sh`
**Usage:** `./scripts/validate-mailu-secrets.sh`

---

## ⚠️ Common Issues

### Issue: Secret file empty

**Symptom:** Service fails to start, authentication errors

**Fix:**
```bash
# Generate new secret key (32 bytes)
openssl rand -base64 32 > /home/comzis/apps/secrets-real/mailu-secret-key

# Set permissions
chmod 600 /home/comzis/apps/secrets-real/mailu-secret-key
```

### Issue: Secret file not readable in container

**Symptom:** Permission denied errors when accessing secrets

**Fix:**
- Ensure secrets are mounted in compose file (check `secrets:` section)
- Check file permissions on host: `chmod 600 /home/comzis/apps/secrets-real/mailu-*`
- Restart container after fixing permissions

### Issue: MESSAGE_SIZE_LIMIT too small

**Symptom:** Large emails rejected

**Fix:**
- Increase `MESSAGE_SIZE_LIMIT` in compose file (currently 52428800 = 50MB)
- Also check postfix message size limit if needed

---

**Next:** See `MAILU-TEST-PLAN.md` for testing procedures.

