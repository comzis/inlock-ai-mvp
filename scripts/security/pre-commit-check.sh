#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "ERROR: Not inside a git repository."
  exit 1
fi
cd "$repo_root"

staged_files="$(git diff --cached --name-only --diff-filter=ACMR)"
if [[ -z "$staged_files" ]]; then
  echo "No staged files to check."
  exit 0
fi

fail=0
warn=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  base="${file##*/}"

  if [[ "$base" == ".env" ]]; then
    echo "ERROR: .env file staged: $file"
    fail=1
  elif [[ "$base" == ".env."* ]]; then
    ext="${base#.env.}"
    case "$ext" in
      example|sample|template) ;;
      *)
        echo "ERROR: .env.* file staged (allowed: .env.example/.env.sample/.env.template): $file"
        fail=1
        ;;
    esac
  fi

  if [[ "$file" == secrets/* ]]; then
    if [[ "$file" != *.example ]]; then
      echo "ERROR: secrets/ file staged without .example extension: $file"
      fail=1
    fi
  fi
done <<< "$staged_files"

added_lines="$(git diff --cached -U0 --no-color | sed -n '/^\+[^+]/p' | cut -c2-)"
if [[ -n "$added_lines" ]]; then
  secret_pattern='(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|xox[baprs]-[0-9A-Za-z-]{10,48}|sk_live_[0-9A-Za-z]{24}|AIza[0-9A-Za-z_-]{35}|-----BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY-----|-----BEGIN PRIVATE KEY-----)'
  secret_hits="$(printf '%s\n' "$added_lines" | grep -E -n "$secret_pattern" || true)"
  if [[ -n "$secret_hits" ]]; then
    echo "ERROR: Potential secret patterns detected in staged additions:"
    echo "$secret_hits"
    fail=1
  fi
fi

if ! git check-ignore -q .env >/dev/null 2>&1; then
  echo "WARN: .env is not ignored by git; ensure .env is in .gitignore."
  warn=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo ""
  echo "Pre-commit check failed. Remove or sanitize the files above."
  exit 1
fi

echo "OK: Basic pre-commit security checks passed."
echo "Reminder (manual checks if applicable):"
echo "- Firewall/SSH/sudo changes approved and documented"
echo "- Auth0/OAuth2 flow still works"
echo "- Network isolation preserved"
echo "- No secrets in docs/configs"

if [[ "$warn" -ne 0 ]]; then
  echo ""
  echo "Warnings were reported above."
fi
