#!/bin/bash
# Verify RAM Upgrade Script
# Verifies that RAM upgrade was successful and system is stable

set -e

echo "========================================="
echo "RAM Upgrade Verification"
echo "========================================="
echo ""

# Expected RAM after upgrade (adjust based on upgrade plan)
EXPECTED_RAM_MIN=24  # Minimum expected RAM in GB
EXPECTED_RAM_MAX=32  # Maximum expected RAM in GB

# Get current RAM
TOTAL_RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/ {print $2}')
AVAILABLE_RAM_MB=$(free -m | awk '/^Mem:/ {print $7}')
AVAILABLE_RAM_PERCENT=$((AVAILABLE_RAM_MB * 100 / TOTAL_RAM_MB))

echo "=== RAM Status ==="
echo "Total RAM: ${TOTAL_RAM_GB} GB (${TOTAL_RAM_MB} MB)"
echo "Available RAM: ${AVAILABLE_RAM_MB} MB (${AVAILABLE_RAM_PERCENT}%)"
echo ""

# Check if RAM meets expectations
if [ "$TOTAL_RAM_GB" -ge "$EXPECTED_RAM_MIN" ] && [ "$TOTAL_RAM_GB" -le "$EXPECTED_RAM_MAX" ]; then
    echo "✅ RAM size is within expected range (${EXPECTED_RAM_MIN}-${EXPECTED_RAM_MAX} GB)"
else
    echo "⚠️  RAM size (${TOTAL_RAM_GB} GB) is outside expected range (${EXPECTED_RAM_MIN}-${EXPECTED_RAM_MAX} GB)"
fi
echo ""

# Check available RAM percentage
if [ "$AVAILABLE_RAM_PERCENT" -ge 30 ]; then
    echo "✅ Available RAM is healthy (>= 30%)"
elif [ "$AVAILABLE_RAM_PERCENT" -ge 20 ]; then
    echo "⚠️  Available RAM is moderate (20-30%)"
else
    echo "❌ Available RAM is low (< 20%)"
fi
echo ""

# Swap usage
SWAP_TOTAL_MB=$(free -m | awk '/^Swap:/ {print $2}')
SWAP_USED_MB=$(free -m | awk '/^Swap:/ {print $3}')
if [ "$SWAP_TOTAL_MB" -gt 0 ]; then
    SWAP_PERCENT=$((SWAP_USED_MB * 100 / SWAP_TOTAL_MB))
    echo "=== Swap Status ==="
    echo "Total Swap: ${SWAP_TOTAL_MB} MB"
    echo "Used Swap: ${SWAP_USED_MB} MB (${SWAP_PERCENT}%)"
    echo ""
    
    if [ "$SWAP_PERCENT" -lt 50 ]; then
        echo "✅ Swap usage is healthy (< 50%)"
    elif [ "$SWAP_PERCENT" -lt 80 ]; then
        echo "⚠️  Swap usage is moderate (50-80%)"
    else
        echo "❌ Swap usage is high (>= 80%)"
    fi
    echo ""
fi

# Load average
LOAD1=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
LOAD5=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $2}' | tr -d ',')
LOAD15=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $3}' | tr -d ',')
CPU_CORES=$(nproc)
LOAD_THRESHOLD=$((CPU_CORES * 2))

echo "=== Load Average ==="
echo "Load 1m: ${LOAD1}"
echo "Load 5m: ${LOAD5}"
echo "Load 15m: ${LOAD15}"
echo "CPU Cores: ${CPU_CORES}"
echo "Threshold (2x cores): ${LOAD_THRESHOLD}"
echo ""

if (( $(echo "$LOAD1 < $LOAD_THRESHOLD" | bc -l) )); then
    echo "✅ Load average is healthy (< ${LOAD_THRESHOLD})"
else
    echo "⚠️  Load average is high (>= ${LOAD_THRESHOLD})"
fi
echo ""

# OOM kill events (last 24 hours)
echo "=== OOM Kill Events (Last 24 Hours) ==="
OOM_COUNT=$(journalctl -k --since "24 hours ago" | grep -i "out of memory" | wc -l)
if [ "$OOM_COUNT" -eq 0 ]; then
    echo "✅ No OOM kill events in last 24 hours"
else
    echo "⚠️  Found ${OOM_COUNT} OOM kill event(s) in last 24 hours"
    echo "Recent events:"
    journalctl -k --since "24 hours ago" | grep -i "out of memory" | tail -5
fi
echo ""

# Critical service status
echo "=== Critical Service Status ==="
CRITICAL_SERVICES=("traefik" "coolify" "prometheus" "grafana" "postgres")
for service in "${CRITICAL_SERVICES[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${service}"; then
        STATUS=$(docker ps --format "{{.Status}}" --filter "name=^${service}$" | head -1)
        echo "✅ ${service}: ${STATUS}"
    else
        echo "❌ ${service}: Not running"
    fi
done
echo ""

# Summary
echo "========================================="
echo "Verification Summary"
echo "========================================="
echo ""
echo "RAM: ${TOTAL_RAM_GB} GB total, ${AVAILABLE_RAM_PERCENT}% available"
echo "Swap: ${SWAP_PERCENT}% used"
echo "Load: ${LOAD1} (threshold: ${LOAD_THRESHOLD})"
echo "OOM Events: ${OOM_COUNT} in last 24 hours"
echo ""

if [ "$TOTAL_RAM_GB" -ge "$EXPECTED_RAM_MIN" ] && \
   [ "$AVAILABLE_RAM_PERCENT" -ge 30 ] && \
   [ "$SWAP_PERCENT" -lt 50 ] && \
   (( $(echo "$LOAD1 < $LOAD_THRESHOLD" | bc -l) )) && \
   [ "$OOM_COUNT" -eq 0 ]; then
    echo "✅ RAM upgrade verification: PASSED"
    exit 0
else
    echo "⚠️  RAM upgrade verification: NEEDS ATTENTION"
    echo "   Review the details above"
    exit 1
fi
