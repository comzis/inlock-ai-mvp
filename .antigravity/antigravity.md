# Antigravity + Cursor Co-Working Guide

Role: Antigravity runs alongside Cursor as a DevOps/SRE assistant for this infra repo. Treat production configs as fragile: prefer additive changes, avoid breaking working deployments, and stage/verify before applying.

## Working Context
- Repo root: `/home/comzis/projects/inlock-ai-mvp`
- Compose entrypoint: `compose/services/stack.yml` (includes service-specific files)
- Traefik config: `traefik/traefik.yml`, `traefik/dynamic/*.yml`
- Secrets: real secrets live under `/home/comzis/apps/secrets-real/` (do not commit); examples under `secrets/*.example`
- Docs/runbooks: `docs/`, `docs/audit/`, `docs/config/`, `docs/runbooks/`
- Scripts: `scripts/*.sh` (verify before running)
- Cursor control workspace: `/home/comzis/.cursor/projects/home-comzis-inlock`

## Safety Rails
- Do not touch real secrets or change live certs without explicit intent.
- Avoid destructive moves on compose/traefik unless validated with `docker compose config` and targeted dry runs.
- Keep admin ingress behind forward-auth + IP allowlists; do not relax auth.
- Pin images (no `:latest`) and avoid enabling password auth/weakening SSH.

## Workflow (preferred)
1) Read context: `docs/audit/security-audit.md`, `docs/config/proposed-config.md`, `TODO.md`.
2) Plan: propose minimal diffs; preserve working behaviors.
3) Edit: apply small, reversible patches; keep comments concise.
4) Validate: run lint/`docker compose config` where allowed; otherwise describe required checks.
5) Summarize: note changes, risks, and next verifications.

## Manifest (antigravity-manifest.json)
Use the adjacent JSON to scope Antigravity's focus to infra-relevant paths and avoid secrets/backups.

## Structure to Keep in Mind
```
projects/inlock-ai-mvp/
  compose/          # stack.yml + service includes
  traefik/          # static + dynamic routers/middlewares/services
  scripts/          # hardening/verification helpers
  docs/             # audit, config proposals, runbooks
  secrets/*.example # sample secrets (real ones in /home/comzis/apps/secrets-real/)

antigravity/
  antigravity.md
  antigravity-manifest.json
  antigravity-rules.md
```
