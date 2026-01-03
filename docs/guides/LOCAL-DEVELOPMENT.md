# Local Development Setup

**Last Updated:** 2026-01-03

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.local.example .env.local
   ```

2. **Edit `.env.local` with your settings:**
   ```bash
   # At minimum, change the database password
   POSTGRES_PASSWORD=your_secure_dev_password
   ```

3. **Start services:**
   ```bash
   docker compose -f compose/services/docker-compose.local.yml --env-file .env.local up -d
   ```

4. **Access services:**
   - Application: http://localhost:3040
   - Database: localhost:5432

## Environment Variables

### Required Variables

- `POSTGRES_USER` - Database user (default: postgres)
- `POSTGRES_PASSWORD` - Database password (**change this!**)
- `POSTGRES_DB` - Database name (default: inlock)
- `NODE_ENV` - Environment (default: development)

### Example `.env.local`

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=my_secure_dev_password
POSTGRES_DB=inlock
NODE_ENV=development
```

## Services

### Inlock AI Application
- **Port:** 3040
- **Image:** Built from local Dockerfile
- **Volumes:** Mounts local code for hot reload

### PostgreSQL Database
- **Port:** 5432
- **Image:** postgres:15-alpine
- **Data:** Persisted in `inlock_db_local` volume

### Redis (if needed)
- **Port:** 6379
- **Image:** redis:6-alpine

## Development Workflow

### Making Changes

1. **Edit code** in your local directory
2. **Restart service** (if needed):
   ```bash
   docker compose -f compose/services/docker-compose.local.yml restart inlock-ai
   ```

### Viewing Logs

```bash
# All services
docker compose -f compose/services/docker-compose.local.yml logs -f

# Specific service
docker compose -f compose/services/docker-compose.local.yml logs -f inlock-ai
```

### Stopping Services

```bash
docker compose -f compose/services/docker-compose.local.yml down
```

### Cleaning Up

```bash
# Stop and remove volumes
docker compose -f compose/services/docker-compose.local.yml down -v
```

## Security Notes

- `.env.local` is in `.gitignore` - never commit it
- Use different passwords than production
- This is for local development only
- No production secrets should be in `.env.local`

## Troubleshooting

### Port Already in Use

If port 3040 or 5432 is already in use:

1. **Find process:**
   ```bash
   lsof -i :3040
   lsof -i :5432
   ```

2. **Kill process or change ports in compose file**

### Database Connection Issues

1. **Check database is running:**
   ```bash
   docker compose -f compose/services/docker-compose.local.yml ps
   ```

2. **Check logs:**
   ```bash
   docker compose -f compose/services/docker-compose.local.yml logs inlock-db
   ```

3. **Verify environment variables:**
   ```bash
   cat .env.local
   ```

## Related Files

- `compose/services/docker-compose.local.yml` - Local development compose file
- `.env.local.example` - Environment template
- `.gitignore` - Ensures `.env.local` is not committed

