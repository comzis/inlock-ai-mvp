#!/bin/bash
# Automated deployment pipeline for Inlock AI
# 1. Runs pre-deploy checks inside application repo
# 2. Builds Docker image
# 3. Deploys via docker compose
# 4. Runs verification script

set -euo pipefail

APP_DIR="/opt/inlock-ai-secure-mvp"
INFRA_DIR="/home/comzis/inlock-infra"

echo "========================================="
echo "Deploying Inlock AI"
echo "========================================="
echo ""

if [ ! -d "$APP_DIR" ]; then
  echo "❌ Application directory $APP_DIR not found"
  exit 1
fi

cd "$APP_DIR"
echo "1️⃣ Running pre-deployment checks..."
./scripts/pre-deploy.sh

echo ""
echo "2️⃣ Building Docker image..."
docker build -t inlock-ai:latest .

echo ""
echo "3️⃣ Deploying new container..."
cd "$INFRA_DIR"
docker compose -f compose/stack.yml --env-file .env up -d --remove-orphans inlock-ai

echo ""
echo "4️⃣ Verifying deployment..."
sleep 8
./scripts/verify-inlock-deployment.sh

echo ""
echo "========================================="
echo "✅ Deployment complete"
echo "========================================="
