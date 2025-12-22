#!/bin/bash
# Debug script to monitor Auth0 authentication flow

LOG_FILE="/home/comzis/.cursor/debug.log"
SESSION_ID="debug-session-$(date +%s)"
RUN_ID="run1"

# Function to log debug information
log_debug() {
    local hypothesis_id=$1
    local location=$2
    local message=$3
    local data=$4
    
    echo "{\"sessionId\":\"$SESSION_ID\",\"runId\":\"$RUN_ID\",\"hypothesisId\":\"$hypothesis_id\",\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"timestamp\":$(date +%s000)}" >> "$LOG_FILE"
}

echo "=== Starting Auth0 Flow Monitoring ==="
log_debug "INIT" "debug-auth-flow.sh" "Monitoring started" "{\"sessionId\":\"$SESSION_ID\"}"

# Monitor OAuth2-Proxy logs in real-time
docker logs -f compose-oauth2-proxy-1 2>&1 | while IFS= read -r line; do
    # Hypothesis A: Check for callback requests
    if echo "$line" | grep -q "/oauth2/callback"; then
        log_debug "A" "oauth2-proxy:callback" "Callback request detected" "{\"logLine\":\"$(echo "$line" | jq -R .)\"}"
    fi
    
    # Hypothesis B: Check for redirect to Auth0
    if echo "$line" | grep -q "302\|redirect"; then
        log_debug "B" "oauth2-proxy:redirect" "Redirect detected" "{\"logLine\":\"$(echo "$line" | jq -R .)\"}"
    fi
    
    # Hypothesis C: Check for state parameter issues
    if echo "$line" | grep -qi "state\|State"; then
        log_debug "C" "oauth2-proxy:state" "State parameter found" "{\"logLine\":\"$(echo "$line" | jq -R .)\"}"
    fi
    
    # Hypothesis D: Check for errors
    if echo "$line" | grep -qiE "error|Error|ERROR|fail|Fail|FAIL"; then
        log_debug "D" "oauth2-proxy:error" "Error detected" "{\"logLine\":\"$(echo "$line" | jq -R .)\"}"
    fi
    
    # Hypothesis E: Check for 404 responses
    if echo "$line" | grep -q "404"; then
        log_debug "E" "oauth2-proxy:404" "404 response detected" "{\"logLine\":\"$(echo "$line" | jq -R .)\"}"
    fi
done

