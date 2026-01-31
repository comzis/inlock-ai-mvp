#!/bin/bash
# Check Traefik access logs for mail + inlock.ai (when adding email on MacBook).
# Run on the server while you add your email account on the MacBook to see which
# requests reach the server and which are blocked (e.g. at Cloudflare).
#
# Usage:
#   ./scripts/check-mail-access-logs.sh [--follow] [--lines N]
#
# When adding email on MacBook, macOS Mail typically hits:
#   - autodiscover.inlock.ai, autoconfig.inlock.ai (autodiscover)
#   - mail.inlock.ai (IMAP/SMTP/HTTP)
#   - inlock.ai (some clients try the main domain for autodiscover)

set -euo pipefail

LINES=200
FOLLOW=""

while [ $# -gt 0 ]; do
  case "$1" in
    --follow) FOLLOW="--follow"; shift ;;
    --lines)  LINES="$2"; shift 2 ;;
    *) break ;;
  esac
done

TRAEFIK_CONTAINER=""
if command -v docker >/dev/null 2>&1; then
  TRAEFIK_CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i traefik | head -1)
fi

if [ -z "$TRAEFIK_CONTAINER" ]; then
  echo "Traefik container not found." >&2
  exit 1
fi

echo "=== Access logs: mail + inlock.ai (last $LINES lines) ==="
echo "Hosts: mail.inlock.ai, autodiscover, autoconfig, mta-sts, webmail, inlock.ai, www.inlock.ai"
echo "Traefik container: $TRAEFIK_CONTAINER"
echo ""

# Match RequestHost for mail-related and main site
PATTERN='"RequestHost":"(mail\.inlock\.ai|autodiscover\.inlock\.ai|autoconfig\.inlock\.ai|mta-sts\.inlock\.ai|webmail\.inlock\.ai|inlock\.ai|www\.inlock\.ai)"'

if [ -n "$FOLLOW" ]; then
  echo "Following (add your email on MacBook now; Ctrl+C to stop)..."
  docker logs "$TRAEFIK_CONTAINER" --tail 100 $FOLLOW 2>&1 | grep --line-buffered -E "$PATTERN"
else
  docker logs "$TRAEFIK_CONTAINER" --tail "$LINES" 2>&1 | grep -E "$PATTERN" || true
  echo ""
  echo "--- By ClientHost (who connected) ---"
  docker logs "$TRAEFIK_CONTAINER" --tail "$LINES" 2>&1 | grep -E "$PATTERN" | grep -oE '"ClientHost":"[^"]*"' | sort | uniq -c | sort -rn || true
  echo ""
  echo "If you see no lines (or no 31.10.147.220), the block is before Traefik (e.g. Cloudflare)."
  echo "Run with --follow while adding the account: $0 --follow"
fi
