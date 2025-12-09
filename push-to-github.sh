#!/bin/bash
# Push inlock-infra to GitHub using token

set -e

cd /home/comzis/inlock-infra

echo "=== Pushing to GitHub ==="
echo ""

# Check if token is provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN environment variable not set"
    echo ""
    echo "Usage:"
    echo "  export GITHUB_TOKEN=your_token_here"
    echo "  ./push-to-github.sh"
    echo ""
    echo "Or provide token interactively:"
    read -sp "GitHub Personal Access Token: " token
    echo ""
    export GITHUB_TOKEN="$token"
fi

# Configure remote with token
git remote set-url origin https://${GITHUB_TOKEN}@github.com/comzis/inlock-ai-mvp.git

# Push
echo "Pushing to GitHub..."
git push -u origin main

# Reset remote URL (remove token from URL)
git remote set-url origin https://github.com/comzis/inlock-ai-mvp.git

echo ""
echo "✅ Push complete!"
echo "Repository: https://github.com/comzis/inlock-ai-mvp"
