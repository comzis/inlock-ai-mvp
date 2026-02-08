# Daily Host Status Report – Investigation

**Host:** vmi2953354 (report typo: "nlock" → inlock)  
**Date:** 2026-02-01  
**Report summary:** Security 9.2/10; 1 container failed (Coolify); integrity diff detected.

---

## 1. Summary of findings

| Item | Status | Action |
|------|--------|--------|
| **Containers** | 7 OK, **1 failed** | Restore Coolify (see §2) |
| **NAT (mailcow)** | OK | None |
| **Backups** | 2 OK | None |
| **HTTP** | 3 OK (inlock.ai, mail, deploy) | None |
| **Integrity diff** | Changes detected | Review on host (see §3) |
| **Disk** | 59% on /dev/sda1 | Monitor |

---

## 2. Coolify not running (`services-coolify-1`)

**What it is:** Coolify is the deployment UI at https://deploy.inlock.ai. It runs as a separate Compose project (not in `stack.yml`).

**Why it might be down (from repo docs):**
- **Cron expression error** – invalid cron in DB can make the health check fail; container may exit or be marked unhealthy.
- **Dependencies** – Coolify depends on `coolify-postgres`, `coolify-redis`, `coolify-soketi`. If any are down, Coolify can fail.
- **OOM or crash** – check `docker logs` and `docker events`.

**Remediation (on host):**

```bash
# From repo root (e.g. /home/comzis/inlock)
cd /home/comzis/inlock

# If Coolify is under compose/services/ with project name "services":
docker compose -f compose/services/coolify.yml -p services ps
docker compose -f compose/services/coolify.yml -p services logs coolify --tail 80

# Start the stack (all Coolify services)
docker compose -f compose/services/coolify.yml -p services up -d

# If health check keeps failing (cron error), fix DB then restart:
# ./scripts/fix-coolify-cron.sh   # if present in repo
docker compose -f compose/services/coolify.yml -p services restart coolify
```

**If your layout uses `compose/coolify.yml`** (e.g. in another repo like inlock-infra):

```bash
cd /home/comzis/inlock-infra   # or wherever compose/coolify.yml lives
docker compose -f compose/coolify.yml --env-file .env ps
docker compose -f compose/coolify.yml --env-file .env up -d
```

**Verify:**  
- `docker ps` shows `services-coolify-1` (or equivalent) as Up.  
- https://deploy.inlock.ai returns HTTP 302 (login) or 200.

**References:**  
- `docs/guides/COOLIFY-SETUP-GUIDE.md`  
- `docs/services/coolify/COOLIFY-MIGRATION-NOTES.md`  
- `docs/security/DEPLOYMENT-COMPLETE-2026-01-08.md` (port 8080 note; Coolify in this repo uses Traefik only, no host port)

---

## 3. Integrity diff: changes detected

**What it is:** File integrity monitoring (e.g. AIDE, Tripwire, or a custom script) has detected changes against the baseline (new/modified/deleted files under monitored paths).

**Action:** Run the same tool that produces “Integrity diff” on the host and inspect the report, e.g.:

### 3.1 Where the "Integrity diff" line comes from

The phrase "Integrity diff: changes detected" is **not** produced by any script in this repo. On the host, check:

| Location | What to look for |
|----------|------------------|
| **Cron** | `grep -r "integrity\|diff\|aide\|tripwire" /etc/cron.d /etc/cron.daily /etc/cron.weekly 2>/dev/null` |
| **Systemd timers** | `systemctl list-timers --all \| grep -i aide` or similar |
| **Netdata / monitoring** | If the full report is from Netdata or another stack, check its config for a "host summary" or "integrity" plugin |
| **Custom script** | Any script that builds the "daily host status" text and is run by cron or a timer |

Once you find the job that prints that line, run it manually (or run the underlying check) to get the **full diff report**.

### 3.2 Common tools that produce integrity diffs

| Tool | Check command | Where reports / baseline live |
|------|----------------|------------------------------|
| **AIDE** | `sudo aide --check` | DB: `/var/lib/aide/aide.db.*`; config: `/etc/aide/aide.conf`. Output goes to stdout or a path configured in cron. |
| **Tripwire** | `sudo tripwire --check` | DB and config under `/etc/tripwire/` and `/var/lib/tripwire/`. |
| **Custom checksum script** | Depends on script | Often a baseline file (e.g. `integrity.baseline`) and a compare step; script may live in `/usr/local/bin` or a repo. |

