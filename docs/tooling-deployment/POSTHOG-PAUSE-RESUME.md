# PostHog Pause / Resume Runbook

**Date created**: 2026-01-24  
**Purpose**: Reduce CPU by stopping PostHog’s CPU-heavy workers. Use when analytics is not needed or during resource pressure.

---

## Context

- **PostHog stack** (`compose/services/tooling.yml`): `posthog_web`, `posthog_worker`, `posthog_plugins`, plus `posthog_db`, `posthog_redis`, `posthog_clickhouse`, `posthog_kafka`, `posthog_zookeeper`.
- **CPU load**: The **worker** and **plugins** services drive most of the steady-state CPU. Migrate-check runs once at startup; ongoing load is from worker/plugin processing.
- **App dependency**: The inlock-ai app does **not** use the PostHog SDK (no `posthog-js` in `apps/inlock-ai`). Pausing workers does not break the app. The PostHog UI at `https://analytics.inlock.ai` will remain up if `posthog_web` is running, but event processing stops while worker/plugins are stopped.

---

## What Gets Stopped vs. Kept

- **Stopped (Pause)**: `posthog_worker`, `posthog_plugins` — async event processing and plugin runs. No CPU from these.
- **Kept**: `posthog_web`, `posthog_clickhouse`, `posthog_db`, `posthog_redis`, `posthog_kafka`, `posthog_zookeeper`. You can still open `https://analytics.inlock.ai`; new events will not be processed until workers are resumed.

---

## 1. Pause (stop CPU-heavy services)

```bash
cd /home/comzis/projects/inlock-ai-mvp

docker compose -p tooling -f compose/services/tooling.yml \
  --env-file compose/services/.env.tooling \
  stop posthog_worker posthog_plugins
```

---

## 2. Verify paused

```bash
# Should show no running containers for worker/plugins
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'posthog_(worker|plugins)'

# Stopped containers (Exited) — optional
docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep -E 'posthog_(worker|plugins)'

# No lines for worker/plugins (they are not running)
docker stats --no-stream | grep -iE 'posthog_worker|posthog_plugins'
```

**Expected when paused:**

- `docker ps` (running): no rows for `posthog_worker` or `posthog_plugins`.
- `docker ps -a`: `posthog_worker` and `posthog_plugins` show `Exited (137)` (or similar).
- `docker stats`: no lines for `posthog_worker` or `posthog_plugins`.

---

## 3. Resume (rollback)

```bash
cd /home/comzis/projects/inlock-ai-mvp

docker compose -p tooling -f compose/services/tooling.yml \
  --env-file compose/services/.env.tooling \
  start posthog_worker posthog_plugins
```

---

## 4. Verify resumed

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'posthog_(worker|plugins)'
docker stats --no-stream | grep -iE 'posthog_worker|posthog_plugins'
```

**Expected when resumed:**

- `posthog_worker` and `posthog_plugins` appear in `docker ps` with status `Up`.
- Both appear in `docker stats` with CPU/memory usage.

---

## Full PostHog shutdown (optional)

To stop the **entire** PostHog stack (including web UI and ClickHouse):

```bash
cd /home/comzis/projects/inlock-ai-mvp

docker compose -p tooling -f compose/services/tooling.yml \
  --env-file compose/services/.env.tooling \
  stop posthog_worker posthog_plugins posthog_web posthog_clickhouse \
       posthog_kafka posthog_zookeeper posthog_redis posthog_db
```

To bring it all back:

```bash
docker compose -p tooling -f compose/services/tooling.yml \
  --env-file compose/services/.env.tooling \
  start posthog_db posthog_redis posthog_zookeeper posthog_kafka \
        posthog_clickhouse posthog_web posthog_worker posthog_plugins
```

(Start order: DB/Redis → Zookeeper → Kafka → ClickHouse → Web → Worker → Plugins.)

---

## Related

- **Tooling stack**: [tooling-setup.md](./tooling-setup.md)
- **PostHog stack definition**: `compose/services/tooling.yml`
- **Throttling alternative** (if you prefer to keep workers running with less CPU): reduce `WEB_CONCURRENCY` (e.g. 2→1) and/or set `POSTHOG_SKIP_MIGRATION_CHECKS=true` in `posthog_worker`. See SRE notes / optimization docs.

---

**Last updated**: 2026-01-24
