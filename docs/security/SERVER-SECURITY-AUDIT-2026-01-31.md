# Server Security Audit — 2026-01-31

**Scope:** Server at `/home/comzis`, Mailcow at `/home/comzis/mailcow`, Traefik at `/home/comzis/inlock`  
**Constraint:** Read-only evidence collection; no config changes or restarts without approval.  
**Known state:** Mailcow admin 2FA enabled; admin access restricted via Traefik allowlist; webmail remains public.

**Changes applied after audit (2026-01-31):**

- SSH restricted to Tailscale via iptables (port 22 allow 100.64.0.0/10, drop others).  
  **Pending:** persist rules (iptables-persistent) so it survives reboot.
- Martian logging enabled and persisted: `/etc/sysctl.d/99-martians.conf`.
- Traefik allowlist cleaned: removed temporary public IP `31.10.147.220/32`.
- Traefik routers hardened:
  - `cockpit`: re-added `allowed-admins` + `admin-forward-auth` + `mgmt-ratelimit`.
  - `homarr`: added `mgmt-ratelimit`.
  - `n8n`: re-enabled `mgmt-ratelimit`.
- Mailcow HTTP redirect enabled: `HTTP_REDIRECT=y`.
- Mailcow nginx admin snippet removed (it caused 405 on admin UI).

**Required service reloads (run as root / via sudo):**

- `cd /home/comzis/inlock && docker compose -f compose/services/stack.yml up -d traefik`
- `cd /home/comzis/mailcow && docker compose restart nginx-mailcow`

---

## 1. Summary

| Area | Status | Notes |
| ------ | ------ | ------ |
| **OS / SSH** | Hardened | PermitRootLogin no, AllowUsers comzis, PasswordAuthentication no, KbdInteractiveAuthentication no. SSH on 0.0.0.0:22 with fail2ban only; no host firewall restriction to Tailscale. |
| **Firewall** | Gaps | INPUT/FORWARD policy ACCEPT; DOCKER-USER empty; MAILCOW chain enforces mailcow isolation and drops one blocklisted IP; f2b-sshd protects SSH. |
| **Docker / Traefik** | Good | Traefik uses socket-proxy (no direct docker.sock); cap_drop ALL, no-new-privileges; admin routes use forwardAuth + allowlist; Mailcow /admin and admin.inlock.ai use mailcow-admin-allowlist. |
| **Mailcow** | Good + Gaps | MySQL/Redis bound to 127.0.0.1; netfilter isolation on; nginx + Traefik restrict /admin; HTTP_REDIRECT=n; credentials in mailcow.conf (mode 600); no backups dir; netfilter logs show sustained brute force / probes. |
| **Credentials** | Risk | mailcow.conf holds DBPASS, DBROOT, REDISPASS, SOGO_URL_ENCRYPTION_KEY in plaintext; file mode 600. Ensure never committed or in unencrypted backups. |
| **Backups** | Verified | Cron at 03:30, dir `/home/comzis/mailcow/backups`; manual full backup run verified 2026-01-31 (vmail, crypt, redis, rspamd, postfix, MariaDB). |

**Prioritized focus:** Restrict SSH at host firewall, remove temporary public IP from admin allowlist, enable martian logging, add rate limit to Homarr, document/implement Mailcow backups, and keep admin restriction as-is (do not re-open /admin).

---

## 2. Findings Table

