#!/bin/bash
# Monitor Auth0 Authentication Status
# Continuously checks logs and status until authentication is working

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=========================================="
echo "Auth0 Status Monitor"
echo "=========================================="
echo "Monitoring OAuth2-Proxy logs for successful authentications..."
echo "Press Ctrl+C to stop"
echo ""

# Track previous log count
LAST_LOG_COUNT=0
SUCCESS_COUNT=0
FAILURE_COUNT=0

while true; do
    # Get recent logs
    RECENT_LOGS=$(docker logs compose-oauth2-proxy-1 --tail 20 --since 30s 2>&1)
    
    # Count successful authentications
    SUCCESSES=$(echo "$RECENT_LOGS" | grep -i "authenticated\|success\|200" | wc -l)
    FAILURES=$(echo "$RECENT_LOGS" | grep -i "error\|failed\|403\|401" | grep -i "callback\|auth" | wc -l)
    
    # Check for callback requests with proper OAuth params
    CALLBACK_REQUESTS=$(echo "$RECENT_LOGS" | grep -i "callback" | grep -v "curl\|Error while loading CSRF" | wc -l)
    
    # Check for Auth0 redirects
    AUTH0_REDIRECTS=$(echo "$RECENT_LOGS" | grep -i "auth0\|authorize" | wc -l)
    
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$SUCCESSES" -gt 0 ] || [ "$CALLBACK_REQUESTS" -gt 0 ]; then
        echo "[$CURRENT_TIME] ✅ Activity detected:"
        echo "   - Successful authentications: $SUCCESSES"
        echo "   - Callback requests: $CALLBACK_REQUESTS"
        echo "   - Auth0 redirects: $AUTH0_REDIRECTS"
        
        if [ "$FAILURES" -gt 0 ]; then
            echo "   - Failures: $FAILURES"
        fi
        
        # Show recent relevant log entries
        echo ""
        echo "   Recent relevant logs:"
        echo "$RECENT_LOGS" | grep -i "callback\|authenticated\|error" | tail -3 | sed 's/^/      /'
        echo ""
    fi
    
    # Check for specific error patterns
    ERROR_PATTERNS=$(echo "$RECENT_LOGS" | grep -i "invalid.*callback\|callback.*not.*allowed\|unauthorized.*client" || echo "")
    if [ -n "$ERROR_PATTERNS" ]; then
        echo "[$CURRENT_TIME] ⚠️  Potential Auth0 configuration issue detected:"
        echo "$ERROR_PATTERNS" | sed 's/^/      /'
        echo ""
        echo "   This may indicate:"
        echo "   - Callback URL not configured in Auth0"
        echo "   - Client ID/Secret mismatch"
        echo "   - Auth0 application settings incorrect"
        echo ""
    fi
    
    sleep 10
done

