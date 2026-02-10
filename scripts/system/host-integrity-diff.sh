#!/usr/bin/env bash
# Diff current host state against integrity baseline. Saves diff with date. No secrets.
# Usage: ./host-integrity-diff.sh [BASELINE_DIR] [OUTPUT_DIR]
# Run weekly (e.g. cron) after host-integrity-baseline.sh has been run once.

set -e

BASELINE_DIR="${1:-${BASELINE_DIR:-/home/comzis/backups/host-integrity/baseline}}"
OUTPUT_DIR="${2:-${OUTPUT_DIR:-/home/comzis/backups/host-integrity/diffs}}"
DATE=$(date +%Y%m%d-%H%M%S)
CURRENT_DIR=$(mktemp -d)
DIFF_FILE="${OUTPUT_DIR}/host-integrity-diff-${DATE}.txt"

mkdir -p "$OUTPUT_DIR"

cleanup() { rm -rf "$CURRENT_DIR"; }
trap cleanup EXIT

if [[ ! -d "$BASELINE_DIR" ]] || [[ -z "$(ls -A "$BASELINE_DIR" 2>/dev/null)" ]]; then
  echo "No baseline at $BASELINE_DIR. Run host-integrity-baseline.sh first."
  exit 1
fi

# Regenerate current state into CURRENT_DIR (same layout as baseline)
cd "$CURRENT_DIR"
for f in /etc/passwd /etc/group /etc/crontab /etc/ssh/sshd_config; do
  if [[ -f "$f" ]]; then
    sha256sum "$f" > "$(basename "$f").sha256"
  fi
done
ls -la /etc/cron.d/ 2>/dev/null > cron.d_list.txt
for f in /root/.ssh/authorized_keys /home/comzis/.ssh/authorized_keys; do
  name=$(echo "$f" | tr '/' '_')
  if [[ -f "$f" ]]; then
    echo "lines=$(wc -l < "$f") path=$f" > "authorized_keys_meta_${name}.txt"
  fi
done
find /usr /bin /sbin /usr/local/bin -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort > setuid_setgid.txt
dpkg -V openssh-server sudo 2>/dev/null > dpkg_V.txt || true
ss -tulpen 2>/dev/null > ss_tulpen.txt
docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null > docker_ps.txt
find /tmp /var/tmp /dev/shm -type f \( -executable -o -name "*.sh" \) 2>/dev/null | sort > find_tmp_executable.txt
find /tmp /var/tmp /dev/shm -maxdepth 2 -type f -mtime -7 2>/dev/null | sort > find_tmp_recent7d.txt

# Diff each file
{
  echo "=== Host integrity diff $DATE ==="
  echo "Baseline: $BASELINE_DIR"
  echo ""

  for f in "$BASELINE_DIR"/*.txt "$BASELINE_DIR"/*.sha256; do
    [[ -f "$f" ]] || continue
    b=$(basename "$f")
    if [[ -f "$CURRENT_DIR/$b" ]]; then
      if ! diff -q "$BASELINE_DIR/$b" "$CURRENT_DIR/$b" >/dev/null 2>&1; then
        echo "--- CHANGED: $b ---"
        diff "$BASELINE_DIR/$b" "$CURRENT_DIR/$b" || true
        echo ""
      fi
    else
      echo "--- MISSING in current: $b ---"
      echo ""
    fi
  done

  # Files in current but not in baseline (new)
  for f in "$CURRENT_DIR"/*; do
    b=$(basename "$f")
    if [[ ! -f "$BASELINE_DIR/$b" ]]; then
      echo "--- NEW in current: $b ---"
      echo ""
    fi
  done

  echo "=== End diff ==="
} > "$DIFF_FILE"

if grep -q "CHANGED\|MISSING\|NEW in current" "$DIFF_FILE"; then
  echo "Differences found. See $DIFF_FILE"
  cat "$DIFF_FILE"
  exit 1
else
  echo "No differences from baseline. Output: $DIFF_FILE"
  echo "No differences from baseline." >> "$DIFF_FILE"
  exit 0
fi