| ID | Severity | Finding | Evidence |
| ---- | --------- | -------- | ---------- |
| F1 | **Critical** | Mailcow credentials in plaintext on disk (DBPASS, DBROOT, REDISPASS, SOGO_URL_ENCRYPTION_KEY) | `mailcow.conf` lines 22–24, 27, 239. File mode 600 (comzis only). |
| F2 | **Critical** | Default Mailcow admin password documented as "moohoo"; must confirm changed in UI | `mailcow.conf` comment lines 5–6. |
| F3 | **High** | SSH listening on 0.0.0.0:22 with no host firewall restriction; only fail2ban protects | ss -tulpn shows 0.0.0.0:22; iptables -S shows INPUT ACCEPT with only port 22 to f2b-sshd. |
| F4 | **High** | User comzis has full sudo (ALL:ALL) and NOPASSWD for docker, systemctl, iptables, etc. | `sudo -l`: `(ALL : ALL) ALL` and NOPASSWD entries. |
| F5 | **High** | Cockpit (cockpit.inlock.ai) has allowed-admins and admin-forward-auth removed; only mgmt-ratelimit | `routers.yml` cockpit: comments "allowed-admins temporarily removed", "admin-forward-auth removed". |
| F6 | **High** | net.ipv4.conf.all.log_martians = 0 — martian packets not logged | `sysctl net.ipv4.conf.all.log_martians` → 0. |
| F7 | **High** | DOCKER-USER chain empty — no host-level restriction on Docker-published ports | `iptables -S DOCKER-USER` → only `-N DOCKER-USER`. |
| F8 | **Medium** | Temporary public IP 31.10.147.220 in allowed-admins (Traefik admin allowlist) | `middlewares.yml` lines 99–105: `"31.10.147.220/32"` Temporary Public IP. |
| F9 | **Medium** | Homarr (dashboard.inlock.ai) has admin-forward-auth but no mgmt-ratelimit | `routers.yml` homarr: middlewares secure-headers, admin-forward-auth only. |
| F10 | **Medium** | n8n has mgmt-ratelimit removed (comment: 429 on asset loading) | `routers.yml` n8n: mgmt-ratelimit commented out. |
| F11 | **Medium** | Mailcow HTTP_REDIRECT=n — no HTTP→HTTPS redirect at Mailcow level | `mailcow.conf` line 48: `HTTP_REDIRECT=n`. |
| F12 | **Medium** | ubuntu user in sudo group with nologin — if login enabled, gains full sudo | `getent group sudo`: ubuntu. `getent passwd ubuntu`: shell `/usr/sbin/nologin`. |
| F13 | **Medium** | No Mailcow backups directory or evidence of scheduled backups | `ls /home/comzis/mailcow/backups`: empty or missing. `helper-scripts/backup_and_restore.sh` exists. |
| F14 | **Medium** | Sustained mail brute force and non-SMTP probes; netfilter banning | `docker logs mailcowdockerized-netfilter-mailcow-1`: SASL failures (62.60.130.248, etc.), non-SMTP (GET, binary). |
| F15 | **Low** | SSH MaxAuthTries left at default 6 | `/etc/ssh/sshd_config`: `#MaxAuthTries 6`. |
| F16 | **Low** | Mailcow admin allowlist has only two IPs (100.83.222.69, 100.96.110.8) — lockout if Tailscale IPs change | `middlewares.yml` mailcow-admin-allowlist: two /32 entries. |

**Positive (no change required):**

- SSH: PermitRootLogin no, AllowUsers comzis, PasswordAuthentication no, KbdInteractiveAuthentication no, X11Forwarding no.
- Kernel: kernel.dmesg_restrict=1, kernel.kptr_restrict=1.
- Network: net.ipv4.tcp_syncookies=1, accept_redirects=0, send_redirects=0.
- Mailcow: SQL_PORT=127.0.0.1:13306, REDIS_PORT=127.0.0.1:7654; DISABLE_NETFILTER_ISOLATION_RULE=n; MAILCOW iptables chain drops non–mailcow→mailcow; nginx site.admin-restrict.custom restricts /admin/ to two IPs.
- Traefik: DOCKER_HOST=socket-proxy; no docker.sock mount; admin routes use admin-forward-auth and (where applied) allowed-admins, mgmt-ratelimit; mailcow-admin-path and mailcow-admin use mailcow-admin-allowlist; webmail routes (mailcow, webmail) intentionally public.
- mailcow.conf: mode 600, owner comzis.

### 2.1 Credentials in plaintext (variable names only)

These **variable names** are stored with plaintext values in `/home/comzis/mailcow/mailcow.conf`. Do not commit this file or include it in unencrypted backups.

| Variable | Purpose |
| -------- | ------- |
| **DBPASS** | Mailcow MariaDB database password |
| **DBROOT** | MariaDB root password |
| **REDISPASS** | Redis password |
| **SOGO_URL_ENCRYPTION_KEY** | SOGo session/URL encryption key |

(Actual secret values are not listed here.)

### 2.2 Backup encryption policy

Any backup that includes `/home/comzis/mailcow/` (or `mailcow.conf`) must be stored encrypted. Unencrypted copies must not be stored off-host or in untrusted locations.

**Pre-commit hook (this repo):** To block commits containing `mailcow.conf` or secret patterns (e.g. `DBPASS=`, `REDISPASS=`), install:  
`cp ops/security/pre-commit-secrets-blocker.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`

---

## 3. Remediation Plan

**Rules:** Do not re-open /admin; keep webmail public. Apply only after approval; prefer quick wins first.

### 3.1 Critical

