#!/usr/bin/env bash
# Integrity diff check: compare current checksums of critical paths to a baseline.
# Outputs "Integrity diff: no changes" or "Integrity diff: changes detected" plus
# the list of changed files, for use in daily host status reports.
#
# Usage:
#   ./integrity-diff-check.sh              # compare to baseline (or create baseline if missing)
#   ./integrity-diff-check.sh --init        # create/update baseline only
#   ./integrity-diff-check.sh --paths FILE  # use custom paths file (one path per line)
#
# Paths checked by default (if --paths not given): /etc (excluding volatile),
# REPO_ROOT/config, REPO_ROOT/traefik, REPO_ROOT/compose/services (key config only).
# Run from repo root or set INLOCK_REPO_ROOT.
#
# Cron example (daily at 06:00, append to report):
#   0 6 * * * root INLOCK_REPO_ROOT=/home/comzis/inlock /home/comzis/inlock/ops/security/integrity-diff-check.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${INLOCK_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
BASELINE_DIR="${INTEGRITY_BASELINE_DIR:-/var/lib/inlock-integrity}"
BASELINE_FILE="$BASELINE_DIR/baseline.sha256"
PATHS_FILE=""

# Paths to include in baseline (relative to REPO_ROOT or absolute). Sensitive config only.
default_paths() {
  echo "/etc/ssh/sshd_config"
  echo "/etc/ssh/sshd_config.d"
  echo "/etc/cron.d"
  [ -d "$REPO_ROOT/config" ] && find "$REPO_ROOT/config" -maxdepth 3 -type f 2>/dev/null | head -200
  [ -d "$REPO_ROOT/traefik/dynamic" ] && find "$REPO_ROOT/traefik/dynamic" -type f 2>/dev/null
  [ -d "$REPO_ROOT/compose/services" ] && find "$REPO_ROOT/compose/services" -maxdepth 1 -name "*.yml" 2>/dev/null
}

# Build list of files to checksum (skip dirs we can't read, log rotation, volatile)
collect_paths() {
  if [[ -n "$PATHS_FILE" && -f "$PATHS_FILE" ]]; then
    cat "$PATHS_FILE"
    return
  fi
  default_paths | while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if [[ "$p" != /* ]]; then
      p="$REPO_ROOT/$p"
    fi
    if [[ -f "$p" ]]; then
      echo "$p"
    elif [[ -d "$p" ]]; then
      find "$p" -type f 2>/dev/null | grep -v -E '\.(log|tmp|bak|swp)$' || true
    fi
  done | sort -u
}

do_init() {
  mkdir -p "$BASELINE_DIR"
  tmp="$(mktemp)"
  collect_paths | while IFS= read -r f; do
    [[ -r "$f" ]] && sha256sum "$f" 2>/dev/null || true
  done | sort -k2 > "$tmp"
  mv "$tmp" "$BASELINE_FILE"
  echo "Integrity diff: baseline created ($(wc -l < "$BASELINE_FILE") entries)."
}

do_check() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    do_init
    return 0
  fi
  tmp_current="$(mktemp)"
  trap "rm -f $tmp_current" EXIT
  collect_paths | while IFS= read -r f; do
    [[ -r "$f" ]] && sha256sum "$f" 2>/dev/null || true
  done | sort -k2 > "$tmp_current"

  if diff -q "$BASELINE_FILE" "$tmp_current" >/dev/null 2>&1; then
    echo "Integrity diff: no changes"
  else
    echo "Integrity diff: changes detected"
    # Path in sha256sum output: "< HASH  PATH" / "> HASH  PATH" (path starts at column 69)
    diff "$BASELINE_FILE" "$tmp_current" 2>/dev/null | grep -E '^[<>]' | awk '{path=substr($0,69); gsub(/^ +| +$/,"",path); print path}' | sort -u || true
  fi
}

# Human-readable report: show each changed file and whether it was added, removed, or changed
do_show() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo "No baseline found. Run: $0 --init" >&2
    exit 1
  fi
  tmp_current="$(mktemp)"
  trap "rm -f $tmp_current" EXIT
  collect_paths | while IFS= read -r f; do
    [[ -r "$f" ]] && sha256sum "$f" 2>/dev/null || true
  done | sort -k2 > "$tmp_current"

  echo "=== Integrity diff report (baseline vs current) ==="
  echo ""

  # diff lines: "< HASH  PATH" or "> HASH  PATH" (HASH = 64 chars, then 2 spaces, then path)
  diff "$BASELINE_FILE" "$tmp_current" 2>/dev/null | awk '
    /^</ { path = substr($0, 69); gsub(/^ +| +$/, "", path); baseline_line[path] = substr($0, 4, 64); next }
    /^>/ { path = substr($0, 69); gsub(/^ +| +$/, "", path); current_line[path] = substr($0, 4, 64); next }
  END {
    for (path in baseline_line) {
      if (path in current_line) {
        if (baseline_line[path] != current_line[path]) changed[path] = 1;
      } else {
        removed[path] = 1;
      }
    }
    for (path in current_line) if (!(path in baseline_line)) added[path] = 1;

    if (length(removed) > 0) {
      print "--- REMOVED or no longer readable (in baseline, not in current) ---";
      n = asorti(removed, sorted);
      for (i = 1; i <= n; i++) print "  " sorted[i];
      print "";
    }
    if (length(added) > 0) {
      print "--- NEW (in current, not in baseline) ---";
      n = asorti(added, sorted);
      for (i = 1; i <= n; i++) print "  " sorted[i];
      print "";
    }
    if (length(changed) > 0) {
      print "--- CHANGED (content differs) ---";
      n = asorti(changed, sorted);
      for (i = 1; i <= n; i++) print "  " sorted[i];
    }
  }'

  # Fallback: if awk failed or no output, list all differing paths
  diff -q "$BASELINE_FILE" "$tmp_current" >/dev/null 2>&1 || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init)
      do_init
      exit 0
      ;;
    --show)
      do_show
      exit 0
      ;;
    --paths)
      PATHS_FILE="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--init] [--show] [--paths FILE]" >&2
      exit 1
      ;;
  esac
done

do_check
