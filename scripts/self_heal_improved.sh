#!/bin/bash
# Inlock AI Self-Healing Script (Improved Version)
# Checks website status and restarts a container if it's down.

# --- Configuration with Defaults ---
URL="${1:-https://inlock.ai}"
CONTAINER="${2:-compose-inlock-ai-1}"
LOG_FILE="/home/comzis/self_heal.log"
LOCK_FILE="/tmp/self_heal.lock"

# --- SMTP Configuration ---
# CRITICAL: SMTP_PASS should be set as an environment variable.
# Example: export SMTP_PASS="your_password"
TO_EMAIL="admin@inlock.ai"
SMTP_HOST="localhost"
SMTP_PORT="25"
SMTP_USER="admin@inlock.ai"
SMTP_PASS="${SMTP_PASS:-}" # Read from environment, default to empty

# --- Locking Mechanism ---
if [ -e "$LOCK_FILE" ]; then
    echo "[$(date)] INFO: Lock file exists. Another instance is likely running. Exiting." >> "$LOG_FILE"
    exit 1
fi
trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT
echo $$ > "$LOCK_FILE"

# --- Function Definitions ---
log_message() {
    echo "[$(date)] $1" >> "$LOG_FILE"
}

send_email() {
  local status_code=$1
  local subject="[Self-Healing] Service Restarted: $CONTAINER"
  
  if [ -z "$SMTP_PASS" ]; then
      log_message "CRITICAL: SMTP_PASS environment variable not set. Cannot send email alert."
      return 1
  fi

  # Using a here document for a cleaner email body
  local body=$(cat <<-EOF
From: System Monitor <$SMTP_USER>
To: $TO_EMAIL
Subject: $subject

Critical Alert:
The website $URL returned status $status_code.
The container $CONTAINER has been restarted automatically by the self-healing script.
Time: $(date)
EOF
)

  log_message "INFO: Sending email alert to $TO_EMAIL..."
  curl --url "smtp://$SMTP_HOST:$SMTP_PORT" \
       --mail-from "$SMTP_USER" \
       --mail-rcpt "$TO_EMAIL" \
       --user "$SMTP_USER:$SMTP_PASS" \
       -T <(echo -e "$body") \
       >> "$LOG_FILE" 2>&1
}

# --- Main Execution ---
log_message "INFO: Running health check for $URL..."
STATUS=$(curl -k -s -L --max-time 10 -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" != "200" ]; then
  log_message "CRITICAL: $URL is DOWN (Status: $STATUS). Restarting $CONTAINER..."
  
  # Restart container and check for success
  if /usr/bin/docker restart "$CONTAINER" >> "$LOG_FILE" 2>&1; then
      log_message "SUCCESS: Container '$CONTAINER' restarted."
      send_email "$STATUS"

      # Wait and verify recovery
      log_message "INFO: Waiting 10 seconds to verify recovery..."
      sleep 10
      NEW_STATUS=$(curl -k -s -L --max-time 10 -o /dev/null -w "%{http_code}" "$URL")
      log_message "INFO: Recovery check for $URL completed with status: $NEW_STATUS."
  else
      log_message "ERROR: Failed to restart container '$CONTAINER'. Manual intervention required."
      # Optionally send a different email for a failed restart
  fi
else
  log_message "OK: $URL is UP (Status: 200)."
fi

# --- Cleanup ---
rm -f "$LOCK_FILE"
trap - INT TERM EXIT

exit 0