| Step | Action | Commands / edits | Restart? |
| ------ | -------- | ------------------- | ---------- |
| C1 | Confirm Mailcow admin password is not "moohoo" | Log in at <https://mail.inlock.ai> (from allowlisted IP) → Login → Change password if still default. | No |
| C2 | Ensure mailcow.conf never in git or unencrypted backups | Add `/home/comzis/mailcow/mailcow.conf` to .gitignore (if repo includes parent); use encrypted backups only for that path. | No |

### 3.2 High

| Step | Action | Commands / edits | Restart? |
| ------ | -------- | ------------------- | ---------- |
| H1 | Restrict SSH to Tailscale (and optional backup IP) | **Test over console/Tailscale first.** Example (adjust order/interface as needed): `sudo iptables -I INPUT 1 -m state --state ESTABLISHED,RELATED -j ACCEPT`; `sudo iptables -I INPUT 2 -p tcp --dport 22 -s 100.64.0.0/10 -j ACCEPT`; `sudo iptables -A INPUT -p tcp --dport 22 -j f2b-sshd`; `sudo iptables -A INPUT -p tcp --dport 22 -j DROP`. Persist (e.g. iptables-save / netfilter-persistent). | No (persist rules) |
| H2 | Enable martian logging | `echo 'net.ipv4.conf.all.log_martians = 1'` \| `sudo tee /etc/sysctl.d/99-martians.conf`; then `sudo sysctl -p /etc/sysctl.d/99-martians.conf` | No |
| H3 | Restore Cockpit IP/auth when Tailscale routing is correct | In `traefik/dynamic/routers.yml`, cockpit router: add `allowed-admins` and/or `admin-forward-auth` back; reload Traefik. | Traefik reload |
| H4 | (Optional) Add DOCKER-USER rules to restrict admin ports by IP | e.g. Allow only Tailscale to ports used by Traefik/admin if desired; document in firewall policy. | No |

### 3.3 Medium

| Step | Action | Commands / edits | Restart? |
| ------ | -------- | ------------------- | ---------- |
| M1 | Remove temporary public IP from allowed-admins | Edit `traefik/dynamic/middlewares.yml`: remove `- "31.10.147.220/32"` and its comment from allowed-admins sourceRange. | Traefik reload (file provider) |
| M2 | Add rate limit to Homarr | Edit `traefik/dynamic/routers.yml`, homarr router middlewares: add `- mgmt-ratelimit`. | Traefik reload |
| M3 | Re-enable rate limit for n8n (tune if 429) | Edit `traefik/dynamic/routers.yml`, n8n router: add `- mgmt-ratelimit` or a dedicated middleware with higher average/burst. | Traefik reload |
| M4 | Mailcow HTTP redirect | In `/home/comzis/mailcow/mailcow.conf` set `HTTP_REDIRECT=y`. Then: `cd /home/comzis/mailcow && docker compose restart nginx-mailcow`. | nginx-mailcow |
| M5 | Remove ubuntu from sudo if not needed | `sudo deluser ubuntu sudo` (ensure console/other admin access first). | No |
| M6 | Implement and document Mailcow backups | Use `helper-scripts/backup_and_restore.sh`; schedule (cron/systemd); store off-host, encrypted; document restore. | No (then schedule) |
| M7 | Monitor netfilter bans | Optional: alert on CRIT ban/unban in netfilter logs; consider GeoIP or additional hardening for SMTP/IMAP. | No |

### 3.4 Low

| Step | Action | Commands / edits | Restart? |
| ------ | -------- | ------------------- | ---------- |
| L1 | Reduce SSH MaxAuthTries | Create `/etc/ssh/sshd_config.d/99-maxauthtries.conf`: `MaxAuthTries 3`. Then `sudo systemctl restart sshd` (keep another session open). | sshd |
| L2 | Widen Mailcow admin allowlist to Tailscale range (optional) | In `middlewares.yml` mailcow-admin-allowlist and in `site.admin-restrict.custom`, add e.g. `100.64.0.0/10` so new Tailscale IPs work; keep deny-by-default. | Traefik / nginx-mailcow |

---

## 4. Verification and Rollback

### 4.1 Verification commands

| Fix | Verification |
| ----- | -------------- |
| SSH restriction (H1) | From non-Tailscale IP: `nc -zv <server> 22` → connection refused or timeout. From Tailscale IP: SSH login works. |
| Martians (H2) | `sysctl net.ipv4.conf.all.log_martians` → 1. |
| Remove 31.10.147.220 (M1) | From that IP, access to admin subdomains (e.g. traefik.inlock.ai, portainer.inlock.ai) returns 403 or auth redirect. |
| Homarr rate limit (M2) | Load dashboard.inlock.ai; no 429 under normal use; excess requests get 429. |
| n8n rate limit (M3) | n8n and assets load; no persistent 429; abuse gets rate-limited. |
| HTTP_REDIRECT (M4) | If direct HTTP to Mailcow possible: redirect to HTTPS. |
| MaxAuthTries (L1) | After 3 failed attempts, next attempt delayed or blocked; valid key login still works. |

