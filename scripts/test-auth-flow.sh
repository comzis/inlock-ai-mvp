#!/bin/bash
# Helper script to monitor authentication flows during testing
# Usage: ./scripts/test-auth-flow.sh [oauth2-proxy|nextauth|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

MODE="${1:-all}"

echo "========================================="
echo "Authentication Flow Monitor"
echo "========================================="
echo ""
echo "Monitoring mode: $MODE"
echo "Press Ctrl+C to stop"
echo ""

case "$MODE" in
  oauth2-proxy)
    echo "📊 Monitoring OAuth2-Proxy (admin auth)..."
    docker logs -f compose-oauth2-proxy-1 2>&1 | grep -E "GET|POST|302|401|redirect|auth0|error|Error" --color=always
    ;;
  nextauth)
    echo "📊 Monitoring NextAuth.js (frontend auth)..."
    docker logs -f compose-inlock-ai-1 2>&1 | grep -E "auth|Auth|signin|callback|error|Error|session|Session" --color=always
    ;;
  all)
    echo "📊 Monitoring all authentication services..."
    docker compose -f compose/stack.yml --env-file .env logs -f oauth2-proxy inlock-ai traefik 2>&1 | \
      grep -E "GET|POST|302|401|redirect|auth0|auth|Auth|signin|callback|error|Error|session|Session" --color=always
    ;;
  *)
    echo "Usage: $0 [oauth2-proxy|nextauth|all]"
    exit 1
    ;;
esac

