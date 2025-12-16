#!/bin/bash
# Inlock AI Self-Healing Script
# Checks website status and restarts container if down.
# Usage: ./self_heal.sh [URL] [CONTAINER_NAME]

# Default Configuration
URL="${1:-https://inlock.ai}"
CONTAINER="${2:-compose-inlock-ai-1}"
LOG_FILE="/home/comzis/self_heal.log"
LOCK_FILE="/tmp/self_heal.lock"

# SMTP Configuration
TO_EMAIL="admin@inlock.ai"
SMTP_HOST="localhost"
SMTP_PORT="25"
SMTP_USER="admin@inlock.ai"
# SMTP_PASS must be set in the environment

# 1. Lock Mechanism
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "[$(date)] Script is already running. Exiting." >> "$LOG_FILE"; exit 1; }

# 2. Secure Password Check
if [ -z "$SMTP_PASS" ]; then
    echo "[$(date)] ERROR: SMTP_PASS environment variable is not set." >> "$LOG_FILE"
    # We continue but email sending will likely fail
fi

send_email() {
  local status_code=$1
  local subject="[Self-Healing] Service Restarted: $CONTAINER"
  local body="Critical Alert:\nThe website $URL returned status $status_code.\nThe container $CONTAINER has been restarted automatically by the self-healing script.\nTime: $(date)"
  
  # Send via curl (forcing insecure for local self-signed certs)
  if [ -n "$SMTP_PASS" ]; then
      curl --url "smtp://$SMTP_HOST:$SMTP_PORT" \
           --mail-from "$SMTP_USER" \
           --mail-rcpt "$TO_EMAIL" \
           --user "$SMTP_USER:$SMTP_PASS" \
           -T <(echo -e "From: System Monitor <$SMTP_USER>\nTo: $TO_EMAIL\nSubject: $subject\n\n$body") \
           >> "$LOG_FILE" 2>&1
  else
      echo "[$(date)] WARNING: Skipping email alert (SMTP_PASS missing)." >> "$LOG_FILE"
  fi
}

echo "[$(date)] Checking $URL (Target Container: $CONTAINER)..." >> "$LOG_FILE"

# Check Status (Follow redirects, max time 10s, insecure SSL)
STATUS=$(curl -k -s -L --max-time 10 -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" != "200" ]; then
  echo "[$(date)] CRITICAL: $URL is DOWN (Status: $STATUS). Restarting $CONTAINER..." >> "$LOG_FILE"
  
  if /usr/bin/docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1; then
      echo "[$(date)] Docker restart command successful." >> "$LOG_FILE"
      
      # Send Email Notification
      echo "[$(date)] Sending email alert to $TO_EMAIL..." >> "$LOG_FILE"
      send_email "$STATUS"

      # Wait and verify
      sleep 10
      NEW_STATUS=$(curl -k -s -L --max-time 10 -o /dev/null -w "%{http_code}" "$URL")
      echo "[$(date)] Recovery Status: $NEW_STATUS" >> "$LOG_FILE"
  else
      echo "[$(date)] ERROR: Docker restart failed." >> "$LOG_FILE"
  fi
else
  # Log success to ensure liveness is tracked (can be verbose, but good for testing)
  echo "[$(date)] OK: $URL is UP." >> "$LOG_FILE"
fi