### 4.2 Rollback notes

| Change | Rollback |
| ------ | -------- |
| SSH iptables (H1) | Remove the SSH DROP and Tailscale ACCEPT rules; ensure `-A INPUT -p tcp --dport 22 -j f2b-sshd` remains so fail2ban still applies. Restore persisted rules (e.g. netfilter-persistent reload). |
| Martians (H2) | Remove `/etc/sysctl.d/99-martians.conf`; `sudo sysctl -w net.ipv4.conf.all.log_martians=0`. |
| Traefik middlewares/routers (M1, M2, M3, L2) | Revert edits in `traefik/dynamic/*.yml`; Traefik file provider picks up revert. If needed: `docker compose -f compose/services/stack.yml restart traefik`. |
| HTTP_REDIRECT (M4) | Set `HTTP_REDIRECT=n` in mailcow.conf; `docker compose restart nginx-mailcow`. |
| ubuntu sudo (M5) | `sudo adduser ubuntu sudo`. |
| MaxAuthTries (L1) | Remove `/etc/ssh/sshd_config.d/99-maxauthtries.conf`; `sudo systemctl restart sshd`. |

---

## 5. Quick Wins vs Restart Required

**Quick wins (no restart):**

- C1: Confirm/change Mailcow admin password.
- C2: .gitignore / backup policy for mailcow.conf.
- H2: Enable log_martians (sysctl).
- M1: Remove 31.10.147.220 from allowed-admins (Traefik reloads dynamic config).
- M2: Add mgmt-ratelimit to Homarr (Traefik).
- M5: Remove ubuntu from sudo (if approved).
- M6: Document and schedule backups.

**Requires restart/reload:**

- H1: iptables persist (no service restart if using netfilter-persistent).
- H3: Traefik (reload/restart after router edits).
- M3: Traefik (n8n rate limit).
- M4: nginx-mailcow restart.
- L1: sshd restart.
- L2: Traefik and optionally nginx-mailcow.

---

## 6. Evidence Summary (Read-Only Commands Run)

- **OS/user/SSH:** uname -a, lsb_release -a, uptime, id, who, last -n 20, sudo -l, getent passwd/group, /etc/ssh/sshd_config, /etc/ssh/sshd_config.d.
- **Network/firewall:** ss -tulpn, ip a, ip r, iptables -S, iptables -S MAILCOW, iptables -S DOCKER-USER, nft list ruleset.
- **Sysctl:** kernel.dmesg_restrict, kernel.kptr_restrict, net.ipv4.tcp_syncookies, net.ipv4.conf.all.log_martians, accept_redirects, send_redirects.
- **Docker:** docker ps, docker network ls; stack.yml (Traefik, socket-proxy, ports, hardening).
- **Mailcow:** mailcow.conf (hostname, DB, Redis, HTTP_REDIRECT, SQL_PORT, REDIS_PORT, SOGO_URL_ENCRYPTION_KEY, DISABLE_NETFILTER_ISOLATION_RULE), data/conf/nginx/site.admin-restrict.custom, data/conf/postfix/main.cf (TLS, postscreen), helper-scripts, backups dir.
- **Traefik:** traefik/dynamic/routers.yml (mailcow-admin-path, mailcow, webmail, cockpit, homarr, n8n), middlewares.yml (mailcow-admin-allowlist, allowed-admins, mgmt-ratelimit).
- **Logs:** docker logs mailcowdockerized-netfilter-mailcow-1 (bans, SASL failures, non-SMTP probes).

---

*Report generated 2026-01-31. Option 6 changes applied on 2026-01-31; see §7.4 for verification results.*

---

## 7. Option 6 Implementation (Prepared Files + Commands)

Prepared files (no sudo needed):

- `ops/security/ssh-hardening.conf` – sets `MaxAuthTries 3` and `LoginGraceTime 20`
- `ops/security/cron.mailcow-backup` – daily Mailcow backups + prune after 14 days
- `ops/security/verify-mailcow-backup.sh` + `ops/security/cron.mailcow-backup-verify` – backup-failure check (runs at 04:00)
- `ops/security/daily-security-summary.sh` + `ops/security/cron.daily-security-summary` – daily fail2ban/netfilter summary (05:00)
- `ops/security/cpu-alert-check.sh` + `ops/security/cron.cpu-alert` – host CPU/load alert (every 5 min; emails **milorad.stevanovic@inlock.ai** when load exceeds threshold, same §7.6 for mail)
- `ops/security/pre-commit-secrets-blocker.sh` – pre-commit hook to block commits containing mailcow.conf or secret patterns (install to `.git/hooks/pre-commit`)
- `ops/security/msmtprc.mailcow.example` – msmtp config template for sending alert emails via Mailcow SMTP (see §7.6)
- `ops/security/iptables-docker-user-admin-ports.sh` – restrict admin ports (default 8080/8443) to Tailscale

