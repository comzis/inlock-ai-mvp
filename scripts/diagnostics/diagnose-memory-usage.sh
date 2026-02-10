#!/bin/bash
# Memory Usage Diagnosis Script
# Identifies top memory consumers and OOM kill patterns

set -euo pipefail

echo "========================================="
echo "Memory Usage Diagnosis"
echo "========================================="
echo ""

# System Memory Overview
echo "=== System Memory Overview ==="
free -h
echo ""

# Top Memory Consumers (Processes)
echo "=== Top 20 Memory Consuming Processes ==="
ps aux --sort=-%mem | head -21
echo ""

# Docker Container Memory Usage
echo "=== Docker Container Memory Usage ==="
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}' 2>/dev/null | head -30 || echo "Docker not available or no containers running"
echo ""

# OOM Kill Events
echo "=== Recent OOM Kill Events (Kernel Log) ==="
if dmesg 2>/dev/null | grep -i "out of memory" | tail -20; then
    echo ""
else
    echo "No OOM events found in dmesg"
fi
echo ""

echo "=== Recent OOM Kill Events (Journal) ==="
if journalctl -k --no-pager 2>/dev/null | grep -i oom | tail -20; then
    echo ""
else
    echo "No OOM events found in journal"
fi
echo ""

# Memory by Service Group
echo "=== Memory Usage by Service Group ==="
echo "Mailcow services:"
docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' 2>/dev/null | grep -i mailcow | head -10 || echo "No Mailcow containers found"
echo ""

echo "Monitoring services:"
docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' 2>/dev/null | grep -E 'prometheus|grafana|loki|alertmanager' | head -10 || echo "No monitoring containers found"
echo ""

echo "Application services:"
docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}' 2>/dev/null | grep -E 'inlock|coolify|n8n' | head -10 || echo "No application containers found"
echo ""

# Swap Usage Details
echo "=== Swap Usage Details ==="
swapon --show
echo ""
echo "Swap usage percentage:"
awk '/SwapTotal/ {total=$2} /SwapFree/ {free=$2} END {if (total>0) printf "%.1f%% used\n", (total-free)/total*100; else print "No swap"}' /proc/meminfo
echo ""

# Memory Pressure Indicators
echo "=== Memory Pressure Indicators ==="
echo "Available memory:"
awk '/MemAvailable/ {printf "%.2f GB\n", $2/1024/1024}' /proc/meminfo
echo ""

echo "Memory pressure (from /proc/pressure/memory):"
if [ -f /proc/pressure/memory ]; then
    cat /proc/pressure/memory
else
    echo "Memory pressure stats not available (kernel < 5.2)"
fi
echo ""

# Recommendations
echo "=== Recommendations ==="
AVAILABLE_MB=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
TOTAL_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
AVAILABLE_PERCENT=$((AVAILABLE_MB * 100 / TOTAL_MB))

if [ "$AVAILABLE_PERCENT" -lt 10 ]; then
    echo "🚨 CRITICAL: Available memory < 10%"
    echo "   - Immediate action required"
    echo "   - Consider restarting high-memory services"
    echo "   - Expand swap space if not already done"
elif [ "$AVAILABLE_PERCENT" -lt 20 ]; then
    echo "⚠️  WARNING: Available memory < 20%"
    echo "   - Monitor closely"
    echo "   - Consider optimizing services"
else
    echo "✅ Memory status: Acceptable (${AVAILABLE_PERCENT}% available)"
fi
echo ""

echo "========================================="
echo "Diagnosis Complete"
echo "========================================="
