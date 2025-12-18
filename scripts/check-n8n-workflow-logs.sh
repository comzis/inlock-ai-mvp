#!/bin/bash
# Check n8n workflow execution logs when stuck

set -e

echo "=== n8n Workflow Execution Logs ==="
echo ""

# Check if n8n container is running
if ! docker ps | grep -q "compose-n8n-1\|n8n"; then
    echo "❌ n8n container is not running"
    echo "Start it with: docker compose -f compose/n8n.yml --env-file .env up -d"
    exit 1
fi

echo "1. Recent n8n Logs (last 50 lines):"
echo "-----------------------------------"
docker logs compose-n8n-1 --tail 50 2>&1 | grep -v "license SDK" || docker logs compose-n8n-1 --tail 50 2>&1
echo ""

echo "2. Workflow Execution Errors:"
echo "----------------------------"
docker logs compose-n8n-1 --tail 200 2>&1 | grep -iE "(error|exception|failed|stuck|timeout|execution)" | grep -v "license SDK" | tail -20 || echo "No execution errors found"
echo ""

echo "3. Database Connection:"
echo "----------------------"
docker logs compose-n8n-1 --tail 100 2>&1 | grep -iE "(database|postgres|db.*connect|connection.*fail)" | tail -10 || echo "No database connection issues"
echo ""

echo "4. Workflow Status (check n8n UI):"
echo "-----------------------------------"
echo "Visit: https://n8n.inlock.ai"
echo "Go to: Executions → Check for stuck/running workflows"
echo ""

echo "5. Check PostgreSQL:"
echo "-------------------"
if docker ps | grep -q "compose-postgres-1\|postgres"; then
    echo "✅ PostgreSQL is running"
    docker logs compose-postgres-1 --tail 20 2>&1 | grep -iE "(error|fatal)" || echo "No PostgreSQL errors"
else
    echo "❌ PostgreSQL is not running"
fi
echo ""

echo "6. Recent API Calls:"
echo "--------------------"
docker logs compose-n8n-1 --tail 100 2>&1 | grep -iE "(api|webhook|http.*request)" | tail -10 || echo "No recent API calls"
echo ""

echo "=== Next Steps ==="
echo ""
echo "If workflow is stuck:"
echo "1. Check n8n UI: https://n8n.inlock.ai → Executions"
echo "2. Look for workflows with status 'Running' or 'Error'"
echo "3. Check the specific workflow execution details"
echo "4. Try stopping and restarting the workflow"
echo ""
echo "To restart n8n:"
echo "  docker compose -f compose/n8n.yml --env-file .env restart n8n"
echo ""