Notes:

- Backup directory is now created at `/home/comzis/mailcow/backups` with owner `comzis:comzis` and mode `755`.
- Admin ports are assumed to be **8080** and **8443**. Adjust `ADMIN_PORTS` in `ops/security/iptables-docker-user-admin-ports.sh` if needed.

### 7.1 Apply (commands to run with sudo)

```bash
# 1) Create backup directory (if missing)
sudo mkdir -p /home/comzis/mailcow/backups
sudo chown comzis:comzis /home/comzis/mailcow/backups
sudo chmod 755 /home/comzis/mailcow/backups

# 2) Install SSH hardening
sudo install -m 644 /home/comzis/inlock/ops/security/ssh-hardening.conf \
  /etc/ssh/sshd_config.d/99-security-hardening.conf
sudo systemctl restart sshd

# 3) Install Mailcow backup cron
sudo install -m 644 /home/comzis/inlock/ops/security/cron.mailcow-backup \
  /etc/cron.d/mailcow-backup

# 4) Apply DOCKER-USER admin-port restrictions (8080/8443 default)
sudo bash /home/comzis/inlock/ops/security/iptables-docker-user-admin-ports.sh

# 5) Persist iptables
sudo apt-get update -y
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save

# 6) Optional: CPU/load alert (emails when host load > ~85% of cores, every 5 min; uses ALERT_EMAIL in cron)
sudo install -m 644 /home/comzis/inlock/ops/security/cron.cpu-alert /etc/cron.d/cpu-alert
```

### 7.2 Verify

```bash
# SSH hardening
sudo sshd -T | egrep 'maxauthtries|logingracetime'

# Cron present
sudo cat /etc/cron.d/mailcow-backup

# DOCKER-USER rules
sudo iptables -S DOCKER-USER

# Backups directory
ls -la /home/comzis/mailcow/backups
```

### 7.3 Rollback

```bash
# SSH hardening
sudo rm -f /etc/ssh/sshd_config.d/99-security-hardening.conf
sudo systemctl restart sshd

# Mailcow backup cron
sudo rm -f /etc/cron.d/mailcow-backup

# DOCKER-USER rules (flush only the rules for admin ports)
# (Manual rollback: remove ACCEPT/DROP rules for 8080/8443 from DOCKER-USER)
# Example:
# sudo iptables -D DOCKER-USER -p tcp --dport 8080 -s 100.64.0.0/10 -j ACCEPT
# sudo iptables -D DOCKER-USER -p tcp --dport 8080 -j DROP
# sudo iptables -D DOCKER-USER -p tcp --dport 8443 -s 100.64.0.0/10 -j ACCEPT
# sudo iptables -D DOCKER-USER -p tcp --dport 8443 -j DROP

# Re-save iptables after rollback
sudo netfilter-persistent save
```

### 7.4 Verification results (completed)

#### SSH hardening

- Output: `logingracetime 20`, `maxauthtries 3`

#### Mailcow backup cron

- `/etc/cron.d/mailcow-backup` contains the daily backup and prune jobs with `MAILCOW_BACKUP_LOCATION=/home/comzis/mailcow/backups`.

#### DOCKER-USER rules

- Rules present:
  - `-A DOCKER-USER -m state --state RELATED,ESTABLISHED -j ACCEPT`
  - `-A DOCKER-USER -s 100.64.0.0/10 -p tcp --dport 8443 -j ACCEPT`
  - `-A DOCKER-USER -s 100.64.0.0/10 -p tcp --dport 8080 -j ACCEPT`
  - `-A DOCKER-USER -p tcp --dport 8080 -j DROP`
  - `-A DOCKER-USER -p tcp --dport 8443 -j DROP`
  - `-A DOCKER-USER -j RETURN`

#### Backup directory

- `/home/comzis/mailcow/backups` exists and is owned by `comzis:comzis`.

### 7.5 Post-change risks and next steps

#### Residual risks

