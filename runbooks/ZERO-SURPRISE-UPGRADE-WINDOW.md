# Zero-Surprise Upgrade Window Runbook

Last updated: 2026-02-10
Target host: `vmi2953354` (`/home/comzis/inlock`)
Audience: operator with sudo + docker access

## Goal

Apply OS security updates and selected container app updates with:

- no unplanned downtime
- clear pause/rollback points
- verifiable health checks after each step

## Scope

This runbook covers:

- OS security patching (priority package: `libexpat1`)
- pinned container updates in:
  - `compose/services/stack.yml`
  - `compose/config/monitoring/logging.yml`
- services currently planned for update:
  - `oauth2-proxy`
  - `alertmanager`
  - `cadvisor`
  - `loki`
  - `promtail`

This runbook does not include Mailcow version upgrades.

## Change Window

Use a 60-minute window with three checkpoints:

1. Preflight + backup evidence (15 min)
2. OS patching + container updates (30 min)
3. Post-check monitoring hold (15 min)

## T-24h Preparation

Run these checks ahead of the maintenance window.

```bash
cd /home/comzis/inlock
git fetch --all --prune
git status --short
```

Confirm no local drift on production host. If there is drift, document and decide to keep or revert before proceeding.

Create a pre-change snapshot file with current runtime state:

```bash
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p /tmp/inlock-maintenance-"$TS"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' > /tmp/inlock-maintenance-"$TS"/docker-ps-before.txt
docker compose -f compose/services/stack.yml --env-file .env config > /tmp/inlock-maintenance-"$TS"/stack-config-before.yml
```

Record current image IDs for fast rollback:

```bash
docker inspect $(docker ps -q) --format '{{.Name}} {{.Config.Image}} {{.Image}}' \
  | sed 's#^/##' > /tmp/inlock-maintenance-"$TS"/image-ids-before.txt
```

## T-15m Preflight

Verify host is stable before starting updates.

```bash
uptime
free -h
df -h /
docker compose -f compose/services/stack.yml --env-file .env ps
docker compose -f compose/services/stack.yml --env-file .env config >/dev/null && echo "compose config OK"
```

Optional quick health checks:

```bash
curl -Ik https://inlock.ai | head -n 5
curl -Ik https://mail.inlock.ai | head -n 5
curl -Ik https://grafana.inlock.ai | head -n 5
```

If any check fails, stop and investigate before applying changes.

## Execution Plan (Production)

### 1) Pull latest repo changes

```bash
cd /home/comzis/inlock
git pull --ff-only
```

### 2) OS security updates first (low risk, high value)

Update `libexpat1` using the maintenance script:

```bash
sudo ./scripts/maintenance/update-libexpat1.sh
```

Optional: check pending security updates:

```bash
sudo apt update
apt list --upgradable 2>/dev/null | rg -i 'security|libexpat1'
```

Checkpoint A:

- `libexpat1` update succeeded
- no unexpected service failures in `journalctl -p err -n 50`

### 3) Container updates in phases (one blast radius at a time)

Use the compose stack file only:

```bash
cd /home/comzis/inlock
```

Phase 1: auth path (`oauth2-proxy`)

```bash
docker compose -f compose/services/stack.yml --env-file .env pull oauth2-proxy
docker compose -f compose/services/stack.yml --env-file .env up -d oauth2-proxy
docker compose -f compose/services/stack.yml --env-file .env ps oauth2-proxy
```

Validate:

```bash
curl -Ik https://auth.inlock.ai/oauth2/start | head -n 5
```

Phase 2: monitoring control plane (`alertmanager`, `cadvisor`)

```bash
docker compose -f compose/services/stack.yml --env-file .env pull alertmanager cadvisor
docker compose -f compose/services/stack.yml --env-file .env up -d alertmanager cadvisor
docker compose -f compose/services/stack.yml --env-file .env ps alertmanager cadvisor
```

Validate:

```bash
curl -fsS http://127.0.0.1:9093/-/ready >/dev/null && echo "alertmanager ready"
```

Phase 3: logging plane (`loki`, `promtail`)

```bash
docker compose -f compose/services/stack.yml --env-file .env pull loki promtail
docker compose -f compose/services/stack.yml --env-file .env up -d loki promtail
docker compose -f compose/services/stack.yml --env-file .env ps loki promtail
```

Validate:

```bash
curl -fsS http://127.0.0.1:3100/ready >/dev/null && echo "loki ready"
```

Checkpoint B:

- updated containers are `Up` and healthy
- auth endpoint returns expected status
- alertmanager and loki readiness checks pass

### 4) Broad stack reconcile

After phased updates, do one full reconcile:

```bash
docker compose -f compose/services/stack.yml --env-file .env up -d
docker compose -f compose/services/stack.yml --env-file .env ps
```

## Post-Change Monitoring Hold (15 min)

Run after all updates:

```bash
uptime
docker ps --format 'table {{.Names}}\t{{.Status}}' | head -n 40
journalctl -p err --since "15 min ago"
```

If available, also check:

```bash
./scripts/test-endpoints.sh || true
```

Success criteria:

- no restart loops
- no new error bursts in journald
- public endpoints return expected responses

## Rollback Plan

Use rollback if any critical path fails and does not recover within 10 minutes.

1. Revert the compose tag changes commit on host and pull old images.

```bash
cd /home/comzis/inlock
git log --oneline -n 10
git revert <commit_with_image_updates>
docker compose -f compose/services/stack.yml --env-file .env pull
docker compose -f compose/services/stack.yml --env-file .env up -d
```

2. If issue is isolated to one service, roll back only that service image in `compose/services/stack.yml` or `compose/config/monitoring/logging.yml`, then:

```bash
docker compose -f compose/services/stack.yml --env-file .env up -d <service_name>
```

3. For OS package issues (`libexpat1`), pin/install previous version from apt cache if required and document exact package version change.

## Fast Path (Scripted)

If prechecks pass and you accept a single-step rollout, use:

```bash
cd /home/comzis/inlock
./scripts/maintenance/update-inlock-compose-services.sh
```

This script validates compose config, pulls images, runs `up -d`, and prints status.

## Operator Checklist

Before window:

- [ ] Maintenance window approved
- [ ] Backup evidence captured (`/tmp/inlock-maintenance-<ts>/`)
- [ ] Rollback owner assigned

During window:

- [ ] Checkpoint A passed (OS patch)
- [ ] Checkpoint B passed (phased containers)
- [ ] Full reconcile done

After window:

- [ ] 15-minute monitoring hold passed
- [ ] Security scorecard updated if versions changed
- [ ] Maintenance notes committed to repo
