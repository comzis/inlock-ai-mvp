#!/bin/bash
# Run diagnostics directly on the server
# Copy this script to the server and run it there

set -e

echo "=== n8n Workflow Diagnostics ==="
echo ""

# Check if n8n container is running
if docker ps | grep -q "compose-n8n-1\|n8n"; then
    echo "✅ n8n container is running"
    echo ""
    echo "Recent n8n Logs (last 50 lines):"
    echo "-----------------------------------"
    docker logs compose-n8n-1 --tail 50 2>&1 | grep -v "license SDK" || docker logs compose-n8n-1 --tail 50 2>&1
    echo ""
    echo "Workflow Execution Errors:"
    echo "----------------------------"
    docker logs compose-n8n-1 --tail 200 2>&1 | grep -iE "(error|exception|failed|stuck|timeout|execution)" | grep -v "license SDK" | tail -20 || echo "No execution errors found"
    echo ""
    echo "Database Connection:"
    echo "----------------------"
    docker logs compose-n8n-1 --tail 100 2>&1 | grep -iE "(database|postgres|db.*connect|connection.*fail)" | tail -10 || echo "No database connection issues"
    echo ""
else
    echo "❌ n8n container is not running"
    echo "Start it with: docker compose -f compose/n8n.yml --env-file .env up -d"
fi

echo ""
echo "=== Blog Content Diagnostics ==="
echo ""

# Check if inlock-ai container is running
if docker ps | grep -q "compose-inlock-ai-1\|inlock-ai"; then
    echo "✅ inlock-ai container is running"
    echo ""
    echo "Recent Inlock AI Logs:"
    echo "-------------------------"
    docker logs compose-inlock-ai-1 --tail 30 2>&1 | grep -iE "(error|blog|content|database|db)" | tail -20 || docker logs compose-inlock-ai-1 --tail 20 2>&1
    echo ""
else
    echo "❌ inlock-ai container is not running"
fi

# Check content files
echo ""
echo "Content Files Check:"
echo "----------------------"
if [ -d "/opt/inlock-ai-secure-mvp/content" ]; then
    echo "✅ Content directory exists"
    FILE_COUNT=$(ls -1 /opt/inlock-ai-secure-mvp/content/*.md 2>/dev/null | wc -l)
    echo "   Blog markdown files: $FILE_COUNT"
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "   Recent files:"
        ls -lt /opt/inlock-ai-secure-mvp/content/*.md 2>/dev/null | head -5 | awk '{print "     " $9 " (" $6 " " $7 " " $8 ")"}'
    else
        echo "   ⚠️  No .md files found in content directory"
    fi
else
    echo "❌ Content directory not found at /opt/inlock-ai-secure-mvp/content"
fi

# Check blog metadata
echo ""
echo "Blog Metadata Check:"
echo "-----------------------"
if [ -f "/opt/inlock-ai-secure-mvp/src/lib/blog.ts" ]; then
    echo "✅ Blog metadata file exists"
    POST_COUNT=$(grep -c "slug:" /opt/inlock-ai-secure-mvp/src/lib/blog.ts 2>/dev/null || echo "0")
    echo "   Blog posts registered: $POST_COUNT"
else
    echo "❌ Blog metadata file not found at /opt/inlock-ai-secure-mvp/src/lib/blog.ts"
fi

# Check database
echo ""
echo "Database Check:"
echo "----------------------------"
if docker ps | grep -q "compose-inlock-db-1\|inlock-db"; then
    echo "✅ inlock-db container is running"
    echo ""
    echo "Checking database content..."
    docker exec compose-inlock-db-1 psql -U inlock -d inlock -c "SELECT COUNT(*) as post_count FROM posts;" 2>/dev/null || echo "   ⚠️  Could not query database (may need to check connection)"
else
    echo "❌ inlock-db container is not running"
fi

echo ""
echo "=== Summary ==="
echo ""
echo "Next steps:"
echo "1. Check n8n UI: https://n8n.inlock.ai → Executions (for stuck workflows)"
echo "2. Check blog page: https://inlock.ai/blog"
echo "3. Review the output above for specific issues"
echo ""








