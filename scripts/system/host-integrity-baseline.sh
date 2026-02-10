#!/usr/bin/env bash
# Capture host integrity baseline (checksums, listeners, docker, dpkg).
# Run once after known-good state; re-run to refresh baseline. No secrets in output.
# Usage: ./host-integrity-baseline.sh [BASELINE_DIR]

set -e

BASELINE_DIR="${1:-${BASELINE_DIR:-/home/comzis/backups/host-integrity/baseline}}"
mkdir -p "$BASELINE_DIR"
cd "$BASELINE_DIR"

echo "Baseline dir: $BASELINE_DIR"
echo "Date: $(date -Iseconds)"

# Critical files (checksum only; no content)
for f in /etc/passwd /etc/group /etc/crontab /etc/ssh/sshd_config; do
  if [[ -f "$f" ]]; then
    sha256sum "$f" > "$(basename "$f").sha256"
  fi
done

# Cron.d listing (names + mtime, no content)
ls -la /etc/cron.d/ 2>/dev/null > cron.d_list.txt

# authorized_keys: metadata only (line count, no keys)
for f in /root/.ssh/authorized_keys /home/comzis/.ssh/authorized_keys; do
  name=$(echo "$f" | tr '/' '_')
  if [[ -f "$f" ]]; then
    echo "lines=$(wc -l < "$f") path=$f" > "authorized_keys_meta_${name}.txt"
  fi
done

# Setuid/setgid
find /usr /bin /sbin /usr/local/bin -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort > setuid_setgid.txt

# dpkg verify (critical packages)
dpkg -V openssh-server sudo 2>/dev/null > dpkg_V.txt || true

# Listeners
ss -tulpen 2>/dev/null > ss_tulpen.txt

# Docker containers (names + status)
docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null > docker_ps.txt

# /tmp /var/tmp /dev/shm: executables or recent (no content)
find /tmp /var/tmp /dev/shm -type f \( -executable -o -name "*.sh" \) 2>/dev/null | sort > find_tmp_executable.txt
find /tmp /var/tmp /dev/shm -maxdepth 2 -type f -mtime -7 2>/dev/null | sort > find_tmp_recent7d.txt

echo "Baseline saved to $BASELINE_DIR"
ls -la "$BASELINE_DIR"
