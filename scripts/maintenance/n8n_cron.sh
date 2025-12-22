#!/bin/bash
# N8N Health Check Trigger - Cron Wrapper
# Runs the N8N workflow via Docker CLI

LOG_FILE="/home/comzis/n8n_cron.log"
WORKFLOW_ID="HealthCheckFinal01"

echo "[$(date)] Triggering Health Check..." >> $LOG_FILE
docker exec -u node compose-n8n-1 n8n execute --id $WORKFLOW_ID >> $LOG_FILE 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "[$(date)] Success." >> $LOG_FILE
else
  echo "[$(date)] Failed with code $EXIT_CODE" >> $LOG_FILE
fi