**AIDE (typical):**

```bash
# Run check (output shows added/changed/deleted files)
sudo aide --check

# If changes are expected (e.g. after apt upgrade), update baseline:
sudo aide --init
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

**Custom / unknown:** Find the script that builds the daily report (search cron, grep for "Integrity diff" or "changes detected" on the host), then run that script or the subcommand that does the integrity check.

### 3.3 How to interpret the diff

- **Expected changes:** Package updates (`/var/lib/dpkg`, `/etc` configs), log rotation (e.g. `/var/log`), cron runs, application logs, Traefik/Docker data under `/home/comzis` or `/var/lib/docker`. After verifying, update the baseline if your tool supports it.
- **Unexpected or suspicious:** New setuid binaries, changes to SSH/sshd config, new scripts in `/etc/cron.*`, changes to sudoers, or files in system dirs you did not change. Treat as potential compromise: capture the diff, preserve logs, and follow your incident response.

### 3.4 Viewing the changes (compromise check)

To see **which files** changed (and whether they were added, removed, or modified), run on the host **as root**:

```bash
sudo /home/comzis/inlock/ops/security/integrity-diff-check.sh --show
```

Output is grouped into:
- **REMOVED or no longer readable** – in baseline but not in current (file deleted or permissions changed).
- **NEW** – in current but not in baseline (new file).
- **CHANGED** – same path but content (checksum) differs.

Review each path. Expected: package/config updates, your own edits. Suspicious: changes to `/etc/ssh/sshd_config`, new files in `/etc/cron.d`, sudoers, or setuid binaries you did not add. If unsure, capture the full output and treat as a potential incident until verified.

### 3.5 Optional: in-repo integrity check script

- **`ops/security/integrity-diff-check.sh`** – builds a baseline of critical paths (e.g. `/etc`, config dirs), then on later runs compares current checksums to the baseline. Use `--show` to list changed files (see §3.4). See script header for usage and cron example.

---

## 4. Report source

This “daily host status” format (Security score, Containers, NAT, Backups, HTTP, Integrity diff, Disk, End report) is **not** produced by the scripts in this repo. The repo’s daily job is:

- `ops/security/daily-security-summary.sh` (cron 05:00) – fail2ban + netfilter only.

So the full host report is likely generated by:

- A script or cron on the host outside this repo, or  
- Netdata / another monitoring stack, or  
- An n8n (or similar) workflow.

To automate response (e.g. restart Coolify when down), you’d need to add logic to whatever generates this report or to a separate cron/alert handler.

---

## 5. Install automation (integrity diff + Coolify recovery)

Scripts and cron files in this repo run the integrity diff check and auto-start Coolify from cron.

**Integrity diff (daily 06:00):** `ops/security/integrity-diff-check.sh` + `ops/security/cron.integrity-diff-check`  
Create baseline once: `sudo /home/comzis/inlock/ops/security/integrity-diff-check.sh --init`  
Install cron: `sudo install -m 644 /home/comzis/inlock/ops/security/cron.integrity-diff-check /etc/cron.d/integrity-diff-check`

**Coolify auto-start (every 15 min):** `ops/security/start-coolify-if-down.sh` + `ops/security/cron.start-coolify-if-down`  
Test: `/home/comzis/inlock/ops/security/start-coolify-if-down.sh --dry-run`  
Install cron: `sudo install -m 644 /home/comzis/inlock/ops/security/cron.start-coolify-if-down /etc/cron.d/start-coolify-if-down`

---

## 6. Quick checklist

- [ ] Start Coolify once: run `ops/security/start-coolify-if-down.sh` or `docker compose -f compose/services/coolify.yml -p services up -d`.
- [ ] Confirm `services-coolify-1` is Up and https://deploy.inlock.ai responds.
- [ ] Install Coolify auto-start cron (see §5).
- [ ] Create integrity baseline and install integrity-diff cron (see §5).
- [ ] On host, run existing integrity check (AIDE or report script) and review diff; confirm changes are expected.
