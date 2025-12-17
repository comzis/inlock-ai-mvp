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

MAX_RETRIES=18 # 18 * 10s = 3 minutes
SLEEP_TIME=10

for url in "${URLS[@]}"; do
    echo "Checking $url ..."
    
    ATTEMPT=1
    SUCCESS=false

    while [ $ATTEMPT -le $MAX_RETRIES ]; do
        # Using curl to fetch headers only, following redirects, max time 10s, insecure (internal check)
        HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url")

        if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "302" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "403" ]]; then
            echo "  ✅ OK ($HTTP_CODE)"
            SUCCESS=true
            break
        else
            echo "  ⚠️  Attempt $ATTEMPT/$MAX_RETRIES: Failed ($HTTP_CODE). Retrying in ${SLEEP_TIME}s..."
            sleep $SLEEP_TIME
            ATTEMPT=$((ATTEMPT+1))
        fi
    done

    if [ "$SUCCESS" = false ]; then
        echo "❌ Failed to reach $url after $MAX_RETRIES attempts."
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
