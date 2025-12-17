#!/bin/bash
# scripts/health_check_remote.sh
# Verifies that key services are responsive over HTTP
# Usage: ./health_check_remote.sh

set -e

# List of URLs to check
URLS=(
    "https://inlock.ai"
    "https://auth.inlock.ai/ping"
    # "https://n8n.inlock.ai/healthz" # N8N health endpoint - authenticated, so maybe just check root
    "https://n8n.inlock.ai"
)

echo "Starting Remote Health Check..."

ERRORS=0

for url in "${URLS[@]}"; do
    echo -n "Checking $url ... "
    # Using curl to fetch headers only, following redirects, max time 10s
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url")

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "403" ]]; then
        # 401/403 are acceptable for protected endpoints (means server is up)
        echo "OK ($HTTP_CODE)"
    else
        echo "FAIL ($HTTP_CODE)"
        ERRORS=$((ERRORS+1))
    fi
done

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ All checks passed."
    exit 0
else
    echo "❌ $ERRORS checks failed."
    exit 1
fi
