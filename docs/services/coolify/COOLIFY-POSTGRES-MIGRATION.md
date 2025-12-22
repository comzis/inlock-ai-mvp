# Coolify PostgreSQL Migration Plan & Execution

## Goals
- Replace the default SQLite database used by the Coolify stack with the bundled PostgreSQL service (`coolify-postgres`).
- Keep a restorable backup of the previous SQLite data set.
- Update container configuration so future migrations run natively on PostgreSQL without the manual workarounds documented in `COOLIFY-MIGRATION-NOTES.md`.

## Cutover Plan

1. **Backups & Validation**
   - Snapshot `/data/coolify` on the host to preserve the existing SQLite database (`coolify.sqlite`) and generated keys.
   - Leave the copy under `/home/comzis/backups/coolify-sqlite-<timestamp>` for future reference.

2. **Prepare PostgreSQL Credentials**
   - Reuse the existing `POSTGRES_PASSWORD` env variable defined in `.env` (the stack already keeps this file outside of version control).
   - Ensure the `coolify-postgres` service uses the same user/database combo (`coolify` / `coolify`).

3. **Update Compose Configuration**
   - Switch `DB_CONNECTION` from `sqlite` to `pgsql`.
   - Provide `DB_HOST=coolify-postgres`, `DB_PORT=5432`, `DB_DATABASE=coolify`, `DB_USERNAME=coolify`, and `DB_PASSWORD=${POSTGRES_PASSWORD}` to the `coolify` container.
   - (Optional) Set `DB_URL`/`DATABASE_URL` variables if Coolify adds support later.

4. **Cutover Steps**
   - Stop the Coolify app container (`docker compose ... stop coolify`).
   - Bring it back up so the new env vars take effect along with the Postgres service.
   - Run `php artisan migrate --force` inside the container to initialize the PostgreSQL schema.
   - If data is required, re-create configs manually or import from the SQLite backup using external tooling (pgloader/psql). For our deployment, Coolify only managed a couple of demo services, so we accepted a fresh DB and noted the backup location.

5. **Verification**
   - `docker compose -f compose/stack.yml --env-file .env ps coolify` → `healthy`.
   - `docker compose ... logs coolify --tail 100` → no SQLite references, migrations run against PostgreSQL.
   - Hit `https://deploy.inlock.ai` → UI loads, login works.

## Completed Actions (2025-12-10)
- Backed up `/data/coolify` ➜ `/home/comzis/backups/coolify-sqlite-20251210-<time>`.
- Edited `compose/coolify.yml` to point Coolify at PostgreSQL.
- Recreated containers and ran `php artisan migrate --force` inside the new Postgres-backed instance.
- Confirmed the UI is reachable and `php artisan tinker` reports `DB_CONNECTION=pgsql`.

### Follow-ups
- Keep the SQLite backup until Coolify has been reconfigured/re-verified by the team.
- If the Coolify UI held important environment definitions, use the backup to re-enter them manually (or perform a sqlite → Postgres import offline).
- Consider creating a helper script to restore from the backup if we need to re-check historical settings.
