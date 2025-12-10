# Docker Compose Environment Variables

## Issue
When running `docker compose -f compose/stack.yml`, you may see warnings:
```
WARN[0000] The "CLOUDFLARE_API_TOKEN" variable is not set. Defaulting to a blank string.
WARN[0000] The "DOMAIN" variable is not set. Defaulting to a blank string.
```

## Solution
Always use the `--env-file .env` flag when running docker compose commands:

```bash
# Correct way
docker compose -f compose/stack.yml --env-file .env <command>

# Examples
docker compose -f compose/stack.yml --env-file .env up -d
docker compose -f compose/stack.yml --env-file .env restart cadvisor
docker compose -f compose/stack.yml --env-file .env ps
docker compose -f compose/stack.yml --env-file .env logs traefik
```

## Why This Happens
- Docker Compose looks for `.env` in the current working directory
- When using `-f compose/stack.yml`, the compose file path doesn't affect where docker compose looks for `.env`
- The `env_file` directive in compose files only applies to container environment variables, not docker compose variable substitution (like `${DOMAIN}`)

## Quick Reference
All scripts in `scripts/` directory use `--env-file .env` - follow the same pattern for manual commands.
