# Coolify Migration Notes

These steps document the SQLite-specific workarounds applied when running the pending Laravel migrations (264 total) inside `coolify` for the Docker stack.

## Indexes Explicitly Dropped

The following indexes referenced columns that did not exist in the SQLite schema. They were removed manually before rerunning migrations:

```sql
DROP INDEX IF EXISTS environment_variables_key_service_id_is_build_time_is_preview_unique;
DROP INDEX IF EXISTS environment_variables_key_database_id_is_build_time_is_preview_unique;
DROP INDEX IF EXISTS services_destination_type_destination_id_index;
DROP INDEX IF EXISTS environment_variables_key_application_id_is_build_time_is_preview_unique;
```

## Migrations Marked as Completed

These migrations expect PostgreSQL-specific features (foreign keys, constraints, composite indexes) that are not available in the embedded SQLite DB. They were marked as "run" with `php artisan migrate --pretend` and recorded as completed:

- `2023_08_06_142952_remove_foreignId_environment_variables`
- `2023_08_06_142954_add_readonly_localpersistentvolumes`
- `2023_08_07_073651_create_s3_storages_table`
- `2023_08_07_142950_create_standalone_postgresqls_table`
- `2023_08_08_150103_create_scheduled_database_backups_table`
- `2023_09_21_135441_update_webhooks_type`
- `2023_10_24_090230_add_resourceable_columns_to_environment_variables_table`
- `2023_11_08_140701_add_performance_indexes`

_Anything requiring `DROP CONSTRAINT`, `ALTER TABLE ... DROP COLUMN`, or Postgres-only functions/metadata (e.g., `pg_indexes`) was treated similarly._

## Scripted Workflow

1. Run `./scripts/run-coolify-migrations.sh` (prompts for confirmation unless `--force`).
2. When an error references an index on a missing column, drop the index via `php artisan tinker`.
3. Re-run `php artisan migrate` until all migrations report Success.
4. Restart the stack’s Coolify service: `docker compose -f compose/stack.yml --env-file .env restart coolify`.

## Current State

- Pending migrations: **0**
- Coolify container: **healthy**
- Schema fixes from `scripts/fix-coolify-cron.sh` remain in place (cron columns, soft deletes).

## Future Improvements

1. **Migrate Coolify to PostgreSQL**
   - Export the SQLite data (or rebuild resources manually) and deploy the official Postgres-backed Coolify stack.
   - Once on Postgres, upstream migrations (including those listed above) will apply without manual intervention.
   - Track this as a maintenance item so we can drop the local workarounds entirely.

2. **Automated Health Checks**
   - Add a scheduled task or monitoring probe that hits `https://deploy.inlock.ai` and checks the internal `/api/health` endpoint so we detect migration drift early.
   - Pair the probe with `docker compose -f compose/stack.yml --env-file .env ps coolify` in the alert runbook.

Use this document as a reference if similar mismatches appear after future Coolify updates, and keep the PostgreSQL migration on the roadmap so the workaround can be retired.
