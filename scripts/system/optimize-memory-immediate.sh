#!/bin/bash
# Immediate Memory Optimization Script
# Restarts high-memory services and applies quick optimizations

set -euo pipefail

echo "========================================="
echo "Immediate Memory Optimization"
echo "========================================="
echo ""
echo "⚠️  This script will restart services to reclaim memory"
echo "    Services may experience brief downtime"
echo ""

# Check current memory
echo "Current memory status:"
free -h
echo ""

# Identify top memory consumers
echo "Identifying top memory consumers..."
TOP_CONSUMERS=$(ps aux --sort=-%mem | head -11 | tail -10)

echo "Top 10 memory consumers:"
echo "$TOP_CONSUMERS"
echo ""

# Ask for confirmation
read -p "Continue with optimization? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Function to safely restart a service
restart_service() {
    local service=$1
    echo "Restarting $service..."
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        docker restart "$service" && echo "✅ $service restarted" || echo "❌ Failed to restart $service"
        sleep 5
    else
        echo "⚠️  $service not running"
    fi
}

# Restart high-memory Docker services (non-critical first)
echo ""
echo "=== Restarting High-Memory Services ==="
echo ""

# Restart monitoring services (usually safe to restart)
echo "Restarting monitoring services..."
restart_service "services-prometheus-1" || true
restart_service "services-grafana-1" || true
restart_service "services-loki-1" || true

# Restart non-critical application services
echo ""
echo "Restarting non-critical services..."
restart_service "services-n8n-1" || true
restart_service "services-portainer-1" || true

# Wait for services to stabilize
echo ""
echo "Waiting 30 seconds for services to stabilize..."
sleep 30

# Check memory after optimization
echo ""
echo "=== Memory Status After Optimization ==="
free -h
echo ""

# Calculate improvement
BEFORE_AVAIL=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
echo "Available memory: ${BEFORE_AVAIL} MB"
echo ""

echo "========================================="
echo "✅ Optimization Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Monitor memory usage for 15-30 minutes"
echo "2. Check service health: docker ps"
echo "3. Review logs if any services failed to start"
echo "4. Consider applying resource limits to prevent future issues"
