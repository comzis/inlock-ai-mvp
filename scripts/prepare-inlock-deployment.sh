#!/bin/bash
# Prepare Inlock AI Deployment - Setup Configuration Without Going Live
# This script prepares all configuration files but does NOT activate production routing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
APP_DIR="/opt/streamart-ai-secure-mvp/streamart-ai-secure-mvp"

echo "========================================="
echo "Inlock AI Deployment Preparation"
echo "========================================="
echo ""
echo "This script will:"
echo "  1. Generate database password"
echo "  2. Generate session secret"
echo "  3. Create environment file"
echo "  4. Verify Positive SSL certificate"
echo "  5. Prepare all configuration files"
echo ""
echo "NOTE: This prepares deployment to inlock.ai"
echo "      The app will replace the current homepage service"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Step 1: Generating database password..."
if [ ! -f "/home/comzis/apps/secrets-real/inlock-db-password" ]; then
    openssl rand -base64 32 | tr -d '\n' > /home/comzis/apps/secrets-real/inlock-db-password
    chmod 600 /home/comzis/apps/secrets-real/inlock-db-password
    chown comzis:comzis /home/comzis/apps/secrets-real/inlock-db-password
    echo "  ✅ Database password generated"
else
    echo "  ℹ️  Database password already exists, skipping..."
fi
DB_PASSWORD=$(cat /home/comzis/apps/secrets-real/inlock-db-password)
echo "  📝 Password saved to: /home/comzis/apps/secrets-real/inlock-db-password"

echo ""
echo "Step 2: Generating session secret..."
AUTH_SECRET=$(openssl rand -base64 32)
echo "  ✅ Session secret generated"

echo ""
echo "Step 3: Creating environment file..."
if [ ! -f "$APP_DIR/.env.production" ]; then
    cat > "$APP_DIR/.env.production" << EOF
# Database Configuration
DATABASE_URL=postgresql://inlock:${DB_PASSWORD}@inlock-db:5432/inlock?sslmode=disable

# Authentication
AUTH_SESSION_SECRET=${AUTH_SECRET}

# Environment
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1

# Optional: AI Provider Keys (uncomment and add your keys)
# GOOGLE_AI_API_KEY=your-key-here
# OPENAI_API_KEY=your-key-here
# ANTHROPIC_API_KEY=your-key-here

# Optional: Redis for Rate Limiting
# UPSTASH_REDIS_REST_URL=your-url
# UPSTASH_REDIS_REST_TOKEN=your-token

# Optional: Sentry
# SENTRY_DSN=your-dsn
# SENTRY_ORG=your-org
# SENTRY_PROJECT=your-project
EOF
    chmod 600 "$APP_DIR/.env.production"
    echo "  ✅ Environment file created: $APP_DIR/.env.production"
else
    echo "  ℹ️  Environment file already exists, skipping..."
fi

echo ""
echo "Step 4: Verifying Positive SSL certificate..."
if [ -f "/home/comzis/apps/secrets-real/positive-ssl.crt" ]; then
    CERT_SUBJECT=$(openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -subject 2>/dev/null | sed 's/subject=//')
    CERT_EXPIRY=$(openssl x509 -in /home/comzis/apps/secrets-real/positive-ssl.crt -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    echo "  ✅ Positive SSL certificate found"
    echo "  📋 Subject: $CERT_SUBJECT"
    echo "  📅 Expires: $CERT_EXPIRY"
    
    # Verify certificate matches key
    CERT_MOD=$(openssl x509 -noout -modulus -in /home/comzis/apps/secrets-real/positive-ssl.crt | openssl md5 | cut -d' ' -f2)
    KEY_MOD=$(openssl rsa -noout -modulus -in /home/comzis/apps/secrets-real/positive-ssl.key 2>/dev/null | openssl md5 | cut -d' ' -f2)
    if [ "$CERT_MOD" == "$KEY_MOD" ]; then
        echo "  ✅ Certificate and key match"
    else
        echo "  ⚠️  WARNING: Certificate and key may not match"
    fi
else
    echo "  ❌ ERROR: Positive SSL certificate not found!"
    echo "     Expected: /home/comzis/apps/secrets-real/positive-ssl.crt"
    exit 1
fi

echo ""
echo "Step 5: Verifying configuration files..."
if [ -f "$INFRA_DIR/compose/inlock-db.yml" ]; then
    echo "  ✅ Database config: compose/inlock-db.yml"
else
    echo "  ❌ ERROR: Database config not found!"
    exit 1
fi

if [ -f "$INFRA_DIR/compose/inlock-ai.yml" ]; then
    echo "  ✅ Application config: compose/inlock-ai.yml"
else
    echo "  ❌ ERROR: Application config not found!"
    exit 1
fi

if grep -q "inlock-ai:" "$INFRA_DIR/traefik/dynamic/services.yml"; then
    echo "  ✅ Traefik service configured"
else
    echo "  ❌ ERROR: Traefik service not configured!"
    exit 1
fi

if grep -q "inlock-ai:" "$INFRA_DIR/traefik/dynamic/routers.yml"; then
    echo "  ✅ Production router configured (inlock.ai)"
else
    echo "  ❌ ERROR: Production router not found in routers.yml!"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Preparation Complete!"
echo "========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Build the Docker image:"
echo "   cd $APP_DIR"
echo "   docker build -t inlock-ai:latest ."
echo ""
echo "2. Add database include to stack.yml:"
echo "   Edit: $INFRA_DIR/compose/stack.yml"
echo "   Add after line 10:"
echo "   include:"
echo "     - compose/inlock-db.yml"
echo ""
echo "3. Add application include to stack.yml:"
echo "   Add:"
echo "     - compose/inlock-ai.yml"
echo ""
echo "4. Start database:"
echo "   cd $INFRA_DIR"
echo "   docker compose -f compose/stack.yml --env-file .env up -d inlock-db"
echo ""
echo "5. Start application:"
echo "   docker compose -f compose/stack.yml --env-file .env up -d inlock-ai"
echo ""
echo "6. Restart Traefik to pick up new routing:"
echo "   docker compose -f compose/stack.yml --env-file .env restart traefik"
echo ""
echo "7. Test production route:"
echo "   https://inlock.ai"
echo ""
echo "Current Status:"
echo "  - inlock.ai → Inlock AI app (replaces homepage)"
echo "  - www.inlock.ai → Inlock AI app"
echo ""
echo "⚠️  IMPORTANT: The homepage service will be replaced!"
echo "   Make sure you've tested the app before deploying."
echo ""

