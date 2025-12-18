#!/bin/bash
set -e

# This script deploys the Mailu stack alongside the main stack.
# It should be run on the remote server in the project's root directory.

COMPOSE_DIR="compose"
ENV_FILE=".env"
PROJECT_DIR="/home/comzis/inlock-ai-mvp"

if [ ! -f "$PROJECT_DIR/$ENV_FILE" ]; then
    echo "Error: .env file not found in $PROJECT_DIR!"
    exit 1
fi

cd "$PROJECT_DIR"

echo "Deploying Mailu and main stack..."
docker compose -f "$COMPOSE_DIR/stack.yml" -f "$COMPOSE_DIR/mailu.yml" --env-file "$ENV_FILE" up -d

echo "Deployment complete. Checking status..."
docker compose -f "$COMPOSE_DIR/stack.yml" -f "$COMPOSE_DIR/mailu.yml" ps
