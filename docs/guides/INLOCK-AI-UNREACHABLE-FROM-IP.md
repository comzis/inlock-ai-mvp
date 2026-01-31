# inlock.ai unreachable from a specific IP (e.g. 31.10.147.220)

## Summary

If you **cannot reach inlock.ai** (or www.inlock.ai) when using a specific IP (e.g. your MacBook public IP **31.10.147.220**), the cause is almost certainly **Cloudflare**, not the server or Traefik.

- **inlock.ai** and **www.inlock.ai** use **Cloudflare proxy ON** (orange cloud).
- Traffic flow: **Your IP → Cloudflare → Origin (156.67.29.52)**.
- UFW on the server allows 80/443 from any IP. Traefik has **no IP allowlist** on the main site route (only `secure-headers`).
- So blocking happens **at Cloudflare** (WAF, firewall rules, security level, or challenge).

---

## What to check in Cloudflare

### 1. IP Access Rules (Firewall → Tools)

- **Dashboard** → **Security** → **WAF** → **Tools** (or **Firewall** → **Tools**).
- Check **IP Access Rules** (and **IP Access Rules** under Firewall Events).
- See if **31.10.147.220** (or a range containing it) is **Block**, **Challenge**, or **JS Challenge**.
- If it is blocked or challenged: **Edit** the rule to **Allow** that IP, or delete the rule if it was a mistake.

### 2. Security Level

- **Security** → **Settings** → **Security Level**.
- If set to **“I’m Under Attack”** or **“High”**, Cloudflare may show a challenge (e.g. JS or CAPTCHA) that can fail for some clients or IPs.
- For your own IP you can:
  - Temporarily set Security Level to **Medium** or **Low**, or
  - Add an **Allow** rule in WAF for **31.10.147.220** so it skips the challenge.

### 3. WAF custom rules

- **Security** → **WAF** → **Custom rules** (or **Firewall rules**).
- Look for any rule that:
  - Blocks or challenges by IP, ASN, or country.
  - Might match 31.10.147.220 (e.g. “Block IP” or “Challenge” with an expression that includes your IP or region).
- Add an **exception** for 31.10.147.220 (e.g. “Allow when IP is 31.10.147.220”) with higher priority, or disable/edit the blocking rule.

### 4. Firewall events (confirm it’s Cloudflare)

- **Security** → **Events** (or **Analytics** → **Security**).
- Filter by **Action**: Block, Challenge, etc.
- Filter by **IP** or **Client IP**: 31.10.147.220.
- If you see events for that IP, the rule name and action tell you what to change (allowlist or lower challenge).

### 5. Bot Fight Mode / Super Bot Fight Mode

- **Security** → **Bots** (or **Scrape Shield**).
- If **Bot Fight Mode** (or similar) is on, some traffic can be challenged or blocked.
- You can allowlist 31.10.147.220 via a WAF rule (“Allow” when `ip.src eq 31.10.147.220`) so your browser is not challenged.

---

## Quick allowlist for your IP in Cloudflare

### Option A: Via API (script)

From the repo root, with `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ZONE_ID` in `.env` (or exported):

```bash
# Allow default IP (31.10.147.220)
./scripts/cloudflare-allow-ip.sh

# Allow a specific IP
./scripts/cloudflare-allow-ip.sh 1.2.3.4

# List current zone IP access rules
./scripts/cloudflare-allow-ip.sh --list

# Remove allow rule for an IP
./scripts/cloudflare-allow-ip.sh --delete 31.10.147.220
```

The script uses the **IP Access Rules** API (zone-level). The token needs **Zone – Firewall – Edit** (or “Firewall Access Rules Write”) permission. Zone ID: Cloudflare Dashboard → inlock.ai → Overview → Zone ID (right column).

### Option B: Via dashboard

1. **Security** → **WAF** → **Custom rules** (or **Firewall** → **Firewall rules**).
2. **Create rule**:
   - **Name:** e.g. `Allow my IP (31.10.147.220)`
   - **Expression:** `(ip.src eq 31.10.147.220)`
   - **Action:** **Allow** (or **Skip** → skip all remaining custom rules / rate limiting if you prefer).
3. Set **priority** higher than any rule that blocks or challenges (e.g. put it near the top).
4. **Save**.

After that, traffic from 31.10.147.220 should reach inlock.ai unless another product (e.g. Rate limiting, DDoS) still applies.

---

## Check access logs (inlock.ai)

**On the server** (where Traefik runs):

```bash
# Last 100 requests to inlock.ai / www.inlock.ai (Traefik access log)
./scripts/check-inlock-ai-access-logs.sh

# More lines or follow live
./scripts/check-inlock-ai-access-logs.sh --lines 500
./scripts/check-inlock-ai-access-logs.sh --follow
```

If you see **no lines** when you try to access inlock.ai, the request is not reaching Traefik (e.g. blocked or challenged at Cloudflare). If you see lines with your client IP and status 200, the request reached the origin.

---

## Verify it’s Cloudflare, not the server

From a machine with a **different** IP (e.g. mobile data, another network):

- `curl -I https://inlock.ai`
- If that works but 31.10.147.220 doesn’t, the problem is per-IP (Cloudflare or path), not a global outage.

From the **server** (156.67.29.52) or via Tailscale:

- `curl -I https://inlock.ai -H "Host: inlock.ai"`
- If this returns 200, the origin and Traefik are fine; the issue is between the client IP and Cloudflare.

---

## Recap

| Layer        | inlock.ai / www.inlock.ai | 31.10.147.220 |
|-------------|----------------------------|----------------|
| UFW         | 80/443 allowed from any    | ✅ Not blocked |
| Traefik     | No IP allowlist on main site | ✅ Not blocked |
| Cloudflare  | Proxy ON                    | ⚠️ Check WAF, Security Level, IP Access Rules, Firewall events |

**Most likely:** 31.10.147.220 is blocked or challenged by a **Cloudflare** firewall rule, security level, or bot setting. Check **Security → WAF / Firewall / Events** and allow or skip challenges for that IP.
