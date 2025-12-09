#!/bin/bash
# Clean up orphan containers from Docker Compose stack
# This removes containers that are no longer defined in the compose files

set -e

cd /home/comzis/inlock-infra

echo "========================================="
echo "Cleaning Up Orphan Containers"
echo "========================================="
echo ""

# List orphan containers
echo "Checking for orphan containers..."
ORPHANS=$(docker ps -a --filter "name=compose-" --format "{{.Names}}" | grep -E "compose-(homarr|n8n|postgres|cockpit)-1" || true)

if [ -z "$ORPHANS" ]; then
    echo "✅ No orphan containers found"
    exit 0
fi

echo "Found orphan containers:"
echo "$ORPHANS" | while read container; do
    STATUS=$(docker ps -a --filter "name=$container" --format "{{.Status}}")
    echo "  - $container ($STATUS)"
done

echo ""
read -p "Remove these orphan containers? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Removing orphan containers..."

# Stop and remove each orphan container
echo "$ORPHANS" | while read container; do
    echo "  Removing $container..."
    docker stop "$container" 2>/dev/null || true
    docker rm "$container" 2>/dev/null || true
done

echo ""
echo "Cleaning up using Docker Compose with --remove-orphans..."
docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans 2>&1 | grep -v "WARN.*orphan" || true

echo ""
echo "========================================="
echo "✅ Orphan Container Cleanup Complete!"
echo "========================================="
echo ""
echo "Remaining containers:"
docker compose -f compose/stack.yml --env-file .env ps --format "table {{.Service}}\t{{.Status}}"

