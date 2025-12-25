#!/bin/bash
# Production Deployment Script
# Usage: ./scripts/deploy_production.sh
# This script is intended to be run on the production server via CI/CD.

set -e

PROJECT_DIR="/home/comzis/projects/inlock-ai-mvp"
COMPOSE_DIR="$PROJECT_DIR/compose"
LOG_FILE="/home/comzis/deployments/deploy.log"

echo "[$(date)] Starting deployment..." | tee -a "$LOG_FILE"

# 1. Navigate to Project Directory
if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    echo "Directory: $(pwd)"
else
    echo "ERROR: Project directory $PROJECT_DIR not found!" | tee -a "$LOG_FILE"
    exit 1
fi

# 2. (Skipped) Pull Latest Code
# echo "Pulling latest changes from git..." | tee -a "$LOG_FILE"
# git pull origin main || { echo "Git pull failed"; exit 1; }
echo "Skipping git pull (handled by CI/CD atomicity)..." | tee -a "$LOG_FILE"

# 3. Update/Restart Containers
# We use multiple compose files as per the verified environment
echo "Rebuilding and restarting containers..." | tee -a "$LOG_FILE"

# Note: Using centralized configuration
ENV_FILE="/home/comzis/deployments/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "WARNING: $ENV_FILE not found. Falling back to project default." | tee -a "$LOG_FILE"
    ENV_FILE="$PROJECT_DIR/.env"
fi

# Deploy Stack and N8N
docker compose -f "$COMPOSE_DIR/stack.yml" -f "$COMPOSE_DIR/n8n.yml" --env-file "$ENV_FILE" up -d --build --remove-orphans >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date)] Deployment Successful." | tee -a "$LOG_FILE"
else
    echo "[$(date)] Deployment Failed with code $EXIT_CODE." | tee -a "$LOG_FILE"
    exit $EXIT_CODE
fi
