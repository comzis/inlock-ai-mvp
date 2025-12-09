#!/bin/bash
# Helper script to add CLOUDFLARE_DNS_API_TOKEN to .env
# Reads CLOUDFLARE_API_TOKEN and creates CLOUDFLARE_DNS_API_TOKEN

set -e

ENV_FILE="../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Check if CLOUDFLARE_API_TOKEN exists
if grep -q "^CLOUDFLARE_API_TOKEN=" "$ENV_FILE"; then
    TOKEN=$(grep "^CLOUDFLARE_API_TOKEN=" "$ENV_FILE" | cut -d'=' -f2-)
    
    # Check if CLOUDFLARE_DNS_API_TOKEN already exists
    if grep -q "^CLOUDFLARE_DNS_API_TOKEN=" "$ENV_FILE"; then
        echo "⚠️  CLOUDFLARE_DNS_API_TOKEN already exists in .env"
        echo "Current value: $(grep "^CLOUDFLARE_DNS_API_TOKEN=" "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/')"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
        # Remove old line
        sed -i '/^CLOUDFLARE_DNS_API_TOKEN=/d' "$ENV_FILE"
    fi
    
    # Add CLOUDFLARE_DNS_API_TOKEN
    echo "CLOUDFLARE_DNS_API_TOKEN=$TOKEN" >> "$ENV_FILE"
    echo "✅ Added CLOUDFLARE_DNS_API_TOKEN to .env"
    echo ""
    echo "Now restart Traefik:"
    echo "  docker compose -f compose/stack.yml --env-file .env restart traefik"
else
    echo "❌ CLOUDFLARE_API_TOKEN not found in .env"
    echo ""
    echo "Please add to .env:"
    echo "  CLOUDFLARE_DNS_API_TOKEN=your-cloudflare-dns-api-token"
    exit 1
fi
