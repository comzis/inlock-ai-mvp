#!/bin/bash
# Pre-commit hook: block commits that contain mailcow.conf or secret patterns (DBPASS=, etc.).
# Install: cp ops/security/pre-commit-secrets-blocker.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# If you already have a pre-commit hook, chain this: run this script first from your hook and exit with its status.
set -euo pipefail

BLOCKED_PATTERNS="DBPASS=|DBROOT=|REDISPASS=|SOGO_URL_ENCRYPTION_KEY="
ALLOWLIST_GREP="docs/|\.md$|\.example$|SERVER-SECURITY-AUDIT|CHANGES-|remediation|pre-commit-secrets-blocker"

# Block if mailcow.conf (or path containing it) is staged
if git diff --cached --name-only | grep -qE "mailcow\.conf$|/mailcow\.conf$"; then
  echo "Blocked: mailcow.conf must not be committed."
  exit 1
fi

# Block if staged diff contains secret-like assignments (allowlist: docs, .md, .example, audit docs)
STAGED_FILES=$(git diff --cached --name-only)
while IFS= read -r path; do
  [ -z "$path" ] && continue
  # Allowlist: docs and audit-related files that may mention variable names only
  if echo "$path" | grep -qE "$ALLOWLIST_GREP"; then
    continue
  fi
  if git diff --cached -- "$path" | grep -qE "$BLOCKED_PATTERNS"; then
    echo "Blocked: possible secret in staged file: $path"
    exit 1
  fi
done <<< "$STAGED_FILES"

exit 0
