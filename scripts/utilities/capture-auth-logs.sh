#!/bin/bash
# Capture Auth0 authentication flow logs for debugging

LOG_FILE="/home/comzis/.cursor/debug.log"
SESSION_ID="debug-session-$(date +%s)"
RUN_ID="run1"

# Function to log debug information in NDJSON format
log_debug() {
    local hypothesis_id=$1
    local location=$2
    local message=$3
    local data=$4
    local timestamp=$(date +%s000)
    
    # Escape JSON properly
    local escaped_data=$(echo "$data" | jq -c . 2>/dev/null || echo "\"$data\"")
    echo "{\"sessionId\":\"$SESSION_ID\",\"runId\":\"$RUN_ID\",\"hypothesisId\":\"$hypothesis_id\",\"location\":\"$location\",\"message\":\"$message\",\"data\":$escaped_data,\"timestamp\":$timestamp}" >> "$LOG_FILE"
}

echo "=== Capturing Auth0 Flow Logs ==="

# Capture recent OAuth2-Proxy logs
log_debug "INIT" "capture-auth-logs.sh" "Log capture started" "{\"timestamp\":\"$(date -Iseconds)\"}"

# Get recent auth endpoint calls
AUTH_CALLS=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep "/oauth2/auth" | tail -10)
AUTH_COUNT=$(echo "$AUTH_CALLS" | wc -l)
log_debug "H1" "oauth2-proxy:auth-calls" "Recent /oauth2/auth calls" "{\"count\":$AUTH_COUNT}"

# Check for callback attempts in OAuth2-Proxy
CALLBACK_CALLS=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep "/oauth2/callback")
if [ -z "$CALLBACK_CALLS" ]; then
    log_debug "H1" "oauth2-proxy:callback-missing" "No callback requests found in OAuth2-Proxy" "{\"observation\":\"No /oauth2/callback entries in logs\"}"
else
    CALLBACK_COUNT=$(echo "$CALLBACK_CALLS" | wc -l)
    log_debug "H1" "oauth2-proxy:callback-found" "Callback requests found" "{\"count\":$CALLBACK_COUNT}"
fi

# Check Traefik for callback attempts
TRAEFIK_CALLBACK=$(docker logs compose-traefik-1 --since 2m 2>&1 | grep "/oauth2/callback")
if [ -z "$TRAEFIK_CALLBACK" ]; then
    log_debug "H1" "traefik:callback-missing" "No callback requests found in Traefik" "{\"observation\":\"Callbacks not reaching Traefik\"}"
else
    TRAEFIK_CALLBACK_COUNT=$(echo "$TRAEFIK_CALLBACK" | wc -l)
    log_debug "H1" "traefik:callback-found" "Callback requests found in Traefik" "{\"count\":$TRAEFIK_CALLBACK_COUNT}"
fi

# Check for redirects to Auth0
REDIRECTS=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep -E "302|redirect")
REDIRECT_COUNT=$(echo "$REDIRECTS" | wc -l)
log_debug "H2" "oauth2-proxy:redirects" "Redirect responses" "{\"count\":$REDIRECT_COUNT}"

# Check /oauth2/start endpoint calls
START_CALLS=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep "/oauth2/start")
START_COUNT=$(echo "$START_CALLS" | wc -l)
log_debug "H2" "oauth2-proxy:start-calls" "/oauth2/start endpoint calls" "{\"count\":$START_COUNT}"

# Get configured redirect URL from .env
if [ -f ".env" ]; then
    CONFIG_REDIRECT=$(grep "OAUTH2_PROXY_REDIRECT_URL" .env | cut -d'=' -f2 | tr -d '"')
    log_debug "H1" "config:redirect-url" "Configured redirect URL" "{\"url\":\"$CONFIG_REDIRECT\"}"
fi

# Check Traefik forwardAuth logs
TRAEFIK_AUTH=$(docker logs compose-traefik-1 --since 2m 2>&1 | grep -E "oauth2|auth\.inlock")
TRAEFIK_AUTH_COUNT=$(echo "$TRAEFIK_AUTH" | wc -l)
log_debug "H3" "traefik:auth-requests" "Traefik auth requests" "{\"count\":$TRAEFIK_AUTH_COUNT}"

# Check for errors
ERRORS=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep -iE "error|Error|ERROR|fail|Fail" | tail -5)
if [ -n "$ERRORS" ]; then
    ERROR_COUNT=$(echo "$ERRORS" | wc -l)
    ERROR_SAMPLE=$(echo "$ERRORS" | head -1 | head -c 200)
    log_debug "H4" "oauth2-proxy:errors" "Errors detected" "{\"count\":$ERROR_COUNT,\"sample\":\"$ERROR_SAMPLE\"}"
fi

# Check for 404s
FOUR04=$(docker logs compose-oauth2-proxy-1 --since 2m 2>&1 | grep "404" | tail -5)
if [ -n "$FOUR04" ]; then
    FOUR04_COUNT=$(echo "$FOUR04" | wc -l)
    log_debug "H5" "oauth2-proxy:404" "404 responses" "{\"count\":$FOUR04_COUNT}"
fi

echo "Logs captured to $LOG_FILE"

