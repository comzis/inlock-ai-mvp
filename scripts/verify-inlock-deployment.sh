#!/bin/bash
# Quick verification script for Inlock AI deployment
# Checks service status, logs, SSL, and key routes

set -e

cd /home/comzis/inlock-infra

echo "========================================="
echo "Inlock AI Deployment Verification"
echo "========================================="
echo ""

echo "1️⃣ Service Status:"
docker compose -f compose/stack.yml --env-file .env ps inlock-ai --format "table {{.Service}}\t{{.Status}}\t{{.Image}}" || exit 1

echo ""
echo "2️⃣ Recent Logs (last 20 lines):"
docker logs compose-inlock-ai-1 --tail 20 2>&1 | tail -20

echo ""
echo "3️⃣ SSL Certificate Check:"
curl -I https://inlock.ai 2>&1 | grep -E "HTTP|strict-transport-security|x-frame-options" || echo "⚠️  Could not verify SSL headers"

echo ""
echo "4️⃣ Health Check Endpoint:"
docker exec compose-inlock-ai-1 wget -qO- http://localhost:3040/api/readiness 2>/dev/null || echo "⚠️  Health check endpoint not accessible"

echo ""
echo "5️⃣ Traefik Routing:"
docker logs compose-traefik-1 --tail 50 2>&1 | grep -i "inlock-ai" | tail -5 || echo "ℹ️  No recent routing logs found"

echo ""
echo "========================================="
echo "✅ Verification Complete"
echo "========================================="
echo ""
echo "Next: Spot-check routes in browser:"
echo "  - https://inlock.ai/"
echo "  - https://inlock.ai/consulting"
echo "  - https://inlock.ai/blog"
echo "  - https://inlock.ai/readiness-checklist"

