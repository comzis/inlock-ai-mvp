#!/bin/bash
# Check blog content status in Inlock AI

set -e

echo "=== Blog Content Status Check ==="
echo ""

# Check if inlock-ai container is running
if ! docker ps | grep -q "compose-inlock-ai-1\|inlock-ai"; then
    echo "❌ inlock-ai container is not running"
    echo "Start it with: docker compose -f compose/stack.yml --env-file .env up -d inlock-ai"
    exit 1
fi

echo "1. Inlock AI Container Status:"
echo "-----------------------------"
docker ps | grep inlock-ai || echo "Container not found"
echo ""

echo "2. Recent Inlock AI Logs:"
echo "-------------------------"
docker logs compose-inlock-ai-1 --tail 50 2>&1 | grep -iE "(error|blog|content|database|db)" | tail -20 || docker logs compose-inlock-ai-1 --tail 30 2>&1
echo ""

echo "3. Database Connection:"
echo "----------------------"
docker logs compose-inlock-ai-1 --tail 100 2>&1 | grep -iE "(database|postgres|db.*connect|connection.*fail)" | tail -10 || echo "No database connection issues in logs"
echo ""

echo "4. Check Database Container:"
echo "----------------------------"
if docker ps | grep -q "compose-inlock-db-1\|inlock-db"; then
    echo "✅ inlock-db container is running"
    docker logs compose-inlock-db-1 --tail 20 2>&1 | grep -iE "(error|fatal)" || echo "No database errors"
    
    echo ""
    echo "5. Database Content Check:"
    echo "-------------------------"
    echo "To check blog content in database, run:"
    echo "  docker exec -it compose-inlock-db-1 psql -U inlock -d inlock -c \"SELECT COUNT(*) FROM posts;\""
    echo "  docker exec -it compose-inlock-db-1 psql -U inlock -d inlock -c \"SELECT title, created_at FROM posts ORDER BY created_at DESC LIMIT 10;\""
else
    echo "❌ inlock-db container is not running"
    echo "Start it with: docker compose -f compose/inlock-db.yml --env-file .env up -d"
fi
echo ""

echo "6. Check Content Files:"
echo "----------------------"
if [ -d "/opt/inlock-ai-secure-mvp/content" ]; then
    echo "✅ Content directory exists"
    echo "Blog markdown files:"
    ls -lh /opt/inlock-ai-secure-mvp/content/*.md 2>/dev/null | wc -l | xargs echo "   Count:"
    echo ""
    echo "Recent blog files:"
    ls -lt /opt/inlock-ai-secure-mvp/content/*.md 2>/dev/null | head -5 || echo "   No .md files found"
else
    echo "❌ Content directory not found at /opt/inlock-ai-secure-mvp/content"
fi
echo ""

echo "7. Check Blog Metadata:"
echo "-----------------------"
if [ -f "/opt/inlock-ai-secure-mvp/src/lib/blog.ts" ]; then
    echo "✅ Blog metadata file exists"
    echo "Blog posts registered:"
    grep -c "slug:" /opt/inlock-ai-secure-mvp/src/lib/blog.ts 2>/dev/null | xargs echo "   Count:" || echo "   Could not count"
else
    echo "❌ Blog metadata file not found at /opt/inlock-ai-secure-mvp/src/lib/blog.ts"
fi
echo ""

echo "8. Test Blog Endpoint:"
echo "----------------------"
echo "Testing https://inlock.ai/blog ..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://inlock.ai/blog 2>&1 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Blog page returns 200 OK"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "❌ Could not reach blog page (connection failed)"
else
    echo "⚠️  Blog page returns HTTP $HTTP_CODE"
fi
echo ""

echo "=== Next Steps ==="
echo ""
echo "If blog content is missing:"
echo "1. Check content files: ls -la /opt/inlock-ai-secure-mvp/content/"
echo "2. Check blog metadata: cat /opt/inlock-ai-secure-mvp/src/lib/blog.ts"
echo "3. Check database: docker exec -it compose-inlock-db-1 psql -U inlock -d inlock"
echo "4. Check if there was a recent database migration or reset"
echo "5. Check backups: ls -la /data/backups/ (if exists)"
echo ""






