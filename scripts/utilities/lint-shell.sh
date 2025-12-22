#!/usr/bin/env bash
set -euo pipefail

# Shell script linting helper (shellcheck)
# Usage: ./scripts/lint-shell.sh [files...]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "❌ shellcheck not installed. Install it (e.g., apt-get install shellcheck) and rerun."
  exit 1
fi

if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  mapfile -t TARGETS < <(find scripts -type f -name "*.sh" | sort)
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No shell scripts found."
  exit 0
fi

echo "Running shellcheck on ${#TARGETS[@]} script(s)..."
shellcheck -x "${TARGETS[@]}"
echo "✅ shellcheck completed without errors."
