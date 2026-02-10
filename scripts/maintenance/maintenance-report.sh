#!/bin/bash
# =============================================================================
# Maintenance Report Viewer
# =============================================================================
# View the latest or a specific maintenance report.
#
# Usage:
#   ./maintenance-report.sh                  # show latest daily check
#   ./maintenance-report.sh --rollout        # show latest rollout report
#   ./maintenance-report.sh --all            # list all reports
#   ./maintenance-report.sh --date 2026-02-10  # show specific date
# =============================================================================
set -euo pipefail

REPORT_DIR="/home/comzis/logs/maintenance"
MODE="latest-check"
TARGET_DATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rollout)  MODE="latest-rollout"; shift ;;
    --all)      MODE="list"; shift ;;
    --date)     MODE="date"; TARGET_DATE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--rollout | --all | --date YYYY-MM-DD]"
      exit 0
      ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d "$REPORT_DIR" ]; then
  echo "No reports found (directory does not exist: $REPORT_DIR)"
  exit 0
fi

case "$MODE" in
  list)
    echo "=== Daily Checks ==="
    ls -1t "$REPORT_DIR"/check-*.md 2>/dev/null || echo "  (none)"
    echo ""
    echo "=== Rollout Reports ==="
    for d in $(ls -1dt "$REPORT_DIR"/rollout-* 2>/dev/null); do
      if [ -f "$d/report.md" ]; then
        status="$(grep -m1 'Status:' "$d/report.md" | sed 's/.*\*\*//;s/\*\*//' || echo "?")"
        echo "  $d/report.md  [$status]"
      fi
    done
    ;;

  latest-check)
    latest="$(ls -1t "$REPORT_DIR"/check-*.md 2>/dev/null | head -1)"
    if [ -z "$latest" ]; then
      echo "No daily check reports found."
      echo "Run: ./scripts/maintenance/daily-update-check.sh"
      exit 0
    fi
    cat "$latest"
    ;;

  latest-rollout)
    latest=""
    for d in $(ls -1dt "$REPORT_DIR"/rollout-* 2>/dev/null); do
      if [ -f "$d/report.md" ]; then
        latest="$d/report.md"
        break
      fi
    done
    if [ -z "$latest" ]; then
      echo "No rollout reports found."
      exit 0
    fi
    cat "$latest"
    ;;

  date)
    # Try daily check first, then rollout
    if [ -f "$REPORT_DIR/check-$TARGET_DATE.md" ]; then
      cat "$REPORT_DIR/check-$TARGET_DATE.md"
    else
      found=false
      for d in "$REPORT_DIR"/rollout-"$TARGET_DATE"-*; do
        if [ -f "$d/report.md" ]; then
          cat "$d/report.md"
          found=true
          break
        fi
      done
      if [ "$found" = false ]; then
        echo "No report found for $TARGET_DATE"
        exit 1
      fi
    fi
    ;;
esac
