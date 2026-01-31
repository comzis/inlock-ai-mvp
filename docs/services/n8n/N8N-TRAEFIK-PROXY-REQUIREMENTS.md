# n8n Behind Traefik — Proxy Requirements

**Purpose:** Required configuration so https://n8n.inlock.ai loads correctly behind Traefik. If these are changed, n8n can show a blank page, "Cannot GET /", or 429 on assets.

**Last updated:** 2026-01-31

---

## 1. n8n environment variables (compose)

**File:** `compose/services/n8n.yml`

n8n must know its **public** host and protocol when behind a reverse proxy. Without this, the backend may not serve the editor at `/` or may generate wrong asset/API URLs.

| Variable | Required value | Why |
|----------|----------------|-----|
| `N8N_EDITOR_BASE_URL` | `https://n8n.${DOMAIN}` | Public URL for the editor (emails, redirects). |
| `WEBHOOK_URL` | `https://n8n.${DOMAIN}` | Public base URL for webhooks. |
| `N8N_HOST` | `n8n.${DOMAIN}` | **Required.** Host n8n considers itself to be served on; must match the request `Host` header or n8n returns "Cannot GET /". |
| `N8N_PROTOCOL` | `https` | **Required.** Protocol n8n is reached over; needed for correct URLs. |
| `N8N_PROXY_HOPS` | `1` | Tells n8n to trust one reverse proxy. |
| `N8N_TRUSTED_PROXIES` | `loopback,linklocal,uniquelocal,172.18.0.0/16,172.20.0.0/16` | Trusted proxy IPs so n8n uses `X-Forwarded-*` headers. |

**Do not remove** `N8N_HOST` or `N8N_PROTOCOL`; removing them can bring back "Cannot GET /" or a blank page.

---

## 2. Traefik middleware: Host and X-Forwarded-Host

**File:** `traefik/dynamic/middlewares.yml` — section `n8n-headers`

Traefik must send the **public hostname** to n8n. By default, the backend may receive `Host: n8n` (Docker service name). n8n only serves the editor when the request host matches `N8N_HOST` (e.g. `n8n.inlock.ai`), so a wrong Host leads to "Cannot GET /".

**Required in `n8n-headers` `customRequestHeaders`:**

- `X-Forwarded-Proto: "https"`
- `X-Forwarded-Host: "n8n.inlock.ai"`
- `Host: "n8n.inlock.ai"`

**Do not** remove `Host` or `X-Forwarded-Host` from the n8n-headers middleware. If you add another proxy in front, keep the host aligned with the public URL (e.g. `n8n.inlock.ai`).

---

## 3. Rate limit: use n8n-ratelimit, not mgmt-ratelimit

**Files:**  
- `traefik/dynamic/middlewares.yml` — define `n8n-ratelimit`  
- `traefik/dynamic/routers.yml` — n8n router must use `n8n-ratelimit`

The n8n UI is a single-page app that loads **many JS assets in parallel** (30+ requests) on first load. The shared `mgmt-ratelimit` (50 req/s average, 100 burst) is too low and causes **429 Too Many Requests** for most assets, so the page stays blank.

**Required:**

1. **Middleware** `n8n-ratelimit` with higher limits, e.g.:
   - `average: 200`
   - `burst: 400`

2. **Router** for `Host(\`n8n.inlock.ai\`)` must use **`n8n-ratelimit`**, not `mgmt-ratelimit`.

**Do not** put `mgmt-ratelimit` on the n8n router. If you need to tighten limits, increase them only in `n8n-ratelimit` so the initial SPA load still succeeds.

---

## 4. Router summary

**File:** `traefik/dynamic/routers.yml`

The n8n router should look like this (middleware order matters):

```yaml
n8n:
  entryPoints:
    - websecure
  rule: Host(`n8n.inlock.ai`)
  middlewares:
    - n8n-headers      # Host + X-Forwarded-Host + proto
    - admin-forward-auth
    - n8n-ratelimit    # NOT mgmt-ratelimit
  service: n8n
  tls:
    certResolver: le-dns
```

---

## 5. Checklist when changing Traefik or n8n

- [ ] `compose/services/n8n.yml`: `N8N_HOST`, `N8N_PROTOCOL`, `N8N_EDITOR_BASE_URL`, `WEBHOOK_URL`, `N8N_PROXY_HOPS`, `N8N_TRUSTED_PROXIES` are set as above.
- [ ] `traefik/dynamic/middlewares.yml`: `n8n-headers` includes `Host: "n8n.inlock.ai"` and `X-Forwarded-Host: "n8n.inlock.ai"`.
- [ ] `traefik/dynamic/middlewares.yml`: `n8n-ratelimit` exists with higher limits (e.g. average 200, burst 400).
- [ ] `traefik/dynamic/routers.yml`: n8n router uses `n8n-ratelimit`, not `mgmt-ratelimit`.

After any change, reload Traefik and hard-refresh https://n8n.inlock.ai (Ctrl+Shift+R). If the page is blank or shows "Cannot GET /", check the browser Network tab for 429s or wrong Host.

---

## 6. Related docs

- `docs/services/n8n/N8N-BLANK-PAGE-ROOT-CAUSE.md` — other causes of blank page (API, setup).
- `docs/guides/N8N-COMPLETE-FIX.md` — encryption, DB, cache.
- `docs/security/INGRESS-HARDENING.md` — general Traefik/admin hardening.
