# Docker Cleanup Guide

## Quick Start

```bash
cd /home/comzis/inlock-infra
./scripts/cleanup-docker.sh
```

This will show an interactive menu to select what to clean.

## Available Options

### Interactive Menu
Run without arguments to see the menu:
```bash
./scripts/cleanup-docker.sh
```

### Command Line Options

```bash
# Dry run (see what would be removed)
./scripts/cleanup-docker.sh --dry-run --all

# Clean specific resources
./scripts/cleanup-docker.sh --images      # Remove unused images
./scripts/cleanup-docker.sh --cache        # Clear build cache
./scripts/cleanup-docker.sh --volumes     # Remove unused volumes
./scripts/cleanup-docker.sh --containers  # Remove stopped containers

# Clean everything
./scripts/cleanup-docker.sh --all
```

## What Gets Cleaned

### 1. Unused Images (saves ~57GB)
- Removes images not used by any container
- Removes dangling images (untagged)
- **Safe**: Only removes images not in use

### 2. Build Cache (saves ~48GB)
- Removes Docker build cache
- **Safe**: Cache can be regenerated on next build
- **Note**: Next builds may be slightly slower

### 3. Unused Volumes (saves ~3GB)
- Removes volumes not attached to any container
- **Safe**: Only removes truly unused volumes
- **Warning**: Prompts for confirmation before removing

### 4. Stopped Containers
- Removes containers that have exited
- **Safe**: Only removes stopped containers
- Running containers are not affected

## Expected Space Savings

Based on current usage:
- **Total potential savings**: ~109GB
  - Images: ~57GB
  - Build cache: ~48GB
  - Volumes: ~3GB
  - Containers: ~1GB

## Safety Features

1. **Dry Run Mode**: Use `--dry-run` to preview changes
2. **Volume Confirmation**: Prompts before removing volumes
3. **No Running Containers**: Never removes running containers
4. **No Active Volumes**: Never removes volumes in use

## Manual Cleanup Commands

If you prefer manual cleanup:

```bash
# Remove unused images
docker image prune -a

# Clear build cache
docker builder prune -a

# Remove unused volumes (with confirmation)
docker volume prune

# Remove stopped containers
docker container prune

# Remove everything unused (WARNING: removes all unused resources)
docker system prune -a --volumes
```

## Check Disk Usage

Before and after cleanup, check disk usage:
```bash
./scripts/check-disk-usage.sh
```

Or use Docker's built-in command:
```bash
docker system df
```

## Best Practices

1. **Regular Cleanup**: Run cleanup monthly or when disk space is low
2. **Before Major Updates**: Clean before pulling new images
3. **After Builds**: Clean build cache after large builds
4. **Monitor Usage**: Check disk usage regularly

## Troubleshooting

### "Cannot remove volume in use"
- The volume is attached to a container (running or stopped)
- Remove the container first, or use `docker volume rm -f` (dangerous)

### "Cannot remove image in use"
- The image is used by a container
- Remove the container first

### Build cache keeps growing
- Run `docker builder prune -a` regularly
- Consider using `.dockerignore` to reduce build context size

## Related Scripts

- `check-disk-usage.sh` - Analyze disk usage
- `cleanup-docker.sh` - Clean Docker resources

