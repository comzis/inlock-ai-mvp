# Block when adding email account on MacBook

If something appears to “block” (or inlock.ai / mail stops working) **when you add your inlock.ai email account on the MacBook**, the requests are usually going to mail-related hosts, not only the main site.

## What macOS Mail does when you add an account

When you add an account (e.g. `you@inlock.ai`), the Mail app typically tries:

- **autodiscover.inlock.ai** or **autoconfig.inlock.ai** (autodiscover/autoconfig)
- **mail.inlock.ai** (IMAP, SMTP, and sometimes HTTPS for the web UI)
- Sometimes **inlock.ai** (e.g. `https://inlock.ai/autodiscover/...`)

If any of these are **blocked or challenged** (e.g. by Cloudflare) for your MacBook IP (**31.10.147.220**), adding the account can fail or hang.

## Where the block can happen

1. **Cloudflare** – If **mail.inlock.ai**, **autodiscover.inlock.ai**, **autoconfig.inlock.ai** (and optionally **inlock.ai**) are behind Cloudflare proxy, Cloudflare can block or challenge your IP. Same as for the main site: allow **31.10.147.220** in Cloudflare (IP Access Rules or WAF).
2. **Traefik** – Your mail routes use only `secure-headers` (no IP allowlist), so Traefik is not blocking by IP.
3. **Mailcow** – Can have its own rate limits or fail2ban; less common for “add account” from one IP.

So the most likely place for a “block when adding email” is **Cloudflare** for those hostnames.

## Check logs on the server

From the **server** (where Traefik runs):

```bash
# Last 200 requests to mail + inlock.ai (see if your MacBook IP appears)
./scripts/check-mail-access-logs.sh

# Follow live while you add the account on the MacBook
./scripts/check-mail-access-logs.sh --follow
```

- If you **see** lines with **ClientHost: 31.10.147.220** when you try to add the account → the request reached Traefik; then check **DownstreamStatus** (e.g. 200, 403, 502) and Mailcow.
- If you **see no** lines (or no 31.10.147.220) when you add the account → the block is **before** Traefik (typically **Cloudflare**).

## Fix in Cloudflare

1. **Security** → **WAF** → **IP Access Rules** (or **Firewall rules**).
2. Ensure **31.10.147.220** is **Allow** (same as for inlock.ai).
3. If mail subdomains use Cloudflare proxy, that single allow rule applies to all of them (mail.inlock.ai, autodiscover.inlock.ai, inlock.ai, etc.).

You can also add the allow rule via script (if the token has Firewall permission):

```bash
./scripts/cloudflare-allow-ip.sh 31.10.147.220
```

## Quick checklist

- [ ] Allow **31.10.147.220** in Cloudflare (IP Access Rules or WAF).
- [ ] Run `./scripts/check-mail-access-logs.sh --follow` on the server and try adding the account; confirm whether 31.10.147.220 appears in the logs.
- [ ] If it appears but account still fails, check **DownstreamStatus** and Mailcow logs; if it doesn’t appear, the block is at Cloudflare.
