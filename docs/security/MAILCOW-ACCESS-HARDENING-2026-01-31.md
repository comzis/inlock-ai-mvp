# Mailcow Admin Restriction and Security Hardening

**Date:** 2026-01-31  
**Status:** Implemented  
**Scope:** mail.inlock.ai admin access restriction; TLS-only confirmation; 2FA recommendation

---

## Summary

- **Admin URL** (`https://mail.inlock.ai/admin/` and `https://admin.inlock.ai`) is restricted to two Tailscale IPs only; all other IPs receive **403 Forbidden**.
- **Tailscale Split DNS** (optional): resolve `mail.inlock.ai` and `admin.inlock.ai` to `100.83.222.69` when on the tailnet so admin access works from Tailscale clients without changing public DNS.
- **Webmail** (https://mail.inlock.ai/, /SOGo) remains **public**.
- **2FA** is recommended in Mailcow but not forced.
- **TLS-only** for IMAP/SMTP/Web is confirmed (no plaintext auth).

---

## 1. What Changed

### 1.1 Traefik (primary enforcement)

- **Middleware:** `mailcow-admin-allowlist` – IP allowlist with:
  - `100.83.222.69/32` (Tailscale server)
  - `100.96.110.8/32` (Tailscale MacBook)
- **Routers:**
  - **mailcow-admin-path:** `Host(mail.inlock.ai)` and `PathPrefix(/admin)` with priority 200, middlewares: `secure-headers`, `mailcow-admin-allowlist`. Non-allowed IPs get **403**.
  - **mailcow-admin:** `Host(admin.inlock.ai)` – same `mailcow-admin-allowlist` middleware.
- **Unchanged:** Router `mailcow` (Host `mail.inlock.ai`, no path) still serves `/` and `/SOGo` publicly.

### 1.2 Mailcow nginx (optional, defense-in-depth)

- **Snippet:** `site.admin-restrict.custom` – location `/admin/` with `allow` for the two IPs, `deny all`, and `proxy_pass` to Mailcow backend.
- **Location in repo:** `config/mailcow/nginx/site.admin-restrict.custom`
- **Location on server (if used):** `/home/comzis/mailcow/data/conf/nginx/site.admin-restrict.custom`

---

## 2. Files Edited / Added

| Path | Action |
|------|--------|
| `traefik/dynamic/middlewares.yml` | Added `mailcow-admin-allowlist` (IP allowlist) |
| `traefik/dynamic/routers.yml` | Added `mailcow-admin-path`; updated `mailcow-admin` with allowlist |
| `config/mailcow/nginx/site.admin-restrict.custom` | **New** – nginx snippet for server (optional) |
| `docs/security/MAILCOW-ACCESS-HARDENING-2026-01-31.md` | **New** – this document |

---

## 3. Exact Commands Executed

### 3.1 Apply Traefik config (main stack)

```bash
# From repo root (e.g. /home/comzis/inlock)
cd /home/comzis/inlock

# Traefik file provider reloads automatically when dynamic YAML changes.
# To force a reload, restart the container (SIGHUP may kill the process):
docker compose -f compose/services/stack.yml up -d traefik
```

(Adjust compose path if your stack is different.)

### 3.2 Optional: Apply Mailcow nginx snippet (on server)

**Confirm before running:** Ensure you can reach the server via Tailscale or console so you are not locked out.

```bash
# Copy snippet to Mailcow nginx conf
sudo cp /home/comzis/inlock/config/mailcow/nginx/site.admin-restrict.custom \
       /home/comzis/mailcow/data/conf/nginx/site.admin-restrict.custom

# Restart Mailcow nginx only
cd /home/comzis/mailcow
docker compose restart nginx-mailcow

# Verify nginx config
docker compose exec nginx-mailcow nginx -t
```

The snippet uses `try_files … @strip-ext` so no PHP-FPM hostname is needed; it reuses the default site’s PHP handling.

---

## 4. Reload / Restart Summary

- **Traefik:** Reload (SIGHUP) or restart so it reads updated `routers.yml` and `middlewares.yml`. Many setups reload automatically when files change.
- **Mailcow:** Only if you deploy the nginx snippet: `docker compose -f /home/comzis/mailcow/docker-compose.yml restart nginx-mailcow`. No need to restart other Mailcow containers for the Traefik-only change.

---

## 5. Verification

### 5.1 From allowed IPs (Tailscale: 100.83.222.69 or 100.96.110.8)

- `https://mail.inlock.ai/admin/` → **200**, admin login page loads.
- `https://admin.inlock.ai/` → **200**, same.
- `https://mail.inlock.ai/` → **200**, webmail (SOGo) loads.

### 5.2 From non-allowed IPs

- `https://mail.inlock.ai/admin/` → **403 Forbidden** (Traefik IPAllowList).
- `https://admin.inlock.ai/` → **403 Forbidden**.
- `https://mail.inlock.ai/` → **200**, webmail still public.

### 5.3 Commands to verify

```bash
# From a non-Tailscale IP (e.g. your home IP without VPN) – expect 403 for /admin
curl -sI -H "Host: mail.inlock.ai" https://mail.inlock.ai/admin/
# Expect: HTTP/2 403

# From Tailscale IP – expect 200 (run from MacBook or server on Tailscale)
curl -sI https://mail.inlock.ai/admin/
# Expect: HTTP/2 200 (or 302 then 200)

# Webmail remains public from any IP
curl -sI https://mail.inlock.ai/
# Expect: HTTP/2 200 or 302
```

---

## 6. TLS-Only and No Plaintext Auth

- **Web:** All access is via HTTPS (Traefik; HTTP redirects to HTTPS). No plaintext HTTP auth.
- **IMAP:** Use **993** (SSL/TLS). Port **143** (STARTTLS) is optional; avoid plaintext.
- **SMTP:** Use **587** (STARTTLS) or **465** (SSL/TLS). No auth over plaintext port 25 from clients.
- **Mailcow:** In Admin → Configuration, ensure TLS is required for services; disable plaintext auth if available. Our docs recommend 993 and 587/465 only (see `docs/guides/MOBILE-EMAIL-SETUP.md`, `docs/reference/AUTH0-MAILCOW-SMTP-QUICK-REFERENCE.md`).

---

## 7. 2FA (Recommended, Not Forced)

- In Mailcow Admin: **Configuration → Admin → Two-Factor Authentication** – enable and recommend 2FA for admin accounts; do **not** force if policy is “recommended only”.
- Document for admins: use 2FA for admin login where possible.

---

## 8. Rollback

### 8.1 Traefik (restore public /admin)

1. In `traefik/dynamic/routers.yml`: remove router `mailcow-admin-path`; remove middleware `mailcow-admin-allowlist` from router `mailcow-admin`.
2. In `traefik/dynamic/middlewares.yml`: remove block `mailcow-admin-allowlist`.
3. Reload or restart Traefik.

### 8.2 Mailcow nginx (if snippet was applied)

```bash
sudo rm /home/comzis/mailcow/data/conf/nginx/site.admin-restrict.custom
cd /home/comzis/mailcow
docker compose restart nginx-mailcow
```

---

## 9. Confirm Before Lock-Out Risk

- **Before** restricting /admin: Ensure you can reach the server (e.g. via Tailscale or console) and that your admin client uses one of 100.83.222.69 or 100.96.110.8 when accessing Mailcow.
- **Before** adding the nginx snippet: Ensure you can reach the server (Tailscale or console); the snippet uses `try_files … @strip-ext` so no upstream hostname is required.

---

## 10. Tailscale Split DNS and Mac-only admin resolution

**Split DNS removed.** Tailscale Split DNS was configured with resolver `100.83.222.69`, but that IP is the Mailcow/Traefik server, not a DNS resolver. Queries to it as a resolver caused timeouts, so Split DNS was removed. Admin access from the Mac is achieved instead with a **Mac-only `/etc/hosts`** mapping (see §10.7).

The subsections below retain the Split DNS configuration and rollback for reference; the **current approach** is §10.7 (Mac `/etc/hosts`).

### 10.1 Current allowlist IPs

| IP | Role |
|----|------|
| `100.83.222.69/32` | Tailscale server (Mailcow/Traefik host) |
| `100.96.110.8/32` | Tailscale MacBook |

### 10.2 Configure Split DNS in Tailscale Admin Console

1. Go to: **https://login.tailscale.com/admin/dns**
2. Under **Split DNS**, add:
   - **Domain:** `mail.inlock.ai`  
     **Resolver:** `100.83.222.69`
   - (Optional) **Domain:** `admin.inlock.ai`  
     **Resolver:** `100.83.222.69`
3. Save.

**Note:** Do **not** change public DNS records for these domains. Webmail (`/`, `/SOGo`) remains publicly accessible; only resolution from Tailscale clients is overridden on the tailnet.

### 10.3 Verify on a Tailscale client (e.g. Mac)

```bash
# Tailscale status
/Applications/Tailscale.app/Contents/MacOS/Tailscale status

# Resolution: should return 100.83.222.69 when on tailnet
dig +short mail.inlock.ai
# Expected: 100.83.222.69

# Admin should succeed (200 or 302, not 403)
curl -sI https://mail.inlock.ai/admin/
# Expected: HTTP/2 200 or HTTP/2 302
```

### 10.4 Verification results (Mac)

Record after enabling Split DNS or Mac hosts (update date when re-verified). **Current approach:** when using Mac `/etc/hosts` (§10.7), use the verification table and final results in §10.7. **Note:** `dig` ignores `/etc/hosts`; on macOS use `dscacheutil -q host -a name mail.inlock.ai` to confirm the hosts mapping → `100.83.222.69`.

| Check | Command | Expected | Result (date: _____) |
|-------|---------|----------|----------------------|
| Resolution (Mac; use dscacheutil, not dig) | `dscacheutil -q host -a name mail.inlock.ai` | `100.83.222.69` | |
| Admin OK | `curl -sI https://mail.inlock.ai/admin/` | 200 or 302 (not 403) | |
| Off-tailnet / public IP | `curl -sI --resolve mail.inlock.ai:443:156.67.29.52 https://mail.inlock.ai/admin/` | 403 | |

### 10.5 Verify from non–Tailscale path (optional)

From a machine **not** on Tailscale (or with Tailscale off), or using public DNS:

```bash
curl -sI https://mail.inlock.ai/admin/
# Expected: HTTP/2 403
```

### 10.6 Rollback (Split DNS only)

1. Go to **https://login.tailscale.com/admin/dns**
2. Under **Split DNS**, remove the entries for `mail.inlock.ai` and (if added) `admin.inlock.ai`.
3. Save. Clients will again use public DNS for these domains.

### 10.7 Mac-only admin resolution (/etc/hosts) — current approach

Because `100.83.222.69` is not a DNS resolver, Split DNS was removed. On the Mac (Tailscale client), use a local hosts entry so `mail.inlock.ai` resolves to the Tailscale server IP. This affects **only that Mac**; public DNS and webmail access are unchanged. **Webmail remains public; admin access is Mac-only via `/etc/hosts`.**

**Add on the Mac (Mac-only /etc/hosts entry):**

```bash
sudo sh -c 'printf "\n# Mailcow admin via Tailscale (Mac-only)\n100.83.222.69 mail.inlock.ai\n" >> /etc/hosts'
```

Or edit `/etc/hosts` and add:

```
# Mailcow admin via Tailscale (Mac-only)
100.83.222.69 mail.inlock.ai
```

**Note:** `dig` bypasses `/etc/hosts` and queries DNS directly. To confirm the hosts mapping on macOS, use:

```bash
dscacheutil -q host -a name mail.inlock.ai
```

Expected: address(es) include `100.83.222.69`.

**Final verification results (2026-01-31 11:00 UTC):**

| Check | Command | Result |
|-------|---------|--------|
| Admin OK (Mac, uses /etc/hosts → Tailscale IP) | `curl -sI https://mail.inlock.ai/admin/` | **200** |
| Admin denied (public IP) | `curl -sI --resolve mail.inlock.ai:443:156.67.29.52 https://mail.inlock.ai/admin/` | **403** |

**Rollback (Mac-only):** Remove the hosts entry and flush the cache:

```bash
# Remove hosts entry
sudo sed -i '' '/mail.inlock.ai/d' /etc/hosts

# Flush DNS/cache so resolution reverts to public DNS
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

Or edit `/etc/hosts` and delete the line containing `mail.inlock.ai`, then run the flush commands above.

---

## 11. Related

- Mailcow deployment: `docs/deployment/MAILCOW-DEPLOYMENT.md`
- Mailcow port/Traefik: `docs/security/MAILCOW-PORT-8080.md`
- Traefik dynamic config: `traefik/dynamic/`
