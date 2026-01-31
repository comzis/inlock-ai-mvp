#!/bin/bash
# Check access logs for inlock.ai (Traefik and optionally Cloudflare).
# Run on the server where Traefik is running:
#   ./scripts/check-inlock-ai-access-logs.sh [--follow] [--lines N]
#
# Examples:
#   ./scripts/check-inlock-ai-access-logs.sh              # last 100 lines for inlock.ai
#   ./scripts/check-inlock-ai-access-logs.sh --lines 500  # last 500 lines
#   ./scripts/check-inlock-ai-access-logs.sh --follow     # tail -f style

set -euo pipefail

LINES=100
FOLLOW=""

while [ $# -gt 0 ]; do
  case "$1" in
    --follow) FOLLOW="--follow"; shift ;;
    --lines)  LINES="$2"; shift 2 ;;
    *) break ;;
  esac
done

# Find Traefik container
TRAEFIK_CONTAINER=""
if command -v docker >/dev/null 2>&1; then
  TRAEFIK_CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i traefik | head -1)
fi

echo "=== Access logs for inlock.ai / www.inlock.ai ==="
echo ""

if [ -z "$TRAEFIK_CONTAINER" ]; then
  echo "Traefik container not found (docker not available or Traefik not running)." >&2
  echo "" >&2
  echo "On the server, run:" >&2
  echo "  docker ps | grep traefik" >&2
  echo "  docker logs <traefik-container> --tail $LINES 2>&1 | grep -E 'inlock\\.ai|www\\.inlock'" >&2
  exit 1
fi

echo "Traefik container: $TRAEFIK_CONTAINER"
echo "Filter: Host inlock.ai or www.inlock.ai"
echo ""

if [ -n "$FOLLOW" ]; then
  echo "Following logs (Ctrl+C to stop)..."
  docker logs "$TRAEFIK_CONTAINER" --tail 50 $FOLLOW 2>&1 | grep --line-buffered -E '"RequestHost":"(inlock\.ai|www\.inlock\.ai)"|"RequestHost":"[^"]*inlock\.ai"'
else
  docker logs "$TRAEFIK_CONTAINER" --tail "$LINES" 2>&1 | grep -E '"RequestHost":"(inlock\.ai|www\.inlock\.ai)"|"RequestHost":"[^"]*inlock\.ai"' || true
  echo ""
  echo "--- Summary (last $LINES log lines) ---"
  echo "If no lines above, no requests to inlock.ai in that window."
  echo ""
  echo "To see more: $0 --lines 500"
  echo "To follow:   $0 --follow"
fi