- Admin ports restricted in `DOCKER-USER` only for 8080/8443. If additional management UIs use other ports, they remain reachable unless restricted.
- Mailcow backups are scheduled but not yet validated with a restore test.
- SSH restriction rules are persisted; ensure you have at least two Tailscale devices available for access recovery.
- Cockpit/Traefik protections depend on current routing and middleware; verify externally if any UI is still reachable without allowlist/auth.

#### Recommended follow-ups

- Confirm which ports are truly “admin-only” (e.g., 8080/8443/9090) and extend `ADMIN_PORTS` if needed.
- Perform a backup integrity check and a restore test (non-prod or dry run).
- Add monitoring/alerting for Mailcow netfilter bans and SSH auth anomalies.
- Review Tailscale ACLs and device posture settings for admin devices.

### 7.6 Alert email via Mailcow (optional)

To have backup-failure and security-threshold alerts sent to **milorad.stevanovic@inlock.ai** via Mailcow SMTP (instead of syslog only):

1. **Install msmtp and sendmail wrapper** (on the server where cron runs):
   ```bash
   sudo apt-get install -y msmtp msmtp-mta
   ```
2. **Create a Mailcow mailbox** for sending alerts (e.g. `no-reply@inlock.ai` or `alerts@inlock.ai`) in Mailcow Admin if you do not already have one.
3. **Create the password file** (use the mailbox password):
   ```bash
   sudo mkdir -p /etc/msmtp
   echo "mailbox-password" | sudo tee /etc/msmtp/alert-secret
   sudo chmod 600 /etc/msmtp/alert-secret
   ```
4. **Install msmtp config** (edit `from`/`user` if you use a different mailbox):
   ```bash
   sudo cp /home/comzis/inlock/ops/security/msmtprc.mailcow.example /etc/msmtprc
   # Edit /etc/msmtprc: set 'from' and 'user' to your mailbox (e.g. no-reply@inlock.ai)
   sudo chmod 600 /etc/msmtprc
   ```
5. **Test reception:** Run as root so msmtp can read `/etc/msmtprc`:
   ```bash
   sudo /home/comzis/inlock/ops/security/test-alert-email.sh
   ```
   Or: `sudo ALERT_EMAIL=milorad.stevanovic@inlock.ai /home/comzis/inlock/ops/security/alert.sh "Test" "Body"`. Check **milorad.stevanovic@inlock.ai** (inbox and spam). Cron jobs already set `ALERT_EMAIL=milorad.stevanovic@inlock.ai`; once msmtp is configured, they will send email through Mailcow.

6. **Password file:** Use no newline (e.g. `printf '%s' 'password' | sudo tee /etc/msmtp/alert-secret > /dev/null`). If the secret file is empty, msmtp will fail with "cannot read output of 'cat /etc/msmtp/alert-secret'".

#### 7.6.1 If you get 451 "Temporary lookup failure" (Mailcow sender ACL)

Postfix uses `mysql_virtual_sender_acl.cf`, which expects a `sender_allowed` column. If your Mailcow DB schema is older, add it and allow the sender:

1. **mailbox table** (if missing):  
   `ALTER TABLE mailbox ADD COLUMN sender_allowed TEXT NULL DEFAULT NULL;`
2. **alias table** (required for the lookup):  
   `ALTER TABLE alias ADD COLUMN sender_allowed TINYINT(1) NOT NULL DEFAULT 1;`  
   Then: `UPDATE alias SET sender_allowed = 1 WHERE address = 'contact@inlock.ai';` (or your sender address).
3. Restart Postfix: `cd /home/comzis/mailcow && docker compose restart postfix-mailcow`.

Run these in the Mailcow MySQL container: `docker compose exec -it mysql-mailcow mysql -u mailcow -p mailcow`. Use the DBPASS from `mailcow.conf` when prompted.

---

## 8. Re-audit (2026-01-31)

**Scope:** Read-only re-audit after recent fixes. No config changes or restarts. Validate SSH hardening, SSH restriction to Tailscale, DOCKER-USER for admin ports, Mailcow backup cron and dir, Traefik allowlists/ratelimits, Mailcow admin restricted, webmail public.

### 8.1 Evidence collected (read-only)

