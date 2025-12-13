# Mailu Fixes - Apply Now

**Issues Identified:**
1. ✅ **Front:** `/var/lib/nginx/logs` directory missing in tmpfs
2. ✅ **Front:** Nginx modules path missing in tmpfs  
3. ✅ **Admin:** `setgroups` blocked despite `no-new-privileges:false` + `cap_drop: ALL` conflict
4. ✅ **Admin:** Volume permissions (`/dkim`) blocked

---

## 🚀 Quick Fix: Front Service

**Problem:** tmpfs mount doesn't create directory structure

**Solution A: Use volume mount instead of tmpfs (simpler)**
```yaml
# In compose/mailu.yml - mailu-front service
volumes:
  - mailu_mail_data:/mail
  - mailu_dkim_data:/dkim
  - nginx_logs:/var/lib/nginx  # Add this
# Remove tmpfs: /var/lib/nginx

volumes:
  mailu_mail_data:
  mailu_dkim_data:
  nginx_logs:  # Add this
```

**Solution B: Create directory structure on startup (if keeping tmpfs)**
```yaml
# Add init container or entrypoint script, or change tmpfs to volume
# Recommendation: Use Solution A (volume)
```

**Apply Fix:**
```bash
cd /home/comzis/inlock-infra
# Edit compose/mailu.yml, add nginx_logs volume
docker compose -f compose/mailu.yml --env-file .env up -d --force-recreate mailu-front
```

---

## 🚀 Quick Fix: Admin Service

**Problem:** `cap_drop: ALL` blocks `setgroups` even with `no-new-privileges:false`

**Solution: Remove cap_drop: ALL**
```yaml
# In compose/mailu.yml - mailu-admin service
# REMOVE this line:
# cap_drop:
#   - ALL

# Keep only:
cap_add:
  - SETGID
  - SETUID
  - CHOWN
  - NET_BIND_SERVICE
security_opt:
  - no-new-privileges:false
```

**Apply Fix:**
```bash
cd /home/comzis/inlock-infra
# Edit compose/mailu.yml, remove cap_drop: ALL from mailu-admin
docker compose -f compose/mailu.yml --env-file .env up -d --force-recreate mailu-admin
```

---

## 🔧 Complete Fixed Config Snippets

### Front Service (Fixed)
```yaml
mailu-front:
  # ... existing config ...
  volumes:
    - mailu_mail_data:/mail
    - mailu_dkim_data:/dkim
    - nginx_logs:/var/lib/nginx  # ✅ Add this
  tmpfs:
    - /tmp
    - /var/run
    # Remove: - /var/lib/nginx  # ❌ Remove this
  cap_add:
    - NET_BIND_SERVICE
    - CHOWN
    - SETGID
    - SETUID
    - DAC_OVERRIDE  # ✅ Add this for file access
  security_opt:
    - no-new-privileges:false
  # NO cap_drop: ALL  # ✅ Already removed

volumes:
  # ... existing volumes ...
  nginx_logs:  # ✅ Add this
```

### Admin Service (Fixed)
```yaml
mailu-admin:
  # ... existing config ...
  cap_add:
    - SETGID
    - SETUID
    - CHOWN
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:false
  # ✅ REMOVED: cap_drop: ALL
```

---

## 🧪 Verify Fixes

```bash
# Check front logs (should see nginx starting)
docker compose -f compose/mailu.yml logs mailu-front | tail -20

# Check admin logs (should see "Starting Mailu admin")
docker compose -f compose/mailu.yml logs mailu-admin | tail -20

# Verify services are running
docker compose -f compose/mailu.yml ps
```

---

**Apply these fixes now!**

