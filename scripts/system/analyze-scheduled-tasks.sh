#!/bin/bash
# Analyze Scheduled Tasks Script
# Identifies cron jobs, systemd timers, and Docker container scheduled tasks
# to help identify batch workloads causing load spikes

set -e

echo "========================================="
echo "Scheduled Tasks Analysis"
echo "========================================="
echo ""

# System cron jobs
echo "=== System Cron Jobs (/etc/cron.*) ==="
echo ""
if [ -d /etc/cron.d ]; then
    echo "Cron.d jobs:"
    ls -la /etc/cron.d/ 2>/dev/null | grep -v "^total" || echo "  (none)"
    echo ""
    for file in /etc/cron.d/*; do
        if [ -f "$file" ]; then
            echo "--- $file ---"
            cat "$file" 2>/dev/null | grep -v "^#" | grep -v "^$" || echo "  (empty)"
            echo ""
        fi
    done
fi

if [ -f /etc/crontab ]; then
    echo "System crontab (/etc/crontab):"
    cat /etc/crontab | grep -v "^#" | grep -v "^$" || echo "  (empty)"
    echo ""
fi

# User cron jobs
echo "=== User Cron Jobs ==="
echo ""
for user in $(cut -f1 -d: /etc/passwd); do
    crontab_file=$(crontab -u "$user" -l 2>/dev/null || echo "")
    if [ -n "$crontab_file" ]; then
        echo "User: $user"
        echo "$crontab_file" | grep -v "^#" | grep -v "^$" || echo "  (empty)"
        echo ""
    fi
done

# Systemd timers
echo "=== Systemd Timers ==="
echo ""
systemctl list-timers --all --no-pager 2>/dev/null || echo "  (unable to list timers)"
echo ""

# Systemd services with OnCalendar
echo "=== Systemd Services with Scheduled Tasks ==="
echo ""
systemctl list-units --type=service --all --no-pager 2>/dev/null | grep -E "\.(timer|service)" | while read -r line; do
    unit=$(echo "$line" | awk '{print $1}')
    if systemctl show "$unit" 2>/dev/null | grep -q "OnCalendar="; then
        echo "--- $unit ---"
        systemctl show "$unit" 2>/dev/null | grep "OnCalendar=" || echo "  (no schedule)"
        echo ""
    fi
done

# Docker container cron jobs
echo "=== Docker Container Scheduled Tasks ==="
echo ""
echo "Checking running containers for cron/cron-like processes..."
docker ps --format "{{.Names}}" | while read -r container; do
    echo "--- Container: $container ---"
    # Check for cron processes
    cron_procs=$(docker exec "$container" ps aux 2>/dev/null | grep -E "(cron|atd|anacron)" | grep -v grep || echo "")
    if [ -n "$cron_procs" ]; then
        echo "$cron_procs"
    else
        echo "  (no cron processes)"
    fi
    
    # Check common cron directories
    for cron_dir in /etc/cron.d /var/spool/cron /etc/crontabs; do
        if docker exec "$container" test -d "$cron_dir" 2>/dev/null; then
            echo "  Found cron directory: $cron_dir"
            docker exec "$container" ls -la "$cron_dir" 2>/dev/null | head -10 || echo "    (empty)"
        fi
    done
    echo ""
done

# Check for common batch job patterns
echo "=== Common Batch Job Patterns ==="
echo ""
echo "Checking for common batch job indicators..."
echo ""

# Logrotate
if [ -f /etc/logrotate.conf ]; then
    echo "Logrotate configuration:"
    grep -v "^#" /etc/logrotate.conf | grep -v "^$" | head -5 || echo "  (default)"
    echo ""
fi

# Updatedb (locate database)
if systemctl is-enabled mlocate 2>/dev/null | grep -q enabled; then
    echo "mlocate (updatedb) is enabled - runs daily"
    echo ""
fi

# Apticron (package updates)
if [ -f /etc/apticron/apticron.conf ]; then
    echo "apticron is configured - checks for updates"
    echo ""
fi

# Docker cleanup jobs
echo "Docker cleanup/system prune jobs:"
docker ps -a --format "{{.Names}}" | grep -E "(cleanup|prune|backup)" || echo "  (none found)"
echo ""

echo "========================================="
echo "Analysis Complete"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Review output above for high-frequency jobs"
echo "2. Consider rescheduling heavy tasks to off-peak hours"
echo "3. Check system load during identified job execution times"
echo ""