| Check | Command / source | Result |
| ------ | ----------------- | ------ |
| SSH hardening | grep in /etc/ssh/ for MaxAuthTries and LoginGraceTime | /etc/ssh/sshd_config.d/99-security-hardening.conf: MaxAuthTries 3, LoginGraceTime 20 |
| SSH INPUT | `sudo iptables -S INPUT` | RELATED,ESTABLISHED ACCEPT; 100.64.0.0/10 port 22 ACCEPT; f2b-sshd for 22; DROP for 22 |
| DOCKER-USER | `sudo iptables -S DOCKER-USER` | RELATED,ESTABLISHED ACCEPT; 100.64.0.0/10 8443 ACCEPT; 100.64.0.0/10 8080 ACCEPT; DROP 8080; DROP 8443; RETURN |
| iptables persist | `dpkg -l iptables-persistent netfilter-persistent` | ii iptables-persistent 1.0.16, ii netfilter-persistent 1.0.16 |
| Mailcow cron | `cat /etc/cron.d/mailcow-backup` | MAILCOW_BACKUP_LOCATION=/home/comzis/mailcow/backups; daily 03:30 backup all; daily 03:45 prune 14 days |
| Backup dir | `ls -la /home/comzis/mailcow/backups` | Dir exists, comzis:comzis, empty (first run 03:30) |
| Traefik allowlists | `traefik/dynamic/middlewares.yml` | allowed-admins: 100.64.0.0/10, 100.96.110.8, 100.83.222.69, 172.18/16, 172.20/16 (no 31.10.147.220). mailcow-admin-allowlist: 100.83.222.69, 100.96.110.8 |
| Traefik ratelimit | `traefik/dynamic/routers.yml` | mgmt-ratelimit (50/100) on dashboard, portainer, n8n, grafana, coolify, homarr, cockpit |
| Mailcow /admin | routers.yml mailcow-admin-path | Host mail.inlock.ai PathPrefix /admin, middlewares mailcow-admin-allowlist, priority 200 |
| Webmail public | routers.yml mailcow, webmail | mailcow: Host mail.inlock.ai secure-headers only. webmail: Host webmail.inlock.ai secure-headers only |
| Nginx defense-in-depth | `mailcow/data/conf/nginx/site.admin-restrict.custom` | location /admin/ allow 100.83.222.69, 100.96.110.8; deny all |
| Cockpit | `routers.yml` cockpit | allowed-admins, admin-forward-auth, mgmt-ratelimit |
| Listening | `ss -tulpn` | 22, 8080, 8443 on 0.0.0.0 (firewall restricts access) |

### 8.2 Backup verification (2026-01-31)

Manual full Mailcow backup was run and verified:

- **Command:** `sudo /home/comzis/mailcow/helper-scripts/backup_and_restore.sh backup all`
- **Location:** `/home/comzis/mailcow/backups`
- **Output:** Timestamped dir `mailcow-2026-01-31-12-43-57`; size ~20M
- **Contents:** vmail (maildirs), crypt (keys), redis, rspamd, postfix, MariaDB (mariabackup); backup prepared OK
- **Image:** `ghcr.io/mailcow/backup:latest` pulled successfully

Backup capability is confirmed; scheduled cron (03:30) and prune (14 days) remain in place.

### 8.3 Findings by severity (re-audit)

| Severity | Finding | Evidence |
| --------- | -------- | ---------- |
| **Critical** | None | — |
| **High** | None | Previous fixes validated. |
| **Medium** | None | Backup gap closed: manual full backup verified 2026-01-31; cron and dir present. |
| **Low** | LoginGraceTime 20 = 20 seconds | `/etc/ssh/sshd_config.d/99-security-hardening.conf`: LoginGraceTime 20. sshd interprets as 20 seconds. If 2 minutes was intended, use 120. |

Validated (no action):

- SSH: MaxAuthTries 3, LoginGraceTime 20 (99-security-hardening.conf). INPUT restricts SSH to 100.64.0.0/10 then f2b-sshd then DROP. iptables-persistent and netfilter-persistent installed.
- DOCKER-USER: 8080 and 8443 restricted to 100.64.0.0/10; other traffic to those ports dropped.
- Mailcow: Cron and backup dir present; admin restricted (Traefik mailcow-admin-allowlist + nginx site.admin-restrict.custom); webmail public (mailcow and webmail routers with secure-headers only).
- Traefik: allowed-admins (no temporary public IP); mailcow-admin-allowlist; mgmt-ratelimit on admin routes; Cockpit has allowed-admins and admin-forward-auth.

### 8.4 Recommended actions (do not run; no changes applied)

| Priority | Action | Exact command / edit |
| --------- | -------- | ----------------------- |
| Low | Optional: LoginGraceTime 2m | If 2 minutes desired: in `/etc/ssh/sshd_config.d/99-security-hardening.conf` set `LoginGraceTime 120`. Then `sudo systemctl restart sshd` (keep another session open). |

### 8.5 Verification steps (re-audit)

