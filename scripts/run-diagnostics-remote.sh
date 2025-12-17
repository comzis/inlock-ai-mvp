#!/bin/bash
# Run diagnostics remotely on the server
# Usage: ./scripts/run-diagnostics-remote.sh

set -e

SERVER="comzis@100.83.222.69"
INLOCK_DIR="/home/comzis/inlock"

echo "=== Running Diagnostics on Server ==="
echo ""
echo "Server: $SERVER"
echo ""

# Check if we can SSH to the server
if ! ssh -o ConnectTimeout=5 "$SERVER" "echo 'Connection successful'" 2>/dev/null; then
    echo "❌ Cannot connect to server: $SERVER"
    echo ""
    echo "Please run these commands manually on the server:"
    echo ""
    echo "1. SSH to server:"
    echo "   ssh $SERVER"
    echo ""
    echo "2. Run n8n diagnostics:"
    echo "   cd $INLOCK_DIR"
    echo "   ./scripts/check-n8n-workflow-logs.sh"
    echo ""
    echo "3. Run blog content diagnostics:"
    echo "   ./scripts/check-blog-content.sh"
    exit 1
fi

echo "✅ Connected to server"
echo ""

# Copy scripts to server if they don't exist
echo "1. Ensuring scripts exist on server..."
ssh "$SERVER" "mkdir -p $INLOCK_DIR/scripts" || true

# Copy scripts
scp scripts/check-n8n-workflow-logs.sh "$SERVER:$INLOCK_DIR/scripts/"
scp scripts/check-blog-content.sh "$SERVER:$INLOCK_DIR/scripts/"

# Make scripts executable
ssh "$SERVER" "chmod +x $INLOCK_DIR/scripts/*.sh"

echo "✅ Scripts copied and made executable"
echo ""

# Run n8n diagnostics
echo "2. Running n8n workflow diagnostics..."
echo "========================================"
ssh "$SERVER" "cd $INLOCK_DIR && ./scripts/check-n8n-workflow-logs.sh"
echo ""

# Run blog content diagnostics
echo "3. Running blog content diagnostics..."
echo "========================================"
ssh "$SERVER" "cd $INLOCK_DIR && ./scripts/check-blog-content.sh"
echo ""

echo "=== Diagnostics Complete ==="
echo ""
echo "Next steps:"
echo "1. Review the output above"
echo "2. Check n8n UI: https://n8n.inlock.ai → Executions"
echo "3. Check blog page: https://inlock.ai/blog"
echo ""







