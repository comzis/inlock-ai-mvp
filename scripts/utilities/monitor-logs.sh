#!/bin/bash
# Real-time log monitor for E2E testing

echo "=== Monitoring OAuth2-Proxy Logs ==="
echo "Press Ctrl+C to stop"
echo ""
echo "Starting log tail at $(date)..."
echo ""

docker compose -f compose/stack.yml --env-file .env logs -f oauth2-proxy 2>/dev/null
