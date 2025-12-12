#!/bin/bash
# Cleanup unused Docker resources to free disk space
# Run with: ./cleanup-docker.sh [--dry-run] [--all] [--images] [--cache] [--volumes] [--containers]

set -euo pipefail

DRY_RUN=false
CLEAN_IMAGES=false
CLEAN_CACHE=false
CLEAN_VOLUMES=false
CLEAN_CONTAINERS=false
CLEAN_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --images)
            CLEAN_IMAGES=true
            shift
            ;;
        --cache)
            CLEAN_CACHE=true
            shift
            ;;
        --volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        --containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--all] [--images] [--cache] [--volumes] [--containers]"
            exit 1
            ;;
    esac
done

# If no specific options, show menu
if [ "$CLEAN_ALL" = false ] && [ "$CLEAN_IMAGES" = false ] && [ "$CLEAN_CACHE" = false ] && [ "$CLEAN_VOLUMES" = false ] && [ "$CLEAN_CONTAINERS" = false ]; then
    echo "=========================================="
    echo "  Docker Cleanup Script"
    echo "=========================================="
    echo ""
    echo "Current Docker disk usage:"
    docker system df
    echo ""
    echo "Select cleanup option:"
    echo "1. Clean unused images (saves ~57GB)"
    echo "2. Clean build cache (saves ~48GB)"
    echo "3. Clean unused volumes (saves ~3GB)"
    echo "4. Clean stopped containers"
    echo "5. Clean all unused resources (images + cache + volumes + containers)"
    echo "6. Dry run (show what would be removed)"
    echo "7. Exit"
    echo ""
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1) CLEAN_IMAGES=true ;;
        2) CLEAN_CACHE=true ;;
        3) CLEAN_VOLUMES=true ;;
        4) CLEAN_CONTAINERS=true ;;
        5) CLEAN_ALL=true ;;
        6) DRY_RUN=true; CLEAN_ALL=true ;;
        7) exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
fi

# If --all, set all flags
if [ "$CLEAN_ALL" = true ]; then
    CLEAN_IMAGES=true
    CLEAN_CACHE=true
    CLEAN_VOLUMES=true
    CLEAN_CONTAINERS=true
fi

echo ""
echo "=========================================="
echo "  Docker Cleanup"
if [ "$DRY_RUN" = true ]; then
    echo "  DRY RUN MODE - No changes will be made"
fi
echo "  Started: $(date)"
echo "=========================================="
echo ""

# Get initial disk usage
echo "=== Initial Disk Usage ==="
INITIAL_DF=$(df -h / | awk 'NR==2 {print $3}')
echo "Root filesystem used: $INITIAL_DF"
docker system df
echo ""

# Clean unused images
if [ "$CLEAN_IMAGES" = true ]; then
    echo "=== Cleaning Unused Images ==="
    UNUSED_IMAGES=$(docker images -f "dangling=true" -q | wc -l)
    if [ "$UNUSED_IMAGES" -gt 0 ]; then
        echo "Found $UNUSED_IMAGES unused images"
        if [ "$DRY_RUN" = true ]; then
            echo "Would remove:"
            docker images -f "dangling=true" --format "  - {{.Repository}}:{{.Tag}} ({{.Size}})"
        else
            docker image prune -a -f
            echo "✓ Unused images removed"
        fi
    else
        echo "No unused images found"
    fi
    echo ""
fi

# Clean build cache
if [ "$CLEAN_CACHE" = true ]; then
    echo "=== Cleaning Build Cache ==="
    CACHE_SIZE=$(docker system df --format '{{.BuildCache}}' | grep -oP '\d+\.\d+GB' | head -1 || echo "0GB")
    echo "Build cache size: $CACHE_SIZE"
    if [ "$DRY_RUN" = true ]; then
        echo "Would remove all build cache"
        docker builder du 2>/dev/null || echo "  (Cannot preview build cache details)"
    else
        docker builder prune -a -f
        echo "✓ Build cache cleared"
    fi
    echo ""
fi

# Clean unused volumes
if [ "$CLEAN_VOLUMES" = true ]; then
    echo "=== Cleaning Unused Volumes ==="
    UNUSED_VOLUMES=$(docker volume ls -f "dangling=true" -q | wc -l)
    if [ "$UNUSED_VOLUMES" -gt 0 ]; then
        echo "Found $UNUSED_VOLUMES unused volumes"
        if [ "$DRY_RUN" = true ]; then
            echo "Would remove:"
            docker volume ls -f "dangling=true" --format "  - {{.Name}}"
        else
            # Show which volumes will be removed
            echo "Unused volumes to be removed:"
            docker volume ls -f "dangling=true" --format "  - {{.Name}}"
            read -p "Continue? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker volume prune -f
                echo "✓ Unused volumes removed"
            else
                echo "Skipped volume cleanup"
            fi
        fi
    else
        echo "No unused volumes found"
    fi
    echo ""
fi

# Clean stopped containers
if [ "$CLEAN_CONTAINERS" = true ]; then
    echo "=== Cleaning Stopped Containers ==="
    STOPPED_CONTAINERS=$(docker ps -a -f "status=exited" -q | wc -l)
    if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
        echo "Found $STOPPED_CONTAINERS stopped containers"
        if [ "$DRY_RUN" = true ]; then
            echo "Would remove:"
            docker ps -a -f "status=exited" --format "  - {{.Names}} ({{.Status}})"
        else
            docker container prune -f
            echo "✓ Stopped containers removed"
        fi
    else
        echo "No stopped containers found"
    fi
    echo ""
fi

# Show final disk usage
if [ "$DRY_RUN" = false ]; then
    echo "=== Final Disk Usage ==="
    FINAL_DF=$(df -h / | awk 'NR==2 {print $3}')
    echo "Root filesystem used: $FINAL_DF"
    docker system df
    echo ""
    
    echo "=== Summary ==="
    echo "Initial: $INITIAL_DF used"
    echo "Final:   $FINAL_DF used"
    echo ""
    echo "✓ Cleanup complete!"
else
    echo "=== Dry Run Summary ==="
    echo "No changes were made. Run without --dry-run to apply cleanup."
fi

echo ""
echo "To see current disk usage:"
echo "  ./scripts/check-disk-usage.sh"
echo ""