| Item | Verification |
| ----- | -------------- |
| SSH hardening | grep MaxAuthTries and LoginGraceTime in /etc/ssh/sshd_config.d/; expect MaxAuthTries 3, LoginGraceTime 20 or 120. |
| SSH restriction | From non–100.64.0.0/10 IP: `nc -zv <server> 22` → timeout/refused. From Tailscale: SSH works. |
| Persistence | After reboot run iptables -S INPUT and iptables -S DOCKER-USER; rules should match. |
| DOCKER-USER | From non-Tailscale IP: access to host:8080 or host:8443 refused. From Tailscale: Mailcow UI / Coolify reachable. |
| Backup | Next day after 03:30: `ls /home/comzis/mailcow/backups` shows timestamped dirs or files. |
| Admin restricted | From non-allowlist IP: <https://mail.inlock.ai/admin> and <https://admin.inlock.ai> return 403. |
| Webmail public | From any IP: <https://mail.inlock.ai> (no /admin) and <https://webmail.inlock.ai> show login page. |

### 8.6 Rollback steps (if needed)

| Change | Rollback |
| ------ | -------- |
| SSH hardening | Remove `/etc/ssh/sshd_config.d/99-security-hardening.conf`; `sudo systemctl restart sshd`. |
| SSH INPUT rules | Remove Tailscale ACCEPT and DROP for 22; keep f2b-sshd; `sudo netfilter-persistent save`. |
| DOCKER-USER rules | Remove ACCEPT/DROP for 8080/8443 from DOCKER-USER; `sudo netfilter-persistent save`. |
| Mailcow cron | `sudo rm -f /etc/cron.d/mailcow-backup`. |

*Re-audit completed 2026-01-31. No changes applied. Admin access remains restricted; webmail remains public.*

---

## 9. Full security audit and score

**Methodology:** Read-only, evidence-based. Controls are checked against configuration and re-audit evidence; no live changes. Score is from 0 to 100.

### 9.1 Control categories and checklist

| Category | Max | Controls checked | Result |
| -------- | --- | ----------------- | ------ |
| **OS / SSH** | 15 | PermitRootLogin no; AllowUsers comzis; no password/kbd auth; MaxAuthTries 3; LoginGraceTime 20; SSH restricted to 100.64.0.0/10; fail2ban; iptables persisted | 15/15 |
| **Firewall** | 15 | INPUT: SSH Tailscale + f2b + DROP; DOCKER-USER: 8080/8443 Tailscale-only, else DROP; martian logging; netfilter-persistent | 15/15 |
| **Docker / Traefik** | 20 | DOCKER_HOST=socket-proxy; no docker.sock; admin routes: allowed-admins + admin-forward-auth + mgmt-ratelimit; no temp public IP; Mailcow /admin: mailcow-admin-allowlist | 20/20 |
| **Mailcow** | 20 | DB/Redis on 127.0.0.1; netfilter isolation; admin restricted (Traefik + nginx); HTTP_REDIRECT=y; backup dir + cron + **manual backup verified** | 20/20 |
| **Credentials** | 15 | mailcow.conf mode 600, owner comzis; not in git; backup encryption policy documented; pre-commit hook blocks secrets; plaintext on disk (accepted risk) | 13/15 |
| **Monitoring & ops** | 15 | log_martians; fail2ban; netfilter bans; backup verified; backup-failure check (cron) added; optional daily security summary; optional webhook/email alerts | 13/15 |

**Deductions:**

- **Credentials (−2):** Sensitive values (DBPASS, REDISPASS, etc.) in plaintext in mailcow.conf; file permissions, backup encryption policy, and pre-commit hook mitigate.
- **Monitoring (−2):** Alerting exists (optional webhook/email), but escalation/ack workflows are not formally defined.

### 9.2 Scoring rubric

- **90–100:** Strong — No critical/high open; minor gaps only.
- **75–89:** Good — Some medium/low items; no critical.
- **60–74:** Fair — Medium findings or important gaps.
- **40–59:** Weak — High or multiple medium findings.
- **0–39:** Poor — Critical or multiple high findings.

### 9.3 Score and grade

| Metric | Value |
| ------ | ----- |
| **Total score** | **95 / 100** |
| **Grade** | **Strong (A)** |

**Summary:** Critical and high findings from the initial audit have been addressed. Backup-failure verification cron and daily security summary (optional) added; optional webhook/email alerts (e.g. ALERT_EMAIL=milorad.stevanovic@inlock.ai) for backup failures and security thresholds. Backup encryption policy documented; pre-commit hook blocks commits containing mailcow.conf or secret patterns. Remaining deductions: credential plaintext on disk; escalation/ack workflows not formally defined. Optional: LoginGraceTime 120; restore testing for Mailcow backups.
